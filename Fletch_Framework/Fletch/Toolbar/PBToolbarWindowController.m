//
//  PBToolbarWindowController.m
//  Fletch
//
//  Created by Issac Penn on 06/13/2018.
//  Copyright © 2018 pbb. All rights reserved.
//

#import "PBToolbarWindowController.h"
#import "PBToolbarDelegate.h"

@interface PBToolbarWindowController ()

@end

@implementation PBToolbarWindowController
#define PBLog(fmt, ...) NSLog((@"Fletch (Sketch Plugin) %s [Line %d] " fmt), __PRETTY_FUNCTION__, __LINE__, ##__VA_ARGS__);
@synthesize delegate;

- (void)windowDidLoad {
    [super windowDidLoad];
    
    // Implement this method to handle any initialization after your window controller's window has been loaded from its nib file.
    [[self window] setMovableByWindowBackground:YES];
    [[[self window] standardWindowButton:NSWindowMiniaturizeButton] setHidden:YES];
    [[[self window] standardWindowButton:NSWindowZoomButton] setHidden:YES];
}
//- (IBAction)didClickToolbarItem:(NSToolbarItem *)sender {
//    PBLog(@"%@ clicked", sender);
//    [delegate willRunCommand:PBToolbarCommandAddHistory];
//}

//- (NSToolbarItem *)toolbar:(NSToolbar *)toolbar itemForItemIdentifier:(NSToolbarItemIdentifier)itemIdentifier willBeInsertedIntoToolbar:(BOOL)flag {
//    PBLog(@"start set command");
//    NSToolbarItem *toolbarItem = [[NSToolbarItem alloc] initWithItemIdentifier:itemIdentifier];
//    if ([itemIdentifier  isEqual: @"PBToolbarCommandAddHistory"]) {
//        PBLog(@"set command");
//        [toolbarItem setTarget:self];
//        [toolbarItem setAction:@selector(runCommand:)];
//    }
//    return toolbarItem;
//}

//- (void)toolbarWillAddItem:(NSNotification *)notification {
//    NSToolbarItem *toolbarItem = [notification userInfo][@"item"];
//    if ([toolbarItem.itemIdentifier  isEqual: @"PBToolbarCommandAddHistory"]) {
//        PBLog(@"set command");
//        [toolbarItem setTarget:self];
//        [toolbarItem setAction:@selector(runCommand:)];
//        [toolbarItem validate];
//        PBLog(@"set command complete");
//    }
//}

- (void) runCommand: (NSToolbarItem *) sender {
    PBLog(@"run command");
//    [delegate willRunCommand:PBToolbarCommandAddHistory];
}

@end
