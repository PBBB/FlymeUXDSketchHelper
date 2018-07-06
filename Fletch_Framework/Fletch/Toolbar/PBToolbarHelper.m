//
//  PBToolbarHelper.m
//  Fletch
//
//  Created by pbb on 2018/7/6.
//  Copyright © 2018年 pbb. All rights reserved.
//

#import "PBToolbarHelper.h"
#import "MSPluginBundle.h"


@implementation PBToolbarHelper
#define PBLog(fmt, ...) NSLog((@"Fletch (Sketch Plugin) %s [Line %d] " fmt), __PRETTY_FUNCTION__, __LINE__, ##__VA_ARGS__);
@synthesize toolbarWC, delegate, toolbarInfo;

- (void)showToolbar:(NSDictionary *)context {
    if (!toolbarWC) {
        [self setupToolbarWC:context];
    }
    [toolbarWC showWindow:nil];
}

-(void) setupToolbarWC:(NSDictionary *)context {
    
    // 初始化工具栏
    toolbarWC = [[PBToolbarWindowController alloc] initWithWindowNibName:@"PBToolbarWindowController"];
    [toolbarWC setHelper:self];
    
    // 获得 manifest 文件
    MSPluginBundle *plugin = context[@"plugin"];
    NSString *pluginManifestURLString = [[[[[plugin url] URLByAppendingPathComponent:@"Contents"]
                                  URLByAppendingPathComponent:@"Sketch"]
                                 URLByAppendingPathComponent:@"manifest.json"] path];
    NSDictionary *pluginManifest = [NSJSONSerialization JSONObjectWithData:[NSData dataWithContentsOfFile:pluginManifestURLString] options:NSJSONReadingMutableContainers error:nil];
    
    // 获得 manifest 中，适合显示在工具栏的 id（用 isTool 标记）
    NSDictionary *pluginCommands = pluginManifest[@"commands"];
    NSMutableDictionary<NSString *, NSDictionary<NSString *, NSString *> *> *toolCommands = [[NSMutableDictionary alloc] init];
    for (NSDictionary *pluginCommand in pluginCommands) {
        if ([(NSString *)pluginCommand[@"isTool"] isEqualToString:@"true"]) {
            [toolCommands setObject:pluginCommand forKey:pluginCommand[@"identifier"]];
        }
    }
    
    // 获得 manifest 中的 menu，并按顺序加入数组
    NSArray *pluginMenus = pluginManifest[@"menu"][@"items"];
    NSMutableArray<NSDictionary<NSString *, NSString *> *> *toolbarCommands = [[NSMutableArray alloc] init];
    NSMutableArray<NSDictionary<NSString *, NSString *> *> *toolbarLabsCommands = [[NSMutableArray alloc] init];
    for (id pluginMenu in pluginMenus) {
        // 如果此处有换行，证明是一个字典，也就是有二级菜单，目前只可能是实验室
        if ([[pluginMenu description] containsString: @"Fletch 实验室"]){
            NSArray *labCommandMenus = (NSArray *)(((NSDictionary *)pluginMenu)[@"items"]);
            for (NSString *labCommandMenu in labCommandMenus) {
                [toolbarLabsCommands addObject:toolCommands[labCommandMenu]];
            }
        // 如果菜单有分隔符，则工具栏也加入分割线
        } else if ([[pluginMenu description] isEqualToString:@"-"]) {
            [toolbarCommands addObject:@{@"identifier":@"-"}];
        // 将除了显示工具栏之外的菜单项记录进来
        } else if(![[pluginMenu description] isEqualToString:@"showToolbar"]) {
            [toolbarCommands addObject:toolCommands[[pluginMenu description]]];
        }
    }
    PBLog(@"toolbar commands: %@", toolbarCommands);
    PBLog(@"toolbar labs commands:: %@", toolbarLabsCommands);
}

-(NSArray<NSToolbarItemIdentifier> *) defaultToolbarItemIdentifiers {
    return @[];
}

-(NSArray<NSToolbarItemIdentifier> *) allowedToolbarItemIdentifiers {
    return @[];
}

@end
