//
//  PBToolbarWindowController.h
//  Fletch
//
//  Created by Issac Penn on 06/13/2018.
//  Copyright © 2018 pbb. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "PBToolbarDelegate.h"

@interface PBToolbarWindowController : NSWindowController <NSToolbarDelegate>
@property (nonatomic, retain) PBToolbarDelegate *delegate;
@property (nonatomic, retain) NSToolbar *toolbar;
- (void)runToolbarCommand:(NSToolbarItem *)sender;
@end
