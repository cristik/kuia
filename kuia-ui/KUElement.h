//
//  KUElement.h
//  kuia
//
//  Created by Cristian Kocza on 6/13/14.
//  Copyright (c) 2014 Cristik. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface KUElement : NSObject

@property(readonly) NSDictionary *properties;

- (id)initWithAXUIElementRef:(AXUIElementRef)elementRef;
@end
