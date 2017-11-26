//
//  ShowHideUIFrameDelegate.h
//  Fletch
//
//  Created by Issac Penn on 2017/11/23.
//  Copyright © 2017年 pbb. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "ShowHideUIFrameWindowController.h"
@class ShowHideUIFrameWindowController;

@interface ShowHideUIFrameDelegate : NSObject

//完成操作
- (void) didClickFinishOperationInWindowController:(ShowHideUIFrameWindowController *)showHideUIFrameWC;

@end
