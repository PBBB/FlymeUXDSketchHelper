//
//  MSDocument.h
//  Fletch
//
//  Created by Issac Penn on 01/14/2018.
//  Copyright © 2018 pbb. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "MSLayerArray.h"
@class MSPage, MSDocumentWindow, MSContentDrawViewController;

@interface MSDocument : NSDocument <NSMenuDelegate, NSToolbarDelegate, NSWindowDelegate>

@property(copy, nonatomic) MSLayerArray *selectedLayers;
@property(retain, nonatomic) MSContentDrawViewController *currentContentViewController;

- (MSDocumentWindow * _Nonnull)window;
- (MSPage * _Nonnull)currentPage;
- (void)showMessage:(NSString *_Nonnull)message;
- (NSArray<MSPage *> *) pages;
- (BOOL)readDocumentFromURL:(NSURL *)url ofType:(NSString *)typeName error:(NSError * _Nullable *)error;

@end
