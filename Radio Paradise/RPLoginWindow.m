//
//  RPLoginWindow.m
//  Radio Paradise
//
//  Created by Giacomo Tufano on 08/04/13.
//  Copyright (c) 2013 Giacomo Tufano. All rights reserved.
//

#import "RPLoginWindow.h"

@interface RPLoginWindow ()

@property (weak) IBOutlet NSTextField *usernameField;
@property (weak) IBOutlet NSSecureTextField *passwordField;

- (IBAction)startPSD:(id)sender;
- (IBAction)cancel:(id)sender;
- (IBAction)createNewUser:(id)sender;

@end

@implementation RPLoginWindow

- (id)initWithWindow:(NSWindow *)window
{
    self = [super initWithWindow:window];
    if (self) {
        // Initialization code here.
    }
    
    return self;
}

- (void)windowDidLoad
{
    [super windowDidLoad];
    
    // Implement this method to handle any initialization after your window controller's window has been loaded from its nib file.
}

- (IBAction)startPSD:(id)sender {
}

- (IBAction)cancel:(id)sender {
}

- (IBAction)createNewUser:(id)sender {
}
@end
