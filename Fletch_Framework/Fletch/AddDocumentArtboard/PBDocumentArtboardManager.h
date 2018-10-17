//
//  PBDocumentArtboardManager.h
//  Fletch
//
//  Created by PBB on 2018/10/17.
//  Copyright © 2018 pbb. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface PBDocumentArtboardManager : NSObject
- (void) addDocumentArtboardType: (NSString *)type withContext: (NSDictionary *)context MSDocumentClass: (Class)MSDocumentClass;

@end

