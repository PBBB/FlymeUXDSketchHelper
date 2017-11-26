//
//  ShowHideUIFrameWindowController.m
//  Fletch
//
//  Created by Issac Penn on 2017/11/23.
//  Copyright © 2017年 pbb. All rights reserved.
//

#import "ShowHideUIFrameWindowController.h"

@interface ShowHideUIFrameWindowController ()
#define PBLog(fmt, ...) NSLog((@"Fletch (Sketch Plugin) %s [Line %d] " fmt), __PRETTY_FUNCTION__, __LINE__, ##__VA_ARGS__);
@end

@implementation ShowHideUIFrameWindowController
@synthesize delegate;
- (IBAction)finishOperation:(NSButton *)sender {
    [delegate didClickFinishOperationInWindowController:self];
}

- (void)windowDidLoad {
    [super windowDidLoad];
    
    [[self window] setBackgroundColor:NSColor.whiteColor];
    [[self window] setMovableByWindowBackground:YES];
    [[[self window] standardWindowButton:NSWindowMiniaturizeButton] setHidden:YES];
    [[[self window] standardWindowButton:NSWindowZoomButton] setHidden:YES];
}

@end
