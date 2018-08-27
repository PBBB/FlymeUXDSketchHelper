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
//    [[self window] setBackgroundColor:NSColor.whiteColor];
    [[self window] setMovableByWindowBackground:YES];
    [[[self window] standardWindowButton:NSWindowMiniaturizeButton] setHidden:YES];
    [[[self window] standardWindowButton:NSWindowZoomButton] setHidden:YES];
    
    //获取关闭按钮，点击后通知 js 执行相应的清理
    [[[self window] standardWindowButton:NSWindowCloseButton] setTarget:self];
    [[[self window] standardWindowButton:NSWindowCloseButton] setAction:@selector(willCloseWindow)];
    
    _datePicker.dateValue = [NSDate dateWithTimeIntervalSinceNow:0];
    [_datePicker setTimeZone: [NSTimeZone localTimeZone]];
    _updateNotesTextView.placeholderString = @"每行一条更新记录，无需输入序号";
    [[self window] setLevel: NSFloatingWindowLevel];
    [[self window] makeFirstResponder:_updateNotesTextView];
}

-(void)willCloseWindow {
    [delegate willCloseWindow];
}

// 将弹窗中的数据用 Delegate 传过去，因为目前还没有找到在 Framework 里直接操作文档的方法
- (IBAction)addHistory:(NSButton *)sender {
    
    //初始化弹窗内容
    NSAlert *alert = [[NSAlert alloc] init];
    [alert addButtonWithTitle:@"确定"];
    [alert setMessageText:@"更新记录不能为空"];

    //若更新记录内容是为空，弹窗提示
    NSString *updateNotesString = _updateNotesTextView.string;
    if ([updateNotesString  isEqual: @""]) {
        [alert beginSheetModalForWindow:[self window] completionHandler:nil];
    } else {
        NSArray *updateNotes = [updateNotesString componentsSeparatedByCharactersInSet:[NSCharacterSet newlineCharacterSet]];
        //处理空行得到的空字符串
        NSArray *finalUpdateNotes = [updateNotes filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"SELF != \"\""]];
        
        //处理空行后无有效更新内容，也弹窗提示
        if (finalUpdateNotes.count == 0) {
            [alert beginSheetModalForWindow:[self window] completionHandler:nil];
            return;
        }
        
        NSDictionary *userInfo = @{
                                   @"date" : _datePicker.dateValue,
                                   @"author" : _authorTextField.stringValue,
                                   @"notes" : finalUpdateNotes,
                                   @"willConbineHistoryOfSameDay" : self.combineHistoryCheckbox.state == NSControlStateValueOn ? @(YES) : @(NO)
                                   };
        
//        [delegate handleHistoryinAddHistoryWindowController:self WithDate:_datePicker.dateValue Author:_authorTextField.stringValue Notes:finalUpdateNotes CombineHistoryOfSameDay:willConbineHistoryOfSameDay];
//        [delegate handleHistoryinAddHistoryWindowController:self WithDate:_datePicker.dateValue Author:_authorTextField.stringValue Notes:finalUpdateNotes];
        [delegate handleHistoryinAddHistoryWindowController:self WithInfo:userInfo];
    }
}

#pragma mark - Touch Bar

- (NSTouchBar *)makeTouchBar {
    NSTouchBar *mainTouchBar = [[NSTouchBar alloc] init];
    mainTouchBar.delegate = self;
    [mainTouchBar setDefaultItemIdentifiers:@[NSTouchBarItemIdentifierOtherItemsProxy, NSTouchBarItemIdentifierFlexibleSpace, @"PBAddHistoryTouchBarPreviousAndNextDay", NSTouchBarItemIdentifierFixedSpaceLarge, @"PBAddHistoryTouchBarAddHistory"]];
    return mainTouchBar;
}

- (NSTouchBarItem *)touchBar:(NSTouchBar *)touchBar makeItemForIdentifier:(NSTouchBarItemIdentifier)identifier {
    NSCustomTouchBarItem *barItem = [[NSCustomTouchBarItem alloc] initWithIdentifier:identifier];
    
    if ([identifier isEqualToString:@"PBAddHistoryTouchBarPreviousAndNextDay"]) {
        //前一天和后一天
        NSSegmentedControl *dateSegment = [NSSegmentedControl segmentedControlWithLabels:@[@"前一天", @"后一天"] trackingMode:NSSegmentSwitchTrackingMomentary target:self action:@selector(changeDateBySegmentedControl:)];
        [barItem setView:dateSegment];
        //设置 constraint，用来限制宽度（默认太窄）
        NSArray<NSLayoutConstraint *> *dateSegmentConstraints = [NSLayoutConstraint constraintsWithVisualFormat:@"[dateSegment(>=180)]" options:NSLayoutFormatAlignAllLeft metrics:nil views:@{@"dateSegment": dateSegment}];
        [NSLayoutConstraint activateConstraints:dateSegmentConstraints];
    } else if ([identifier isEqualToString:@"PBAddHistoryTouchBarAddHistory"]) {
        //添加按钮
        NSButton *addButton = [NSButton buttonWithTitle:@"添加" target:self action:@selector(addHistory:)];
        [addButton setKeyEquivalent:@"\r"];
        [addButton setKeyEquivalentModifierMask: NSEventModifierFlagCommand];
        [barItem setView:addButton];
        //设置 constraint，用来限制宽度（默认太窄）
        NSArray<NSLayoutConstraint *> *buttonConstraints = [NSLayoutConstraint constraintsWithVisualFormat:@"[button(>=108)]" options:NSLayoutFormatAlignAllLeft metrics:nil views:@{@"button": addButton}];
        [NSLayoutConstraint activateConstraints:buttonConstraints];
    }
    return barItem;
}

- (void) changeDateBySegmentedControl: (NSSegmentedControl *) segmentedControl {
    NSDate *dateOfPicker = _datePicker.dateValue;
    
    //通过 NSCalendar 和 NSDateComponents 来对日期进行增减，可以避免错误以及自动计算月份
    NSCalendar *calendar = [[NSCalendar alloc] initWithCalendarIdentifier:NSCalendarIdentifierGregorian];
    NSDateComponents *adcomps = [[NSDateComponents alloc] init];
    switch (segmentedControl.selectedSegment) {
        case 0:
            [adcomps setDay: -1];
            break;
        case 1:
            [adcomps setDay:1];
            break;
        default: break;
    }
    NSDate *newdate = [calendar dateByAddingComponents:adcomps toDate:dateOfPicker options:0];
    
    [_datePicker setDateValue:newdate];
}

#pragma mark -

-(void)shakeWindow {
    static int numberOfShakes = 3;
    static float durationOfShake = 0.5f;
    static float vigourOfShake = 0.05f;
    
    CGRect frame=[self.window frame];
    CAKeyframeAnimation *shakeAnimation = [CAKeyframeAnimation animation];
    
    CGMutablePathRef shakePath = CGPathCreateMutable();
    CGPathMoveToPoint(shakePath, NULL, NSMinX(frame), NSMinY(frame));
    for (NSInteger index = 0; index < numberOfShakes; index++){
        CGPathAddLineToPoint(shakePath, NULL, NSMinX(frame) - frame.size.width * vigourOfShake, NSMinY(frame));
        CGPathAddLineToPoint(shakePath, NULL, NSMinX(frame) + frame.size.width * vigourOfShake, NSMinY(frame));
    }
    CGPathCloseSubpath(shakePath);
    shakeAnimation.path = shakePath;
    shakeAnimation.duration = durationOfShake;
    
    [self.window setAnimations:[NSDictionary dictionaryWithObject: shakeAnimation forKey:@"frameOrigin"]];
    [[self.window animator] setFrameOrigin:[self.window frame].origin];
}

@end

