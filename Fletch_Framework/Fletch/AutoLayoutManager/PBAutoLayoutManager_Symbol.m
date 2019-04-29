//
//  PBAutoLayoutManager_Symbol.m
//  Fletch
//
//  Created by PBB on 2019/4/26.
//  Copyright © 2019 pbb. All rights reserved.
//

#import "PBAutoLayoutManager_Symbol.h"

@implementation PBAutoLayoutManager_Symbol

+(void)performLayoutOfSymbolInstance: (MSSymbolInstance *) symbolInstance {
    
    // 如果图层名前面有 _，就视为不需要处理高度
    if ([[symbolInstance name] hasPrefix:@"_"]) {
        return;
    }
    
    // 如果是弹框组件，才会处理
    if ([[symbolInstance symbolID] isEqualToString:kAlertSymbolMasterID]) {
        
//        PBLog(@"availableOverrides: %@", symbolInstance.availableOverrides);
//        PBLog(@"overridePoints: %@", symbolInstance.overridePoints);
//        PBLog(@"OverrideValues: %@", symbolInstance.overrideValues);
//        PBLog(@"Overrides: %@", symbolInstance.overrides);
        //PBLog(@"symbolID: %@", symbolInstance.symbolID)；
        
        // 获取 override 信息，并判断是否有文字 override
        BOOL hasStringValueOverride = NO;
        NSArray<MSOverrideValue *> *overrideValues = symbolInstance.overrideValues;
        NSMutableDictionary<NSString *, NSObject<NSCopying> *> *overrideValuesDictionary = [[NSMutableDictionary alloc] init];
        for (MSOverrideValue *overrideValue in overrideValues) {
            if (!hasStringValueOverride && [overrideValue.overrideName containsString:@""]) {
                hasStringValueOverride = YES;
            }
            [overrideValuesDictionary setObject:overrideValue.value forKey:overrideValue.overrideName];
        }
        
        // 没有文字 override 的话就恢复默认样式
        if (!hasStringValueOverride) {
            [symbolInstance setOverrideValues:@[]];
        }
        
        PBLog(@"overrideValuesDictionary: %@", overrideValuesDictionary);
        
        // 如果有文字 override，就判断行数情况
        
        // 如果只有一行，将文字恢复成默认样式
        
        // 如果超过一行，将文字改为左对齐
        
        // 根据文字高度调整弹框高度（通用方法）
        // 需要注意，如果文字内容为单个空格，等同于把这行文字删掉，即减少文字本身高度以及间距 13 pt
        
        
        
    }
    
    
    

}

@end
