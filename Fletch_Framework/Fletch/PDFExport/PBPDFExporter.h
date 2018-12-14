//
//  PBPDFExporter.h
//  Fletch
//
//  Created by Issac Penn on 01/13/2018.
//  Copyright © 2018 pbb. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "PDFExportDelegate.h"
#import <UserNotifications/UserNotifications.h>

@class MSArtboardGroup, MSDocumentWindow;

@interface PBPDFExporter : NSObject <UNUserNotificationCenterDelegate>

@property (nonatomic, retain) PDFExportDelegate *delegate;
@property (weak) MSDocumentWindow *documentWindow;

- (void)exportPDF: (NSDictionary *)context withPDFExporterClass: (Class)MSPDFBookExporterClass
                    TextLayerClass: (Class)MSTextLayerClass
                    ArtboardGroupClass: (Class)MSArtboardGroupClass;
@end

