//
//  KUAppDelegate.h
//  kuia-ui
//
//  Created by Cristian Kocza on 6/13/14.
//  Copyright (c) 2014 Cristik. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface KUAppDelegate : NSObject <NSApplicationDelegate>

@property (assign) IBOutlet NSWindow *window;
@property int pid;
@property NSArray *uiElements;

- (IBAction)gatherElements:(id)sender;

@end
