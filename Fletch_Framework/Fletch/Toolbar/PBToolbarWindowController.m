//
//  PBToolbarWindowController.m
//  Fletch
//
//  Created by Issac Penn on 06/13/2018.
//  Copyright © 2018 pbb. All rights reserved.
//

#import "PBToolbarWindowController.h"
#import "PBToolbarHelper.h"
#import <Quartz/Quartz.h>

@interface PBToolbarWindowController ()

@end

@implementation PBToolbarWindowController
#define PBLog(fmt, ...) NSLog((@"Fletch (Sketch Plugin) %s [Line %d] " fmt), __PRETTY_FUNCTION__, __LINE__, ##__VA_ARGS__);
@synthesize helper, toolbar;

- (void)windowDidLoad {
    [super windowDidLoad];
    
    // 简单初始化窗口
    [[self window] setMovableByWindowBackground:YES];
    [[[self window] standardWindowButton:NSWindowMiniaturizeButton] setHidden:YES];
    [[[self window] standardWindowButton:NSWindowZoomButton] setHidden:YES];
    [[self window] setDelegate:self];
    
    // 增加了一个 View，目的是让窗口的高度不为 0（为 0 的时候窗口拉伸有问题，而且窗口圆角有问题）
    [[self backgroudView] setWantsLayer:YES];
    [[[self backgroudView] layer] setBackgroundColor:[[NSColor colorWithRed:209.0/255.0 green:208.0/255.0 blue:209.0/255.0 alpha:1.0] CGColor]];
    
    // 初始化工具栏
    toolbar = [[NSToolbar alloc] initWithIdentifier:@"PBToolbar"];
    [toolbar setAllowsUserCustomization:YES];
    [toolbar setShowsBaselineSeparator:NO];
    [toolbar setDelegate:self];
    [toolbar setSizeMode:NSToolbarSizeModeSmall];
    [self.window setToolbar:toolbar];
}

- (NSToolbarItem *)toolbar:(NSToolbar *)toolbar itemForItemIdentifier:(NSToolbarItemIdentifier)itemIdentifier willBeInsertedIntoToolbar:(BOOL)flag {
    NSToolbarItem *toolbarItem = [[NSToolbarItem alloc] initWithItemIdentifier:itemIdentifier];
    if (![itemIdentifier  isEqual: NSToolbarSeparatorItemIdentifier]) {
        // 工具栏项目命名
        NSString *commandName = [helper commandNameOfIdentifier:itemIdentifier requireFullName:YES];
        
        [toolbarItem setLabel:commandName];
        [toolbarItem setPaletteLabel:commandName];
        
        // 如果是带子菜单的项目，则需要单独处理
        if ([itemIdentifier containsString:@"Parent"]) {
            NSPopUpButton *popUpButton = [NSPopUpButton buttonWithImage:[NSImage imageNamed:NSImageNameActionTemplate] target:nil action:nil];
            [popUpButton addItemWithTitle:itemIdentifier];
            [popUpButton setBezelStyle: NSBezelStyleTexturedRounded];
            [popUpButton setBordered:NO];
            [popUpButton setImage:[NSImage imageNamed:NSImageNameAddTemplate]];
            [popUpButton setPullsDown:YES];
            [popUpButton setImagePosition:NSImageOnly];
            for (NSString *secondaryCommandIdentifier in [self.helper secondaryCommandsIdentifierOfIdentifier: itemIdentifier]) {
                PBLog(@"secondaryCommandIdentifier: %@", secondaryCommandIdentifier);
                PBLog(@"secondaryCommandName: %@", [helper commandNameOfIdentifier:secondaryCommandIdentifier requireFullName:NO]);
                [popUpButton addItemWithTitle:[helper commandNameOfIdentifier:secondaryCommandIdentifier requireFullName:NO]];
            }
            [toolbarItem setView:popUpButton];
        } else {
            [toolbarItem setImage: [NSImage imageNamed:NSImageNameAddTemplate]];
            [toolbarItem setTarget:self];
            [toolbarItem setAction:@selector(runToolbarCommand:)];
        }
    }
    return toolbarItem;
}

- (NSArray<NSToolbarItemIdentifier> *)toolbarDefaultItemIdentifiers:(NSToolbar *)toolbar {
    return [helper defaultToolbarItemIdentifiers];
}

- (NSArray<NSToolbarItemIdentifier> *)toolbarAllowedItemIdentifiers:(NSToolbar *)toolbar {
    return [helper allowedToolbarItemIdentifiers];
}

- (void)runToolbarCommand:(NSToolbarItem *)sender {
    if ([[sender itemIdentifier] containsString:@"Parent"]) {
        
    } else {
        [self.helper.delegate runToolbarCommand: [helper commandIdentifierOfIdentifier:[sender itemIdentifier]]];
    }
    
}

// 窗口关闭时移除引用
- (void)windowWillClose:(NSNotification *)notification{
    NSMutableDictionary *threadDictionary = [[NSThread mainThread] threadDictionary];
    NSString *threadIdentifier = @"com.flyme.uxd.pbb.sketch-helper.toolbar";
    [threadDictionary removeObjectForKey:threadIdentifier];
}

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
