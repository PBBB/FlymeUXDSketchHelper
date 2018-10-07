//
//  AddHistoryDelegate.h
//  Fletch
//
//  Created by pbb on 2017/9/4.
//  Copyright © 2017年 pbb. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "AddHistoryWindowController.h"

@class AddHistoryWindowController;
@interface AddHistoryDelegate : NSObject

//处理弹窗中输入的内容
- (void) handleHistoryinAddHistoryWindowController:(AddHistoryWindowController *)addHistoryWC WithInfo:(NSDictionary *)userInfo;
- (void) willCloseWindow;
//- (void) handleHistoryinAddHistoryWindowController:(AddHistoryWindowController *)addHistoryWC WithDate:(NSDate *)date Author:(NSString *)author Notes:(NSArray *)updateNotes;
@end
