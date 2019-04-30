//
//  MSLayer.h
//  Fletch
//
//  Created by Issac Penn on 01/14/2018.
//  Copyright © 2018 pbb. All rights reserved.
//

@class MSRect, MSArtboardGroup, MSPage;

@interface MSLayer : NSObject

@property (copy, nonatomic) NSString *name;
@property (retain, nonatomic) MSRect *frame;
@property (readonly, nonatomic) NSString *objectID;
@property (readonly, nonatomic) MSArtboardGroup *parentArtboard;
@property (readonly, nonatomic) __weak MSPage *parentPage;

- (NSArray<MSLayer *> *)childrenIncludingSelf:(BOOL)includingSelf;
- (void)removeFromParent;
- (MSLayer *)duplicate;

@end
