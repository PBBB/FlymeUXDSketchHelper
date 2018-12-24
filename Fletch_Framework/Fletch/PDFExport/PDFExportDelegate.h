//
//  PDFExportDelegate.h
//  Fletch
//
//  Created by pbb on 2018/1/15.
//  Copyright © 2018年 pbb. All rights reserved.
//

@interface PDFExportDelegate : NSObject

- (void)didFinishExportingWithType: (NSString *)type count: (NSNumber *) count;

- (void)didOpenFolderWithType: (NSString *)type;

@end
