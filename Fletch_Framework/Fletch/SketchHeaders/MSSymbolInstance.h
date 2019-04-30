//
//  MSSymbolInstance.h
//  Fletch
//
//  Created by pbb on 2018/7/11.
//  Copyright © 2018年 pbb. All rights reserved.
//

#import "MSStyledLayer.h"
#import "MSSymbolMaster.h"
#import "MSOverrideValue.h"
#import "MSOverridePoint.h"

@interface MSSymbolInstance : MSStyledLayer

@property (copy, nonatomic) NSDictionary *overrides;
@property (retain, nonatomic) NSArray<MSOverrideValue *> *overrideValues;
@property (retain, nonatomic) NSString *symbolID;
//@property (readonly, nonatomic) NSArray *availableOverrides;
@property (readonly, nonatomic) NSArray<MSOverridePoint *> *overridePoints;

- (MSSymbolMaster *) symbolMaster;
- (MSLayerGroup *)detachStylesAndReplaceWithGroupRecursively:(BOOL)recursive;

@end
