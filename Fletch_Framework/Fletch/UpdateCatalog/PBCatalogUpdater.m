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

- (void) updateCatalogWithContext: (NSDictionary *)context MSArtboardGroupClass: (Class)MSArtboardGroupClass MSSymbolInstanceClass: (Class)MSSymbolInstanceClass  MSImmutableColorClass:(Class)MSImmutableColorClass MSTextLayerClass:(Class)MSTextLayerClass MSLayerGroupClass:(Class)MSLayerGroupClass{
    
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
    NSMutableArray<NSString *> *artboardNamesArray = [[NSMutableArray alloc] init];
    
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
            [artboardNamesArray addObject:[pageTitleLayer stringValue]];
            
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
    
    // 处理重复标题
    NSString * __block tempName = nil;
    [artboardNamesArray enumerateObjectsUsingBlock:^(NSString * _Nonnull layerName, NSUInteger idx, BOOL * _Nonnull stop) {
        if (idx == 0) {
            tempName = layerName;
        } else if ([layerName isEqualToString:tempName]) {
            tempName = layerName;
            artboardNamesArray[idx] = @"";
        } else {
            tempName = layerName;
        }
    }];
    
    // 用新数组来计算目录总数。保留空字符串是为了保证页码关系
    NSMutableArray *artboardNamesArrayToCount = [NSMutableArray arrayWithArray:artboardNamesArray];
    [artboardNamesArrayToCount removeObject:@""];
    
    // 如果目录大于 36，提示暂不支持
    if (artboardNamesArrayToCount.count > 36) {
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
    MSArtboardGroup *coverArtboard = selectedArtboards[0];
    NSArray<MSLayer *> *layersInCoverArtboard = [coverArtboard childrenIncludingSelf:NO];
    MSTextLayer *dateLayer = nil;
    for (MSLayer *layer in layersInCoverArtboard) {
        if ([[layer name] isEqualToString:@"目录一"] ||
            [[layer name] isEqualToString:@"目录二"] ||
            [[layer name] isEqualToString:@"目录三"] ||
            [[layer name] isEqualToString:@"目录四"]) {
            [layer removeFromParent];
        } else if ([[layer name] containsString:@"最后更新"]) {
            dateLayer = (MSTextLayer *)layer;
        }
    }
    
    // 生成新目录文字图层
    NSMutableArray<MSTextLayer *> * __block catalogTextLayers = [[NSMutableArray alloc] init];
    [artboardNamesArray enumerateObjectsUsingBlock:^(NSString * _Nonnull layerName, NSUInteger idx, BOOL * _Nonnull stop) {
        if (![layerName isEqualToString:@""]) {
            
            // 拼接文本
            MSTextLayer *textLayer = [[MSTextLayerClass alloc] init];
            NSString *catalogString = [NSString stringWithFormat:@"%lu %@", (unsigned long)idx + 3, layerName];
            [textLayer setStringValue:catalogString];
            [textLayer setName:catalogString];
            
            // 设定样式
            NSFont *font = [NSFont fontWithName:@"PingFangSC-Medium" size:40.0];
            MSImmutableColor *textColor = [MSImmutableColorClass colorWithRed:0.29 green:0.29 blue:0.29 alpha:1.0];
            [textLayer setFont:font];
            [textLayer setTextColor:textColor];
            [textLayer adjustFrameToFit];
            
            [catalogTextLayers addObject:textLayer];
        }
        
    }];
    
    // 设定目录文字图层的纵向间距
    [catalogTextLayers enumerateObjectsUsingBlock:^(MSTextLayer * _Nonnull textLayer, NSUInteger idx, BOOL * _Nonnull stop) {
        if (idx > 0) {
           [[textLayer frame] setY:([catalogTextLayers[idx-1] frame].y + 117.0)];
        }
    }];
    
    // 用于存放目录图层组
    NSArray<MSLayerGroup *> *catalogTextLayerGroups = nil;
    int groupSize = 4;
    
    // 5、6、9 条目录时，每组目录 3 条，其他 16 条以内都是 4 条；超过 16 条就按四列的容量来排
    if (catalogTextLayers.count == 5 || catalogTextLayers.count == 6 || catalogTextLayers.count == 9) {
        groupSize = 3;
    } else if (catalogTextLayers.count <= 16) {
        groupSize = 4;
    } else {
        groupSize = (int)ceil((double)catalogTextLayers.count / 4.0);
    }
    
    catalogTextLayerGroups = [self genetateGroupsFromLayers:catalogTextLayers groupSize:groupSize withMSLayerGroupClass:MSLayerGroupClass];
    
    // 设定每个组的位置，并置入封面画板
    catalogTextLayerGroups[0].frame.x = (coverArtboard.frame.width - catalogTextLayerGroups.lastObject.frame.width - 691.0 * (catalogTextLayerGroups.count - 1)) / 2;
    [catalogTextLayerGroups enumerateObjectsUsingBlock:^(MSLayerGroup * _Nonnull layerGroup, NSUInteger idx, BOOL * _Nonnull stop) {
        if (idx > 0) {
            layerGroup.frame.x = catalogTextLayerGroups[0].frame.x + 691 * idx;
        }
        
        //小于等于 4 行（即总数小于等于 16 时），从固定的 Y 坐标开始向下排
        if (catalogTextLayers.count <= 16) {
            layerGroup.frame.y = 1132.0;
        } else {
            //大于 4 行时，目录从原来四行的位置的基础上上下延伸
            layerGroup.frame.y = 1132.0 + 407.0 / 2.0 - catalogTextLayerGroups[0].frame.height / 2;
        }
    }];
    [coverArtboard addLayers:catalogTextLayerGroups];
    
    // 更新日期
    if (dateLayer) {
        NSDate *dateNow = [NSDate date];
        NSDateComponents *components = [[NSCalendar currentCalendar] components:NSCalendarUnitDay|NSCalendarUnitMonth|NSCalendarUnitYear fromDate:dateNow];
        NSString *dateInfo = [NSString stringWithFormat:@"最后更新 %lu年%lu月%lu日",components.year, components.month, components.day];
        [dateLayer setTextAlignment: 0]; // 设置左对齐
        [dateLayer setStringValue:dateInfo];
        [dateLayer setName:dateInfo];
    } else {
        NSAlert *alert = [[NSAlert alloc] init];
        [alert setMessageText:@"页码及目录更新成功，日期更新失败"];
        [alert setInformativeText:@"请更新至最新版交互文档模板"];
        [alert addButtonWithTitle:@"确定"];
        [alert beginSheetModalForWindow:window completionHandler:nil];
    }
    [delegate didUpdateCatalogWithResult:@{@"category":@"UpdateCatalog",
                                           @"action":@"Success",
                                           @"label":@"Success",
                                           @"value":[NSString stringWithFormat:@"%lu", (unsigned long)catalogTextLayers.count]
                                           }];
    [document showMessage:@"✅ 页码及目录更新成功"];
}

// 根据目录文字图层，以及每一组的图层数量来将目录图层文字分组
- (NSArray<MSLayerGroup *> *) genetateGroupsFromLayers: (NSArray<MSLayer *> *)layers groupSize:(int)groupSize withMSLayerGroupClass: (Class)MSLayerGroupClass {
    NSMutableArray<MSLayerGroup *> *layerGroups = [[NSMutableArray alloc] init];
    NSArray *names = @[@"目录一", @"目录二", @"目录三", @"目录四"];
    int numberOfGroups = (int)ceil((double)layers.count / (double)groupSize);
    for (int i = 0; i < numberOfGroups; i++) {
        MSLayerGroup *layerGroup = [[MSLayerGroupClass alloc] init];
        [layerGroup setName:names[i]];
        
        //选出每个目录下包含的图层
        NSRange range = NSMakeRange(i*groupSize, MIN((i+1)*groupSize, layers.count) - i*groupSize);
        [layerGroup addLayers: [layers subarrayWithRange:range]];
        [layerGroup resizeToFitChildrenWithOption:0];
        [layerGroups addObject:layerGroup];
    }
    return layerGroups;
}

@end
