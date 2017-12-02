//
//  ShowHideUIFrameWindowController.m
//  Fletch
//
//  Created by Issac Penn on 2017/11/23.
//  Copyright © 2017年 pbb. All rights reserved.
//

#import "ShowHideUIFrameWindowController.h"

@interface ShowHideUIFrameWindowController ()
#define PBLog(fmt, ...) NSLog((@"Fletch (Sketch Plugin) %s [Line %d] " fmt), __PRETTY_FUNCTION__, __LINE__, ##__VA_ARGS__);
@end

@implementation ShowHideUIFrameWindowController
@synthesize delegate;
- (IBAction)finishOperation:(NSButton *)sender {
    [delegate didClickFinishOperationInWindowController:self];
}

- (void)windowDidLoad {
    [super windowDidLoad];
    
//    [[self window] setBackgroundColor:NSColor.whiteColor];
    [[self window] setMovableByWindowBackground:YES];
    [[[self window] standardWindowButton:NSWindowMiniaturizeButton] setHidden:YES];
    [[[self window] standardWindowButton:NSWindowZoomButton] setHidden:YES];
}

-(void)shakeWindow {
    static int numberOfShakes = 3;
    static float durationOfShake = 0.5f;
    static float vigourOfShake = 0.05f;
    
    CGRect frame=[self.window frame];
    CAKeyframeAnimation *shakeAnimation = [CAKeyframeAnimation animation];
    
    CGMutablePathRef shakePath = CGPathCreateMutable();
    CGPathMoveToPoint(shakePath, NULL, NSMinX(frame), NSMinY(frame));
    for (NSInteger index = 0; index < numberOfShakes; index++){
        CGPathAddLineToPoint(shakePath, NULL, NSMinX(frame) - frame.size.width * vigourOfShake, NSMinY(frame));
        CGPathAddLineToPoint(shakePath, NULL, NSMinX(frame) + frame.size.width * vigourOfShake, NSMinY(frame));
    }
    CGPathCloseSubpath(shakePath);
    shakeAnimation.path = shakePath;
    shakeAnimation.duration = durationOfShake;
    
    [self.window setAnimations:[NSDictionary dictionaryWithObject: shakeAnimation forKey:@"frameOrigin"]];
    [[self.window animator] setFrameOrigin:[self.window frame].origin];
}

-(void) handleSelectedLayer:(__autoreleasing id *)layer {
    [delegate didSelectLayer:layer];
}

@end
