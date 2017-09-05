//
//  AddHistoryWindowController.m
//  Fletch
//
//  Created by pbb on 2017/9/4.
//  Copyright © 2017年 pbb. All rights reserved.
//

#import "AddHistoryWindowController.h"

@interface AddHistoryWindowController ()
@end

@implementation AddHistoryWindowController
#define PBLog(fmt, ...) NSLog((@"Fletch (Sketch Plugin) %s [Line %d] " fmt), __PRETTY_FUNCTION__, __LINE__, ##__VA_ARGS__);
@synthesize delegate;

- (void)windowDidLoad {
    [super windowDidLoad];

    // Implement this method to handle any initialization after your window controller's window has been loaded from its nib file.
    _datePicker.dateValue = [NSDate dateWithTimeIntervalSinceNow:0];
    [_datePicker setTimeZone: [NSTimeZone localTimeZone]];
    _updateNotesTextView.placeholderString = @"每行一条更新记录，无需输入序号";
    [[self window] makeFirstResponder:_updateNotesTextView];
}

// 将弹窗中的数据用 Delegate 传过去，因为目前还没有找到在 Framework 里直接操作文档的方法
- (IBAction)addHistory:(NSButton *)sender {
    //若更新记录内容是为空，则需要确认
    NSString *updateNotesString = _updateNotesTextView.string;
    if ([updateNotesString  isEqual: @""]) {
        _errorTipLabel.hidden = NO;
    } else {
        _errorTipLabel.hidden = YES;
        NSArray *updateNotes = [updateNotesString componentsSeparatedByCharactersInSet:[NSCharacterSet newlineCharacterSet]];
        //处理空行得到的空字符串
        NSArray *finalUpdateNotes = [updateNotes filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"SELF != \"\""]];
        [delegate handleHistoryinAddHistoryWindowController:self WithDate:_datePicker.dateValue Author:_authorTextField.stringValue Notes:finalUpdateNotes];
    }
}

/*
- (void)close {
    [super close];
    [delegate didCloseAddHistoryWindowController:self];
}
 */
@end

