//
//  MSLayerGroup.h
//  Fletch
//
//  Created by Issac Penn on 01/14/2018.
//  Copyright © 2018 pbb. All rights reserved.
//


#import "MSStyledLayer.h"
@class MSLayer;

@interface MSLayerGroup : MSStyledLayer

@property(retain, nonatomic) NSArray<MSLayer *> *layers;

- (void)addLayers: (NSArray<MSLayer *> *)layers;
- (BOOL)resizeToFitChildrenWithOption:(long long)option;

@end

