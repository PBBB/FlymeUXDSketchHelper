//
//  PBMain.m
//  Fletch
//
//  Created by pbb on 2017/9/1.
//  Copyright © 2017年 pbb. All rights reserved.
//

#import "PBMain.h"

@implementation PBMain
#define PBLog(fmt, ...) NSLog((@"Fletch (Sketch Plugin) %s [Line %d] " fmt), __PRETTY_FUNCTION__, __LINE__, ##__VA_ARGS__);
@synthesize addHistoryWC;

- (NSString *)helloText {
    PBLog(@"Reading helloText");
    return @"Hey there, sending signal from PBMain, over.";
}

- (AddHistoryWindowController *)addHistoryWindowController {
    addHistoryWC = [[AddHistoryWindowController alloc] initWithWindowNibName:@"AddHistoryWindowController"];
    return addHistoryWC;
}

@end
