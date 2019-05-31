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
            NSMutableArray<MSLayer *> *layersToOverrideInSymbolMaster = [[NSMutableArray<MSLayer *> alloc] init];
            NSMutableArray<MSRect *> *newLayerFrames = [[NSMutableArray<MSRect *> alloc] init];
            [layersToOverride enumerateObjectsUsingBlock:^(MSLayer * _Nonnull layerFromSymbolMaster, NSUInteger idx, BOOL * _Nonnull stop) {
                [[newGroupFromDetachedInstance childrenIncludingSelf:NO] enumerateObjectsUsingBlock:^(MSLayer * _Nonnull layerFromDetachedInstance, NSUInteger idx, BOOL * _Nonnull stop) {
                    if ([layerFromSymbolMaster.name isEqualToString:layerFromDetachedInstance.name] &&
                        layerFromSymbolMaster.frame.x == layerFromDetachedInstance.frame.x && layerFromSymbolMaster.frame.y == layerFromDetachedInstance.frame.y) {
                        [layersToOverrideInDetachedInstance addObject:layerFromDetachedInstance];
                        [layersToOverrideInSymbolMaster addObject:layerFromSymbolMaster];
                        [newLayerFrames addObject:layerFromDetachedInstance.frame];
                        *stop = YES;
                    }
                }];
            }];
//            PBLog(@"layersToOverride: %@",layersToOverrideInDetachedInstance);
//            PBLog(@"originalLayerFrames: %@",newLayerFrames);
        
            // 4. 根据新的文字高度，调整文字样式和计算总高度
            __block double deltaHeight = 0.0;
            NSMutableArray<MSOverrideValue *> *newOverrideValues = [[NSMutableArray<MSOverrideValue *> alloc] initWithArray:symbolInstance.overrideValues];
            
            [layersToOverrideInDetachedInstance enumerateObjectsUsingBlock:^(MSLayer * _Nonnull layerFromDetachedInstance, NSUInteger idx, BOOL * _Nonnull stop) {
                
                // 如果文字内容为单个空格，那么就等同于把这行文字删掉，即减少文字本身高度以及间距 13 pt
                if ([layerFromDetachedInstance isMemberOfClass:NSClassFromString(@"MSTextLayer")] && [((MSTextLayer *)layerFromDetachedInstance).stringValue isEqualToString:@" "]) {
                    deltaHeight = deltaHeight - newLayerFrames[idx].height - 13;
                } else {
                    deltaHeight += (newLayerFrames[idx].height - originalLayerFrames[idx].height);
                }
                
                // 如果只有一行（即高度相等），将文字恢复成默认样式
                NSMutableIndexSet *indexesOfOverrideValuesToRemove = [[NSMutableIndexSet alloc] init];
                if ([layerFromDetachedInstance isMemberOfClass:NSClassFromString(@"MSTextLayer")] && newLayerFrames[idx].height == originalLayerFrames[idx].height) {
                    [[symbolInstance overridePoints] enumerateObjectsUsingBlock:^(MSOverridePoint * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
                        [layersToOverrideInSymbolMaster enumerateObjectsUsingBlock:^(MSLayer * _Nonnull obj2, NSUInteger idx2, BOOL * _Nonnull stop2) {
                            if ([obj.layerID isEqualToString: obj2.objectID] && [obj.name containsString:@"textStyle"]) {
                                NSString *overrideName = obj.name;
                                [newOverrideValues enumerateObjectsUsingBlock:^(MSOverrideValue * _Nonnull obj3, NSUInteger idx3, BOOL * _Nonnull stop3) {
                                    if ([obj3.overrideName isEqualToString:overrideName]) {
                                        [indexesOfOverrideValuesToRemove addIndex:idx3];
                                    }
                                }];
                            }
                        }];
                    }];
                    [newOverrideValues removeObjectsAtIndexes:indexesOfOverrideValuesToRemove];
                } else {
                    // 如果超过一行，将文字改为左对齐
                    if ([[symbolInstance overridePoints][idx].name isEqualToString:kAlertTitleTextOverrideName]) {
                        //TODO: 调整左对齐样式
                    } else if ([[symbolInstance overridePoints][idx].name isEqualToString:kAlertSubtitleTextOverrideName]) {
                        //TODO: 调整左对齐样式
                    }
                }
                
            }];
            
            // 5. 调整高度，并且删除新建的图层
            
            symbolInstance.frame.height = symbolInstance.symbolMaster.frame.height + deltaHeight;
            symbolInstance.overrideValues = newOverrideValues;
            [newGroupFromDetachedInstance removeFromParent];
            
        }

        
        
        
        
        
        
        // 根据文字高度调整弹框高度（通用方法）
        
        
        
    }
    
    
    

}

@end
