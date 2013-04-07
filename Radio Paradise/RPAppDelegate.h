//
//  RPAppDelegate.h
//  Radio Paradise
//
//  Created by Giacomo Tufano on 04/04/13.
//  Copyright (c) 2013 Giacomo Tufano. All rights reserved.
//

#import <Cocoa/Cocoa.h>

// global notifications
#define kMainUIBusy     @"Action Pending On Main UI"
#define kMainUIReady    @"Main UI pending"

@interface RPAppDelegate : NSObject <NSApplicationDelegate>

@property (assign) IBOutlet NSWindow *window;

@end
