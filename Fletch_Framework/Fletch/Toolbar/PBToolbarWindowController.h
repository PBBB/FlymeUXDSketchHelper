//
//  PBToolbarWindowController.h
//  Fletch
//
//  Created by Issac Penn on 06/13/2018.
//  Copyright © 2018 pbb. All rights reserved.
//

#import <Cocoa/Cocoa.h>
@class PBToolbarHelper;

@interface PBToolbarWindowController : NSWindowController <NSWindowDelegate, NSToolbarDelegate>
@property (weak) PBToolbarHelper *helper;
@property (nonatomic, retain) NSToolbar *toolbar;
@property (weak) IBOutlet NSView *backgroudView;
- (void)runToolbarCommand:(NSToolbarItem *)sender;
- (void)shakeWindow;
@end
