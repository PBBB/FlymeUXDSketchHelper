//
//  PBToolbarHelper.h
//  Fletch
//
//  Created by pbb on 2018/7/6.
//  Copyright © 2018年 pbb. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "PBToolbarWindowController.h"
#import "PBToolbarDelegate.h"

@interface PBToolbarHelper : NSObject
@property (nonatomic, retain) PBToolbarWindowController *toolbarWC;
@property (nonatomic, retain) PBToolbarDelegate *delegate;
@property (nonatomic, retain) NSDictionary<NSString *, NSDictionary<NSString *, NSString *> *> *toolbarInfo;
- (void)showToolbar: (NSDictionary *)context;

@end

