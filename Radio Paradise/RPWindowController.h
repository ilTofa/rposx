//
//  RPWindowController.h
//  Radio Paradise
//
//  Created by Giacomo Tufano on 04/04/13.
//  ©2013 Giacomo Tufano.
//  Licensed under MIT license. See LICENSE file or http://www.opensource.org/licenses/mit-license.php
//

#import <Cocoa/Cocoa.h>

#define kRPURL24K @"http://radioparadise.com/m3u/aac-32.m3u"
#define kRPURL64K @"http://radioparadise.com/m3u/aac-64.m3u"
#define kRPURL128K @"http://radioparadise.com/m3u/aac-128.m3u"
#define kRPURL320K @"http://radioparadise.com/m3u/aac-320.m3u"

#define kHDImageURLURL @"http://radioparadise.com/readtxt.php"
#define kHDImagePSDURL @"http://www.radioparadise.com/ajax_image_ipad.php"
#define kRPMetadataURL @"http://www.radioparadise.com/ajax_nowplaying_data.php"

#define kPsdFadeOutTime 4.0
#define kFadeInTime 2.5

@interface RPWindowController : NSWindowController


@end
