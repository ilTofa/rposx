//
//  RPAppDelegate.m
//  Radio Paradise
//
//  Created by Giacomo Tufano on 04/04/13.
//  ©2013 Giacomo Tufano.
//  Licensed under MIT license. See LICENSE file or http://www.opensource.org/licenses/mit-license.php
//

#import "RPAppDelegate.h"

#import "iRate.h"

// This header defines PIWIK_URL, SITE_ID and PIWIK_TOKEN (substitute your piwik info)
#import "piwikinfo.h"

@implementation RPAppDelegate

+ (void)initialize {
    // Init iRate
    [iRate sharedInstance].daysUntilPrompt = 5;
    [iRate sharedInstance].usesUntilPrompt = 15;
    [iRate sharedInstance].appStoreID = 663334697;
    [iRate sharedInstance].appStoreGenreID = 0;
    [iRate sharedInstance].onlyPromptIfMainWindowIsAvailable = NO;
}

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
    self.tracker = [PiwikTracker sharedInstanceWithBaseURL:[NSURL URLWithString:PIWIK_URL] siteID:SITE_ID authenticationToken:PIWIK_TOKEN];
    self.tracker.debug = NO;
}

- (NSApplicationTerminateReply)applicationShouldTerminate:(NSApplication *)sender {
    return NSTerminateNow;
}

@end
