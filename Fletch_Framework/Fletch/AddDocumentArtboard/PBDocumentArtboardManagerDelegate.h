//
//  PBDocumentArtboardManagerDelegate.h
//  Fletch
//
//  Created by pbb on 2017/9/4.
//  Copyright © 2017年 pbb. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface PBDocumentArtboardManagerDelegate : NSObject

//添加成功之后上报埋点
- (void) addDocumentArtboardSuccessWithType:(NSString *)type;
@end
