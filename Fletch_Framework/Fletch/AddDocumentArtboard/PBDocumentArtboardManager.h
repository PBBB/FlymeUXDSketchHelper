//
//  PBDocumentArtboardManager.h
//  Fletch
//
//  Created by PBB on 2018/10/17.
//  Copyright © 2018 pbb. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "PBDocumentArtboardManagerDelegate.h"

@interface PBDocumentArtboardManager : NSObject
@property(nonatomic, retain) PBDocumentArtboardManagerDelegate *delegate;

- (void) addDocumentArtboardType: (NSString *)type withContext: (NSDictionary *)context MSDocumentClass: (Class)MSDocumentClass;

@end

