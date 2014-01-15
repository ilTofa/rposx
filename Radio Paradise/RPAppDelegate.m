//
//  RPAppDelegate.m
//  Radio Paradise
//
//  Created by Giacomo Tufano on 04/04/13.
//  ©2013 Giacomo Tufano.
//  Licensed under MIT license. See LICENSE file or http://www.opensource.org/licenses/mit-license.php
//

#import "RPAppDelegate.h"

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
    if (![[NSUserDefaults standardUserDefaults] boolForKey:@"disallowPiwik"]) {
        [self piwikSetup];
    }
    [iRate sharedInstance].delegate = self;
}

- (NSApplicationTerminateReply)applicationShouldTerminate:(NSApplication *)sender {
    return NSTerminateNow;
}

#pragma mark - iRateDelegate

- (void)iRateUserDidAttemptToRateApp {
    [self.piwikTracker sendEventWithCategory:@"rate" action:@"iRateUserDidAttemptToRateApp" label:@""];
}

- (void)iRateUserDidDeclineToRateApp {
    [self.piwikTracker sendEventWithCategory:@"rate" action:@"iRateUserDidDeclineToRateApp" label:@""];
}

- (void)iRateUserDidRequestReminderToRateApp {
    [self.piwikTracker sendEventWithCategory:@"rate" action:@"iRateUserDidRequestReminderToRateApp" label:@""];
}

#pragma mark piwik setup

- (void)piwikSetup {
    NSLog(@"Setting up piwik");
    self.piwikTracker = [PiwikTracker sharedInstanceWithBaseURL:[NSURL URLWithString:PIWIK_URL] siteID:SITE_ID authenticationToken:PIWIK_TOKEN];
    self.piwikTracker.debug = YES;
}

@end
