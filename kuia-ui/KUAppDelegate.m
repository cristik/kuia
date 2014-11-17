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
