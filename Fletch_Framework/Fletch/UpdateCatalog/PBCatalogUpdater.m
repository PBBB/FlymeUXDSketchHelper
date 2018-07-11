//
//  PBCatalogUpdater.m
//  Fletch
//
//  Created by pbb on 2018/7/11.
//  Copyright © 2018年 pbb. All rights reserved.
//

#import "PBCatalogUpdater.h"

@interface PBCatalogUpdater()
#define PBLog(fmt, ...) NSLog((@"Fletch (Sketch Plugin) %s [Line %d] " fmt), __PRETTY_FUNCTION__, __LINE__, ##__VA_ARGS__);
@end


@implementation PBCatalogUpdater
@synthesize delegate;

- (void) updateCatalogWithContext: (NSDictionary *)context MSArtboardGroupClass: (Class)MSArtboardGroupClass MSSymbolInstanceClass: (Class)MSSymbolInstanceClass {
    
    MSDocument *document = context[@"document"];
    MSDocumentWindow * _Nonnull window = [document window];
    
    // 提取所选画板
    NSArray *selection = context[@"selection"];
    NSMutableArray<MSArtboardGroup *> *selectedArtboards = [[NSMutableArray alloc] init];
    for (NSObject *eachSelection in selection) {
        if ([eachSelection isMemberOfClass:MSArtboardGroupClass]) {
            [selectedArtboards addObject:(MSArtboardGroup *)eachSelection];
        }
    }
    
    // 如果没选择画板，则视为选中所有画板
    if (selectedArtboards.count == 0) {
        selectedArtboards = [NSMutableArray arrayWithArray:[[document currentPage] artboards]];
    }
    // 如果还是没有画板，就提示并退出
    if (selectedArtboards.count == 0) {
        NSAlert *alert = [[NSAlert alloc] init];
        [alert setMessageText:@"页码更新失败"];
        [alert setInformativeText:@"请选择文档的所有画板（包括封面和概述）"];
        [alert addButtonWithTitle:@"确定"];
        [alert beginSheetModalForWindow:window completionHandler:nil];
        [delegate didUpdateCatalogWithResult:@{@"category":@"UpdateCatalog",
                                               @"action":@"Fail",
                                               @"label":@"NoSelection",
//                                               @"value":nil
                                               }];
        return;
    }
    
    // 将画板按照画布中的位置排序
    [selectedArtboards sortUsingComparator:^NSComparisonResult(MSArtboardGroup *  _Nonnull firstAB, MSArtboardGroup * _Nonnull secondAB) {
        if (fabs([[firstAB frame] y] - [[secondAB frame] y]) < [[firstAB frame] height]) {
            return [[firstAB frame] x] > [[secondAB frame] x];
        } else {
            return [[firstAB frame] y] > [[secondAB frame] y];
        }
    }];
    
    // 获取要修改的图层 ID（页码的 ID 应该都一样，所以尽量只获取一次）
    NSMutableDictionary<NSString *, NSString *> *layerIDsForPageNumber = nil;
    
    // 记录图层名，用于生成目录
    NSMutableArray<NSString *> *layerNamesArray = [[NSMutableArray alloc] init];
    
    // 从第三个画板开始，找到页码图层并更新内容
    for (int i = 0; i < selectedArtboards.count; i++) {
        if (i > 1) {
            NSArray *layersInArtboard = [selectedArtboards[i] layers];
            MSTextLayer *pageTitleLayer = nil;
            MSSymbolInstance *pageNumberLayer = nil;
            
            for (MSLayer *layer in layersInArtboard) {
                
                // 筛选出功能概述并重命名画板
                if ([[layer name] isEqualToString:@"功能概述"]) {
                    pageTitleLayer = (MSTextLayer *)layer;
                    [selectedArtboards[i] setName:[pageTitleLayer stringValue]];
                    continue;
                }
                
                // 筛选出页码
                if ([[layer name] isEqualToString:@"交互图例 / 页码"] && [layer isMemberOfClass:MSSymbolInstanceClass]) {
                    pageNumberLayer = (MSSymbolInstance *)layer;
                    if (layerIDsForPageNumber == nil) {
                        
                        // 获取图层 ID
                        MSSymbolMaster *symbolMaster = [pageNumberLayer symbolMaster];
                        NSArray<MSLayer *> *children = [symbolMaster childrenIncludingSelf:NO];
                        layerIDsForPageNumber = [[NSMutableDictionary alloc] init];
                        
                        for (MSLayer *layer in children) {
                            if ([[layer name] isEqualToString:@"3"]) {
                                [layerIDsForPageNumber setValue:[layer objectID] forKey:@"currentPage_ID"];
                            } else if ([[layer name] isEqualToString:@"10"]) {
                                [layerIDsForPageNumber setValue:[layer objectID] forKey:@"totalPages_ID"];
                            }
                        }
                        // 两种方式获取，未来说不定哪种才变成了兼容处理
                        if ([layerIDsForPageNumber objectForKey:@"currentPage_ID"] == nil) {
                            [layerIDsForPageNumber setValue:[children[0] objectID] forKey:@"currentPage_ID"];
                        }
                        if ([layerIDsForPageNumber objectForKey:@"totalPages_ID"] == nil) {
                            [layerIDsForPageNumber setValue:[children[1] objectID] forKey:@"totalPages_ID"];
                        }
                    }
                    continue;
                }
            }
            
            // 检查对应的图层是否都获取到
            if (pageTitleLayer == nil || pageNumberLayer == nil) {
                NSAlert *alert = [[NSAlert alloc] init];
                [alert setMessageText:@"页码更新失败"];
                [alert setInformativeText:@"请检查文档是否符合以下条件：\n1. 文档所有画板（包括封面和概述）都被选中，并按从上到下、从左到右的顺序排列\n2. 从第三个画板开始，功能概述的图层名需为“功能概述”，页码的图层名需为“交互图例 / 页码”"];
                [alert addButtonWithTitle:@"确定"];
                [alert beginSheetModalForWindow:window completionHandler:nil];
                [delegate didUpdateCatalogWithResult:@{@"category":@"UpdateCatalog",
                                                       @"action":@"Fail",
                                                       @"label":@"NoPageTitleOrPageNumber",
//                                               @"value":nil
                                                       }];
                return;
            }
            // 记录页面标题
            [layerNamesArray addObject:[pageTitleLayer stringValue]];
            
            // 设定页码值
            NSMutableDictionary<NSString *, NSString *> *pageData = [[NSMutableDictionary alloc] init];
            [pageData setValue:[NSString stringWithFormat:@"%d", i+1] forKey:[layerIDsForPageNumber objectForKey:@"currentPage_ID"]];
            [pageData setValue:[NSString stringWithFormat:@"%lu", (unsigned long)selectedArtboards.count] forKey:[layerIDsForPageNumber objectForKey:@"totalPages_ID"]];
            [pageNumberLayer setOverrides:pageData];
            
            // 更新标题与页码的间距
            [[pageTitleLayer frame] setX:164.0];
            [[pageTitleLayer frame] setY:65.0];
            [[pageNumberLayer frame] setX:[[pageTitleLayer frame] x] + [[pageTitleLayer frame] width] + 50.0];
            [[pageNumberLayer frame] setY:[[pageTitleLayer frame] y] - 2];
        }
    }
    
    // 处理重复标题，生成目录数据
    NSString * __block tempName = nil;
    [layerNamesArray enumerateObjectsUsingBlock:^(NSString * _Nonnull layerName, NSUInteger idx, BOOL * _Nonnull stop) {
        if (idx == 0) {
            tempName = layerName;
        } else if ([layerName isEqualToString:tempName]) {
            tempName = layerName;
            layerNamesArray[idx] = @"";
        } else {
            tempName = layerName;
        }
    }];
    [layerNamesArray removeObject:@""];
    
    // 如果目录大于 36，提示暂不支持
    if (layerNamesArray.count > 36) {
        NSAlert *alert = [[NSAlert alloc] init];
        [alert setMessageText:@"页码更新成功，目录更新失败"];
        [alert setInformativeText:@"暂不支持超过 36 条的目录"];
        [alert addButtonWithTitle:@"确定"];
        [alert beginSheetModalForWindow:window completionHandler:nil];
        [delegate didUpdateCatalogWithResult:@{@"category":@"UpdateCatalog",
                                               @"action":@"Fail",
                                               @"label":@"TooManyPages",
//                                               @"value":nil
                                               }];
        return;
    }
    
    // 清理旧目录，以及获取日期图层
    
}

@end
