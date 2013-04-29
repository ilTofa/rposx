//
//  RPLoginWindow.m
//  Radio Paradise
//
//  Created by Giacomo Tufano on 08/04/13.
//  ©2013 Giacomo Tufano.
//  Licensed under MIT license. See LICENSE file or http://www.opensource.org/licenses/mit-license.php
//

#import "RPLoginWindowController.h"

#import "STKeychain.h"

@interface RPLoginWindowController ()

@property (weak) IBOutlet NSTextField *usernameField;
@property (weak) IBOutlet NSSecureTextField *passwordField;
@property (weak) IBOutlet NSTextField *formHeader;

- (IBAction)startPSD:(id)sender;
- (IBAction)cancel:(id)sender;
- (IBAction)createNewUser:(id)sender;

@end

@implementation RPLoginWindowController

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
    
    NSError *err;
    NSString *userName = [[NSUserDefaults standardUserDefaults] stringForKey:@"userName"];
    if(userName)
    {
        self.usernameField.stringValue = userName;
        NSString *password = [STKeychain getPasswordForUsername:userName andServiceName:@"RP" error:&err];
        if(password)
            self.passwordField.stringValue = password;
    }
    [self.usernameField becomeFirstResponder];
}

- (IBAction)startPSD:(id)sender {
    // Try to login to RP
    NSString *temp = [NSString stringWithFormat:@"http://www.radioparadise.com/ajax_login.php?username=%@&passwd=%@", self.usernameField.stringValue, self.passwordField.stringValue];
    DLog(@"Logging in with <%@>", temp);
    NSURLRequest *req = [[NSURLRequest alloc] initWithURL:[NSURL URLWithString:temp]];
    [NSURLConnection sendAsynchronousRequest:req queue:[[NSOperationQueue alloc] init] completionHandler:^(NSURLResponse *res, NSData *data, NSError *err)
     {
         // Login is successful if data is not nil and data is not "invalid login"
         NSString *retValue = nil;
         if(data)
             retValue = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
         BOOL invalidLogin = [retValue rangeOfString:@"invalid "].location != NSNotFound;
         if(retValue && !invalidLogin) { // If login successful, save info and send information to parent
             DLog(@"Login to RP is successful");
             retValue = [retValue stringByTrimmingCharactersInSet:[NSCharacterSet newlineCharacterSet]];
             NSArray *values = [retValue componentsSeparatedByString:@"|"];
             if([values count] != 2)
                 dispatch_async(dispatch_get_main_queue(), ^{
                     self.formHeader.stringValue = @"Network error in login, please retry later.";
                     self.formHeader.textColor = [NSColor redColor];
                 });
             NSString *cookieString = [NSString stringWithFormat:@"C_username=%@; C_passwd=%@", [values objectAtIndex:0], [values objectAtIndex:1]];
             dispatch_async(dispatch_get_main_queue(), ^{
                 NSError *err;
                 [[NSUserDefaults standardUserDefaults] setObject:self.usernameField.stringValue forKey:@"userName"];
                 [STKeychain storeUsername:self.usernameField.stringValue andPassword:self.passwordField.stringValue forServiceName:@"RP" updateExisting:YES error:&err];
                 [STKeychain storeUsername:@"cookies" andPassword:cookieString forServiceName:@"RP" updateExisting:YES error:&err];
                 self.formHeader.stringValue = @"Enter your Radio Paradise login";
                 self.formHeader.textColor = [NSColor blackColor];
                 [self.delegate RPLoginWindowControllerDidSelect:self withCookies:cookieString];
             });
         } else { // If not, notify the user (on main thread)
             dispatch_async(dispatch_get_main_queue(), ^{
                 self.formHeader.stringValue = @"Invalid login, please retry";
                 self.formHeader.textColor = [NSColor redColor];
             });
         }
     }];
}

- (IBAction)cancel:(id)sender {
    [self.delegate RPLoginWindowControllerDidCancel:self];
}

- (IBAction)createNewUser:(id)sender {
    [[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:@"http://www.radioparadise.com/rp_2.php#name=Members&file=register"]];
    [self.delegate RPLoginWindowControllerDidCancel:self];
}
@end
