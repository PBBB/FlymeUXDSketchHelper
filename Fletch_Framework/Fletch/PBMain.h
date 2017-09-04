//
//  PBMain.h
//  Fletch
//
//  Created by pbb on 2017/9/1.
//  Copyright © 2017年 pbb. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "AddHistoryWindowController.h"

@interface PBMain : NSObject
@property (strong, retain) AddHistoryWindowController *addHistoryWC;

// 添加历史记录的入口
- (AddHistoryWindowController *)addHistoryWindowController;
@end
