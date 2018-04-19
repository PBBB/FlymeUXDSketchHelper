//
//  PDFExportDelegate.h
//  Fletch
//
//  Created by pbb on 2018/1/15.
//  Copyright © 2018年 pbb. All rights reserved.
//

@interface PDFExportDelegate : NSObject

//类型 0 是点击保存的时候后台已经生成完成，类型 1 是后台生成后才导出成功
- (void)didFinishExportingWithType: (NSString *)type count: (NSNumber *) count;

@end
