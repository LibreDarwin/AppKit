/*
 * Copyright (C) 2026, LibreDarwin.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions are met:
 *
 * 1. Redistributions of source code must retain the above copyright notice,
 *    this list of conditions and the following disclaimer.
 * 2. Redistributions in binary form must reproduce the above copyright notice,
 *    this list of conditions and the following disclaimer in the documentation
 *    and/or other materials provided with the distribution.
 * 3. Neither the name of the copyright holder nor the names of its
 *    contributors may be used to endorse or promote products derived from
 *    this software without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
 * AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
 * IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
 * ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE
 * LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
 * CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
 * SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
 * INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
 * CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
 * ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
 * POSSIBILITY OF SUCH DAMAGE.
 */

/* NSMenuItem.h — LibreDarwin reimplementation of Apple's AppKit NSMenuItem.h. */

#ifndef _NSMENUITEM_H
#define _NSMENUITEM_H

#import <Foundation/NSObject.h>
#import <AppKit/AppKitDefines.h>
#import <AppKit/NSUserInterfaceValidation.h>

@class NSMenu, NSImage, NSAttributedString;

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSInteger, NSControlStateValue) {
    NSControlStateValueMixed = -1,
    NSControlStateValueOff   = 0,
    NSControlStateValueOn    = 1,
};

@interface NSMenuItem : NSObject <NSCopying, NSValidatedUserInterfaceItem>

+ (NSMenuItem *)separatorItem;

- (instancetype)initWithTitle:(NSString *)title action:(nullable SEL)action keyEquivalent:(NSString *)keyEquivalent;
- (instancetype)init NS_UNAVAILABLE;

@property (nullable, assign) NSMenu *menu;

@property (readonly) BOOL hasSubmenu;
@property (nullable, strong) NSMenu *submenu;
@property (nullable, readonly, assign) NSMenuItem *parentItem; /* macos(10.6) */

@property (copy) NSString *title;
@property (nullable, copy) NSAttributedString *attributedTitle;
@property (copy, nullable) NSString *subtitle; /* macos(14.4) */

@property (getter=isSeparatorItem, readonly) BOOL separatorItem;
@property (getter=isSectionHeader, readonly) BOOL sectionHeader; /* macos(14.0) */

@property (copy) NSString *keyEquivalent;
@property (assign) NSUInteger keyEquivalentModifierMask;

@property (nullable, strong) NSImage *image;

@property (assign) NSControlStateValue state;
@property (null_resettable, strong) NSImage *onStateImage;
@property (nullable, strong) NSImage *offStateImage;
@property (null_resettable, strong) NSImage *mixedStateImage;

@property (getter=isEnabled) BOOL enabled;
@property (getter=isAlternate) BOOL alternate;

@property (assign) NSInteger indentationLevel;

@property (nullable, weak) id target;
@property (nullable) SEL action;

@property (assign) NSInteger tag;

@property (nullable, strong) id representedObject;

@property (getter=isHidden) BOOL hidden;
@property (getter=isHiddenOrHasHiddenAncestor, readonly) BOOL hiddenOrHasHiddenAncestor; /* macos(10.5) */

@property (nullable, copy) NSString *toolTip;

@end

NS_ASSUME_NONNULL_END

#endif /* _NSMENUITEM_H */
