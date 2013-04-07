//
//  RPLoginWindow.h
//  Radio Paradise
//
//  Created by Giacomo Tufano on 08/04/13.
//  Copyright (c) 2013 Giacomo Tufano. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class RPLoginWindow;

@protocol RPLoginWindowDelegate <NSObject>
- (void)RPLoginWindowDidCancel:(RPLoginWindow *)controller;
- (void)RPLoginWindowDidSelect:(RPLoginWindow *)controller withCookies:(NSString *)cookiesString;
@end

@interface RPLoginWindow : NSWindowController

@property(weak, nonatomic) id<RPLoginWindowDelegate> delegate;

@end
