//
//  PDFExportProgressWindowController.m
//  Fletch
//
//  Created by pbb on 2018/4/3.
//  Copyright © 2018年 pbb. All rights reserved.
//

#import "PDFExportProgressWindowController.h"

@interface PDFExportProgressWindowController ()

@end

@implementation PDFExportProgressWindowController

- (void)windowDidLoad {
    [super windowDidLoad];
    
    // Implement this method to handle any initialization after your window controller's window has been loaded from its nib file.
    [[self window] setMovableByWindowBackground:YES];
}
- (IBAction)cancelExport:(NSButton *)sender {
    NSString *const TaskCanceledByUserNotificationName = @"TaskCanceledByUserNotification";
    [[NSNotificationCenter defaultCenter] postNotificationName:TaskCanceledByUserNotificationName object:self];
}

@end
