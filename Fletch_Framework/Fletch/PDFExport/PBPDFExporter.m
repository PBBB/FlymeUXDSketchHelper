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
    
    //用数组保存压缩任务
    NSMutableArray <NSTask *> *CompressionTaskArray = [[NSMutableArray alloc] init];
    
    //接收任务完成所发出的通知，并合并文件
    NSString *const TaskCompletionNotificationName = @"TaskCompletionNotification";
    __block BOOL allCompressionTaskFinished = NO;
    __block NSURL *saveFileURL = nil;
    __block int finishedArtboardsCount = 0;
    [[NSNotificationCenter defaultCenter] addObserverForName:TaskCompletionNotificationName object:self queue:nil usingBlock:^(NSNotification * _Nonnull note) {
        finishedArtboardsCount++;
        PBLog(@"task notification received: %@", [note userInfo]);
        if (finishedArtboardsCount == [sortedArtboardArray count]) {
            PBLog(@"All compression tasks finished.");
            allCompressionTaskFinished = YES;
            if (saveFileURL != nil) {
                [self combinePDFDocumentToURL:saveFileURL pageCount:[sortedArtboardArray count] inWindow:window];
                [self->delegate didFinishExportingWithType:@"1"];
            }
        }
    }];
    
    //弹出保存对话框
    NSSavePanel *savePanel = [NSSavePanel savePanel];
    [savePanel setNameFieldStringValue:fileName];
    [savePanel setAllowedFileTypes:@[@"pdf"]];
    [savePanel setMessage:@"导出较大文件时请耐心等候"];
    [savePanel beginSheetModalForWindow:window completionHandler:^(NSModalResponse result) {
        [savePanel orderOut:nil];
        if (result == NSModalResponseOK) {
            //如果点击 OK 之后后台工作都准备好，那么直接合成文件
            saveFileURL = [savePanel URL];
            if (allCompressionTaskFinished) {
                [self combinePDFDocumentToURL:saveFileURL pageCount:[sortedArtboardArray count] inWindow:window];
                [self->delegate didFinishExportingWithType:@"0"];
            } else {
//                [[NSNotificationCenter defaultCenter] postNotificationName:SaveFileURLReceivedNotificationName object:self userInfo:@{@"URL" : [savePanel URL]}];
            }
            
        } else {
            //如果点击取消，最好清理缓存文件以及停止导出的进程
            for (int i = 0; i < [CompressionTaskArray count]; i++) {
                [CompressionTaskArray[i] terminate];
            }
        }
    }];
    
    //后台生成 PDF
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
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
            [CompressionTaskArray addObject:task];
            [task setExecutableURL:[NSURL URLWithString:@"file:///bin/bash"]];
            [task setArguments:@[@"-l", @"-c", [NSString stringWithFormat:@"gs -dPDFSETTINGS=/ebook -dNOPAUSE -sDEVICE=pdfwrite -sOUTPUTFILE=%@ -dBATCH %@",
                                               tmpCompressedFileURLStringForTerminal, tmpFileURLStringForTerminal]]];
            NSError *compressTaskError = nil;
            //第一个任务记录输出，检查命令是否存在
            NSPipe *outPipe = nil;
            NSFileHandle *fileHandle = nil;
            if (i == 0) {
                outPipe = [[NSPipe alloc] init];
                [task setStandardError:outPipe];
                fileHandle = [outPipe fileHandleForReading];
            }
            //任务完成后发送通知
            [task setTerminationHandler:^(NSTask * _Nonnull someTask) {
                if (i == 0) {
                    NSData *data = [fileHandle readDataToEndOfFile];
                    NSString *grepOutput = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
                    if ([grepOutput containsString:@"command not found"]) {
                        //没有找到命令，提示用户，并且不发送导出成功的消息
                        PBLog(@"grepOutput: %@", grepOutput);
                        dispatch_async(dispatch_get_main_queue(), ^{
                            [savePanel cancel:nil];
                            NSAlert *alert = [[NSAlert alloc] init];
                            [alert addButtonWithTitle:@"确定"];
                            [alert setMessageText:@"未找到 GhostScript"];
                            [alert setInformativeText:@"PDF 压缩功能需要 GhostScript，请在终端中执行命令“brew install ghostscript”以安装 GhostScript。\n\n若提示“brew: command not found”，则需要先执行“/usr/bin/ruby -e \"$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)\"”（注：命令不包含中文引号）"];
                            [alert beginSheetModalForWindow:window completionHandler:nil];
                        });
                    } else {
                        [[NSNotificationCenter defaultCenter] postNotificationName:TaskCompletionNotificationName object:self userInfo:@{@"id" : [NSNumber numberWithInt:i]}];
                    }
                } else {
                    [[NSNotificationCenter defaultCenter] postNotificationName:TaskCompletionNotificationName object:self userInfo:@{@"id" : [NSNumber numberWithInt:i]}];
                }
                
            }];
            [task launchAndReturnError: &compressTaskError];
            
            //TO DO: 需要考虑没有找到命令的情况
            PBLog(@"compress task launch, id: %d", i);
        }
    });
}

//- (void) combinePDFDocument2ToURL:(NSURL *) url pageCount: (NSUInteger) pageCount inWindow: (MSDocumentWindow *) window {
//    NSString *urlString = [[url absoluteString] stringByRemovingPercentEncoding];
//    NSTask *task = [[NSTask alloc] init];
//    [task setExecutableURL:[NSURL URLWithString:@"file:///bin/bash"]];
//    NSMutableString *inputFileURLStrings = [[NSMutableString alloc] init];
//    NSString *TmpPath = NSTemporaryDirectory();
//    for (int i = 0; i < pageCount; i++) {
//        [inputFileURLStrings appendString:[NSString stringWithFormat:@"%@%d_compressed.pdf ", TmpPath, i]];
//    }
//    NSString *outputfileURLString = [urlString substringFromIndex:7];
//    [task setArguments:@[@"-l", @"-c", [NSString stringWithFormat:@"pdftkk %@cat output %@", inputFileURLStrings, outputfileURLString]]];
//    //检查命令是否存在
//    NSPipe *outPipe = [[NSPipe alloc] init];
//    [task setStandardError:outPipe];
//    NSFileHandle *fileHandle = [outPipe fileHandleForReading];
//   
//    [task setTerminationHandler:^(NSTask * _Nonnull someTask) {
//        NSData *data = [fileHandle readDataToEndOfFile];
//        NSString *grepOutput = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
//        if ([grepOutput containsString:@"command not found"]) {
//            PBLog(@"pdftk not found");
//            dispatch_async(dispatch_get_main_queue(), ^{
//                NSAlert *alert = [[NSAlert alloc] init];
//                [alert addButtonWithTitle:@"确定"];
//                [alert setMessageText:@"未找到 pdftk"];
//                [alert setInformativeText:@"PDF 压缩功能需要 pdftk，请在终端中执行命令“brew install https://raw.githubusercontent.com/turforlag/homebrew-cervezas/master/pdftk.rb”以安装 pdftk"];
//                [alert beginSheetModalForWindow:window completionHandler:nil];
//            });
//        }
//    }];
//    
//    NSError *compressTaskError = nil;
//    PBLog(@"inputFileURLStrings: %@, outputfileURLString: %@", inputFileURLStrings, outputfileURLString);
//    [task launchAndReturnError: &compressTaskError];
//}

- (void) combinePDFDocumentToURL:(NSURL *) url pageCount: (NSUInteger) pageCount inWindow: (MSDocumentWindow *) window {
    PDFDocument *pdfDocument = nil;
    NSString *TmpPath = NSTemporaryDirectory();
    for (int i = 0; i < pageCount; i++) {
        NSString *filePath = [NSString stringWithFormat:@"file://%@%d_compressed.pdf", TmpPath, i];
        if (i == 0) {
            pdfDocument = [[PDFDocument alloc] initWithURL:[NSURL URLWithString:filePath]];
        } else {
            PDFDocument *tmpDocument = [[PDFDocument alloc] initWithURL:[NSURL URLWithString:filePath]];
            [pdfDocument insertPage:[tmpDocument pageAtIndex:0] atIndex:[pdfDocument pageCount]];
        }
    }
    [pdfDocument writeToURL:url];
}


@end

