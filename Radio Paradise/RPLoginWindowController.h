//
//  RPLoginWindow.h
//  Radio Paradise
//
//  Created by Giacomo Tufano on 08/04/13.
//  Copyright (c) 2013 Giacomo Tufano. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class RPLoginWindowController;

@protocol RPLoginWindowControllerDelegate <NSObject>
- (void)RPLoginWindowControllerDidCancel:(RPLoginWindowController *)controller;
- (void)RPLoginWindowControllerDidSelect:(RPLoginWindowController *)controller withCookies:(NSString *)cookiesString;
@end

@interface RPLoginWindowController : NSWindowController

@property(weak, nonatomic) id<RPLoginWindowControllerDelegate> delegate;

@end
