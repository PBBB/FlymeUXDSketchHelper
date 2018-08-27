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
#import "AppController.h"


@implementation PBToolbarHelper
#define PBLog(fmt, ...) NSLog((@"Fletch (Sketch Plugin) %s [Line %d] " fmt), __PRETTY_FUNCTION__, __LINE__, ##__VA_ARGS__);
@synthesize context, toolbarWC, delegate, toolbarCommands, toolbarSecondaryCommands;

- (void)showToolbar:(NSDictionary *)context {

    if (!toolbarWC) {
        self.context = context;
        [self setupToolbarWC:context];
    }
    MSDocument *document = context[@"document"];
    MSDocumentWindow *documentWindow = [document window];
    
    // 初始化工具栏的宽高和位置
    CGFloat tabbarHeight = 24.0;
    CGFloat toolbarHeightRegular = 70.0;
    CGFloat toolbarHeightIconOnly = 58.0;

    NSPoint toolbarOrigin = NSMakePoint(0.0, 0.0);
    BOOL isToolbarHeightRegular = documentWindow.toolbar.displayMode == NSToolbarDisplayModeIconAndLabel;
    CGFloat toolbarHeight = isToolbarHeightRegular ? toolbarHeightRegular : toolbarHeightIconOnly;
    
    // 如果本地存储有工具栏宽度，就用它（未存入时，获取到的值是 0）
    if ([NSUserDefaults.standardUserDefaults doubleForKey:@"PBToolbarWidth"] != 0.0) {
        CGRect oldFrame = toolbarWC.window.frame;
        CGRect newFrame = CGRectMake(oldFrame.origin.x, oldFrame.origin.y, [NSUserDefaults.standardUserDefaults doubleForKey:@"PBToolbarWidth"], oldFrame.size.height);
        [toolbarWC.window setFrame:newFrame display:YES];
    }
    
    toolbarOrigin.x = documentWindow.frame.origin.x + documentWindow.frame.size.width - toolbarWC.window.frame.size.width - 215.0;
    if (([documentWindow styleMask] & NSWindowStyleMaskFullScreen) == NSWindowStyleMaskFullScreen) {
        toolbarOrigin.y = documentWindow.frame.origin.y + documentWindow.frame.size.height - toolbarWC.window.frame.size.height;
    } else if (documentWindow.tabGroup.tabBarVisible) {
        toolbarOrigin.y = documentWindow.frame.origin.y + documentWindow.frame.size.height - toolbarWC.window.frame.size.height - toolbarHeight - tabbarHeight;
    } else {
        toolbarOrigin.y = documentWindow.frame.origin.y + documentWindow.frame.size.height - toolbarWC.window.frame.size.height - toolbarHeight;
    }
    [[toolbarWC window] setFrameOrigin:toolbarOrigin];
//    [documentWindow addChildWindow:[toolbarWC window] ordered:NSWindowAbove];
    [toolbarWC showWindow:self];
    
    // 文档窗口进入或退出全屏时，重置工具栏位置
    [[NSNotificationCenter defaultCenter] addObserverForName:NSWindowDidEnterFullScreenNotification object:documentWindow queue:nil usingBlock:^(NSNotification * _Nonnull note) {
        NSPoint toolbarOrigin = NSMakePoint(0.0, 0.0);
        toolbarOrigin.x = documentWindow.frame.origin.x + documentWindow.frame.size.width - self->toolbarWC.window.frame.size.width - 215.0;
        toolbarOrigin.y = documentWindow.frame.origin.y + documentWindow.frame.size.height - self->toolbarWC.window.frame.size.height;
        [[self->toolbarWC window] setFrameOrigin:toolbarOrigin];
    }];
    
    // 文档窗口退出全屏时，工具栏会浮在上面，所以要先隐藏工具栏
    // 隐藏工具栏再显示会导致全屏状态下关闭文档时工具栏仍然显示，所以这个处理只能先去掉了
    [[NSNotificationCenter defaultCenter] addObserverForName:NSWindowWillExitFullScreenNotification object:documentWindow queue:nil usingBlock:^(NSNotification * _Nonnull note) {
//        [[self->toolbarWC window] orderOut:self];
    }];
    
    [[NSNotificationCenter defaultCenter] addObserverForName:NSWindowDidExitFullScreenNotification object:documentWindow queue:nil usingBlock:^(NSNotification * _Nonnull note) {
        NSPoint toolbarOrigin = NSMakePoint(0.0, 0.0);
        toolbarOrigin.x = documentWindow.frame.origin.x + documentWindow.frame.size.width - self->toolbarWC.window.frame.size.width - 215.0;
        if (documentWindow.tabGroup.tabBarVisible) {
            toolbarOrigin.y = documentWindow.frame.origin.y + documentWindow.frame.size.height - self->toolbarWC.window.frame.size.height - toolbarHeight - tabbarHeight;
        } else {
            toolbarOrigin.y = documentWindow.frame.origin.y + documentWindow.frame.size.height - self->toolbarWC.window.frame.size.height - toolbarHeight;
        }
//        [[self->toolbarWC window] orderFront:self];
        [[self->toolbarWC window] setFrameOrigin:toolbarOrigin];
    }];
    
    // 文档窗口进入或退出版本浏览时，工具栏会被关闭，而且有个很奇怪的动画
    // 全屏下进入或退出版本浏览时，工具栏可能会出现多个实例，不知道发生了什么……所以这种情况先不处理
//    [[NSNotificationCenter defaultCenter] addObserverForName:NSWindowWillEnterVersionBrowserNotification object:documentWindow queue:nil usingBlock:^(NSNotification * _Nonnull note) {
//        [[self->toolbarWC window] setIsVisible:NO];
//    }];
//
//    [[NSNotificationCenter defaultCenter] addObserverForName:NSWindowDidExitVersionBrowserNotification object:documentWindow queue:nil usingBlock:^(NSNotification * _Nonnull note) {
//        [[self->toolbarWC window] setIsVisible:YES];
//    }];
    
    
    
    // 根据窗口缩放计算工具栏位置（暂时不处理，因为工具栏与多个文档都关联）
//    [[NSNotificationCenter defaultCenter] addObserverForName:NSWindowDidResizeNotification object:documentWindow queue:nil usingBlock:^(NSNotification * _Nonnull note) {
//        PBLog(@"resized");
//    }];
    
    // 先激活文档窗口，否则工具栏上的操作不能生效
    [documentWindow makeKeyAndOrderFront:nil];
    [[toolbarWC window] makeKeyAndOrderFront:nil];
}

-(void) setupToolbarWC:(NSDictionary *)context {
    
    // 如果窗口已经存在，那么工具栏抖动
    NSMutableDictionary *threadDictionary = [[NSThread mainThread] threadDictionary];
    NSString *threadIdentifier = @"com.flyme.uxd.pbb.sketch-helper.toolbar";
    
    if (threadDictionary[threadIdentifier]) {
        [[(PBToolbarWindowController *)threadDictionary[threadIdentifier] window] makeKeyAndOrderFront:nil];
        [(PBToolbarWindowController *)threadDictionary[threadIdentifier] shakeWindow];
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
    toolbarSecondaryCommands = [[NSMutableArray alloc] init];
    for (id pluginMenu in pluginMenus) {
        NSString *pluginMenuASCIIString = [self ASCIIStringFromUnicodeString:[pluginMenu description]];
        
        // 如果这一项有 "{" 那就是有二级菜单了
        if ([pluginMenuASCIIString containsString: @"{"]){
            // 将带二级菜单的项目进行特殊处理，让数据符合工具栏调用的需求
            NSMutableDictionary<NSString *, id> *toolbarCommandWithSecondaryCommand = pluginMenu;
            [toolbarCommandWithSecondaryCommand setObject:toolbarCommandWithSecondaryCommand[@"title"] forKey:@"name"];
            [toolbarCommands addObject:toolbarCommandWithSecondaryCommand];
            
            //将二级菜单的子项分离出来
            NSArray *secondaryCommandMenus = (NSArray *)(toolbarCommandWithSecondaryCommand[@"items"]);
            for (NSString *secondaryCommandMenu in secondaryCommandMenus) {
                [toolbarSecondaryCommands addObject:toolCommands[secondaryCommandMenu]];
            }
        } else if ([pluginMenuASCIIString isEqualToString:@"-"]) {
            // 如果菜单有分隔符，则暂时不处理（工具栏已经没有分割线，空白又不合适）
            //
//            [toolbarCommands addObject:@{@"identifier":@"-"}];
        } else if(![pluginMenuASCIIString isEqualToString:@"showToolbar"]) {
            // 将除了显示工具栏之外的菜单项记录进来
            [toolbarCommands addObject:toolCommands[[pluginMenu description]]];
        }
    }
}

#pragma mark - Toolbar identifiers

-(NSArray<NSToolbarItemIdentifier> *) defaultToolbarItemIdentifiers {
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
    for (NSDictionary<NSString *, NSString *> *toolbarLabsCommand in toolbarSecondaryCommands) {
        // 实验室菜单理论上不会有分割线，不过先加入处理吧
        if ([toolbarLabsCommand[@"identifier"] isEqualToString:@"-"]) {
//            [toolbarLabsItemIdentifiers addObject:NSToolbarSeparatorItemIdentifier];
        } else {
            // 处理首字母大写，并加入前缀
            NSString *toolbarLabsCommandIdentifier = toolbarLabsCommand[@"identifier"];
            NSString *toolbarLabsCommandIdentifierWithFirstLetterCapitalized = [[NSMutableString stringWithString:[[toolbarLabsCommandIdentifier substringToIndex:1] uppercaseString]] stringByAppendingString:[toolbarLabsCommandIdentifier substringFromIndex:1]];
            [toolbarLabsItemIdentifiers addObject:[[NSMutableString stringWithString:@"PBToolbarSecondaryCommand"] stringByAppendingString:toolbarLabsCommandIdentifierWithFirstLetterCapitalized]];
        }
    }
    NSArray<NSToolbarItemIdentifier> *allowedToolbarItemIdentifiers = [[[self defaultToolbarItemIdentifiers] arrayByAddingObjectsFromArray:toolbarLabsItemIdentifiers] arrayByAddingObjectsFromArray:@[NSToolbarSpaceItemIdentifier, NSToolbarFlexibleSpaceItemIdentifier]];
    return allowedToolbarItemIdentifiers;
}

#pragma mark - Toolbar info from identifier

//通过 identifier 获取命令信息
- (NSString *) commandIdentifierOfIdentifier: (NSToolbarItemIdentifier) identifier {
    NSString *identifierWithFirstLetterCapitalized;
    if ([identifier containsString:@"PBToolbarCommand"]) {
        identifierWithFirstLetterCapitalized = [identifier substringFromIndex: 16];
    } else if ([identifier containsString:@"PBToolbarSecondaryCommand"]) {
        identifierWithFirstLetterCapitalized = [identifier substringFromIndex: 25];
    } else {
        // 如果 identifier 没有前缀，那么就直接返回
        return identifier;
    }
    NSString *pluginCommandIdentifier = [[NSMutableString stringWithString:[[identifierWithFirstLetterCapitalized substringToIndex:1] lowercaseString]] stringByAppendingString:[identifierWithFirstLetterCapitalized substringFromIndex:1]];
    return pluginCommandIdentifier;
}

- (NSString *) commandNameOfIdentifier: (NSToolbarItemIdentifier) identifier requireFullName: (BOOL) fullName {
    NSString *pluginCommandIdentifier = [self commandIdentifierOfIdentifier:identifier];
    for (NSDictionary<NSString *, NSString *> *toolbarCommand in [toolbarCommands arrayByAddingObjectsFromArray:toolbarSecondaryCommands]) {
        if ([toolbarCommand[@"identifier"] isEqualToString:pluginCommandIdentifier]) {
            NSString *commandName;
            // 如果有全名字段，则取这个
            if (fullName && toolbarCommand[@"fullName"]) {
                commandName = [toolbarCommand[@"fullName"] description];
            } else {
                commandName = [toolbarCommand[@"name"] description];
            }
            if ([commandName containsString:@"..."]) {
                return [commandName substringToIndex:([commandName length] - 3)];
            } else {
                return commandName;
            }
        }
    }
    return NSToolbarSpaceItemIdentifier;
}

- (NSArray<NSString *>*) secondaryCommandsIdentifierOfIdentifier: (NSToolbarItemIdentifier) identifier {
    NSString *pluginCommandIdentifier = [self commandIdentifierOfIdentifier:identifier];
    for (NSDictionary<NSString *, id> *toolbarCommand in toolbarCommands) {
        if ([toolbarCommand[@"identifier"] isEqualToString: pluginCommandIdentifier]) {
            return (NSArray *)(toolbarCommand[@"items"]);
        }
    }
    return @[];
}

- (NSString *) commandImagePathOfIdentifier: (NSToolbarItemIdentifier) identifier {
    NSString *pluginCommandIdentifier = [self commandIdentifierOfIdentifier:identifier];
    MSPluginBundle *plugin = context[@"plugin"];
    NSString *pluginIconsDirectoryURLString = [[[[[plugin url] URLByAppendingPathComponent:@"Contents"]
                                           URLByAppendingPathComponent:@"Resources"]
                                          URLByAppendingPathComponent:@"icons"] path];
    return [NSString stringWithFormat:@"%@/toolbar_%@.tiff", pluginIconsDirectoryURLString, pluginCommandIdentifier];
}

#pragma mark - Toolbar action

- (void) didClickToolbarWithIdentifier: (NSToolbarItemIdentifier) toolbarIdentifier {
    AppController *appController = (AppController *)[NSApp delegate];
    MSPluginBundle *plugin = context[@"plugin"];
    MSPluginCommand *command = [[plugin commands] objectForKey:[self commandIdentifierOfIdentifier:toolbarIdentifier]];
    
    // 工具栏需要跨多个文档使用，所以需要更新 context，但是不加似乎也可以，先留着观望吧
    Class MSDocument = NSClassFromString(@"MSDocument");
    NSDictionary *pluginContext = [MSDocument valueForKeyPath:@"currentDocument.pluginContext"];
    
    [appController runPluginCommand:command fromMenu:YES context:pluginContext];
    
    // 上报埋点
    [delegate runToolbarCommand:[self commandIdentifierOfIdentifier:toolbarIdentifier]];
}

#pragma mark -

// 用来将 manifest 的字符从 Unicode 代码转为中文
- (NSString *) ASCIIStringFromUnicodeString: (NSString *) unicodeString {
    return [NSString stringWithCString:[unicodeString cStringUsingEncoding:NSUTF8StringEncoding] encoding:NSNonLossyASCIIStringEncoding];
}


@end
