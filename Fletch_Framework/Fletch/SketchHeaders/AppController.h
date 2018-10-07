//
//  AppController.h
//  Fletch
//
//  Created by Issac Penn on 2018/8/27.
//  Copyright © 2018 pbb. All rights reserved.
//

#import <Cocoa/Cocoa.h>
@class MSPluginCommand;

@interface AppController : NSObject <NSApplicationDelegate, NSWindowDelegate, NSMenuDelegate, NSUserNotificationCenterDelegate>

- (NSString *)runPluginCommand:(MSPluginCommand *)arg1 fromMenu:(BOOL)arg2 context:(NSDictionary *)arg3;

@end
