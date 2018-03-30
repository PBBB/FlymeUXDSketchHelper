//
//  PBPDFExporter.m
//  Fletch
//
//  Created by Issac Penn on 01/13/2018.
//  Copyright © 2018 pbb. All rights reserved.
//

#import "PBPDFExporter.h"
#import <Quartz/Quartz.h>
#import "MSTextLayer.h"
#import "MSPage.h"
#import "MSDocumentWindow.h"
#import "MSDocument.h"
#import "MSPDFBookExporter.h"
#import "MSRect.h"
#import "MSArtboardGroup.h"

@implementation PBPDFExporter
#define PBLog(fmt, ...) NSLog((@"Fletch (Sketch Plugin) %s [Line %d] " fmt), __PRETTY_FUNCTION__, __LINE__, ##__VA_ARGS__);

@synthesize delegate;

- (void)exportPDF: (NSDictionary *)context withPDFExporterClass: (Class)MSPDFBookExporterClass
   TextLayerClass: (Class)MSTextLayerClass ArtboardGroupClass: (Class)MSArtboardGroupClass {

    //获取画板
    NSArray<MSArtboardGroup *> *artboardsToExport = nil;
    NSArray *selection = context[@"selection"];
    NSMutableArray<MSArtboardGroup *> *selectedArtboards = [NSMutableArray<MSArtboardGroup *> array];
    MSDocument *document = context[@"document"];
    MSDocumentWindow *window = [document window];
    
    //从选择中筛选出画板
    for (int i = 0; i < [selection count]; i++) {
        if ([selection[i] isKindOfClass: MSArtboardGroupClass]) {
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
        NSAlert *alert = [[NSAlert alloc] init];
        [alert setMessageText:@"请选择需要导出的画板"];
        [alert addButtonWithTitle:@"确定"];
        [alert beginSheetModalForWindow:window completionHandler:nil];
    }
    
    //画板排序
    NSArray<MSArtboardGroup *> *sortedArtboardArray = [artboardsToExport sortedArrayUsingComparator:^NSComparisonResult(MSArtboardGroup *  _Nonnull firstAB, MSArtboardGroup * _Nonnull secondAB) {
        if (fabs([[firstAB frame] y] - [[secondAB frame] y]) < [[firstAB frame] height]) {
            return [[firstAB frame] x] > [[secondAB frame] x];
        } else {
            return [[firstAB frame] y] > [[secondAB frame] y];
        }
    }];
    
    //生成文件名
    NSString *appName = nil;
    for (int i = 0; i < [sortedArtboardArray count]; i++) {
        if ([[sortedArtboardArray[i] name]  isEqual: @"封面 "] || [[sortedArtboardArray[i] name]  isEqual: @"封面"]) {
            NSArray<MSLayer *> *layers = [sortedArtboardArray[i] layers];
            for (int j = 0; j < [layers count]; j++) {
                if ([[layers[j] name]  isEqual: @"应用名称"] && [layers[j] isKindOfClass:MSTextLayerClass]) {
                    appName = [(MSTextLayer *)layers[j] stringValue];
                    break;
                }
            }
            break;
        }
    }
    
    //生成文件名中的日期
    NSDate *currentDate = [NSDate date];
    NSCalendar *currentCalendar = [NSCalendar currentCalendar];
    NSDateComponents *dateComponents = [currentCalendar components:NSCalendarUnitMonth|NSCalendarUnitDay fromDate:currentDate];
    NSInteger month = [dateComponents month];
    NSInteger day = [dateComponents day];
    NSString *dateString = [NSString stringWithFormat: @"%02ld%02ld", (long)month, (long)day];
    
    //合并文件名，并去掉 app 名称里的空格
    NSString *fileName = appName == nil ? [NSString stringWithFormat: @"功能概述_交互文档_%@", dateString]
    : [NSString stringWithFormat: @"%@_交互文档_%@", [appName stringByReplacingOccurrencesOfString:@" " withString:@""], dateString];
    
    //弹出保存对话框
    NSSavePanel *savePanel = [NSSavePanel savePanel];
    [savePanel setNameFieldStringValue:fileName];
    [savePanel setAllowedFileTypes:@[@"pdf"]];
    [savePanel setMessage:@"导出较大文件时请耐心等候"];
//    PDFDocument *pdfDocument = [[PDFDocument alloc] init];
    __block BOOL isFinishedGenerating = NO;
    [savePanel beginSheetModalForWindow:window completionHandler:^(NSModalResponse result) {
        [savePanel orderOut:nil];
        if (result == NSModalResponseOK) {
            //如果点击 OK 之后后台工作都准备好，那么直接合成文件
            PBLog(@"save panel url: %@", [savePanel URL]);
            /*
            if (isFinishedGenerating) {
//                [pdfDocument writeToURL:[savePanel URL]];
                [delegate didFinishExportingWithType:@"0"];
                [document showMessage:@"✅ 导出成功"];
            } else {
                [[NSNotificationCenter defaultCenter] postNotificationName:@"SaveFileURLReceived" object:self userInfo:@{@"URL" : [savePanel URL]}];
            }*/
            
        } else {
            //如果点击取消，最好清理缓存文件以及停止导出的进程
        }
    }];
    
    //后台生成 PDF
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
//        __block BOOL isFinishiedExporting = YES;
        __block NSURL *url = nil;
        [[NSNotificationCenter defaultCenter] addObserverForName:@"SaveFileURLReceived" object:self queue:nil usingBlock:^(NSNotification * _Nonnull note) {
            url = [note userInfo][@"URL"];
//            isFinishiedExporting = NO;
        }];

        for (int i = 0; i < [sortedArtboardArray count]; i++) {
            //从画板生成 PDFPage
            PDFPage *pdfPage = [MSPDFBookExporterClass pdfFromArtboard:sortedArtboardArray[i]];
            //每一页一个文档
            PDFDocument *pdfDocument = [[PDFDocument alloc] init];
            [pdfDocument insertPage:pdfPage atIndex:0];
            //每一页都导出一个 PDF 文件，放在缓存文件夹
            NSString *TmpPath = NSTemporaryDirectory();
            NSString *tmpFileURLString = [NSString stringWithFormat:@"file://%@%d.pdf", TmpPath, i];
            BOOL success = [pdfDocument writeToURL:[NSURL URLWithString:tmpFileURLString]];
            PBLog(@"Tmp file exported to URL: %@, success: %hhd", tmpFileURLString, success);
            //执行压缩命令
            NSString *tmpFileURLStringForTerminal = [NSString stringWithFormat:@"%@%d.pdf", TmpPath, i];
            NSString *tmpCompressedFileURLStringForTerminal = [NSString stringWithFormat:@"%@%d_compressed.pdf", TmpPath, i];
            NSTask *task = [[NSTask alloc] init];
            [task setExecutableURL:[NSURL URLWithString:@"file:///bin/bash"]];
            [task setArguments:@[@"-l", @"-c",[NSString stringWithFormat:@"gs -dPDFSETTINGS=/printer -dNOPAUSE -sDEVICE=pdfwrite -sOUTPUTFILE=%@ -dBATCH %@",
                                               tmpCompressedFileURLStringForTerminal, tmpFileURLStringForTerminal]]];
            NSError *compressTaskError = nil;
            [task launchAndReturnError: &compressTaskError];
            //TO DO: 需要考虑没有找到命令的情况
            PBLog(@"compress task launch, id: %d", i);
        }
        PBLog(@"out of loop");
        //待所有压缩命令完成后，将 PDF 文件合并，保存在保存框选择的 URL
        isFinishedGenerating = YES;
        if (url != nil) {
//            [pdfDocument writeToURL:url];
            [delegate didFinishExportingWithType:@"1"];
            dispatch_sync(dispatch_get_main_queue(), ^{
                [document showMessage:@"✅ 导出成功"];
            });
        }
    });
    
    //接收压缩任务完成的通知（目前未生效）
    [[NSNotificationCenter defaultCenter] addObserverForName:NSTaskDidTerminateNotification object:self queue:nil usingBlock:^(NSNotification * _Nonnull note) {
        PBLog(@"finished: %@", [note object]);
    }];
}


@end

