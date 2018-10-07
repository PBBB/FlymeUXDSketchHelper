//
//  MSSymbolInstance.h
//  Fletch
//
//  Created by pbb on 2018/7/11.
//  Copyright © 2018年 pbb. All rights reserved.
//

#import "MSStyledLayer.h"
#import "MSSymbolMaster.h"

@interface MSSymbolInstance : MSStyledLayer

@property (copy, nonatomic) NSDictionary *overrides;

- (MSSymbolMaster *) symbolMaster;

@end
