//
//  PBCatalogUpdater.h
//  Fletch
//
//  Created by pbb on 2018/7/11.
//  Copyright © 2018年 pbb. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "PBCatalogUpdaterDelegate.h"
#import "MSArtboardGroup.h"
#import "MSDocument.h"
#import "MSPage.h"
#import "MSRect.h"
#import "MSDocumentWindow.h"
#import "MSTextLayer.h"
#import "MSSymbolInstance.h"


@interface PBCatalogUpdater : NSObject
@property(nonatomic, retain) PBCatalogUpdaterDelegate *delegate;

- (void) updateCatalogWithContext: (NSDictionary *)context MSArtboardGroupClass: (Class)MSArtboardGroupClass MSSymbolInstanceClass: (Class)MSSymbolInstanceClass;
@end
