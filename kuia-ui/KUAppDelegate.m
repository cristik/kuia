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
    self.pid = 2231;
    self.queryRole = @"AXButton";
    self.queryTitle = @"Next";
    [self gatherElements:nil];
}

- (IBAction)gatherElements:(id)sender{
    self.uiElements = @[[KUElement appElementForPath:@"/Applications/TextEdit.app/Contents/MacOS/TextEdit" launchIfNotRunning:YES]];
}

- (IBAction)searchElements:(id)sender{
    NSMutableDictionary *query = [NSMutableDictionary dictionary];
    if(self.queryRole.length) query[@"AXRole"] = self.queryRole;
    if(self.queryTitle.length) query[@"AXTitle"] = self.queryTitle;
    self.uiElements = [[KUElement appElementForPID:self.pid] query:query];
}

- (IBAction)clickElement:(id)sender{
    [(KUElement*)[self.uiElementsController selectedObjects].lastObject performAction:@"AXPress"];
}
@end

@implementation NSObject(KUIA)

- (BOOL)isNotUIElement{
    return ![self isKindOfClass:[KUElement class]];
}

@end
