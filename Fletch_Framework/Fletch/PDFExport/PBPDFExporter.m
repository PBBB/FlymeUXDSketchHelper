//
//  PBPDFExporter.m
//  Fletch
//
//  Created by Issac Penn on 01/13/2018.
//  Copyright © 2018 pbb. All rights reserved.
//

#import "PBPDFExporter.h"
#import <Quartz/Quartz.h>

@class MSDocument, MSPage, MSArtboardGroup, MSPDFBookExporter;


@implementation PBPDFExporter
#define PBLog(fmt, ...) NSLog((@"Fletch (Sketch Plugin) %s [Line %d] " fmt), __PRETTY_FUNCTION__, __LINE__, ##__VA_ARGS__);

- (void)exportPDF: (NSDictionary *)context{
    
    //获取画板
    NSArray<MSArtboardGroup *> *artboardsToExport = nil;
    NSArray *selection = context[@"selection"];
    NSMutableArray<MSArtboardGroup *> *selectedArtboards = [];
    
    //从选择中筛选出画板
    for (int i = 0; i < [selection count]; i++) {
        if ([selection[i] isKindOfClass: [MSArtboardGroup class]]) {
            [selectedArtboards addObject: selection[i]];
        }
    }
    
    //如果有选择的画板，就只导出选择的画板，否则导出当前 Page 所有画板
    if ([selectedArtboards count] > 0) {
        artboardsToExport = selectedArtboards;
    } else {
        MSDocument *document = context[@"document"];
        MSPage *page = [document currentPage];
        artboardsToExport = [page artboards];
    }
    
    if ([artboardsToExport count] <= 0) {
        //TO DO: 提示用户没有可导出的画板
        PBLog(@"no artboards to export");
    }
    
    //画板排序
    NSArray<MSArtboardGroup *> *sortedArtboardArray = [artboardsToExport sortedArrayUsingSelector:@selector(compareArtboardsWithFirstOne:SecondOne:)];
    
    //生成文件名
    
    
    //弹出保存对话框
    
    
    //生成 PDF（考虑放在另一个线程）
    PDFDocument *pdfDocument = [[PDFDocument alloc] init];
    for (int i = 0; i < [sortedArtboardArray count]; i++) {
        PDFPage *pdfPage = [MSPDFBookExporter pdfFromArtboard:sortedArtboardArray[i]];
        [pdfDocument insertPage:pdfPage atIndex:[pdfDocument pageCount]];
    }
    
    //导出 PDF
    
}

- (BOOL)compareArtboardsWithFirstOne: (MSArtboardGroup *)firstAB SecondOne: (MSArtboardGroup *)secondAB {
    return YES;
}


//function compareArtboards (firstAB, secondAB) {
//    if (Math.abs(firstAB.frame().y() - secondAB.frame().y()) < firstAB.frame().height()) {
//        return firstAB.frame().x() - secondAB.frame().x();
//    } else {
//        return firstAB.frame().y() - secondAB.frame().y();
//    }
//}
//selectedArtboards.sort(compareArtboards);


@end
