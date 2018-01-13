//
//  ShowHideUIFrameWindowController.h
//  Fletch
//
//  Created by Issac Penn on 2017/11/23.
//  Copyright © 2017年 pbb. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <Quartz/Quartz.h>
#import "ShowHideUIFrameDelegate.h"

@interface ShowHideUIFrameWindowController : NSWindowController <NSWindowDelegate>
@property (nonatomic, retain) ShowHideUIFrameDelegate *delegate;
-(void)shakeWindow;
-(void)handleSelectedLayer: (id *)layer;
@end
