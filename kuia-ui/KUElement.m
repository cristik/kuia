//
//  KUElement.m
//  kuia
//
//  Created by Cristian Kocza on 6/13/14.
//  Copyright (c) 2014 Cristik. All rights reserved.
//

#import "KUElement.h"

@implementation KUElement{
    AXUIElementRef _elementRef;
    NSDictionary *_properties;
    NSArray *_children;
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
        for(id elementRef in self.properties[@"AXChildren"]){
            [children addObject:[[KUElement alloc] initWithAXUIElementRef:(AXUIElementRef)elementRef]];
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
        CFArrayRef attributeNames;
        CFArrayRef attributeValues;
        AXUIElementCopyAttributeNames(_elementRef, &attributeNames);
        AXUIElementCopyMultipleAttributeValues(_elementRef, attributeNames, 0, &attributeValues);
        _properties = [NSDictionary dictionaryWithObjects:(__bridge_transfer NSArray*)attributeValues
                                                  forKeys:(__bridge_transfer NSArray*)attributeNames];
    }
    return _properties;
}
@end
