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

/* NSMenu.h — LibreDarwin reimplementation of Apple's AppKit NSMenu.h. */

#ifndef _NSMENU_H
#define _NSMENU_H

#import <Foundation/NSObject.h>
#import <Foundation/NSArray.h>
#import <Foundation/NSGeometry.h>
#import <AppKit/AppKitDefines.h>
#import <AppKit/NSMenuItem.h>
#import <AppKit/NSUserInterfaceLayout.h>

NS_ASSUME_NONNULL_BEGIN

@class NSEvent, NSView, NSFont, NSScreen;

@protocol NSMenuDelegate;

@interface NSMenu : NSObject <NSCopying, NSCoding>

- (instancetype)initWithTitle:(NSString *)title;
- (instancetype)initWithCoder:(NSCoder *)coder;
- (instancetype)init NS_UNAVAILABLE;

@property (copy) NSString *title;

+ (void)popUpContextMenu:(NSMenu *)menu withEvent:(NSEvent *)event forView:(NSView *)view;

@property (nullable, assign) NSMenu *supermenu;

- (void)insertItem:(NSMenuItem *)newItem atIndex:(NSInteger)index;
- (void)addItem:(NSMenuItem *)newItem;

- (NSMenuItem *)insertItemWithTitle:(NSString *)string action:(nullable SEL)selector keyEquivalent:(NSString *)charCode atIndex:(NSInteger)index;
- (NSMenuItem *)addItemWithTitle:(NSString *)string action:(nullable SEL)selector keyEquivalent:(NSString *)charCode;

- (void)removeItemAtIndex:(NSInteger)index;
- (void)removeItem:(NSMenuItem *)item;
- (void)setSubmenu:(nullable NSMenu *)menu forItem:(NSMenuItem *)item;
- (void)removeAllItems; /* macos(10.6) */

@property (copy) NSArray<NSMenuItem *> *itemArray;
@property (readonly) NSInteger numberOfItems;

- (nullable NSMenuItem *)itemAtIndex:(NSInteger)index;
- (NSInteger)indexOfItem:(NSMenuItem *)item;
- (NSInteger)indexOfItemWithTitle:(NSString *)title;
- (NSInteger)indexOfItemWithTag:(NSInteger)tag;
- (NSInteger)indexOfItemWithRepresentedObject:(nullable id)object;
- (NSInteger)indexOfItemWithSubmenu:(nullable NSMenu *)submenu;
- (NSInteger)indexOfItemWithTarget:(nullable id)target andAction:(nullable SEL)actionSelector;

- (nullable NSMenuItem *)itemWithTitle:(NSString *)title;
- (nullable NSMenuItem *)itemWithTag:(NSInteger)tag;

@property BOOL autoenablesItems;
- (void)update;
- (BOOL)performKeyEquivalent:(NSEvent *)event;
- (void)itemChanged:(NSMenuItem *)item;
- (void)performActionForItemAtIndex:(NSInteger)index;

@property (nullable, weak) id<NSMenuDelegate> delegate;

@property (readonly) CGFloat menuBarHeight;
- (void)cancelTracking; /* macos(10.5) */
- (void)cancelTrackingWithoutAnimation; /* macos(10.6) */
@property (nullable, readonly, strong) NSMenuItem *highlightedItem; /* macos(10.5) */
@property CGFloat minimumWidth; /* macos(10.6) */
@property (readonly) NSSize size; /* macos(10.6) */
@property (null_resettable, strong) NSFont *font; /* macos(10.6) */
@property BOOL allowsContextMenuPlugIns; /* macos(10.6) */
@property NSUserInterfaceLayoutDirection userInterfaceLayoutDirection; /* macos(10.11) */

@end

@interface NSMenu (NSSubmenuAction)
- (void)submenuAction:(nullable id)sender;
@end

@protocol NSMenuDelegate <NSObject>
@optional
- (void)menuNeedsUpdate:(NSMenu *)menu;
- (NSInteger)numberOfItemsInMenu:(NSMenu *)menu;
- (BOOL)menu:(NSMenu *)menu updateItem:(NSMenuItem *)item atIndex:(NSInteger)index shouldCancel:(BOOL)shouldCancel;
- (BOOL)menuHasKeyEquivalent:(NSMenu *)menu forEvent:(NSEvent *)event target:(id _Nullable * _Nonnull)target action:(SEL _Nullable * _Nonnull)action;
- (void)menuWillOpen:(NSMenu *)menu;
- (void)menuDidClose:(NSMenu *)menu;
- (void)menu:(NSMenu *)menu willHighlightItem:(nullable NSMenuItem *)item;
- (NSRect)confinementRectForMenu:(NSMenu *)menu onScreen:(nullable NSScreen *)screen;
@end

NS_ASSUME_NONNULL_END

#endif /* _NSMENU_H */
