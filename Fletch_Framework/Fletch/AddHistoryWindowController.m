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
@synthesize delegate;

- (void)windowDidLoad {
    [super windowDidLoad];
    _datePicker.dateValue = [NSDate dateWithTimeIntervalSinceNow:0];
    // Implement this method to handle any initialization after your window controller's window has been loaded from its nib file.
}

- (IBAction)addHistory:(NSButton *)sender {
    NSString *updateNotesString = _updateNotesTextView.string;
    NSArray *updateNotes = [updateNotesString componentsSeparatedByCharactersInSet:[NSCharacterSet newlineCharacterSet]];
    [delegate handleHistoryinAddHistoryWindowController:self WithDate:_datePicker.dateValue Author:_authorTextField.stringValue Notes:updateNotes];
}
@end

