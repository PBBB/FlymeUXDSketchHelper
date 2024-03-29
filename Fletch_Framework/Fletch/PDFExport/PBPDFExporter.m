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
#import "MSSelfContainedHighLevelExporter.h"
#import "PDFExportProgressWindowController.h"

@implementation PBPDFExporter
#define PBLog(fmt, ...) NSLog((@"Fletch (Sketch Plugin) %s [Line %d] " fmt), __PRETTY_FUNCTION__, __LINE__, ##__VA_ARGS__);

@synthesize delegate, documentWindow;

- (void)exportPDF: (NSDictionary *)context withPDFExporterClass: (Class)MSPDFBookExporterClass
   TextLayerClass: (Class)MSTextLayerClass ArtboardGroupClass: (Class)MSArtboardGroupClass MSSelfContainedHighLevelExporterClass:(Class)MSSelfContainedHighLevelExporterClass {

    //获取画板
    NSArray<MSArtboardGroup *> *artboardsToExport = nil;
    NSArray *selection = context[@"selection"];
    NSMutableArray<MSArtboardGroup *> *selectedArtboards = [NSMutableArray<MSArtboardGroup *> array];
    MSDocument *document = context[@"document"];
    documentWindow = [document window];
    
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
        [alert beginSheetModalForWindow:documentWindow completionHandler:nil];
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
    
    //压缩过程中使用这个额外的部分做文件名，用于避免同时导出 PDF 时文件混淆
    NSString *extraFileNameForCompression = [NSString stringWithFormat:@"%f", currentDate.timeIntervalSince1970];
    
    //用数组保存压缩任务
    NSMutableArray <NSTask *> *CompressionTaskArray = [[NSMutableArray alloc] init];
    
    //接收任务完成所发出的通知，并合并文件
    NSString *const TaskCompletionNotificationName = @"TaskCompletionNotification";
    NSString *const TaskCanceledByUserNotificationName = @"TaskCanceledByUserNotification";
    __block BOOL allCompressionTaskFinished = NO;
    __block BOOL userCanceledTask = NO;
    __block NSURL *saveFileURL = nil;
    __block int finishedArtboardsCount = 0;
    __block PDFExportProgressWindowController *progressWC; //用来显示导出进度
    [[NSNotificationCenter defaultCenter] addObserverForName:TaskCompletionNotificationName object:self queue:nil usingBlock:^(NSNotification * _Nonnull note) {
        if (userCanceledTask) {return;}
        finishedArtboardsCount++;
        if (progressWC) {
            [[progressWC pdfExportProgressIndicator] setDoubleValue:(double)finishedArtboardsCount/(double)[sortedArtboardArray count]*100.0];
//            进度条不能直接做动画，坑爹
//            [NSAnimationContext runAnimationGroup:^(NSAnimationContext * _Nonnull context) {
//                [context setDuration:0.2];
//                [[[progressWC pdfExportProgressIndicator] animator] setDoubleValue: (double)finishedArtboardsCount/(double)[sortedArtboardArray count]*100.0];
//            } completionHandler:nil];
        }
        if (finishedArtboardsCount == [sortedArtboardArray count]) {
            allCompressionTaskFinished = YES;
            if (saveFileURL != nil) {
                // 之前是全部压缩完成后就关闭进度面板，但是和最后的导出成功之间可能有延迟
//                if (progressWC) {
//                    [[progressWC pdfExportProgressIndicator] setIndeterminate:YES];
//                    [[progressWC pdfExportProgressIndicator] startAnimation:nil];
//                    [[progressWC exportLabel] setStringValue:@"即将完成…"];
//                }
                if ([self combinePDFDocumentToURL:saveFileURL pageCount:[sortedArtboardArray count] extraFileName:extraFileNameForCompression]) {
                    dispatch_async(dispatch_get_main_queue(), ^{
//                        [progressWC close];
                        [progressWC changeToSuccessViewWithFileURL:saveFileURL];
                        [self showExportSuccessNotificationWithFileURL:saveFileURL inDocument:document];
//                        [document showMessage:@"✅ 导出成功"];
                    });
                    [self->delegate didFinishExportingWithType:@"DoneGeneratingAfterClickingSave" count:0];
                }
                else {
                    //如果有部分页面压缩失败则进行提示
                    dispatch_async(dispatch_get_main_queue(), ^{
                        NSAlert *alert = [[NSAlert alloc] init];
                        [alert addButtonWithTitle:@"确定"];
                        [alert setMessageText:@"导出成功，但部分页面压缩失败"];
                        [alert setInformativeText:@"你可以使用其他软件再次压缩导出后的 PDF。\n这种情况通常是由于文档中的部分图片在压缩过程中出现异常，你可以检查一下文档中所使用的图片。"];
                        [progressWC close];
                        [alert beginSheetModalForWindow:self->documentWindow completionHandler:nil];
                    });
                }
            }
        }
    }];
    
    //弹出保存对话框
    NSSavePanel *savePanel = [NSSavePanel savePanel];
    [savePanel setNameFieldStringValue:fileName];
    [savePanel setAllowedFileTypes:@[@"pdf"]];
//    [savePanel setMessage:@"导出较大文件时请耐心等候"];
    [savePanel beginSheetModalForWindow:documentWindow completionHandler:^(NSModalResponse result) {
        [savePanel orderOut:nil];
        if (result == NSModalResponseOK) {
            //如果点击 OK 之后后台工作都准备好，那么直接合成文件
            saveFileURL = [savePanel URL];
            
            //初始化进度弹框
            progressWC = [[PDFExportProgressWindowController alloc] initWithWindowNibName:@"PDFExportProgressWindowController"];
            progressWC.pdfExporter = self;
            NSPoint progressOrigin;
            progressOrigin.x = self->documentWindow.frame.origin.x + (self->documentWindow.frame.size.width - progressWC.window.frame.size.width) / 2;
            progressOrigin.y = self->documentWindow.frame.origin.y + 30;
            [[progressWC window] setFrameOrigin:progressOrigin];
            [[progressWC window] orderOut:nil];
//            [[progressWC window] makeKeyAndOrderFront:nil];
            
            //接收通知，用户取消之后就停掉导出进程
            [[NSNotificationCenter defaultCenter] addObserverForName:TaskCanceledByUserNotificationName object:progressWC queue:nil usingBlock:^(NSNotification * _Nonnull note) {
                userCanceledTask = YES;
                for (int i = 0; i < [CompressionTaskArray count]; i++) {
                    [CompressionTaskArray[i] terminate];
                }
                [progressWC close];
            }];
            
            [[progressWC PDFExportingView] setHidden:YES];
            [self->documentWindow addChildWindow:[progressWC window] ordered:NSWindowAbove];
            
            
            //接收通知，根据父窗口的尺寸变化，调整自己的位置
            [[NSNotificationCenter defaultCenter] addObserverForName:NSWindowDidResizeNotification object:self->documentWindow queue:nil usingBlock:^(NSNotification * _Nonnull note) {
                NSPoint progressOrigin;
                progressOrigin.x = self->documentWindow.frame.origin.x + (self->documentWindow.frame.size.width - progressWC.window.frame.size.width) / 2;
                progressOrigin.y = self->documentWindow.frame.origin.y + 30;
                [[progressWC window] setFrameOrigin:progressOrigin];
            }];
            
            if (allCompressionTaskFinished) {
                if ([self combinePDFDocumentToURL:saveFileURL pageCount:[sortedArtboardArray count] extraFileName:extraFileNameForCompression]) {
                    dispatch_async(dispatch_get_main_queue(), ^{
                        [[progressWC window] makeKeyAndOrderFront:nil];
                        [progressWC showSuccessViewWithFileURL:saveFileURL];
                        [self showExportSuccessNotificationWithFileURL:saveFileURL inDocument:document];
                    });
                    [self->delegate didFinishExportingWithType:@"DoneGeneratingBeforeClickingSave" count:0];
                } else {
                    //如果有部分页面压缩失败则进行提示
                    dispatch_async(dispatch_get_main_queue(), ^{
                        NSAlert *alert = [[NSAlert alloc] init];
                        [alert addButtonWithTitle:@"确定"];
                        [alert setMessageText:@"导出成功，但部分页面压缩失败"];
                        [alert setInformativeText:@"你可以使用其他软件再次压缩导出后的 PDF。\n这种情况通常是由于文档中的部分图片在压缩过程中出现异常，你可以检查一下文档中所使用的图片。"];
                        [progressWC close];
                        [alert beginSheetModalForWindow:self->documentWindow completionHandler:nil];
                    });
                    return;
                }
            } else {
                [[progressWC window] makeKeyAndOrderFront:nil];
                [[progressWC PDFExportingView] setHidden:NO];
                [[progressWC pdfExportProgressIndicator] setDoubleValue:(double)finishedArtboardsCount/(double)[sortedArtboardArray count]*100.0];
//                进度条不能直接做动画，坑爹
//                [NSAnimationContext runAnimationGroup:^(NSAnimationContext * _Nonnull context) {
//                    [context setDuration:0.2];
//                    [[[progressWC pdfExportProgressIndicator] animator] setDoubleValue: (double)finishedArtboardsCount/(double)[sortedArtboardArray count]*100.0];
//                } completionHandler:nil];
                
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
//            PDFPage *pdfPage = [MSPDFBookExporterClass pdfFromArtboard:sortedArtboardArray[i]];
            //每一页一个文档
//            PDFDocument *pdfDocument = [[PDFDocument alloc] init];
//            [pdfDocument insertPage:pdfPage atIndex:0];
            //每一页都导出一个 PDF 文件，放在缓存文件夹
            NSString *TmpPath = NSTemporaryDirectory();
//            NSString *tmpFileURLString = [NSString stringWithFormat:@"file://%@%@%d.pdf", TmpPath, extraFileNameForCompression, i];
//            [pdfDocument writeToURL:[NSURL URLWithString:tmpFileURLString]];
            
            //设定导出选项
            NSDictionary *exporterOptions = @{
                @"overwriting" : @YES,
                @"use-id-for-name" : @YES,
                @"formats" : @[@"pdf"],
                @"output" : TmpPath
            };
            
            MSSelfContainedHighLevelExporter *exporter = [(MSSelfContainedHighLevelExporter *)[MSSelfContainedHighLevelExporterClass alloc] initWithOptions: exporterOptions];
            [exporter exportLayers:@[sortedArtboardArray[i]]];
            
            
            //执行压缩命令
            NSString *exportedFileURLString = [NSString stringWithFormat:@"%@%@.pdf", TmpPath, [sortedArtboardArray[i] objectID]];
            NSString *tmpFileURLStringForTerminal = [NSString stringWithFormat:@"%@%@%d.pdf", TmpPath, extraFileNameForCompression, i];
            [[NSFileManager defaultManager] moveItemAtPath:exportedFileURLString toPath:tmpFileURLStringForTerminal error:nil];
            NSString *tmpCompressedFileURLStringForTerminal = [NSString stringWithFormat:@"%@%@%d_compressed.pdf", TmpPath, extraFileNameForCompression, i];
            NSTask *task = [[NSTask alloc] init];
            [CompressionTaskArray addObject:task];
            if (@available(macOS 10.13, *)) {
                [task setExecutableURL:[NSURL URLWithString:@"file:///bin/bash"]];
            } else {
                [task setLaunchPath:@"/bin/bash"];
            }
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
                        dispatch_async(dispatch_get_main_queue(), ^{
                            [savePanel cancel:nil];
                            NSAlert *alert = [[NSAlert alloc] init];
                            [alert addButtonWithTitle:@"去下载"];
                            [alert addButtonWithTitle:@"取消"];
                            [alert setMessageText:@"请先安装 GhostScript"];
                            [alert setInformativeText:@"PDF 压缩功能需要 GhostScript，请先下载并安装"];
                            [alert beginSheetModalForWindow:self->documentWindow completionHandler:^(NSModalResponse returnCode) {
                                switch (returnCode) {
                                    case NSAlertFirstButtonReturn:
                                        [[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:@"https://pages.uoregon.edu/koch/Ghostscript-9.55-Full.pkg"]];
                                        [self->documentWindow endSheet:[alert window]];
                                        break;
                                    case NSAlertSecondButtonReturn:
                                        [self->documentWindow endSheet:[alert window]];
                                        break;
                                    default:
                                        break;
                                }
                            }];
                        });
                    } else {
                        [[NSNotificationCenter defaultCenter] postNotificationName:TaskCompletionNotificationName object:self userInfo:@{@"id" : [NSNumber numberWithInt:i]}];
                    }
                } else {
                    [[NSNotificationCenter defaultCenter] postNotificationName:TaskCompletionNotificationName object:self userInfo:@{@"id" : [NSNumber numberWithInt:i]}];
                }
                
            }];
            [task launchAndReturnError: &compressTaskError];
        }
    });
}

- (BOOL) combinePDFDocumentToURL:(NSURL *) url pageCount: (NSUInteger) pageCount extraFileName: (NSString *) extraFileNameForCompression{
    PDFDocument *pdfDocument = nil;
    NSString *TmpPath = NSTemporaryDirectory();
    NSMutableArray<NSNumber *> *failedPagesArray = [NSMutableArray<NSNumber *> array];
    for (int i = 0; i < pageCount; i++) {
        NSString *compressedFilePath = [NSString stringWithFormat:@"file://%@%@%d_compressed.pdf", TmpPath, extraFileNameForCompression, i];
        NSString *originalFilePath = [NSString stringWithFormat:@"file://%@%@%d.pdf", TmpPath, extraFileNameForCompression, i];
        if (i == 0) {
            pdfDocument = [[PDFDocument alloc] initWithURL:[NSURL URLWithString:compressedFilePath]];
            if ([pdfDocument pageCount] == 0){
                pdfDocument = [[PDFDocument alloc] initWithURL:[NSURL URLWithString:originalFilePath]];
                [failedPagesArray addObject: [NSNumber numberWithInt:i]];
            }
        } else {
            PDFDocument *tmpDocument = [[PDFDocument alloc] initWithURL:[NSURL URLWithString:compressedFilePath]];
            if ([tmpDocument pageCount] == 0){
                tmpDocument = [[PDFDocument alloc] initWithURL:[NSURL URLWithString:originalFilePath]];
                [failedPagesArray addObject: [NSNumber numberWithInt:i]];
            }
            [pdfDocument insertPage:[tmpDocument pageAtIndex:0] atIndex:[pdfDocument pageCount]];
        }
    }
    [pdfDocument writeToURL:url];
    if ([failedPagesArray count] > 0) {
        [self->delegate didFinishExportingWithType:@"FailedCompressing" count: [NSNumber numberWithUnsignedInteger:[failedPagesArray count]]];
        return NO;
    } else {
        return YES;
    }
}

- (void) showExportSuccessNotificationWithFileURL: (NSURL *) saveFileURL inDocument: (MSDocument *) document{
    // 文档内显示导出成功
//    [document showMessage:@"✅ 导出成功"];
    
    
    
    // 显示通知（UserNotification 在 10.14 才有，所以做了系统判断）
    if (@available(macOS 10.14, *)) {
        // 定义类别，为通知添加操作做准备
        UNNotificationAction *openFolderAction = [UNNotificationAction actionWithIdentifier:@"OPEN_FOLDER" title:@"打开目录" options:UNNotificationActionOptionNone];
        UNNotificationCategory *PDFExportSuccessNotificationCategpry = [UNNotificationCategory categoryWithIdentifier:@"PDF_EXPORT_SUCCESS" actions:@[openFolderAction] intentIdentifiers:@[] hiddenPreviewsBodyPlaceholder:@"" categorySummaryFormat:nil options:UNNotificationCategoryOptionCustomDismissAction];
        
        // 向通知中心注册此类通知
        UNUserNotificationCenter* center = [UNUserNotificationCenter currentNotificationCenter];
        [center setNotificationCategories: [NSSet setWithObject:PDFExportSuccessNotificationCategpry]];
        [center setDelegate:self];
        
        // 初始化通知信息
        UNMutableNotificationContent* content = [[UNMutableNotificationContent alloc] init];
        content.title = @"PDF 导出成功";
        content.body = saveFileURL.lastPathComponent;
        content.sound = [UNNotificationSound defaultSound];
        content.categoryIdentifier = @"PDF_EXPORT_SUCCESS";
        content.userInfo = @{@"FILE_URL": saveFileURL.absoluteString};
        
        UNTimeIntervalNotificationTrigger* trigger = [UNTimeIntervalNotificationTrigger triggerWithTimeInterval:0.001 repeats:NO];
        UNNotificationRequest* request = [UNNotificationRequest requestWithIdentifier:@"PBPDFExportSuccess" content:content trigger:trigger];
        
        [center addNotificationRequest:request withCompletionHandler:nil];
    } else {
        // Fallback on earlier versions
    }
}

- (void)userNotificationCenter:(UNUserNotificationCenter *)center didReceiveNotificationResponse:(UNNotificationResponse *)response withCompletionHandler:(void (^)(void))completionHandler API_AVAILABLE(macos(10.14)){
    if ([response.actionIdentifier isEqualToString:@"OPEN_FOLDER"]) {
        NSString *fileURLString = response.notification.request.content.userInfo[@"FILE_URL"];
        NSURL *fileURL = [NSURL URLWithString:fileURLString];
        [[NSWorkspace sharedWorkspace] activateFileViewerSelectingURLs:@[fileURL]];
        [delegate didOpenFolderWithType:@"Notification"];
    } else if ([response.actionIdentifier isEqualToString:UNNotificationDefaultActionIdentifier]){
        [documentWindow makeKeyAndOrderFront:nil];
        [NSApp activateIgnoringOtherApps:YES];
    }
    completionHandler();
}

@end
