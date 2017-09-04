//
//  PBUpdateNotesTextView.h
//  Fletch
//
//  Created by pbb on 2017/9/4.
//  Copyright © 2017年 pbb. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface PBUpdateNotesTextView : NSTextView

//用来显示占位文本，但是因为是私有 API 所以只能用继承的方式来做
@property (nonatomic, retain) NSString *placeholderString;
@end
