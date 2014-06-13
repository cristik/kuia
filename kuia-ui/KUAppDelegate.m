//
//  KUAppDelegate.m
//  kuia-ui
//
//  Created by Cristian Kocza on 6/13/14.
//  Copyright (c) 2014 Cristik. All rights reserved.
//

#import "KUAppDelegate.h"
#import "KUElement.h"

@implementation KUAppDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification{
    self.pid = 309;
    [self gatherElements:nil];
}

- (IBAction)gatherElements:(id)sender{
    AXUIElementRef appElement = AXUIElementCreateApplication(self.pid);
    self.uiElements = @[[[KUElement alloc] initWithAXUIElementRef:appElement]];
}

@end

@implementation NSObject(KUIA)

- (BOOL)isUIElement{
    return ![self isKindOfClass:[KUElement class]];
}

@end
