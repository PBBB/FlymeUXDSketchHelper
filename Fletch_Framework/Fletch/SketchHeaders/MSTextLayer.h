//
//  MSTextLayer.h
//  Fletch
//
//  Created by Issac Penn on 01/14/2018.
//  Copyright © 2018 pbb. All rights reserved.
//

#import "MSStyledLayer.h"
#import "MSImmutableColor.h"

@interface MSTextLayer : MSStyledLayer

@property(copy, nonatomic) NSString *stringValue;
@property(copy, nonatomic) MSImmutableColor *textColor;
@property (nonatomic) unsigned long long textAlignment;

- (void)setFont:(NSFont *)font;
- (void)adjustFrameToFit;

@end
