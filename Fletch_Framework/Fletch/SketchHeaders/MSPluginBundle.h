//
//  MSPluginBundle.h
//  Fletch
//
//  Created by pbb on 2018/7/6.
//  Copyright © 2018年 pbb. All rights reserved.
//

@class MSPluginCommand;

@interface MSPluginBundle : NSObject
@property (nonatomic, retain) NSURL *url;
@property(readonly, copy, nonatomic) NSDictionary<NSString *, MSPluginCommand *> *commands;

@end
