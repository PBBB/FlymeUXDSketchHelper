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

#define kAlertSymbolMasterID @"1EA1A886-C5E1-4145-8679-1D9E20E1805D"
#define kAlertTitleTextOverrideName @"E3D16CDC-A576-4400-B115-4EC836793214"
#define kAlertTitleLeftAlignTextStyleID @"7F21F730-4B86-465E-845C-13C46E412551"
#define kAlertSubtitleTextOverrideName @"DBE035AC-00AC-48F0-A015-8DC837555D43"
#define kAlertSubtitleLeftAlignTextStyleID @"47B4E527-89D5-4D99-9978-197031155409"

+ (void)performLayoutOfSymbolInstance: (MSSymbolInstance *) symbolInstance;
@end

NS_ASSUME_NONNULL_END
