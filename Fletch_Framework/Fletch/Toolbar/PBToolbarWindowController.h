//
//  PBToolbarWindowController.h
//  Fletch
//
//  Created by Issac Penn on 06/13/2018.
//  Copyright © 2018 pbb. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "PBToolbarDelegate.h"

NS_ASSUME_NONNULL_BEGIN

@interface PBToolbarWindowController : NSWindowController <NSToolbarDelegate>
@property (nonatomic, retain) PBToolbarDelegate *delegate;

@end

NS_ASSUME_NONNULL_END
