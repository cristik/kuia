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
    if(AXAPIEnabled()){
    }
    self.pid = 0;
    self.queryRole = @"AXButton";
    self.queryTitle = @"Next";
    [self gatherElements:nil];
}

- (KUElement*)appElement{
    if(self.pid){
        if(self.pid == 1) return [KUElement systemWideElement];
        else return [KUElement appElementForPID:self.pid];
    }else{
        return [KUElement appElementForPath:@"/Applications/TextEdit.app"];
    }
}
- (IBAction)gatherElements:(id)sender{
    self.uiElements = @[self.appElement];
}

- (IBAction)searchElements:(id)sender{
    NSMutableDictionary *query = [NSMutableDictionary dictionary];
    if(self.queryRole.length) query[@"AXRole"] = self.queryRole;
    if(self.queryTitle.length) query[@"AXTitle"] = self.queryTitle;
    if(self.queryDescription.length) query[@"AXDescription"] = self.queryDescription;
    if(self.queryValue.length) query[@"AXValue"] = self.queryValue;
    self.uiElements = [self.appElement query:query];
    [self.appElement queryOne:query];
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
