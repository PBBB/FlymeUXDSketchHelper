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
@synthesize delegate, toolbar;

- (void)windowDidLoad {
    [super windowDidLoad];
    
    // Implement this method to handle any initialization after your window controller's window has been loaded from its nib file.
    [[self window] setMovableByWindowBackground:YES];
    [[[self window] standardWindowButton:NSWindowMiniaturizeButton] setHidden:YES];
    [[[self window] standardWindowButton:NSWindowZoomButton] setHidden:YES];
    toolbar = [[NSToolbar alloc] initWithIdentifier:@"PBToolbar"];
    [toolbar setAllowsUserCustomization:YES];
    [toolbar setDelegate:self];
    [toolbar setSizeMode:NSToolbarSizeModeRegular];
    [self.window setToolbar:toolbar];
    
}
//- (IBAction)didClickToolbarItem:(NSToolbarItem *)sender {
//    PBLog(@"%@ clicked", sender);
//    [delegate willRunCommand:PBToolbarCommandAddHistory];
//}

- (NSToolbarItem *)toolbar:(NSToolbar *)toolbar itemForItemIdentifier:(NSToolbarItemIdentifier)itemIdentifier willBeInsertedIntoToolbar:(BOOL)flag {
    NSToolbarItem *toolbarItem = [[NSToolbarItem alloc] initWithItemIdentifier:itemIdentifier];
    if ([itemIdentifier  isEqual: @"PBToolbarCommandAddHistory"]) {
        [toolbarItem setLabel:@"添加更新记录"];
        [toolbarItem setPaletteLabel:@"添加更新记录"];
        [toolbarItem setImage: [NSImage imageNamed:NSImageNameAddTemplate]];
        [toolbarItem setTarget:self];
        [toolbarItem setAction:@selector(runToolbarCommand:)];
        [toolbarItem setTag:0];
        PBLog(@"set command complete");
    } else {
        toolbarItem = nil;
    }
    return toolbarItem;
}

//- (void)toolbarWillAddItem:(NSNotification *)notification {
//    NSToolbarItem *toolbarItem = [notification userInfo][@"item"];
//    if ([toolbarItem.itemIdentifier  isEqual: @"PBToolbarCommandAddHistory"]) {
//        [toolbarItem setTarget:self];
//        [toolbarItem setAction:@selector(runToolbarCommand:)];
//        PBLog(@"set command complete in will");
//    }
//}

- (NSArray<NSToolbarItemIdentifier> *)toolbarDefaultItemIdentifiers:(NSToolbar *)toolbar {
    return @[@"PBToolbarCommandAddHistory"];
}

- (NSArray<NSToolbarItemIdentifier> *)toolbarAllowedItemIdentifiers:(NSToolbar *)toolbar {
    return @[@"PBToolbarCommandAddHistory"];
}

- (void)runToolbarCommand:(NSToolbarItem *)sender {
    PBLog(@"run command");
//    [delegate willRunCommand:PBToolbarCommandAddHistory];
}

- (BOOL)validateToolbarItem:(NSToolbarItem *)item {
    return YES;
}

@end
