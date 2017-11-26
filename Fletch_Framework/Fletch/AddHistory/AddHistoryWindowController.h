//
//  AddHistoryWindowController.h
//  Fletch
//
//  Created by pbb on 2017/9/4.
//  Copyright © 2017年 pbb. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "AddHistoryDelegate.h"
#import "PBUpdateNotesTextView.h"

@interface AddHistoryWindowController : NSWindowController
@property (nonatomic, retain) AddHistoryDelegate *delegate;
@property (weak) IBOutlet NSDatePicker *datePicker;
@property (weak) IBOutlet NSTextField *authorTextField;
@property (unsafe_unretained) IBOutlet PBUpdateNotesTextView *updateNotesTextView;
@property (weak) IBOutlet NSButton *combineHistoryCheckbox;
- (IBAction)addHistory:(NSButton *)sender;
@end
