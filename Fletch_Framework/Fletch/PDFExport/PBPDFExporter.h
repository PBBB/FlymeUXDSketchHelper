//
//  PBPDFExporter.h
//  Fletch
//
//  Created by Issac Penn on 01/13/2018.
//  Copyright © 2018 pbb. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface PBPDFExporter : NSObject

- (void)exportPDF: (NSDictionary *)context;
@end
