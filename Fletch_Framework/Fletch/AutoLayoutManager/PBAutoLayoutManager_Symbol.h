//
//  PBAutoLayoutManager_Symbol.h
//  Fletch
//
//  Created by PBB on 2019/4/26.
//  Copyright © 2019 pbb. All rights reserved.
//

#import "PBAutoLayoutManager.h"
#import "MSSymbolInstance.h"

NS_ASSUME_NONNULL_BEGIN

@interface PBAutoLayoutManager_Symbol : PBAutoLayoutManager
#define PBLog(fmt, ...) NSLog((@"Fletch (Sketch Plugin) %s [Line %d] " fmt), __PRETTY_FUNCTION__, __LINE__, ##__VA_ARGS__);

+ (void)performLayoutOfSymbolInstance: (MSSymbolInstance *) symbolInstance;
@end

NS_ASSUME_NONNULL_END
