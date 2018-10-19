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
#import "MSRect.h"
#import "MSContentDrawView.h"
#import "MSDocumentWindow.h"


@implementation PBDocumentArtboardManager
#define PBLog(fmt, ...) NSLog((@"Fletch (Sketch Plugin) %s [Line %d] " fmt), __PRETTY_FUNCTION__, __LINE__, ##__VA_ARGS__);

- (void) addDocumentArtboardType: (NSString *)type withContext: (NSDictionary *)context MSDocumentClass: (Class)MSDocumentClass {
    
    // 获得当前文档和窗口
    MSDocument *document = context[@"document"];
    MSDocumentWindow * _Nonnull documentWindow = [document window];
    MSPage *currentPage = [document currentPage];
    NSMutableArray <MSArtboardGroup *> *artboardsInCurrentPage = [NSMutableArray arrayWithArray:[currentPage artboards]];
    
    // 将画板按照画布中的位置排序
    [artboardsInCurrentPage sortUsingComparator:^NSComparisonResult(MSArtboardGroup *  _Nonnull firstAB, MSArtboardGroup * _Nonnull secondAB) {
        if (fabs([[firstAB frame] y] - [[secondAB frame] y]) < [[firstAB frame] height]) {
            return [[firstAB frame] x] > [[secondAB frame] x];
        } else {
            return [[firstAB frame] y] > [[secondAB frame] y];
        }
    }];
    
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
        NSAlert *alert = [[NSAlert alloc] init];
        [alert addButtonWithTitle:@"去下载"];
        [alert addButtonWithTitle:@"取消"];
        [alert setMessageText:@"文件读取失败，请重新安装插件"];
        [alert beginSheetModalForWindow:documentWindow completionHandler:^(NSModalResponse returnCode) {
            switch (returnCode) {
                case NSAlertFirstButtonReturn:
                    [[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:@"https://github.com/PBBB/FlymeUXDSketchHelper/releases"]];
                    [documentWindow endSheet:[alert window]];
                    break;
                case NSAlertSecondButtonReturn:
                    [documentWindow endSheet:[alert window]];
                    break;
                default:
                    break;
            }
        }];
        return;
    }
    
    MSArtboardGroup *artboardtoAdd = nil;
    for (MSPage *page in [FlymeUIKitArtboardsSketchDocument pages]) {
        if ([[page name] isEqualToString:@"Artboards"]) {
            for (MSArtboardGroup *artboard in [page artboards]) {
                if ([[artboard name] isEqualToString:type]) {
                    artboardtoAdd = (MSArtboardGroup *)[artboard duplicate];
                    break;
                }
                
            }
            break;
        }
    }
    
    if (artboardtoAdd == nil) {
        NSAlert *alert = [[NSAlert alloc] init];
        [alert addButtonWithTitle:@"去下载"];
        [alert addButtonWithTitle:@"取消"];
        [alert setMessageText:@"文件读取失败，请重新安装插件"];
        [alert beginSheetModalForWindow:documentWindow completionHandler:^(NSModalResponse returnCode) {
            switch (returnCode) {
                case NSAlertFirstButtonReturn:
                    [[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:@"https://github.com/PBBB/FlymeUXDSketchHelper/releases"]];
                    [documentWindow endSheet:[alert window]];
                    break;
                case NSAlertSecondButtonReturn:
                    [documentWindow endSheet:[alert window]];
                    break;
                default:
                    break;
            }
        }];
        return;
    }
    
    // 将画板插入及放入对应位置
    [artboardtoAdd setName:@"功能概述"];
    [currentPage insertLayer:artboardtoAdd atIndex:artboardsInCurrentPage.count - 1];
    [artboardtoAdd.frame setX:artboardsInCurrentPage.lastObject.frame.x + artboardsInCurrentPage.lastObject.frame.width + 100.0];
    [artboardtoAdd.frame setY:artboardsInCurrentPage.lastObject.frame.y];
    
    // 定位至刚添加的画板
    MSContentDrawView *canvasView = document.currentContentViewController.contentDrawView;
    CGRect originalRect = artboardtoAdd.frame.rect;
    CGRect zoomRect = CGRectMake(originalRect.origin.x - 200, originalRect.origin.y - 200, originalRect.size.width + 400, originalRect.size.height + 400);
    [canvasView zoomToFitRect:zoomRect];
    
    // 操作完成后关闭并释放文档
    [FlymeUIKitArtboardsSketchDocument close];
    FlymeUIKitArtboardsSketchDocument = nil;
}


@end

