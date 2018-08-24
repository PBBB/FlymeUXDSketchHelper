//
//  AddHistoryDateSrubberDataSource.m
//  Fletch
//
//  Created by Issac Penn on 2018/8/24.
//  Copyright © 2018 pbb. All rights reserved.
//

#import "AddHistoryDateSrubberDataSource.h"

@implementation AddHistoryDateSrubberDataSource

- (NSInteger)numberOfItemsForScrubber:(NSScrubber *)scrubber {
    return 9;
}

- (NSScrubberItemView *)scrubber:(NSScrubber *)scrubber viewForItemAtIndex:(NSInteger)index {
//    NSDate *currentDate = [[NSDate alloc] initWithTimeIntervalSinceNow:0];
    NSScrubberTextItemView *scrubberItem = [scrubber makeItemWithIdentifier:@"AddHistoryDateSrubberData" owner:self];
    if (scrubberItem == nil) {
        scrubberItem = [[NSScrubberTextItemView alloc] init];
    }
    [scrubberItem setTitle:[NSString stringWithFormat:@"Item %ld", (long)index]];
    return scrubberItem;
}

@end
