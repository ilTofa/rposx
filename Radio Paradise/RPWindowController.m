//
//  RPWindowController.m
//  Radio Paradise
//
//  Created by Giacomo Tufano on 04/04/13.
//  ©2014 Giacomo Tufano / Christoph Gommel.
//  Licensed under MIT license. See LICENSE file or http://www.opensource.org/licenses/mit-license.php
//

#import "RPWindowController.h"

#import <AVFoundation/AVFoundation.h>

#import "RPAppDelegate.h"
#import "RPLoginWindowController.h"
#import "STKeychain.h"

@interface RPWindowController () <RPLoginWindowControllerDelegate>

@property (strong, nonatomic) AVPlayer *theStreamer;
@property (strong, nonatomic) AVPlayer *thePsdStreamer;
@property (strong, nonatomic) AVPlayer *theOldPsdStreamer;
@property double volumeLevel;
@property (weak) IBOutlet NSSlider *volumeSlider;

@property (copy, nonatomic) NSAttributedString *currentSongMetadata;
@property (copy, nonatomic) NSAttributedString *lastSongMetadata;

@property (copy, nonatomic) NSString *rawMetadataString;
@property (copy, nonatomic) NSString *theRedirector;
@property (copy, nonatomic) NSString *cookieString;
@property (copy, nonatomic) NSString *currentSongId;

@property BOOL songIsAlreadySaved;
@property (nonatomic) BOOL isPSDPlaying;

@property (strong) NSTimer *theStreamMetadataTimer;
@property (strong) NSTimer *thePsdTimer;
@property (strong) NSTimer *theImagesTimer;

@property (strong, nonatomic) NSOperationQueue *imageLoadQueue;

@property (nonatomic) NSNumber *psdDurationInSeconds;

@property (strong) NSImage *coverImage;

@property BOOL isLyricsToBeShown;

@property (strong, nonatomic) RPLoginWindowController *theLoginBox;

@property (strong) NSStatusItem *theStatusItem;
@property (strong) IBOutlet NSMenu *theStatusMenu;
@property (weak) IBOutlet NSMenuItem *mainUIMenuItem;
@property (weak) IBOutlet NSMenuItem *menuItem24K;
@property (weak) IBOutlet NSMenuItem *menuItem64K;
@property (weak) IBOutlet NSMenuItem *menuItem128K;
@property (weak) IBOutlet NSMenuItem *menuItem320K;
@property (weak) IBOutlet NSMenuItem *lyricsWindowMenuItem;
@property (weak) IBOutlet NSMenuItem *slideshowWindowMenuItem;
@property (weak) IBOutlet NSMenuItem *bitrateMenu;
@property (weak) IBOutlet NSMenuItem *songNameMenuItem;
@property (weak) IBOutlet NSMenuItem *songInfoMenuItem;
@property (weak) IBOutlet NSMenuItem *playOrStopMenuItem;
@property (weak) IBOutlet NSMenuItem *psdMenuItem;

@property (weak, nonatomic) IBOutlet NSTextField *metadataInfo;
@property (weak) IBOutlet NSButton *psdButton;
@property (weak) IBOutlet NSButton *playOrStopButton;
@property (weak) IBOutlet NSImageView *coverImageView;
@property (weak) IBOutlet NSImageView *hdImage;
@property (weak) IBOutlet NSButton *songInfoButton;
@property (unsafe_unretained) IBOutlet NSTextView *lyricsText;
@property (unsafe_unretained) IBOutlet NSWindow *slideshowWindow;
@property (unsafe_unretained) IBOutlet NSWindow *lyricsWindow;
@property (weak) IBOutlet NSTextField *metadataIntoLyrics;
@property (weak) IBOutlet NSTextField *metadataOnSlideShow;
@property (unsafe_unretained) IBOutlet NSWindow *settingsWindow;
@property (weak) IBOutlet NSButton *systemMenuIconButton;

- (IBAction)playOrStop:(id)sender;
- (IBAction)supportRP:(id)sender;
- (IBAction)startPSD:(id)sender;
- (IBAction)showSongInformations:(id)sender;

- (IBAction)showMainUI:(id)sender;
- (IBAction)showLyricsWindow:(id)sender;
- (IBAction)showSlideshowWindow:(id)sender;
- (IBAction)showSettings:(id)sender;
- (IBAction)systemMenuIconSelected:(id)sender;

- (IBAction)bitrateSelected:(id)sender;

- (IBAction)sliderChanged:(id)sender;

@end

@implementation RPWindowController

- (id)initWithWindow:(NSWindow *)window
{
    self = [super initWithWindow:window];
    if (self) {
        // Initialization code here.
    }
    
    return self;
}

-(void)awakeFromNib {
    DLog(@"Initing UI");
    //    self.window.backgroundColor = [NSColor grayColor];
    [self.window setExcludedFromWindowsMenu:YES];
    [self.slideshowWindow setContentAspectRatio:NSMakeSize(16.0, 9.0)];
    // reset text
    self.metadataInfo.stringValue = self.metadataIntoLyrics.stringValue = self.metadataOnSlideShow.stringValue = self.rawMetadataString = self.lyricsText.string = @"";
    // Set volume
    self.volumeLevel = [[NSUserDefaults standardUserDefaults] floatForKey:@"volumeLevel"];
    if (self.volumeLevel == 0.0) {
        self.volumeLevel = 0.5;
    }
    self.volumeSlider.intValue = 100 * self.volumeLevel;
    // Set menu
    [self statusItemSetup];
    // Let's see if we already have a preferred bitrate
    long savedBitrate = [[NSUserDefaults standardUserDefaults] integerForKey:@"bitrate"];
    if(savedBitrate == 0) {
        self.theRedirector = kRPURL128K;
    } else {
        [self selectBitrate:savedBitrate - 1];
    }
    self.imageLoadQueue = [[NSOperationQueue alloc] init];
    // Set PSD to not logged, not playing
    self.cookieString = nil;
    self.isPSDPlaying = NO;
    [self playMainStream];
}

- (void)windowWillClose:(NSNotification *)notification {
    if(notification.object == self.slideshowWindow) {
        DLog(@"Slideshow Window is closing");
        [self unscheduleImagesTimer];
    }
    if (notification.object == self.lyricsWindow) {
        // TODO: change menu
    }
    if(notification.object == self.window) {
        // TODO: change menu
    }
}

#pragma mark - HD images loading

-(void)scheduleImagesTimer
{
    if(self.theImagesTimer)
    {
        NSLog(@"*** WARNING: scheduleImagesTimer called with a valid timer already active!");
        return;
    }
    dispatch_async(dispatch_get_main_queue(), ^{
        NSTimeInterval howMuchTimeBetweenImages;
        if ([self.theRedirector isEqualToString:kRPURL24K]) {
            howMuchTimeBetweenImages = 60.0;
        } else if ([self.theRedirector isEqualToString:kRPURL64K]) {
            howMuchTimeBetweenImages = 25.0;
        } else {
            howMuchTimeBetweenImages = 15.0;
        }
        self.theImagesTimer = [NSTimer scheduledTimerWithTimeInterval:howMuchTimeBetweenImages target:self selector:@selector(loadNewImage:) userInfo:nil repeats:YES];
        // While we are at it, let's load a first image...
        [self loadNewImage:nil];
        DLog(@"Scheduling images timer (%@) setup to %f.0 seconds", self.theImagesTimer, howMuchTimeBetweenImages);
    });
}

-(void)unscheduleImagesTimer
{
    DLog(@"Unscheduling images timer (%@)", self.theImagesTimer);
    if(self.theImagesTimer == nil)
    {
        NSLog(@"*** WARNING: unscheduleImagesTimer called with no valid timer around!");
        return;
    }
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.theImagesTimer invalidate];
        self.theImagesTimer = nil;
    });
}

-(void)loadNewImage:(NSTimer *)timer
{
    NSMutableURLRequest *req;
    if(self.isPSDPlaying)
    {
        DLog(@"Requesting PSD image");
        req = [[NSMutableURLRequest alloc] initWithURL:[NSURL URLWithString:kHDImagePSDURL]];
        [req addValue:self.cookieString forHTTPHeaderField:@"Cookie"];
    }
    else
    {
        req = [[NSMutableURLRequest alloc] initWithURL:[NSURL URLWithString:kHDImageURLURL]];
    }
    [req setCachePolicy:NSURLRequestReloadIgnoringLocalAndRemoteCacheData];
    [req addValue:@"no-cache" forHTTPHeaderField:@"Cache-Control"];
    [NSURLConnection sendAsynchronousRequest:req queue:self.imageLoadQueue completionHandler:^(NSURLResponse *res, NSData *data, NSError *err)
     {
         if(data)
         {
             NSString *imageUrl = [[[NSString alloc]  initWithBytes:[data bytes] length:[data length] encoding: NSUTF8StringEncoding] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
             if(imageUrl)
             {
                 NSURLRequest *req = [[NSURLRequest alloc] initWithURL:[NSURL URLWithString:imageUrl]];
                 [NSURLConnection sendAsynchronousRequest:req queue:self.imageLoadQueue completionHandler:^(NSURLResponse *res, NSData *data, NSError *err)
                  {
                      if(data)
                      {
                          NSImage *temp = [[NSImage alloc] initWithData:data];
                          DLog(@"Loaded %@, sending it to screen", [res URL]);
                          // Protect from 404's
                          if(temp)
                          {
                              // load images on the main thread
                              dispatch_async(dispatch_get_main_queue(), ^{
                                  self.hdImage.image = temp;
                                  self.hdImage.hidden = NO;
                              });
                          }
                      }
                      else
                      {
                          DLog(@"Failed loading image from: <%@>", [res URL]);
                      }
                  }];
             }
             else {
                 DLog(@"Got an invalid URL");
             }
         }
     }];
}

#pragma mark -
#pragma mark Metadata management

- (NSAttributedString *)getSongMetadataStringWithSinger:(NSString *)singer andSongName:(NSString *)songName {
    NSString *title = [NSString stringWithFormat:@"%@\n%@", singer, songName];
    NSMutableAttributedString *attributed_title = [[NSMutableAttributedString alloc] initWithString:title];
    // Center text
    NSMutableParagraphStyle *paragraphStyle = [NSMutableParagraphStyle new];
    paragraphStyle.alignment = kCTTextAlignmentCenter;
    [attributed_title addAttribute:NSParagraphStyleAttributeName value:paragraphStyle range:NSMakeRange(0, [[attributed_title string] length])];
    // This is the system default for controls. anything else and it looks off
    NSDictionary *title_options = @{NSFontAttributeName: [NSFont menuFontOfSize:0]};
    // make our subtitle a different color as it is just auxillary information
    NSDictionary *sub_title_options = @{NSForegroundColorAttributeName: [NSColor disabledControlTextColor]};
    // apply our color attributes to the ranges of the string they are applicable to...
    [attributed_title addAttributes:title_options range:[title rangeOfString:singer]];
    [attributed_title addAttributes:sub_title_options range:[title rangeOfString:songName]];
    // finally set our attributed to the menu item
    return attributed_title;
}

- (void)updateSongInformationWithSinger:(NSString *)singer andSongName:(NSString *)songName
{
    self.currentSongMetadata = [self getSongMetadataStringWithSinger:singer andSongName:songName];
    
    // Avoid double notifications
    if ([self.currentSongMetadata isEqualToAttributedString:self.lastSongMetadata]) {
        return;
    }
    self.lastSongMetadata = self.currentSongMetadata;
    self.coverImageView.image = [NSImage imageNamed:@"icon"];
    self.metadataIntoLyrics.stringValue = [NSString stringWithFormat:@"%@\n%@", singer,songName];
    [self.metadataInfo setAttributedStringValue:self.currentSongMetadata];
    self.songNameMenuItem.image = [NSImage imageNamed:@"menu-icon"];
    [self.songNameMenuItem setAttributedTitle:self.currentSongMetadata];
    
    // Notification Center stuff
    if ([NSUserNotification class]) {
        NSUserNotification *notification = [[NSUserNotification alloc] init];
        [notification setTitle:singer];
        [notification setInformativeText:songName];
        [notification setHasActionButton:NO];
        [[NSUserNotificationCenter defaultUserNotificationCenter] deliverNotification:notification];
    }
}

-(void)metatadaHandler:(NSTimer *)timer
{
    // This function get metadata directly in case of PSD (no stream metadata)
    DLog(@"This is metatadaHandler: called %@", (timer == nil) ? @"directly" : @"from the 'self-timer'");
    // Get song name first
    NSMutableURLRequest *req = [[NSMutableURLRequest alloc] initWithURL:[NSURL URLWithString:@"http://www.radioparadise.com/ajax_rp2_playlist_ipad.php"]];
    // Shutdown cache (don't) and cookie management (we'll send them manually, if needed)
    [req setCachePolicy:NSURLRequestReloadIgnoringLocalAndRemoteCacheData];
    [req addValue:@"no-cache" forHTTPHeaderField:@"Cache-Control"];
    [req setHTTPShouldHandleCookies:NO];
    // Add cookies only for PSD play
    if(self.isPSDPlaying)
        [req addValue:self.cookieString forHTTPHeaderField:@"Cookie"];
    [NSURLConnection sendAsynchronousRequest:req queue:self.imageLoadQueue completionHandler:^(NSURLResponse *res, NSData *data, NSError *err)
     {
         DLog(@"metadata received %@ ", (data) ? @"successfully." : @"with errors.");
         if(data)
         {
             // Get name and massage it (it's web encoded and with triling spaces)
             NSString *stringData = [[NSString alloc]  initWithBytes:[data bytes] length:[data length] encoding: NSUTF8StringEncoding];
             NSArray *values = [stringData componentsSeparatedByString:@"|"];
             if([values count] != 4)
             {
                 NSLog(@"Error in reading metadata from http://www.radioparadise.com/ajax_rp2_playlist_ipad.php: <%@> received.", stringData);
                 return;
             }
             NSString *metaText = [values objectAtIndex:0];
             metaText = [metaText stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
             metaText = [metaText stringByReplacingOccurrencesOfString:@"&mdash;" withString:@"-"];
             dispatch_async(dispatch_get_main_queue(), ^{
                 self.metadataInfo.stringValue = self.metadataIntoLyrics.stringValue = self.metadataOnSlideShow.stringValue = self.rawMetadataString = metaText;
                 // Update metadata info
                 NSArray *songPieces = [metaText componentsSeparatedByString:@" - "];
                 if([songPieces count] == 2)
                     [self updateSongInformationWithSinger:songPieces[0] andSongName:songPieces[1]];
                 
             });
             // remembering songid for forum view
             self.currentSongId = [values objectAtIndex:1];
             DLog(@"Song id is %@.", self.currentSongId);
             // In any case, reset the "add song" capability (we have a new song, it seems).
             self.songIsAlreadySaved = NO;
             // Reschedule ourselves at the end of the song
             if(self.theStreamMetadataTimer != nil)
             {
                 dispatch_async(dispatch_get_main_queue(), ^{
                     [self.theStreamMetadataTimer invalidate];
                     self.theStreamMetadataTimer = nil;
                 });
             }
             NSNumber *whenRefresh = [values objectAtIndex:2];
             if([whenRefresh intValue] <= 0)
             {
                 whenRefresh = @([whenRefresh intValue] * -1);
                 if([whenRefresh intValue] < 5 || [whenRefresh intValue] > 30)
                     whenRefresh = @(5);
                 DLog(@"We're into the fade out... skipping %@ seconds", whenRefresh);
             }
             else
             {
                 DLog(@"Given value for song duration is: %@. Now calculating encode skew.", whenRefresh);
                 // Manually compensate for skew in encoder on lower bitrates.
                 if([self.theRedirector isEqualToString:kRPURL24K] && !self.isPSDPlaying)
                     whenRefresh = @([whenRefresh intValue] + 70);
                 else if([self.theRedirector isEqualToString:kRPURL64K] && !self.isPSDPlaying)
                     whenRefresh = @([whenRefresh intValue] + 25);
                 DLog(@"This song will last for %.0f seconds, rescheduling ourselves for refresh", [whenRefresh doubleValue]);
             }
             /* whenRefresh=@(10); //Produce lots of metadata updates for de-duplication test */
             
             dispatch_async(dispatch_get_main_queue(), ^{
                 self.theStreamMetadataTimer = [NSTimer scheduledTimerWithTimeInterval:[whenRefresh doubleValue] target:self selector:@selector(metatadaHandler:) userInfo:nil repeats:NO];
             });
             // Now get album artwork
             NSString *temp = [NSString stringWithFormat:@"http://www.radioparadise.com/graphics/covers/l/%@.jpg", [values objectAtIndex:3]];
             DLog(@"URL for Artwork: <%@>", temp);
             [self.imageLoadQueue cancelAllOperations];
             NSURLRequest *req = [[NSURLRequest alloc] initWithURL:[NSURL URLWithString:temp]];
             [NSURLConnection sendAsynchronousRequest:req queue:self.imageLoadQueue completionHandler:^(NSURLResponse *res, NSData *data, NSError *err)
              {
                  if(data)
                  {
                      self.coverImage = [[NSImage alloc] initWithData:data];
                      // Update metadata info
                      if(self.coverImage != nil)
                      {
                          dispatch_async(dispatch_get_main_queue(), ^{
                              self.coverImageView.image = self.coverImage;
                              CGImageSourceRef source;
                              source = CGImageSourceCreateWithData((__bridge CFDataRef)[self.coverImage TIFFRepresentation], NULL);
                              CGImageRef maskRef =  CGImageSourceCreateImageAtIndex(source, 0, NULL);
                              CFRelease(source);
                              NSSize imageSize = { 64.0, 64.0 };
                              NSImage *tempImage = [[NSImage alloc] initWithCGImage:maskRef size:imageSize];
                              CGImageRelease(maskRef);
                              self.songNameMenuItem.image = tempImage;
                          });
                      }
                  }
              }];
             // Now get song text
             temp = [NSString stringWithFormat:@"http://radioparadise.com/lyrics/%@.txt", self.currentSongId];
             NSURLRequest *lyricsReq = [[NSURLRequest alloc] initWithURL:[NSURL URLWithString:temp]];
             [NSURLConnection sendAsynchronousRequest:lyricsReq queue:[[NSOperationQueue alloc] init] completionHandler:^(NSURLResponse *res, NSData *data, NSError *err)
              {
                  if(data)
                  {
                      NSString *lyrics;
                      if(((NSHTTPURLResponse *)res).statusCode == 404)
                      {
                          DLog(@"No lyrics for the song");
                          lyrics = @"\r\r\r\r\rNo Lyrics Found.";
                      }
                      else
                      {
                          DLog(@"Got lyrics for the song!");
                          lyrics = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
                      }
                      dispatch_async(dispatch_get_main_queue(), ^{
                          [self.lyricsText setString:lyrics];
                      });
                  }
              }];
         }
     }];
}


#pragma mark - UI management

-(void)statusItemIconSetup {
    if ([[NSUserDefaults standardUserDefaults] boolForKey:@"bwmenuicon"]) {
        [self.theStatusItem setImage:[NSImage imageNamed:@"sessionitem-icon-bw"]];
    } else {
        [self.theStatusItem setImage:[NSImage imageNamed:@"sessionitem-icon"]];
    }
}

-(void)statusItemSetup
{
    if (self.theStatusItem) {
        DLog(@"Refreshing icon.");
        [self statusItemIconSetup];
        return;
    }
    DLog(@"Creating status menu.");
    // Init the status menu
    NSStatusBar *bar = [NSStatusBar systemStatusBar];
    self.theStatusItem = [bar statusItemWithLength:NSSquareStatusItemLength];
    [self statusItemIconSetup];
    [self.theStatusItem setHighlightMode:YES];
    [self.theStatusItem setMenu:self.theStatusMenu];
}

-(void)interfaceStop
{
    DLog(@"*** interfaceStop");
    self.currentSongId = 0;
    self.metadataInfo.stringValue = self.metadataIntoLyrics.stringValue = self.rawMetadataString = self.lyricsText.string = @"";
    [self updateSongInformationWithSinger:@"Radio Paradise" andSongName:@"Commercial Free, Listener Supported Radio"];
    [self.bitrateMenu setEnabled:YES];
    [self.playOrStopButton setTitle:@"Play"];
    NSMutableAttributedString *attributedButtonTitle = [self.psdButton.attributedTitle mutableCopy];
    [attributedButtonTitle addAttribute:NSForegroundColorAttributeName value:[NSColor blackColor] range:NSMakeRange(0,[attributedButtonTitle length] )];
    [self.psdButton setAttributedTitle:attributedButtonTitle];
    self.playOrStopButton.enabled = YES;
    [self.playOrStopMenuItem setTitle:@"Play"];
    [self.playOrStopMenuItem setEnabled:YES];
    self.psdButton.enabled = YES;
    [self.psdMenuItem setEnabled:YES];
    self.hdImage.hidden = YES;
    self.songInfoButton.enabled = NO;
    [self.songNameMenuItem setEnabled:NO];
    self.songIsAlreadySaved = YES;
    self.coverImageView.image = [NSImage imageNamed:@"icon"];
    self.songNameMenuItem.image = [NSImage imageNamed:@"menu-icon"];
    if(self.theStreamMetadataTimer != nil)
    {
        [self.theStreamMetadataTimer invalidate];
        self.theStreamMetadataTimer = nil;
    }
}

-(void)interfaceStopPending
{
    DLog(@"*** interfaceStopPending");
    self.playOrStopButton.enabled = NO;
    [self.playOrStopMenuItem setEnabled:NO];
    [self.bitrateMenu setEnabled:NO];
    self.psdButton.enabled = NO;
    [self.psdMenuItem setEnabled:NO];
    self.songInfoButton.enabled = NO;
    [self.songNameMenuItem setEnabled:NO];
}

-(void)interfacePlay
{
    DLog(@"*** interfacePlay");
    [self.bitrateMenu setEnabled:YES];
    [self.playOrStopButton setTitle:@"Stop"];
    NSMutableAttributedString *attributedButtonTitle = [self.psdButton.attributedTitle mutableCopy];
    [attributedButtonTitle addAttribute:NSForegroundColorAttributeName value:[NSColor blackColor] range:NSMakeRange(0,[attributedButtonTitle length] )];
    [self.psdButton setAttributedTitle:attributedButtonTitle];
    self.playOrStopButton.enabled = YES;
    [self.playOrStopMenuItem setTitle:@"Stop"];
    [self.playOrStopMenuItem setEnabled:YES];
    self.psdButton.enabled = YES;
    [self.psdMenuItem setEnabled:YES];
    self.songInfoButton.enabled = YES;
    [self.songNameMenuItem setEnabled:YES];
    self.songIsAlreadySaved = NO;
    self.hdImage.hidden = NO;
    if([self.slideshowWindow isVisible])
        [self scheduleImagesTimer];
    // Start metadata reading.
    DLog(@"Starting metadata handler...");
    [self metatadaHandler:nil];
}

-(void)interfacePlayPending
{
    DLog(@"*** interfacePlayPending");
    self.playOrStopButton.enabled = NO;
    [self.playOrStopMenuItem setEnabled:NO];
    [self.bitrateMenu setEnabled:NO];
    self.psdButton.enabled = NO;
    [self.psdMenuItem setEnabled:NO];
    self.songInfoButton.enabled = NO;
    [self.songNameMenuItem setEnabled:NO];
}

-(void)interfacePsd
{
    DLog(@"*** interfacePsd");
    [self.psdMenuItem setEnabled:YES];
    [self.bitrateMenu setEnabled:NO];
    [self.playOrStopButton setTitle:@"Stop PSD"];
    NSMutableAttributedString *attributedButtonTitle = [self.psdButton.attributedTitle mutableCopy];
    [attributedButtonTitle addAttribute:NSForegroundColorAttributeName value:[NSColor blueColor] range:NSMakeRange(0,[attributedButtonTitle length] )];
    [self.psdButton setAttributedTitle:attributedButtonTitle];
    self.playOrStopButton.enabled = YES;
    self.psdButton.enabled = YES;
    [self.playOrStopMenuItem setTitle:@"Stop PSD"];
    [self.playOrStopMenuItem setEnabled:YES];
    self.songInfoButton.enabled = YES;
    [self.songNameMenuItem setEnabled:YES];
    self.songIsAlreadySaved = NO;
    self.hdImage.hidden = NO;
    if([self.slideshowWindow isVisible]) {
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 0.1 * NSEC_PER_SEC), dispatch_get_main_queue(), ^(void){
            [self scheduleImagesTimer];
        });
    }
    DLog(@"Getting PSD metadata...");
    [self metatadaHandler:nil];
}

-(void)interfacePsdPending
{
    DLog(@"*** interfacePsdPending");
    self.playOrStopButton.enabled = NO;
    [self.playOrStopMenuItem setEnabled:NO];
    [self.bitrateMenu setEnabled:NO];
    self.psdButton.enabled = NO;
    [self.psdMenuItem setEnabled:NO];
    self.songInfoButton.enabled = NO;
    [self.songNameMenuItem setEnabled:NO];
}

#pragma mark - Notifications

-(void)activateNotifications
{
    DLog(@"*** activateNotifications");
    [self.theStreamer addObserver:self forKeyPath:@"status" options:0 context:nil];
    [[[NSWorkspace sharedWorkspace] notificationCenter] addObserver:self selector:@selector(appWillSleep:) name:NSWorkspaceWillSleepNotification object:NULL];
}

-(void)removeNotifications
{
    DLog(@"*** removeNotifications");
    [self.theStreamer removeObserver:self forKeyPath:@"status"];
    [[[NSWorkspace sharedWorkspace] notificationCenter] removeObserver:self name:NSWorkspaceWillSleepNotification object:NULL];
}

-(void)appWillSleep:(NSNotification *)notification {
    DLog(@"System is going to sleep, stop play (and wait for resume)");
    [self stopPressed:nil];
    [[[NSWorkspace sharedWorkspace] notificationCenter] addObserver: self selector: @selector(appIsAwake:) name:NSWorkspaceDidWakeNotification object: NULL];
}

-(void)appIsAwake:(NSNotification *)notification {
    DLog(@"Awake from sleep, received notification so (re)start play");
    [[[NSWorkspace sharedWorkspace] notificationCenter] removeObserver:self name:NSWorkspaceDidWakeNotification object:NULL];
    [self playOrStop:nil];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    DLog(@"*** observeValueForKeyPath:ofObject:change:context called!");
    if (object == self.thePsdStreamer && [keyPath isEqualToString:@"status"])
    {
        if (self.thePsdStreamer.status == AVPlayerStatusReadyToPlay)
        {
            DLog(@"psdStreamer is ReadyToPlay for %@ secs", self.psdDurationInSeconds);
            // reduce psdDurationInSeconds to allow for some fading
            NSNumber *startPsdFadingTime = @([self.psdDurationInSeconds doubleValue] - kPsdFadeOutTime);
            // Prepare stop and restart stream after the claimed lenght (minus kPsdFadeOutTime seconds to allow for fading)...
            if(self.thePsdTimer)
            {
                [self.thePsdTimer invalidate];
                self.thePsdTimer = nil;
            }
            DLog(@"We'll start PSD fading and prepare to stop after %@ secs", startPsdFadingTime);
            self.thePsdTimer = [NSTimer scheduledTimerWithTimeInterval:[startPsdFadingTime doubleValue] target:self selector:@selector(stopPsdFromTimer:) userInfo:nil repeats:NO];
            // start slow
            [self fadeInCurrentTrackNow:self.thePsdStreamer forSeconds:kFadeInTime];
            [self.thePsdStreamer play];
            DLog(@"Setting fade out after %@ sec for %.0f sec", startPsdFadingTime, kPsdFadeOutTime);
            [self presetFadeOutToCurrentTrack:self.thePsdStreamer startingAt:[startPsdFadingTime intValue] forSeconds:kPsdFadeOutTime];
            // Stop main streamer, remove observers and and reset timers.
            if(self.theImagesTimer)
                [self unscheduleImagesTimer];
            if(self.isPSDPlaying)
            {
                // Fade out and quit previous stream
                [self fadeOutCurrentTrackNow:self.theOldPsdStreamer forSeconds:kPsdFadeOutTime];
                dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, kPsdFadeOutTime * NSEC_PER_SEC);
                dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
                    DLog(@"Previous PSD stream now stopped!");
                    [self.theOldPsdStreamer pause];
                    self.theOldPsdStreamer = nil;
                });
            }
            else
            {
                // Quit main stream after fade-in of PSD
                self.isPSDPlaying = YES;
                dispatch_after(dispatch_time(DISPATCH_TIME_NOW, kFadeInTime * NSEC_PER_SEC), dispatch_get_main_queue(), ^(void){
                    DLog(@"Main stream now stopped!");
                    [self.theStreamer pause];
                    [self.theStreamer removeObserver:self forKeyPath:@"status"];
                    self.theStreamer = nil;
                });
            }
            [self interfacePsd];
        }
        else if (self.thePsdStreamer.status == AVPlayerStatusFailed)
        {
            // something went wrong. player.error should contain some information
            DLog(@"Error starting PSD streamer: %@", self.thePsdStreamer.error);
            self.thePsdStreamer = nil;
            [self playMainStream];
        }
        else if (self.thePsdStreamer.status == AVPlayerStatusUnknown)
        {
            // something went wrong. player.error should contain some information
            DLog(@"AVPlayerStatusUnknown");
        }
        else
        {
            DLog(@"Unknown status received: %ld", self.thePsdStreamer.status);
        }
    }
    else if(object == self.theStreamer && [keyPath isEqualToString:@"status"])
    {
        if (self.theStreamer.status == AVPlayerStatusFailed)
        {
            // something went wrong. player.error should contain some information
            DLog(@"Error starting the main streamer: %@", self.thePsdStreamer.error);
            self.theStreamer = nil;
            [self playMainStream];
        }
        else if (self.theStreamer.status == AVPlayerStatusReadyToPlay)
            
        {
            DLog(@"Stream is connected.");
            dispatch_async(dispatch_get_main_queue(), ^{
                [self interfacePlay];
            });
        }
        else
        {
            DLog(@"Unknown status received: %ld", self.thePsdStreamer.status);
        }
    }
    else
    {
        DLog(@"Something else called observeValueForKeyPath. KeyPath is %@", keyPath);
    }
}

-(void)stopPsdFromTimer:(NSTimer *)aTimer {
    DLog(@"This is the PSD timer triggering the end of the PSD song");
    // If still playing PSD, restart "normal" stream
    if(self.isPSDPlaying) {
        [self interfacePlayPending];
        self.isPSDPlaying = NO;
        if(self.thePsdTimer) {
            [self.thePsdTimer invalidate];
            self.thePsdTimer = nil;
        }
        DLog(@"Stopping stream in timer firing (starting fade out)");
        if(self.theImagesTimer)
            [self unscheduleImagesTimer];
        // restart main stream...
        [self playMainStream];
        // ...while giving the delay to the fading
        [self.thePsdStreamer removeObserver:self forKeyPath:@"status"];
        dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, kPsdFadeOutTime * NSEC_PER_SEC);
        dispatch_after(popTime, dispatch_get_main_queue(), ^(void) {
            DLog(@"PSD stream now stopped!");
            [self.thePsdStreamer pause];
            self.thePsdStreamer = nil;
        });
    }
}

#pragma mark - Audio Fading

-(void)setupFading:(AVPlayer *)stream fadeOut:(BOOL)isFadingOut startingAt:(CMTime)start ending:(CMTime)end
{
    DLog(@"This is setupFading fading %@ stream %@ from %lld to %lld", isFadingOut ? @"out" : @"in", stream, start.value/start.timescale, end.value/end.timescale);
    // AVPlayerObject is a property which points to an AVPlayer
    AVPlayerItem *myAVPlayerItem = stream.currentItem;
    AVAsset *myAVAsset = myAVPlayerItem.asset;
    NSArray *audioTracks = [myAVAsset tracksWithMediaType:AVMediaTypeAudio];
    
    NSMutableArray *allAudioParams = [NSMutableArray array];
    for (AVAssetTrack *track in audioTracks)
    {
        AVMutableAudioMixInputParameters *audioInputParams = [AVMutableAudioMixInputParameters audioMixInputParametersWithTrack:track];
        if(isFadingOut)
            [audioInputParams setVolumeRampFromStartVolume:1.0 toEndVolume:0 timeRange:CMTimeRangeFromTimeToTime(start, end)];
        else
            [audioInputParams setVolumeRampFromStartVolume:0 toEndVolume:1.0 timeRange:CMTimeRangeFromTimeToTime(start, end)];
        DLog(@"Adding %@ to allAudioParams", audioInputParams);
        [allAudioParams addObject:audioInputParams];
    }
    AVMutableAudioMix *audioMix = [AVMutableAudioMix audioMix];
    [audioMix setInputParameters:allAudioParams];
    [myAVPlayerItem setAudioMix:audioMix];
}

-(void)presetFadeOutToCurrentTrack:(AVPlayer *)streamToBeFaded startingAt:(int)start forSeconds:(int)duration
{
    DLog(@"This is presetFadeOutToCurrentTrack called for %@, starting at %d and for %d seconds.", streamToBeFaded, start, duration);
    [self setupFading:streamToBeFaded fadeOut:YES startingAt:CMTimeMake(start, 1) ending:CMTimeMake(start + duration, 1)];
}

-(void)fadeOutCurrentTrackNow:(AVPlayer *)streamToBeFaded forSeconds:(int)duration
{
    int32_t preferredTimeScale = 600;
    CMTime durationTime = CMTimeMakeWithSeconds((Float64)duration, preferredTimeScale);
    CMTime startTime = streamToBeFaded.currentItem.currentTime;
    CMTime endTime = CMTimeAdd(startTime, durationTime);
    DLog(@"This is fadeOutCurrentTrackNow called for %@ and %d seconds (current time is %lld).", streamToBeFaded, duration, startTime.value/startTime.timescale);
    [self setupFading:streamToBeFaded fadeOut:YES startingAt:startTime ending:endTime];
}

-(void)fadeInCurrentTrackNow:(AVPlayer *)streamToBeFaded forSeconds:(int)duration
{
    int32_t preferredTimeScale = 600;
    CMTime durationTime = CMTimeMakeWithSeconds((Float64)duration, preferredTimeScale);
    CMTime startTime = streamToBeFaded.currentItem.currentTime;
    CMTime endTime = CMTimeAdd(startTime, durationTime);
    DLog(@"This is fadeInCurrentTrackNow called for %@ and %d seconds (current time is %lld).", streamToBeFaded, duration, startTime.value/startTime.timescale);
    [self setupFading:streamToBeFaded fadeOut:NO startingAt:startTime ending:endTime];
}

#pragma mark - Actions

- (void)stopPressed:(id)sender
{
    if(self.isPSDPlaying)
    {
        // If PSD is running, simply get back to the main stream by firing the end timer...
        DLog(@"Manually firing the PSD timer (starting fading now)");
        [self fadeOutCurrentTrackNow:self.thePsdStreamer forSeconds:kPsdFadeOutTime];
        [self.thePsdTimer fire];
    }
    else
    {
        [self interfaceStopPending];
        // Process stop request.
        [self.theStreamer pause];
        // Let's give the stream a couple seconds to really stop itself
        double delayInSeconds = 1.0;    //was 2.0: MONITOR!
        dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, delayInSeconds * NSEC_PER_SEC);
        dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
            [self removeNotifications];
            if(self.theImagesTimer)
                [self unscheduleImagesTimer];
            self.theStreamer = nil;
            [self interfaceStop];
            // if called from bitrateChanged, restart
            if(sender == self)
                [self playMainStream];
        });
    }
}

- (void)RPLoginWindowControllerDidCancel:(RPLoginWindowController *)controller {
    [self.theLoginBox.window orderOut:self];
    self.theLoginBox = nil;
}

- (void)RPLoginWindowControllerDidSelect:(RPLoginWindowController *)controller withCookies:(NSString *)cookiesString {
    [self RPLoginWindowControllerDidCancel:controller];
    self.cookieString = cookiesString;
    [self playPSDNow];
}


- (void)playPSDNow
{
    DLog(@"playPSDNow called. Cookie is <%@>", self.cookieString);
    [self interfacePsdPending];
    long savedBitrate = [[NSUserDefaults standardUserDefaults] integerForKey:@"bitrate"];
    if(savedBitrate == 0) {
        savedBitrate = 2;
    } else {
        savedBitrate = savedBitrate - 1;
    }
    NSString *psdURLString = [NSString stringWithFormat:@"http://www.radioparadise.com/ajax_replace-x.php?option=0&agent=iOS&bitrate=%ld", savedBitrate];
    NSMutableURLRequest *req = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:psdURLString]];
    [req addValue:self.cookieString forHTTPHeaderField:@"Cookie"];
    [NSURLConnection sendAsynchronousRequest:req queue:self.imageLoadQueue completionHandler:^(NSURLResponse *res, NSData *data, NSError *err) {
        if(data) {
            NSString *retValue = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
            retValue = [retValue stringByTrimmingCharactersInSet:[NSCharacterSet newlineCharacterSet]];
            if (!retValue || [retValue length] == 0) {
                // This is an invalid login
                [STKeychain deleteItemForUsername:@"cookies" andServiceName:@"RP" error:&err];
                self.cookieString = nil;
                [self startPSD:self];
                return;
            }
            NSArray *values = [retValue componentsSeparatedByString:@"|"];
            if([values count] != 5) {
                NSLog(@"ERROR: wrong number of values (%ld) returned from ajax_replace", (unsigned long)[values count]);
                NSLog(@"retValue: <%@>", retValue);
                // This could be from the password changed on the RP web site in itself. Reset the cache so that the next PSD request will trigger a new login and get back to the current stream.
                self.cookieString = nil;
                [STKeychain deleteItemForUsername:@"cookies" andServiceName:@"RP" error:&err];
                NSString *userName = [[NSUserDefaults standardUserDefaults] stringForKey:@"userName"];
                [STKeychain deleteItemForUsername:userName andServiceName:@"RP" error:&err];
                [self startPSD:self];
                return;
            }
            NSString *psdSongUrl = [values objectAtIndex:0];
            NSNumber *psdSongLenght = [values objectAtIndex:1];
            NSNumber * __unused psdSongFadeIn = [values objectAtIndex:2];
            NSNumber * __unused psdSongFadeOut = [values objectAtIndex:3];
            NSNumber * __unused psdWhatever = [values objectAtIndex:4];
            DLog(@"Got PSD song information: <%@>, should run for %@ ms, with fade-in, fade-out for %@ and %@", psdSongUrl, psdSongLenght, psdSongFadeIn, psdSongFadeOut);
            // reset stream on main thread
            dispatch_async(dispatch_get_main_queue(), ^{
                // If PSD is already running...
                if(self.isPSDPlaying) {
                    self.theOldPsdStreamer = self.thePsdStreamer;
                    [self.thePsdStreamer removeObserver:self forKeyPath:@"status"];
                }
                // Begin buffering...
                self.thePsdStreamer = [[AVPlayer alloc] initWithURL:[NSURL URLWithString:psdSongUrl]];
                self.thePsdStreamer.volume = self.volumeLevel;
                // Add observer for real start and stop.
                self.psdDurationInSeconds = @(([psdSongLenght doubleValue] / 1000.0));
                [self.thePsdStreamer addObserver:self forKeyPath:@"status" options:0 context:nil];
            });
        }
        else // we have an error in PSD processing, (re)start main stream)
        {
            [self playMainStream];
        }
    }];
}

- (void)playMainStream
{
    [self interfacePlayPending];
    self.theStreamer = [[AVPlayer alloc] initWithURL:[NSURL URLWithString:self.theRedirector]];
    self.theStreamer.volume = self.volumeLevel;
    [self activateNotifications];
    [self.theStreamer play];
}

- (IBAction)playOrStop:(id)sender {
    if(self.theStreamer.rate != 0.0 || self.isPSDPlaying)
        [self stopPressed:nil];
    else
        [self playMainStream];
}

- (IBAction)supportRP:(id)sender {
    [[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:@"https://www.radioparadise.com/rp2s-content.php?name=Support&file=settings"]];
}

- (IBAction)startPSD:(id)sender {
    // Try to understand if we have cookie string in KeyChain
    NSError *err;
    self.cookieString = [STKeychain getPasswordForUsername:@"cookies" andServiceName:@"RP" error:&err];
    if(self.cookieString) {
        [self playPSDNow];
        return;
    }
    if(self.cookieString != nil) {   // already logged in. no need to show the login box
        [self playPSDNow];
    } else {
        // Show login window if it already exists, else init controller and set ourself for callback
        if(self.theLoginBox) {
            [self.theLoginBox.window makeKeyAndOrderFront:self];
        } else {
            self.theLoginBox = [[RPLoginWindowController alloc] initWithWindowNibName:@"RPLoginWindowController"];
            self.theLoginBox.delegate = self;
            [self.theLoginBox showWindow:self];
        }
    }
}

- (IBAction)showSongInformations:(id)sender {
    if(self.currentSongId == 0) {
        [self supportRP:sender];
    } else {
        NSString *url = [NSString stringWithFormat:@"http://www.radioparadise.com/rp_2.php?#name=Music&file=songinfo&song_id=%@", self.currentSongId];
        DLog(@"Opening %@ per user request", url);
        [[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:url]];
    }
}

- (IBAction)showMainUI:(id)sender {
    DLog(@"called.");
    [self.window makeKeyAndOrderFront:self];
    [NSApp activateIgnoringOtherApps:YES];
}

- (IBAction)showLyricsWindow:(id)sender {
    [self.lyricsWindow makeKeyAndOrderFront:self];
    [NSApp activateIgnoringOtherApps:YES];
}

- (IBAction)showSlideshowWindow:(id)sender {
    [self scheduleImagesTimer];
    [self.slideshowWindow makeKeyAndOrderFront:self];
    [NSApp activateIgnoringOtherApps:YES];
}

- (IBAction)showSettings:(id)sender {
    [self.settingsWindow makeKeyAndOrderFront:self];
    [NSApp activateIgnoringOtherApps:YES];
}

- (IBAction)systemMenuIconSelected:(id)sender {
    [self statusItemIconSetup];
}

- (void)selectBitrate:(NSInteger)index {
    switch (index)
    {
        case 0:
            [self bitrateSelected:self.menuItem24K];
            break;
        case 1:
            [self bitrateSelected:self.menuItem64K];
            break;
        case 2:
            [self bitrateSelected:self.menuItem128K];
            break;
        case 3:
            [self bitrateSelected:self.menuItem320K];
            break;
        default:
            break;
    }
}

- (IBAction)bitrateSelected:(id)sender {
    NSInteger selectedIndex;
    [self.menuItem24K setState:NSOffState];
    [self.menuItem64K setState:NSOffState];
    [self.menuItem128K setState:NSOffState];
    [self.menuItem320K setState:NSOffState];
    if (sender == self.menuItem24K) {
        selectedIndex = 1;
        self.theRedirector = kRPURL24K;
        [self.menuItem24K setState:NSOnState];
    } else if (sender == self.menuItem64K) {
        selectedIndex = 2;
        self.theRedirector = kRPURL64K;
        [self.menuItem64K setState:NSOnState];
    } else if (sender == self.menuItem128K) {
        selectedIndex = 3;
        self.theRedirector = kRPURL128K;
        [self.menuItem128K setState:NSOnState];
    } else {
        selectedIndex = 4;
        self.theRedirector = kRPURL320K;
        [self.menuItem320K setState:NSOnState];
    }
    // Save it for next time (+1 to use 0 as "not saved")
    [[NSUserDefaults standardUserDefaults] setInteger:selectedIndex forKey:@"bitrate"];
    // If needed, stop the stream
    if(self.theStreamer.rate != 0.0)
        [self stopPressed:self];
}

- (IBAction)sliderChanged:(id)sender {
    DLog(@"Slider value: %d", [sender intValue]);
    self.volumeLevel = [sender intValue] / 100.0;
    self.thePsdStreamer.volume = self.theStreamer.volume = self.volumeLevel;
    [[NSUserDefaults standardUserDefaults] setFloat:self.volumeLevel forKey:@"volumeLevel"];
}

@end
