//
//  MSLayer.h
//  Fletch
//
//  Created by Issac Penn on 01/14/2018.
//  Copyright © 2018 pbb. All rights reserved.
//

@class MSRect;

@interface MSLayer : NSObject

@property (retain, nonatomic) NSString *name;
@property (retain, nonatomic) MSRect *frame;

@end
