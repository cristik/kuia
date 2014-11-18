// Copyright (c) 2014, Cristian Kocza
// All rights reserved.
//
// Redistribution and use in source and binary forms, with or without
// modification, are permitted provided that the following conditions are met:
//
// 1. Redistributions of source code must retain the above copyright notice,
// this list of conditions and the following disclaimer.
//
// 2. Redistributions in binary form must reproduce the above copyright notice,
// this list of conditions and the following disclaimer in the documentation
// and/or other materials provided with the distribution.
//
// THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
// AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO,
// THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR
// PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER
// OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL,
// EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO,
// PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS;
// OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY,
// WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE
// OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF
// ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

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

+ (BOOL)hasAccess{
    NSDictionary *options = @{(__bridge NSString*)kAXTrustedCheckOptionPrompt:@YES};
    return AXIsProcessTrustedWithOptions((__bridge CFDictionaryRef)options);
}

+ (id)systemWideElement{
    AXUIElementRef systemWideElement = AXUIElementCreateSystemWide();
    KUElement *element = nil;
    if(systemWideElement){
        element = [[KUElement alloc] initWithAXUIElementRef:systemWideElement];
        CFRelease(systemWideElement);
    }
    return element;
}

+ (id)appElementForPID:(pid_t)pid{
    AXUIElementRef appElement = AXUIElementCreateApplication(pid);
    KUElement *element = nil;
    if(appElement){
        element = [[KUElement alloc] initWithAXUIElementRef:appElement];
        CFRelease(appElement);
    }
    return element;
}

+ (id)appElementForPath:(NSString*)path{
    ProcessSerialNumber psn = { kNoProcess, kNoProcess };
    while (GetNextProcess(&psn) == noErr){
        NSDictionary *info = (__bridge_transfer NSDictionary*)ProcessInformationCopyDictionary(&psn,  kProcessDictionaryIncludeAllInformationMask);
        if([info[@"CFBundleExecutable"] isEqual:path] || [info[@"BundlePath"] isEqual:path]){
            return [self appElementForPID:[info[@"pid"] intValue]];
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
        CFArrayRef actions = NULL;
        AXUIElementCopyActionNames(_elementRef, &actions);
        if(actions){
            [children addObject:[[KUIElementProperty alloc] initWithName:@"actions" value:[(__bridge_transfer NSArray*)actions componentsJoinedByString:@", "]]];
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

- (id)matches:(NSDictionary*)queryDict{
    NSNumber *childIndex = queryDict[@":index"];
    BOOL match = YES;
    for(NSString *key in queryDict){
        if(![key isKindOfClass:[NSString class]]) continue;
        if(key.length && [key characterAtIndex:0] == ':') continue;
        if(![queryDict[key] isEqual:self.properties[key]]){
            match = NO;
            break;
        }
    }
    if(match){
        if(childIndex){
            NSArray *children = self.properties[NSAccessibilityChildrenAttribute];
            if(childIndex.integerValue < children.count){
                return [[KUElement alloc] initWithAXUIElementRef:(__bridge AXUIElementRef)children[childIndex.integerValue]];
            }else{
                return nil;
            }
        }else{
            return self;
        }
    }else{
        return nil;
    }
}

- (id)query:(NSDictionary*)queryDict returnFirst:(BOOL)returnFirst{
    //NSLog(@"query: %@",queryDict);
    NSNumber *order = queryDict[@":order"];
    NSMutableArray *candidates = [NSMutableArray arrayWithObject:self];
    NSMutableArray *result = returnFirst&&!order?nil:[NSMutableArray arrayWithCapacity:1];
    while(candidates.count){
        KUElement *candidate = candidates[0];
        //NSLog(@"candidate props: %@",candidate.properties);
        [candidates removeObjectAtIndex:0];
        KUElement *match = [candidate matches:queryDict];
        if(match){
            if(returnFirst && !order) return match;
            else [result addObject:match];
        }
        if([candidate.properties[@"AXChildren"] isKindOfClass:[NSArray class]]){
            for(id uiElem in candidate.properties[@"AXChildren"]){
                [candidates addObject:[[KUElement alloc] initWithAXUIElementRef:(__bridge AXUIElementRef)uiElem]];
            }
        }
    }
    if(order) {
        if(result.count >= order.integerValue) {
            result = result[order.integerValue-1];
        } else {
            result = nil;
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