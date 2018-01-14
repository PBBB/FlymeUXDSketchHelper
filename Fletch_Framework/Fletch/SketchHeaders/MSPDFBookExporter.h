//
//  MSPDFBookExporter.h
//  Fletch
//
//  Created by Issac Penn on 01/14/2018.
//  Copyright © 2018 pbb. All rights reserved.
//

@class PDFPage, MSArtboardGroup;

@interface MSPDFBookExporter : NSObject

+ (PDFPage *)pdfFromArtboard:(MSArtboardGroup *)artboard;

@end
