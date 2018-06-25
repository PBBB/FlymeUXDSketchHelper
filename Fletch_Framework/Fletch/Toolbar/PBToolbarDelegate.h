//
//  PBToolbarDelegate.h
//  Fletch
//
//  Created by pbb on 2018/6/25.
//  Copyright © 2018年 pbb. All rights reserved.
//

typedef enum : NSUInteger {
    PBToolbarCommandAddHistory,
} PBToolbarCommand;

@interface PBToolbarDelegate : NSObject

- (void)willRunCommand: (PBToolbarCommand) command;

@end

