//
//  PBToolbarHelper.m
//  Fletch
//
//  Created by pbb on 2018/7/6.
//  Copyright © 2018年 pbb. All rights reserved.
//

#import "PBToolbarHelper.h"
#import "MSDocument.h"
#import "MSDocumentWindow.h"
#import "MSPluginBundle.h"


@implementation PBToolbarHelper
#define PBLog(fmt, ...) NSLog((@"Fletch (Sketch Plugin) %s [Line %d] " fmt), __PRETTY_FUNCTION__, __LINE__, ##__VA_ARGS__);
@synthesize toolbarWC, delegate, toolbarCommands, toolbarLabsCommands;

- (void)showToolbar:(NSDictionary *)context {
    if (!toolbarWC) {
        [self setupToolbarWC:context];
    }
    MSDocument *document = context[@"document"];
    MSDocumentWindow *documentWindow = [document window];
    [documentWindow addChildWindow:[toolbarWC window] ordered:NSWindowAbove];
    [[toolbarWC window] makeKeyWindow];
}

-(void) setupToolbarWC:(NSDictionary *)context {
    
    // 如果窗口已经存在，那么工具栏抖动
    NSMutableDictionary *threadDictionary = [[NSThread mainThread] threadDictionary];
    NSString *threadIdentifier = @"com.flyme.uxd.pbb.sketch-helper.toolbar";
    
    if (threadDictionary[threadIdentifier]) {
        [(PBToolbarWindowController *)threadDictionary[threadIdentifier] shakeWindow];
        PBLog(@"toolbar frame: %@", NSStringFromRect([[(PBToolbarWindowController *)threadDictionary[threadIdentifier] window] frame]));
        return;
    }
    
    // 初始化工具栏
    toolbarWC = [[PBToolbarWindowController alloc] initWithWindowNibName:@"PBToolbarWindowController"];
    [toolbarWC setHelper:self];
    [threadDictionary setObject:toolbarWC forKey:threadIdentifier];
    
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
    toolbarCommands = [[NSMutableArray alloc] init];
    toolbarLabsCommands = [[NSMutableArray alloc] init];
    for (id pluginMenu in pluginMenus) {
        NSString *pluginMenuASCIIString = [self ASCIIStringFromUnicodeString:[pluginMenu description]];
        // 首先将实验室分离出来
        if ([pluginMenuASCIIString containsString: @"Fletch 实验室"]){
            NSArray *labCommandMenus = (NSArray *)(((NSDictionary *)pluginMenu)[@"items"]);
            for (NSString *labCommandMenu in labCommandMenus) {
                [toolbarLabsCommands addObject:toolCommands[labCommandMenu]];
            }
        // 如果菜单有分隔符，则暂时不处理（工具栏已经没有分割线，空白又不合适）
        } else if ([pluginMenuASCIIString isEqualToString:@"-"]) {
            //
//            [toolbarCommands addObject:@{@"identifier":@"-"}];
        // 将除了显示工具栏之外的菜单项记录进来
        } else if(![pluginMenuASCIIString isEqualToString:@"showToolbar"]) {
            [toolbarCommands addObject:toolCommands[[pluginMenu description]]];
        }
    }
}

-(NSArray<NSToolbarItemIdentifier> *) defaultToolbarItemIdentifiers {
    // 实验室需要自定义工具栏，暂时先不做
    NSMutableArray<NSToolbarItemIdentifier> *defaultToolbarItemIdentifiers = [[NSMutableArray alloc] init];
    for (NSDictionary<NSString *, NSString *> *toolbarCommand in toolbarCommands) {
        // 如果菜单有分隔符，则暂时不处理（工具栏已经没有分割线，空白又不合适）
        if ([toolbarCommand[@"identifier"] isEqualToString:@"-"]) {
//            [defaultToolbarItemIdentifiers addObject:NSToolbarSpaceItemIdentifier];
        } else {
            // 处理首字母大写，并加入前缀
            NSString *toolbarCommandIdentifier = toolbarCommand[@"identifier"];
            NSString *toolbarCommandIdentifierWithFirstLetterCapitalized = [[NSMutableString stringWithString:[[toolbarCommandIdentifier substringToIndex:1] uppercaseString]] stringByAppendingString:[toolbarCommandIdentifier substringFromIndex:1]];
            [defaultToolbarItemIdentifiers addObject:[[NSMutableString stringWithString:@"PBToolbarCommand"] stringByAppendingString:toolbarCommandIdentifierWithFirstLetterCapitalized]];
        }
    }
    return defaultToolbarItemIdentifiers;
}

-(NSArray<NSToolbarItemIdentifier> *) allowedToolbarItemIdentifiers {
    NSMutableArray<NSToolbarItemIdentifier> *toolbarLabsItemIdentifiers = [[NSMutableArray alloc] init];
    for (NSDictionary<NSString *, NSString *> *toolbarLabsCommand in toolbarLabsCommands) {
        // 实验室菜单理论上不会有分割线，不过先加入处理吧
        if ([toolbarLabsCommand[@"identifier"] isEqualToString:@"-"]) {
//            [toolbarLabsItemIdentifiers addObject:NSToolbarSeparatorItemIdentifier];
        } else {
            // 处理首字母大写，并加入前缀
            NSString *toolbarLabsCommandIdentifier = toolbarLabsCommand[@"identifier"];
            NSString *toolbarLabsCommandIdentifierWithFirstLetterCapitalized = [[NSMutableString stringWithString:[[toolbarLabsCommandIdentifier substringToIndex:1] uppercaseString]] stringByAppendingString:[toolbarLabsCommandIdentifier substringFromIndex:1]];
            [toolbarLabsItemIdentifiers addObject:[[NSMutableString stringWithString:@"PBToolbarLabsCommand"] stringByAppendingString:toolbarLabsCommandIdentifierWithFirstLetterCapitalized]];
        }
    }
    NSArray<NSToolbarItemIdentifier> *allowedToolbarItemIdentifiers = [[[self defaultToolbarItemIdentifiers] arrayByAddingObjectsFromArray:toolbarLabsItemIdentifiers] arrayByAddingObjectsFromArray:@[NSToolbarSpaceItemIdentifier, NSToolbarFlexibleSpaceItemIdentifier]];
    return allowedToolbarItemIdentifiers;
}
//通过 identifier 获取命令信息
- (NSString *) commandNameOfIdentifier: (NSToolbarItemIdentifier) identifier {
    NSString *pluginCommandIdentifier = [self commandIdentifierOfIdentifier:identifier];
    for (NSDictionary<NSString *, NSString *> *toolbarCommand in [toolbarCommands arrayByAddingObjectsFromArray:toolbarLabsCommands]) {
        if ([toolbarCommand[@"identifier"] isEqualToString:pluginCommandIdentifier]) {
            NSString *commandName = [toolbarCommand[@"name"] description];
            if ([commandName containsString:@"..."]) {
                return [commandName substringToIndex:([commandName length] - 3)];
            } else {
                return commandName;
            }
        }
    }
    return NSToolbarSpaceItemIdentifier;
}

- (NSString *) commandIdentifierOfIdentifier: (NSToolbarItemIdentifier) identifier {
    NSString *identifierWithFirstLetterCapitalized;
    if ([identifier containsString:@"PBToolbarCommand"]) {
        identifierWithFirstLetterCapitalized = [identifier substringFromIndex: 16];
    } else if ([identifier containsString:@"PBToolbarLabsCommand"]) {
        identifierWithFirstLetterCapitalized = [identifier substringFromIndex: 20];
    }
    NSString *pluginCommandIdentifier = [[NSMutableString stringWithString:[[identifierWithFirstLetterCapitalized substringToIndex:1] lowercaseString]] stringByAppendingString:[identifierWithFirstLetterCapitalized substringFromIndex:1]];
    return pluginCommandIdentifier;
}

- (NSString *) commandImagePathOfIdentifier: (NSToolbarItemIdentifier) identifier {
    return @"";
}


// 用来将 manifest 的字符从 Unicode 代码转为中文
- (NSString *) ASCIIStringFromUnicodeString: (NSString *) unicodeString {
    return [NSString stringWithCString:[unicodeString cStringUsingEncoding:NSUTF8StringEncoding] encoding:NSNonLossyASCIIStringEncoding];
}

@end
