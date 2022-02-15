//
//  MSPage.h
//  Fletch
//
//  Created by Issac Penn on 01/14/2018.
//  Copyright © 2018 pbb. All rights reserved.
//

#import <MSLayerGroup.h>
@class MSArtboardGroup;

@interface MSPage : MSLayerGroup

- (NSArray<MSArtboardGroup *> *)artboards;

@end
