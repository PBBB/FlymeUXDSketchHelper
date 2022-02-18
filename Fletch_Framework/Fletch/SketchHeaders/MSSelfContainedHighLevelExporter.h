//
//  MSSelfContainedHighLevelExporter.h
//  Fletch
//
//  Created by PBB on 2/18/22.
//  Copyright © 2022 pbb. All rights reserved.
//

#import <MSHighLevelExporter.h>

@interface MSSelfContainedHighLevelExporter : MSHighLevelExporter

@property(retain, nonatomic) NSDictionary *options; // @synthesize options=_options;

- (instancetype)initWithOptions: (NSDictionary *)options;

@end
