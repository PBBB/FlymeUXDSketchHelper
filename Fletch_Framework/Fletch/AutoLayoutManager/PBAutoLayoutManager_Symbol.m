//
//  PBAutoLayoutManager_Symbol.m
//  Fletch
//
//  Created by PBB on 2019/4/26.
//  Copyright © 2019 pbb. All rights reserved.
//

#import "PBAutoLayoutManager_Symbol.h"
#import "MSRect.h"
#import "MSTextLayer.h"

@implementation PBAutoLayoutManager_Symbol

+(void)performLayoutOfSymbolInstance: (MSSymbolInstance *) symbolInstance {
    
    MSLayerGroup *currentArtboardGroup = [symbolInstance parentArtboard] ? (MSLayerGroup *)[symbolInstance parentArtboard] : (MSLayerGroup *)[symbolInstance parentPage] ;
    
    
    // 如果图层名前面有 _，就视为不需要处理高度
    if ([[symbolInstance name] hasPrefix:@"_"]) {
        return;
    }
    
    // 如果是弹框组件，才会处理
    if ([[[symbolInstance symbolMaster] name] isEqualToString:kAlertSymbolMasterName]) {
        
//        PBLog(@"availableOverrides: %@", symbolInstance.availableOverrides);
//        PBLog(@"overridePoints: %@", symbolInstance.overridePoints);
        PBLog(@"OverrideValues: %@", symbolInstance.overrideValues);
//        PBLog(@"Overrides: %@", symbolInstance.overrides);
        //PBLog(@"symbolID: %@", symbolInstance.symbolID)；
        
        // 获取 override 信息，并判断是否有文字 override
        BOOL hasStringValueOverride = NO;
        NSArray<MSOverrideValue *> *overrideValues = symbolInstance.overrideValues;
        if ([overrideValues count] > 0) {
            for (MSOverrideValue *overrideValue in overrideValues) {
                if (!hasStringValueOverride && [overrideValue.overrideName containsString:@"stringValue"]) {
                    hasStringValueOverride = YES;
                }
            }
        }
        
        
        // 没有文字 override 的话就恢复默认样式，并且恢复默认高度
        if (!hasStringValueOverride) {
            NSMutableArray *overrideValuesWithoutTextStyle = [NSMutableArray arrayWithArray:overrideValues];
            [overrideValuesWithoutTextStyle enumerateObjectsUsingBlock:^(MSOverrideValue * _Nonnull overrideValue, NSUInteger idx, BOOL * _Nonnull stop) {
                if ([overrideValue.overrideName containsString:@"textStyle"]) {
                    [overrideValuesWithoutTextStyle setObject:@"" atIndexedSubscript:idx];
                }
            }];
            [overrideValuesWithoutTextStyle removeObject:@""];
            [symbolInstance setOverrideValues:overrideValuesWithoutTextStyle];
            symbolInstance.frame.height = [symbolInstance symbolMaster].frame.height;
        } else {
            // 如果有文字 override，就判断行数情况
            
            // 1. 在当前画板新建这个画板的实例，并且将宽度设置为跟所选实例一样
            MSSymbolMaster *symbolMaster = [symbolInstance symbolMaster];
            MSSymbolInstance *newInstance = [symbolMaster newSymbolInstance];
            [currentArtboardGroup insertLayer:newInstance atIndex:0];
            
            // 2. 记下当前 override 相关图层的宽高信息
            
            // 2.1 通过 overridePoints 获得相关的 layer ID
            NSMutableArray<NSString *> *layerIdOfOverridePoints = [[NSMutableArray<NSString *> alloc] init];
            [[symbolInstance overridePoints] enumerateObjectsUsingBlock:^(MSOverridePoint * _Nonnull overridePoint, NSUInteger idx, BOOL * _Nonnull stop) {
                [layerIdOfOverridePoints addObject:overridePoint.layerID];
            }];
            
            // 2.2 看图层的 ID 在 overridePoints 里有没有，有的话就把图层和尺寸信息记录下来
            NSMutableArray<MSLayer *> *layersToOverride = [[NSMutableArray<MSLayer *> alloc] init];
            NSMutableArray<MSRect *> *originalLayerFrames = [[NSMutableArray<MSRect *> alloc] init];
            [[symbolMaster childrenIncludingSelf:NO] enumerateObjectsUsingBlock:^(MSLayer * _Nonnull layer, NSUInteger idx, BOOL * _Nonnull stop) {
                if ([layerIdOfOverridePoints containsObject:layer.objectID]) {
                    [layersToOverride addObject:layer];
                    [originalLayerFrames addObject:layer.frame];
                }
            }];
//            PBLog(@"layersToOverride: %@",layersToOverride);
//            PBLog(@"originalLayerFrames: %@",originalLayerFrames);
            
            // 3. 修改 override，并计算文字图层高度
            
            // 3.1 修改后解组，并找到之前 override 对应的解组后图层
            [newInstance setOverrideValues:symbolInstance.overrideValues];
            MSLayerGroup *newGroupFromDetachedInstance = [newInstance detachStylesAndReplaceWithGroupRecursively:NO];
            
            // 3.2 通过对比 frame 和名字，如果两个图层的坐标、名称都相同，就当作同一个图层了
            // 这种对比对于左对齐的 symbol 才有用，之后做到其他 symbol 的时候，看有没有什么新的图层关联方式
            NSMutableArray<MSLayer *> *layersToOverrideInDetachedInstance = [[NSMutableArray<MSLayer *> alloc] init];
            NSMutableArray<MSRect *> *newLayerFrames = [[NSMutableArray<MSRect *> alloc] init];
            [layersToOverride enumerateObjectsUsingBlock:^(MSLayer * _Nonnull layerFromSymbolMaster, NSUInteger idx, BOOL * _Nonnull stop) {
                [[newGroupFromDetachedInstance childrenIncludingSelf:NO] enumerateObjectsUsingBlock:^(MSLayer * _Nonnull layerFromDetachedInstance, NSUInteger idx, BOOL * _Nonnull stop) {
                    if ([layerFromSymbolMaster.name isEqualToString:layerFromDetachedInstance.name] &&
                        layerFromSymbolMaster.frame.x == layerFromDetachedInstance.frame.x && layerFromSymbolMaster.frame.y == layerFromDetachedInstance.frame.y) {
                        [layersToOverrideInDetachedInstance addObject:layerFromDetachedInstance];
                        [newLayerFrames addObject:layerFromDetachedInstance.frame];
                        *stop = YES;
                    }
                }];
            }];
//            PBLog(@"layersToOverride: %@",layersToOverride);
//            PBLog(@"layersToOverrideInSymbolMaster: %@",layersToOverrideInSymbolMaster);
        
            // 4. 根据新的文字高度，调整文字样式和计算总高度
            __block double deltaHeight = 0.0;
            NSMutableArray<MSOverrideValue *> *newOverrideValues = [[NSMutableArray<MSOverrideValue *> alloc] initWithArray:symbolInstance.overrideValues];
            
//            NSMutableIndexSet *indexesOfOverrideValuesToRemove = [[NSMutableIndexSet alloc] init];
            NSMutableArray<MSOverrideValue *> *overrideValuesToRemove = [[NSMutableArray<MSOverrideValue *> alloc] init];
            NSMutableArray<MSOverrideValue *> *overrideValuesToAdd = [[NSMutableArray<MSOverrideValue *> alloc] init];
            [layersToOverrideInDetachedInstance enumerateObjectsUsingBlock:^(MSLayer * _Nonnull layerFromDetachedInstance, NSUInteger idxOfLayerFromDetachedInstance, BOOL * _Nonnull stop) {
                
                // 如果文字内容为单个空格，那么就等同于把这行文字删掉，即减少文字本身高度以及间距 13 pt
                if ([layerFromDetachedInstance isMemberOfClass:NSClassFromString(@"MSTextLayer")] && [((MSTextLayer *)layerFromDetachedInstance).stringValue isEqualToString:@" "]) {
                    deltaHeight = deltaHeight - newLayerFrames[idxOfLayerFromDetachedInstance].height - 13;
                } else {
                    deltaHeight += (newLayerFrames[idxOfLayerFromDetachedInstance].height - originalLayerFrames[idxOfLayerFromDetachedInstance].height);
                }
                
                
                
                // 找到这个图层的 style 对应的 override point，开始遍历
                [[symbolInstance overridePoints] enumerateObjectsUsingBlock:^(MSOverridePoint * _Nonnull overridePoint, NSUInteger idxOfOverridePoint, BOOL * _Nonnull stop2) {
                    
                    // 如果 layer ID 对上号了，那就是匹配上了
                    if ([overridePoint.layerID isEqualToString: layersToOverride[idxOfLayerFromDetachedInstance].objectID] && [overridePoint.name containsString:@"textStyle"]) {
                        NSString *overrideName = overridePoint.name;
                        
                        // 先删掉对应的 override value（记录一下哪些要删，最后一起删），结果是恢复成默认的居中样式
                        [newOverrideValues enumerateObjectsUsingBlock:^(MSOverrideValue * _Nonnull newOverrideValue, NSUInteger idxOfNewOverrideValue, BOOL * _Nonnull stop3) {
                            if ([newOverrideValue.overrideName isEqualToString:overrideName]) {
                                [overrideValuesToRemove addObject:newOverrideValue];
                                *stop3 = YES;
                            }
                        }];
                        
                        // 判断是否高度相等，如果不相等，意味着高度不止一行，就要加左对齐样式
                        if ([layerFromDetachedInstance isMemberOfClass:NSClassFromString(@"MSTextLayer")] && newLayerFrames[idxOfLayerFromDetachedInstance].height != originalLayerFrames[idxOfLayerFromDetachedInstance].height) {
                            MSOverrideValue *newTextStyleOverrideValue = [[NSClassFromString(@"MSOverrideValue") alloc] init];
                            newTextStyleOverrideValue.overrideName = overridePoint.name;
                            if ([overridePoint.name containsString:kAlertTitleTextOverrideName]) {
                                newTextStyleOverrideValue.value = kAlertTitleLeftAlignTextStyleID;
                                [overrideValuesToAdd addObject:newTextStyleOverrideValue];
                            } else if ([overridePoint.name containsString:kAlertSubtitleTextOverrideName]){
                                newTextStyleOverrideValue.value = kAlertSubtitleLeftAlignTextStyleID;
                                [overrideValuesToAdd addObject:newTextStyleOverrideValue];
                            }
                            
                        }
                        *stop2 = YES;
                    }
                }];
            }];

            [newOverrideValues removeObjectsInArray:overrideValuesToRemove];
            [newOverrideValues addObjectsFromArray:overrideValuesToAdd];
            
            
            // 5. 调整高度，并且删除新建的图层
            
            symbolInstance.frame.height = symbolInstance.symbolMaster.frame.height + deltaHeight;
            symbolInstance.overrideValues = newOverrideValues;
            [newGroupFromDetachedInstance removeFromParent];
            
        }
    }
    
    
    

}

@end
