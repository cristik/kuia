//
//  KUElement.h
//  kuia
//
//  Created by Cristian Kocza on 6/13/14.
//  Copyright (c) 2014 Cristik. All rights reserved.
//

#import <Foundation/Foundation.h>

const uint8_t libraryVersion = 1;

@interface KUElement : NSObject

@property(readonly) NSDictionary *properties;
@property(readonly) NSArray *children;

+ (id)appElementForPID:(pid_t)pid;
+ (id)appElementForPath:(NSString*)path launchIfNotRunning:(BOOL)launch;
- (id)initWithAXUIElementRef:(AXUIElementRef)elementRef;

- (BOOL)matches:(NSDictionary*)queryDict;
- (NSArray*)query:(NSDictionary*)queryDict;
- (KUElement*)queryOne:(NSDictionary*)queryDict;
- (void)performAction:(NSString*)action;
@end
