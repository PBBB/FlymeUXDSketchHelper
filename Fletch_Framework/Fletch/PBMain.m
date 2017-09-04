//
//  PBMain.m
//  Fletch
//
//  Created by pbb on 2017/9/1.
//  Copyright © 2017年 pbb. All rights reserved.
//

#import "PBMain.h"
#import "AddHistoryWindowController.h"

@implementation PBMain
#define PBLog(fmt, ...) NSLog((@"HelloSketch (Sketch Plugin) %s [Line %d] " fmt), __PRETTY_FUNCTION__, __LINE__, ##__VA_ARGS__);


- (NSString *)helloText {
    PBLog(@"Reading helloText");
    return @"Hey there, sending signal from PBMain, over.";
}

- (void)addHistory {
    AddHistoryWindowController *addHistoryWC = [[AddHistoryWindowController alloc] init];
    PBLog(@"addHistory");
    [addHistoryWC showWindow:self];
}

@end
