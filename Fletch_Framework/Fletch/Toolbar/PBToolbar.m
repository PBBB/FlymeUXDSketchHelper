//
//  PBToolbar.m
//  Fletch
//
//  Created by pbb on 2018/8/1.
//  Copyright © 2018年 pbb. All rights reserved.
//

#import "PBToolbar.h"
#import "PBToolbarWindowController.h"

@implementation PBToolbar
#define PBLog(fmt, ...) NSLog((@"Fletch (Sketch Plugin) %s [Line %d] " fmt), __PRETTY_FUNCTION__, __LINE__, ##__VA_ARGS__);

- (BOOL)_allowsSizeMode:(NSToolbarSizeMode)mode {
    return mode != NSToolbarSizeModeRegular;
}

- (NSView*) __toolbarView {
    return (NSView*)[self valueForKey:@"_toolbarView"];
}

// 去掉仅显示文字的菜单项
- (void) disableTextOnlyMode {
    NSView *toolbarView = [self __toolbarView];
    NSMenu *toolbarMenu = toolbarView.menu;
    for (NSMenuItem *item in [toolbarMenu.itemArray objectEnumerator]) {
        if (item.tag == 3) {
            [toolbarMenu removeItem:item];
            break;
        }
    }
}

// 去掉自定义菜单里”仅显示文字“的下拉项目
- (void)runCustomizationPalette:(id)sender {
    [super runCustomizationPalette:sender];
    NSWindow* toolbarWindow = ((PBToolbarWindowController *)self.delegate).window;
    NSWindow* sheet = [toolbarWindow attachedSheet];
    for(NSView* view in [[sheet contentView] subviews]){
        if([view isKindOfClass:[NSStackView class]]){
            for(NSView* view2 in [((NSStackView *)view) subviews]){
                if([view2 isKindOfClass:[NSPopUpButton class]]){
                    [((NSPopUpButton *)view2) removeItemWithTitle:@"Text Only"];
                }
            }
        }
    }
}

@end
