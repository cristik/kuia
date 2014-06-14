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
@property (assign) IBOutlet NSTreeController *uiElementsController;

@property int pid;
@property NSArray *uiElements;
@property NSString *queryRole;
@property NSString *queryTitle;
@property NSString *queryDescription;
@property NSString *queryValue;

- (IBAction)gatherElements:(id)sender;
- (IBAction)searchElements:(id)sender;
- (IBAction)clickElement:(id)sender;

@end
