//
//  PBToolbarHelper.h
//  Fletch
//
//  Created by pbb on 2018/7/6.
//  Copyright © 2018年 pbb. All rights reserved.
//

#import <Foundation/Foundation.h>
//#import "PBToolbar.h"
#import "PBToolbarWindowController.h"
#import "PBToolbarDelegate.h"

@interface PBToolbarHelper : NSObject

@property (nonatomic, retain, readonly) PBToolbarWindowController *toolbarWC;
@property (nonatomic, retain) PBToolbarDelegate *delegate;
//@property (nonatomic, retain, readonly) NSDictionary<NSString *, NSDictionary<NSString *, NSString *> *> *toolbarInfo;
@property (nonatomic, retain, readonly) NSMutableArray<NSDictionary<NSString *, NSString *> *> *toolbarCommands;
@property (nonatomic, retain, readonly) NSMutableArray<NSDictionary<NSString *, NSString *> *> *toolbarSecondaryCommands;

- (void)showToolbar: (NSDictionary *)context;
-(NSArray<NSToolbarItemIdentifier> *) defaultToolbarItemIdentifiers;
-(NSArray<NSToolbarItemIdentifier> *) allowedToolbarItemIdentifiers;
- (NSString *) commandNameOfIdentifier: (NSToolbarItemIdentifier) identifier requireFullName: (BOOL) fullName;
- (NSString *) commandIdentifierOfIdentifier: (NSToolbarItemIdentifier) identifier;
- (NSString *) commandImagePathOfIdentifier: (NSToolbarItemIdentifier) identifier;
- (NSArray<NSString *>*) secondaryCommandsIdentifierOfIdentifier: (NSToolbarItemIdentifier) identifier;


@end

