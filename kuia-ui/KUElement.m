//
//  KUElement.m
//  kuia
//
//  Created by Cristian Kocza on 6/13/14.
//  Copyright (c) 2014 Cristik. All rights reserved.
//

#import "KUElement.h"
#include <Carbon/Carbon.h>

@interface KUIElementProperty: NSObject
@property id name;
@property id value;
- (id)initWithName:(id)name value:(id)value;
@end

@implementation KUElement{
    AXUIElementRef _elementRef;
    NSDictionary *_properties;
    NSArray *_children;
}

+ (id)appElementForPID:(pid_t)pid{
    AXUIElementRef appElement = AXUIElementCreateApplication(pid);
    if(appElement) return [[KUElement alloc] initWithAXUIElementRef:appElement];
    return nil;
}

+ (id)appElementForPath:(NSString*)path launchIfNotRunning:(BOOL)launch{
    ProcessSerialNumber psn = { kNoProcess, kNoProcess };
    while (GetNextProcess(&psn) == noErr){
        NSDictionary *info = (__bridge_transfer NSDictionary*)ProcessInformationCopyDictionary(&psn,  kProcessDictionaryIncludeAllInformationMask);
        if([info[@"CFBundleExecutable"] isEqual:path]) return [self appElementForPID:[info[@"pid"] intValue]];
    }
    if(launch){
        @try{
            NSTask *task = [NSTask launchedTaskWithLaunchPath:path arguments:@[]];
            return [self appElementForPID:task.processIdentifier];
        }@catch (NSException *ex) {
        }
    }
    return nil;
}

- (id)initWithAXUIElementRef:(AXUIElementRef)elementRef{
    if(self = [super init]){
        _elementRef = elementRef;
        CFRetain(_elementRef);
    }
    return self;
}

- (void)dealloc{
    CFRelease(_elementRef);
}

- (NSArray*)children{
    if(!_children){
        NSMutableArray *children = [NSMutableArray array];
        /*for(id elementRef in self.properties[@"AXChildren"]){
            [children addObject:[[KUElement alloc] initWithAXUIElementRef:(AXUIElementRef)elementRef]];
        }*/
        for(id prop in self.properties){
            [children addObject:[[KUIElementProperty alloc] initWithName:prop value:self.properties[prop]]];
        }
        _children = children;
    }
    return _children;
}

- (NSString*)roleDescription{
    return [NSString stringWithFormat:@"%@: %@",self.properties[(__bridge NSString*)kAXRoleDescriptionAttribute],
            self.properties[(__bridge NSString*)kAXTitleAttribute]];
}

- (NSDictionary*)properties{
    if(_properties == nil){
        CFArrayRef attributeNames = NULL;
        CFArrayRef attributeValues = NULL;
        AXUIElementCopyAttributeNames(_elementRef, &attributeNames);
        AXUIElementCopyMultipleAttributeValues(_elementRef, attributeNames, 0, &attributeValues);
        if(attributeNames && attributeValues){
            _properties = [NSDictionary dictionaryWithObjects:(__bridge_transfer NSArray*)attributeValues
                                                  forKeys:(__bridge_transfer NSArray*)attributeNames];
        }else{
            _properties = [NSDictionary dictionary];
        }
    }
    return _properties;
}

- (BOOL)matches:(NSDictionary*)queryDict{
    for(id key in queryDict){
        if(![queryDict[key] isEqual:self.properties[key]]) return NO;
    }
    return YES;
}

- (id)query:(NSDictionary*)queryDict returnFirst:(BOOL)returnFirst{
    //NSLog(@"query: %@",queryDict);
    NSMutableArray *candidates = [NSMutableArray arrayWithObject:self];
    NSMutableArray *result = returnFirst?nil:[NSMutableArray arrayWithCapacity:1];
    while(candidates.count){
        KUElement *candidate = candidates[0];
        //NSLog(@"candidate props: %@",candidate.properties);
        [candidates removeObjectAtIndex:0];
        if([candidate matches:queryDict]){
            if(returnFirst) return candidate;
            else [result addObject:candidate];
        }
        if([candidate.properties[@"AXChildren"] isKindOfClass:[NSArray class]]){
            for(id uiElem in candidate.properties[@"AXChildren"]){
                [candidates addObject:[[KUElement alloc] initWithAXUIElementRef:(__bridge AXUIElementRef)uiElem]];
            }
        }
    }
    return result;
}

- (NSArray*)query:(NSDictionary*)queryDict{
    return [self query:queryDict returnFirst:NO];
}
- (KUElement*)queryOne:(NSDictionary*)queryDict{
    return [self query:queryDict returnFirst:YES];
}

- (void)performAction:(NSString*)action{
    AXUIElementPerformAction(_elementRef, (__bridge CFStringRef)(action));
}

- (void)postKeyboardEvent:(CGCharCode)keyChar virtualKey:(CGKeyCode)virtualKey keyDown:(BOOL)keyDown{
    AXUIElementPostKeyboardEvent(_elementRef, keyChar, virtualKey, keyDown);
}

- (void)typeCharacter:(char)c{
    NSLog(@"characted: %c",c);
    static NSDictionary *charToKeyMap = nil;
    if(!charToKeyMap){
        //build the key code -> character mapping, currently only for the shift key
        TISInputSourceRef currentKeyboard = TISCopyCurrentKeyboardInputSource();
        CFDataRef layoutData = TISGetInputSourceProperty(currentKeyboard,
                                                         kTISPropertyUnicodeKeyLayoutData);
        const UCKeyboardLayout *keyboardLayout = (const UCKeyboardLayout *)CFDataGetBytePtr(layoutData);
        
        NSMutableDictionary *tmp = [NSMutableDictionary dictionaryWithCapacity:256];
        for(int i=0;i<128;i++){
            UInt32 keysDown = 0;
            UniChar chars[4];
            UniCharCount realLength;
            
            OSStatus err = UCKeyTranslate(keyboardLayout,
                                          i,
                                          kUCKeyActionDisplay,
                                          0,
                                          LMGetKbdType(),
                                          kUCKeyTranslateNoDeadKeysBit,
                                          &keysDown,
                                          sizeof(chars) / sizeof(chars[0]),
                                          &realLength,
                                          chars);
            
            if(err == noErr){
                NSString  *str = (__bridge NSString*)CFStringCreateWithCharacters(kCFAllocatorDefault,
                                                                                  chars, 1);
                if(!tmp[str]) tmp[str] = @(i);
            }
            
            //with shift holded down
            err = UCKeyTranslate(keyboardLayout,
                                 i,
                                 kUCKeyActionDisplay,
                                 (shiftKey >> 8) & 0xFF,
                                 LMGetKbdType(),
                                 kUCKeyTranslateNoDeadKeysBit,
                                 &keysDown,
                                 sizeof(chars) / sizeof(chars[0]),
                                 &realLength,
                                 chars);
            if(err == noErr){
                NSString *str = (__bridge NSString*)CFStringCreateWithCharacters(kCFAllocatorDefault,
                                                                                 chars, 1);
                if(!tmp[str]) tmp[str] = @(i+128);
                
            }
        }
        CFRelease(currentKeyboard);
        charToKeyMap = tmp;
    }
    int keyCode = [charToKeyMap[[NSString stringWithFormat:@"%c",c]] intValue];
    BOOL sendShift = keyCode >= 128;
    if(sendShift) keyCode -= 128;
    
    if(sendShift) [self postKeyboardEvent:0 virtualKey:56 keyDown:YES];
    [self postKeyboardEvent:0 virtualKey:keyCode keyDown:YES];
    [self postKeyboardEvent:0 virtualKey:keyCode keyDown:NO];
    if(sendShift) [self postKeyboardEvent:0 virtualKey:56 keyDown:NO];
}

- (void)changeAttribute:(NSString*)attribute to:(id)value{
    AXUIElementSetAttributeValue(_elementRef, (__bridge CFStringRef)attribute, (__bridge CFTypeRef)(value));
}
@end

@implementation KUIElementProperty

- (id)initWithName:(id)name value:(id)value{
    if(self = [super init]){
        _name = name;
        if(CFGetTypeID((__bridge CFTypeRef)(value)) == AXUIElementGetTypeID()){
            _value = [[KUElement alloc] initWithAXUIElementRef:(__bridge AXUIElementRef)value];
        }else if([value isKindOfClass:[NSArray class]]){
            NSMutableArray *elems = [NSMutableArray array];
            for(id elem in value){
                if(CFGetTypeID((__bridge CFTypeRef)(elem)) == AXUIElementGetTypeID()){
                    [elems addObject:[[KUElement alloc] initWithAXUIElementRef:(__bridge AXUIElementRef)elem]];
                }else{
                    [elems addObject:elem];
                }
            }
            _value = elems;
        }else{
            _value = value;
        }
    }
    return self;
}

- (NSString*)roleDescription{
    if([self.value isKindOfClass:[KUElement class]]){
        return [NSString stringWithFormat:@"%@: %@",self.name,[self.value roleDescription]];
    }else if([self.value isKindOfClass:[NSArray class]]){
        return self.name;
    }
    return [NSString stringWithFormat:@"%@: %@",self.name,self.value];
}

- (NSArray*)children{
    if([self.value isKindOfClass:[KUElement class]]){
        return [self.value children];
    }else if([self.value isKindOfClass:[NSArray class]]){
        return self.value;
    }
    return nil;
        
}
@end

@implementation NSObject(KUElement)

- (NSString*)roleDescription{
    return self.description;
}

- (NSArray*)children{
    return nil;
}

@end