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

//#define kAlertSymbolMasterID @"95F30D38-A2BB-431D-9989-EB746ADF9710"
#define kAlertSymbolMasterName @"3 弹框 / 警示框 / a 主副标题"
#define kAlertTitleTextOverrideName @"51FFE8CF-A7AB-45E0-A32F-1B899A84BDF9"
#define kAlertTitleLeftAlignTextStyleID @"8F9E9568-0575-49C9-BA01-80F53BE1E1C6"
#define kAlertSubtitleTextOverrideName @"84E02B3E-C676-475D-B982-12BA5887D7A0"
#define kAlertSubtitleLeftAlignTextStyleID @"229A38F9-14CF-4B71-A635-5BF4F9944392"

+ (void)performLayoutOfSymbolInstance: (MSSymbolInstance *) symbolInstance;
@end

NS_ASSUME_NONNULL_END
