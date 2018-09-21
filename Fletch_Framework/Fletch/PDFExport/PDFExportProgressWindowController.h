//
//  PDFExportProgressWindowController.h
//  Fletch
//
//  Created by pbb on 2018/4/3.
//  Copyright © 2018年 pbb. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface PDFExportProgressWindowController : NSWindowController
@property (weak) IBOutlet NSProgressIndicator *pdfExportProgressIndicator;
@property (weak) IBOutlet NSTextField *exportLabel;
@property (weak) IBOutlet NSView *PDFExportingView;
@property (weak) IBOutlet NSView *PDFExportSucessView;
@property (nonatomic, retain) NSURL *fileURL;

- (void)changeToSuccessViewWithFileURL: (NSURL *)fileURL;
- (void)showSuccessViewWithFileURL: (NSURL *)fileURL;
- (IBAction)openFolder:(NSButton *)sender;
@end


