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
//    PBLog(@"Overrides: %@", symbolInstance.overrides);
    PBLog(@"OverrideValues: %@", symbolInstance.overrideValues);
//    PBLog(@"symbolID: %@", symbolInstance.symbolID);
}

@end
