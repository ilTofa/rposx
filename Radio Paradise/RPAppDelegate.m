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

#define PIWIK_URL @"http://piwik.iltofa.com/"
#define SITE_ID_TEST @"7"

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
    self.tracker = [PiwikTracker sharedTracker];
    [self startTracker:self];
}

- (NSApplicationTerminateReply)applicationShouldTerminate:(NSApplication *)sender {
    [self.tracker stopTracker];
    return NSTerminateNow;
}

#pragma mark - piwik tracker

- (IBAction)startTracker:(id)sender {
    DLog(@"Start the Tracker");
    // Start the tracker. This also creates a new session.
    NSError *error = nil;
    [self.tracker startTrackerWithPiwikURL:PIWIK_URL
                                    siteID:SITE_ID_TEST
                       authenticationToken:nil
                                 withError:&error];
    self.tracker.dryRun = NO;
    // Start the timer dispatch strategy
    self.timerStrategy = [PTTimerDispatchStrategy strategyWithErrorBlock:^(NSError *error) {
        NSLog(@"The timer strategy failed to initated dispatch of analytic events");
    }];
    self.timerStrategy.timeInteraval = 20; // Set the time interval to 20s, default value is 3 minutes
    [self.timerStrategy startDispatchTimer];
}


- (IBAction)stopTracker:(id)sender {
    DLog(@"Stop the Tracker");
    // Stop the Tracker from accepting new events
    [self.tracker stopTracker];
    // Stop the time strategy
    [self.timerStrategy stopDispatchTimer];
}

@end
