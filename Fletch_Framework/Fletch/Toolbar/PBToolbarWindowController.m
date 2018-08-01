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
    toolbar = [[PBToolbar alloc] initWithIdentifier:@"PBToolbar"];
    [toolbar setAllowsUserCustomization:YES];
    [toolbar setShowsBaselineSeparator:NO];
    [toolbar setDelegate:self];
    [toolbar setSizeMode:NSToolbarSizeModeSmall];
    [toolbar setAutosavesConfiguration:YES];
    [self.window setToolbar:toolbar];
    [toolbar disableTextOnlyMode];
}

- (NSToolbarItem *)toolbar:(NSToolbar *)toolbar itemForItemIdentifier:(NSToolbarItemIdentifier)itemIdentifier willBeInsertedIntoToolbar:(BOOL)flag {
    NSToolbarItem *toolbarItem = [[NSToolbarItem alloc] initWithItemIdentifier:itemIdentifier];
    if (![itemIdentifier  isEqual: NSToolbarSeparatorItemIdentifier]) {
        // 工具栏项目命名
        NSString *commandName = [helper commandNameOfIdentifier:itemIdentifier requireFullName:YES];
        
        [toolbarItem setLabel:commandName];
        [toolbarItem setToolTip:commandName];
        [toolbarItem setPaletteLabel:commandName];
        
        // 如果是带子菜单的项目，则需要单独处理
        if ([itemIdentifier containsString:@"Parent"]) {
            
            // 初始化下拉菜单控件
            NSPopUpButton *popUpButton = [NSPopUpButton buttonWithTitle:@"" target:nil action:nil];
            [popUpButton setBezelStyle: NSBezelStyleTexturedRounded];
            [popUpButton setBordered:NO];
            [popUpButton setPullsDown:YES];
            
            // 设定第一个项目的标题为空，这样控件才能使用它的 icon
            [popUpButton addItemWithTitle:@""];
            [[[popUpButton itemArray] firstObject] setImage:[NSImage imageNamed:NSImageNameBookmarksTemplate]];
            [((NSPopUpButtonCell *)[popUpButton cell]) setArrowPosition:NSPopUpNoArrow];
            [popUpButton setImagePosition:NSImageOnly];
            [popUpButton setImageScaling:NSImageScaleProportionallyUpOrDown];
            
            // 设定下拉项目的菜单，用来在它被折叠时使用
            NSMenuItem *menuFormRepresentation = [[NSMenuItem alloc] init];
            [menuFormRepresentation setTitle:commandName];
            [menuFormRepresentation setImage:[NSImage imageNamed:NSImageNameBookmarksTemplate]];
            [menuFormRepresentation setSubmenu:[[NSMenu alloc] init]];
            
            // 加入子菜单
            for (NSString *secondaryCommandIdentifier in [self.helper secondaryCommandsIdentifierOfIdentifier: itemIdentifier]) {
                [popUpButton addItemWithTitle:[helper commandNameOfIdentifier:secondaryCommandIdentifier requireFullName:NO]];
                
                // 菜单传入命令 ID，方便处理的时候调用
                [[[popUpButton itemArray] lastObject] setRepresentedObject:secondaryCommandIdentifier];
                [[[popUpButton itemArray] lastObject] setTarget:self];
                [[[popUpButton itemArray] lastObject] setAction:@selector(menuItemClicked:)];
                
                //下拉项目的菜单也需要它们作为子菜单
                [[menuFormRepresentation submenu] addItem:[[[popUpButton itemArray] lastObject] copy]];
            }
            
            [toolbarItem setView:popUpButton];
            [toolbarItem setMenuFormRepresentation:menuFormRepresentation];
        } else {
             // 如果不是带子菜单的项目，处理就简单多了
            [toolbarItem setImage: [NSImage imageNamed:NSImageNameBookmarksTemplate]];
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
                 
- (void)menuItemClicked:(NSMenuItem *)sender {
    [self.helper.delegate runToolbarCommand: [helper commandIdentifierOfIdentifier:(NSString *)[sender representedObject]]];
}
                 
// 窗口关闭时移除引用，并记忆工具栏的宽度
- (void)windowWillClose:(NSNotification *)notification{
    [NSUserDefaults.standardUserDefaults setDouble:self.window.frame.size.width forKey:@"PBToolbarWidth"];
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
