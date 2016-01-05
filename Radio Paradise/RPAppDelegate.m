//
//  RPAppDelegate.m
//  Radio Paradise
//
//  Created by Giacomo Tufano on 04/04/13.
//  ©2013 Giacomo Tufano.
//  Licensed under MIT license. See LICENSE file or http://www.opensource.org/licenses/mit-license.php
//

#import "RPAppDelegate.h"

@implementation RPAppDelegate

+ (void)initialize {
    // Init iRate
    [iRate sharedInstance].daysUntilPrompt = 5;
    [iRate sharedInstance].usesUntilPrompt = 15;
    [iRate sharedInstance].appStoreID = 663334697;
    [iRate sharedInstance].appStoreGenreID = 0;
    [iRate sharedInstance].promptForNewVersionIfUserRated = YES;
    [iRate sharedInstance].onlyPromptIfMainWindowIsAvailable = NO;
}

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
    [iRate sharedInstance].delegate = self;
    [[NSUserDefaults standardUserDefaults] setObject:@YES forKey:@"NSQuitAlwaysKeepsWindows"];
    self.appIsQuitting = NO;
}

- (NSApplicationTerminateReply)applicationShouldTerminate:(NSApplication *)sender {
    self.appIsQuitting = YES;
    return NSTerminateNow;
}

@end
