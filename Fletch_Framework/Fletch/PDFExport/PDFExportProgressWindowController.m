//
//  PDFExportProgressWindowController.m
//  Fletch
//
//  Created by pbb on 2018/4/3.
//  Copyright © 2018年 pbb. All rights reserved.
//

#import "PDFExportProgressWindowController.h"
#import <Quartz/Quartz.h>

@interface PDFExportProgressWindowController ()

@end

@implementation PDFExportProgressWindowController
#define PBLog(fmt, ...) NSLog((@"Fletch (Sketch Plugin) %s [Line %d] " fmt), __PRETTY_FUNCTION__, __LINE__, ##__VA_ARGS__);
@synthesize fileURL;

- (void)windowDidLoad {
    [super windowDidLoad];
    
    // Implement this method to handle any initialization after your window controller's window has been loaded from its nib file.
    [[self window] setMovableByWindowBackground:YES];
    NSButton *closeButton = [self.window standardWindowButton:NSWindowCloseButton];
    [closeButton setHidden:YES];
    [[[self window] contentView] setWantsLayer:YES];
    [_PDFExportSucessView setWantsLayer:YES];
}
- (IBAction)cancelExport:(NSButton *)sender {
    NSString *const TaskCanceledByUserNotificationName = @"TaskCanceledByUserNotification";
    [[NSNotificationCenter defaultCenter] postNotificationName:TaskCanceledByUserNotificationName object:self];
}

- (void)showSuccessViewWithFileURL: (NSURL *)fileURL {
    [self setFileURL:fileURL];
    NSButton *closeButton = [self.window standardWindowButton:NSWindowCloseButton];
    [closeButton setHidden:NO];
    
    // 计算对话框扩大后的位置及大小
    NSWindow *parentWindow = [[self window] parentWindow];
    NSPoint progressOrigin;
    progressOrigin.x = parentWindow.frame.origin.x + (parentWindow.frame.size.width - 189.0) / 2;
    progressOrigin.y = parentWindow.frame.origin.y + 30;
    
    // 放大对话框，添加导出成功的画面并设定透明度为 0
    [[self window] setFrame:NSMakeRect(progressOrigin.x, progressOrigin.y, 189.0, 145.0) display:YES animate:YES];
    [self.window.contentView addSubview:_PDFExportSucessView];
    [_PDFExportSucessView.layer setOpacity:0.0];
//    NSArray<NSLayoutConstraint *> *successViewHorizontalConstraints = [NSLayoutConstraint constraintsWithVisualFormat:@"|[successView]|" options:NSLayoutFormatAlignAllLeft metrics:nil views:@{@"successView": _PDFExportSucessView}];
//    NSArray<NSLayoutConstraint *> *successViewVerticalConstraints = [NSLayoutConstraint constraintsWithVisualFormat:@"V:|[successView]|" options:NSLayoutFormatAlignAllLeft metrics:nil views:@{@"successView": _PDFExportSucessView}];
//    [NSLayoutConstraint activateConstraints:[successViewHorizontalConstraints arrayByAddingObjectsFromArray:successViewVerticalConstraints]];

    // “正在导出”渐变消失动画
    CABasicAnimation* exportingFadeOutAnim = [CABasicAnimation animationWithKeyPath:@"opacity"];
    exportingFadeOutAnim.fromValue = [NSNumber numberWithFloat:1.0];
    exportingFadeOutAnim.toValue = [NSNumber numberWithFloat:0.0];
    exportingFadeOutAnim.duration = 0.1;
    
//    CABasicAnimation* exportingScaleDownAnim = [CABasicAnimation animationWithKeyPath:@"transform"];
//    CATransform3D tr = CATransform3DIdentity;
//    tr = CATransform3DTranslate(tr, _PDFExportingView.bounds.size.width/2, _PDFExportingView.bounds.size.height/2, 0);
//    tr = CATransform3DScale(tr, 0.0, 0.0, 1);
//    tr = CATransform3DTranslate(tr, -_PDFExportingView.bounds.size.width/2, -_PDFExportingView.bounds.size.height/2, 0);
//    exportingScaleDownAnim.toValue = [NSValue valueWithCATransform3D:tr];
//    exportingScaleDownAnim.duration = 2;
    
    // “导出成功”渐变显示动画
    CABasicAnimation* successFadeInAnim = [CABasicAnimation animationWithKeyPath:@"opacity"];
    successFadeInAnim.fromValue = [NSNumber numberWithFloat:0.0];
    successFadeInAnim.toValue = [NSNumber numberWithFloat:1.0];
    successFadeInAnim.beginTime = CACurrentMediaTime() + 0.1;
    successFadeInAnim.duration = 0.2;
    
    // 开始动画
    [_PDFExportingView.layer addAnimation:exportingFadeOutAnim forKey:@"opacity"];
//    [_PDFExportingView.layer addAnimation:exportingScaleDownAnim forKey:@"transform"];
    [_PDFExportSucessView.layer addAnimation:successFadeInAnim forKey:@"opacity"];
    
    // 延迟设定属性值（立即设定会出现闪一下的情况）
    dispatch_time_t delayTime = dispatch_time(DISPATCH_TIME_NOW, 0.1 * NSEC_PER_SEC);
    dispatch_after(delayTime, dispatch_get_main_queue(), ^(void){
        [self.PDFExportingView.layer setOpacity:0.0];
//        [self.PDFExportingView.layer setTransform:tr];
        [self.PDFExportSucessView.layer setOpacity:1.0];
    });
    
    // 定时自动关闭窗口
    dispatch_time_t delayCloseTime = dispatch_time(DISPATCH_TIME_NOW, 3 * NSEC_PER_SEC);
    dispatch_after(delayCloseTime, dispatch_get_main_queue(), ^(void){
        [self close];
    });
}

- (IBAction)openFolder:(NSButton *)sender {
    [[NSWorkspace sharedWorkspace] activateFileViewerSelectingURLs:@[fileURL]];
    [self close];
}

@end
