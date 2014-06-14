//
//  KUElement.m
//  kuia
//
//  Created by Cristian Kocza on 6/13/14.
//  Copyright (c) 2014 Cristik. All rights reserved.
//

#import "KUElement.h"

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
    NSMutableArray *candidates = [NSMutableArray arrayWithObject:self];
    NSMutableArray *result = returnFirst?nil:[NSMutableArray arrayWithCapacity:1];
    while(candidates.count){
        KUElement *candidate = candidates[0];
        [candidates removeObjectAtIndex:0];
        if([candidate matches:queryDict]){
            if(returnFirst) return candidate;
            else [result addObject:candidate];
        }
        for(id uiElem in candidate.properties[@"AXChildren"]){
            [candidates addObject:[[KUElement alloc] initWithAXUIElementRef:(__bridge AXUIElementRef)uiElem]];
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