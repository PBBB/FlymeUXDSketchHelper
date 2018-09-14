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
//    PDFExportSuccessView *successView = [[PDFExportSuccessView alloc] initWithFrame:NSMakeRect(0.0, 0.0, 214.0, 159.0)];
    NSButton *closeButton = [self.window standardWindowButton:NSWindowCloseButton];
    [closeButton setHidden:NO];
    
    NSWindow *parentWindow = [[self window] parentWindow];
    NSPoint progressOrigin;
    progressOrigin.x = parentWindow.frame.origin.x + (parentWindow.frame.size.width - 189.0) / 2;
    progressOrigin.y = parentWindow.frame.origin.y + 30;
    
    
//    NSArray<NSLayoutConstraint *> *successViewHorizontalConstraints = [NSLayoutConstraint constraintsWithVisualFormat:@"|[successView]|" options:NSLayoutFormatAlignAllLeft metrics:nil views:@{@"successView": _PDFExportSucessView}];
//    NSArray<NSLayoutConstraint *> *successViewVerticalConstraints = [NSLayoutConstraint constraintsWithVisualFormat:@"V:|[successView]|" options:NSLayoutFormatAlignAllLeft metrics:nil views:@{@"successView": _PDFExportSucessView}];
//    [NSLayoutConstraint activateConstraints:[successViewHorizontalConstraints arrayByAddingObjectsFromArray:successViewVerticalConstraints]];

    
    [[self window] setFrame:NSMakeRect(progressOrigin.x, progressOrigin.y, 189.0, 145.0) display:YES animate:YES];
    [self.window.contentView addSubview:_PDFExportSucessView];
//    NSArray<NSLayoutConstraint *> *successViewHorizontalConstraints = [NSLayoutConstraint constraintsWithVisualFormat:@"|[successView]|" options:NSLayoutFormatAlignAllLeft metrics:nil views:@{@"successView": _PDFExportSucessView}];
//    NSArray<NSLayoutConstraint *> *successViewVerticalConstraints = [NSLayoutConstraint constraintsWithVisualFormat:@"V:|[successView]|" options:NSLayoutFormatAlignAllLeft metrics:nil views:@{@"successView": _PDFExportSucessView}];
//    [NSLayoutConstraint activateConstraints:[successViewHorizontalConstraints arrayByAddingObjectsFromArray:successViewVerticalConstraints]];
    [_PDFExportSucessView.layer setOpacity:0.0];
    
    CABasicAnimation* exportingFadeOutAnim = [CABasicAnimation animationWithKeyPath:@"opacity"];
    exportingFadeOutAnim.fromValue = [NSNumber numberWithFloat:1.0];
    exportingFadeOutAnim.toValue = [NSNumber numberWithFloat:0.0];
    exportingFadeOutAnim.duration = 0.3;
    
    CABasicAnimation* exportingScaleDownAnim = [CABasicAnimation animationWithKeyPath:@"transform"];
    CATransform3D tr = CATransform3DIdentity;
    tr = CATransform3DTranslate(tr, _PDFExportingView.bounds.size.width/2, _PDFExportingView.bounds.size.height/2, 0);
    tr = CATransform3DScale(tr, 0.8, 0.8, 1);
    tr = CATransform3DTranslate(tr, -_PDFExportingView.bounds.size.width/2, -_PDFExportingView.bounds.size.height/2, 0);
    exportingScaleDownAnim.toValue = [NSValue valueWithCATransform3D:tr];
    exportingFadeOutAnim.duration = 0.3;
    
    
    CABasicAnimation* successFadeInAnim = [CABasicAnimation animationWithKeyPath:@"opacity"];
    successFadeInAnim.fromValue = [NSNumber numberWithFloat:0.0];
    successFadeInAnim.toValue = [NSNumber numberWithFloat:1.0];
    successFadeInAnim.beginTime = CACurrentMediaTime() + 0.2;
    successFadeInAnim.duration = 0.2;
    
    
    [_PDFExportingView.layer addAnimation:exportingFadeOutAnim forKey:@"opacity"];
    [_PDFExportingView.layer addAnimation:exportingScaleDownAnim forKey:@"transform"];
    [_PDFExportSucessView.layer addAnimation:successFadeInAnim forKey:@"opacity"];
    
    dispatch_time_t delayTime = dispatch_time(DISPATCH_TIME_NOW, 0.3 * NSEC_PER_SEC);
    dispatch_after(delayTime, dispatch_get_main_queue(), ^(void){
        [self.PDFExportingView.layer setOpacity:0.0];
        [self.PDFExportingView.layer setTransform:tr];
        [self.PDFExportSucessView.layer setOpacity:1.0];
    });
//    [_PDFExportSucessView.layer setOpacity:1.0];
    
//    [NSAnimationContext runAnimationGroup:^(NSAnimationContext * _Nonnull context) {
//        [[[self PDFExportingView] animator] removeFromSuperview];
//        [[[[self window] contentView] animator] addSubview:self->_PDFExportSucessView];
//    } completionHandler:^{
//        dispatch_time_t delayTime = dispatch_time(DISPATCH_TIME_NOW, 2 * NSEC_PER_SEC);
//        dispatch_after(delayTime, dispatch_get_main_queue(), ^(void){
//            [self close];
//        });
//    }];
}

- (IBAction)openFolder:(NSButton *)sender {
    [[NSWorkspace sharedWorkspace] activateFileViewerSelectingURLs:@[fileURL]];
    [self close];
}

@end
