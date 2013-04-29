//
//  RPLoginWindow.h
//  Radio Paradise
//
//  Created by Giacomo Tufano on 08/04/13.
//  ©2013 Giacomo Tufano.
//  Licensed under MIT license. See LICENSE file or http://www.opensource.org/licenses/mit-license.php
//

#import <Cocoa/Cocoa.h>

@class RPLoginWindowController;

@protocol RPLoginWindowControllerDelegate <NSObject>
- (void)RPLoginWindowControllerDidCancel:(RPLoginWindowController *)controller;
- (void)RPLoginWindowControllerDidSelect:(RPLoginWindowController *)controller withCookies:(NSString *)cookiesString;
@end

@interface RPLoginWindowController : NSWindowController

@property(unsafe_unretained, nonatomic) id<RPLoginWindowControllerDelegate> delegate;

@end
