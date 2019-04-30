//
//  MSOverrideValue.h
//  Fletch
//
//  Created by Issac Penn on 01/14/2018.
//  Copyright © 2018 pbb. All rights reserved.
//

@interface MSOverrideValue : NSObject

@property(retain, nonatomic) NSObject<NSCopying> *value;
@property(retain, nonatomic) NSString *overrideName;
@property(readonly, nonatomic) NSString *attributeName;

- (instancetype)initWithName:(NSString *)overrideName value:(NSObject<NSCopying> *) value;

@end
