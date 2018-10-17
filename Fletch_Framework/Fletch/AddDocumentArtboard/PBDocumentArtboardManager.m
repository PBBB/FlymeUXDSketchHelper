//
//  PBDocumentArtboardManager.m
//  Fletch
//
//  Created by PBB on 2018/10/17.
//  Copyright © 2018 pbb. All rights reserved.
//

#import "PBDocumentArtboardManager.h"
#import "MSPluginBundle.h"
#import "MSDocument.h"
#import "MSpage.h"
#import "MSArtboardGroup.h"


@implementation PBDocumentArtboardManager
#define PBLog(fmt, ...) NSLog((@"Fletch (Sketch Plugin) %s [Line %d] " fmt), __PRETTY_FUNCTION__, __LINE__, ##__VA_ARGS__);

- (void) addDocumentArtboardType: (NSString *)type withContext: (NSDictionary *)context MSDocumentClass: (Class)MSDocumentClass {
    
    // 获得当前文档和窗口
    MSDocument *document = context[@"document"];
    MSDocumentWindow * _Nonnull documentWindow = [document window];
    
    // 获得 sketch 文件
    MSPluginBundle *plugin = context[@"plugin"];
    NSURL *FlymeUIKitArtboardsSketchURL = [[[[[plugin url] URLByAppendingPathComponent:@"Contents"]
                                            URLByAppendingPathComponent:@"Resources"]
                                           URLByAppendingPathComponent:@"sketch"]
                                          URLByAppendingPathComponent:@"FlymeUIKit_Artboards.sketch"];
    
    // 读取文件中对应的画板
    MSDocument *FlymeUIKitArtboardsSketchDocument = [[MSDocumentClass alloc] init];
    BOOL readFileResult = [FlymeUIKitArtboardsSketchDocument readDocumentFromURL:FlymeUIKitArtboardsSketchURL ofType:@"com.bohemiancoding.sketch.drawing" error:nil];

    if (!readFileResult) {
        PBLog(@"文件读取失败");
        return;
    }
    
    MSArtboardGroup *artboardtoAdd = nil;
    for (MSPage *page in [FlymeUIKitArtboardsSketchDocument pages]) {
        if ([[page name] isEqualToString:@"Artboards"]) {
            for (MSArtboardGroup *artboard in [page artboards]) {
                if ([[artboard name] isEqualToString:type]) {
                    artboardtoAdd = artboard;
                    break;
                }
                
            }
            break;
        }
    }
    
    if (artboardtoAdd == nil) {
        PBLog(@"未找到对应画板");
        return;
    }
    
    [[document currentPage] insertLayer:[artboardtoAdd duplicate] atIndex:[[document currentPage] artboards].count - 1];
}


@end

