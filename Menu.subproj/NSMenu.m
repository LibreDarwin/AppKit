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

#import <AppKit/NSMenu.h>
#import <AppKit/NSMenuItem.h>
#import <AppKit/NSApplication.h>
#import <AppKit/NSEvent.h>
#import <Foundation/NSArray.h>
#import <Foundation/NSString.h>

@implementation NSMenu {
    NSMenu *_supermenu;
    NSString *_title;
    NSMutableArray *_itemArray;
    BOOL _autoenablesItems;
    id<NSMenuDelegate> _delegate;
    CGFloat _minimumWidth;
    CGFloat _menuBarHeight;
    NSFont *_font;
    BOOL _allowsContextMenuPlugIns;
    NSUserInterfaceLayoutDirection _userInterfaceLayoutDirection;
}

+ (void)popUpContextMenu:(NSMenu *)menu withEvent:(NSEvent *)event forView:(NSView *)view {
    /* FIXME(macos): requires window/menu window implementation */
}

- (instancetype)initWithTitle:(NSString *)title {
    self = [super init];
    if (self) {
        _title = [title copy];
        _itemArray = [[NSMutableArray alloc] init];
        _autoenablesItems = YES;
        _minimumWidth = 0;
        _menuBarHeight = 0;
        _allowsContextMenuPlugIns = YES;
        _userInterfaceLayoutDirection = NSUserInterfaceLayoutDirectionLeftToRight;
    }
    return self;
}

- (instancetype)initWithCoder:(NSCoder *)coder {
    return [self initWithTitle:@""];
}

- (void)dealloc {
    _supermenu = nil;
    _delegate = nil;
}

- (id)copyWithZone:(NSZone *)zone {
    NSMenu *copy = [[NSMenu allocWithZone:zone] initWithTitle:_title];
    copy.autoenablesItems = _autoenablesItems;
    copy.minimumWidth = _minimumWidth;
    copy.allowsContextMenuPlugIns = _allowsContextMenuPlugIns;
    copy.userInterfaceLayoutDirection = _userInterfaceLayoutDirection;
    copy.font = _font;
    for (NSMenuItem *item in _itemArray) {
        [copy addItem:[item copyWithZone:zone]];
    }
    return copy;
}

- (NSString *)title {
    return _title;
}

- (void)setTitle:(NSString *)title {
    _title = [title copy];
}

- (NSMenu *)supermenu {
    return _supermenu;
}

- (void)setSupermenu:(NSMenu *)supermenu {
    _supermenu = supermenu;
}

- (void)insertItem:(NSMenuItem *)newItem atIndex:(NSInteger)index {
    if (newItem == nil) {
        return;
    }
    [newItem setMenu:self];
    if (index < 0) {
        index = 0;
    }
    if (index > [_itemArray count]) {
        index = [_itemArray count];
    }
    [_itemArray insertObject:newItem atIndex:index];
}

- (void)addItem:(NSMenuItem *)newItem {
    if (newItem == nil) {
        return;
    }
    [newItem setMenu:self];
    [_itemArray addObject:newItem];
}

- (NSMenuItem *)insertItemWithTitle:(NSString *)string action:(SEL)selector keyEquivalent:(NSString *)charCode atIndex:(NSInteger)index {
    NSMenuItem *item = [[NSMenuItem alloc] initWithTitle:string action:selector keyEquivalent:charCode];
    [self insertItem:item atIndex:index];
    return item;
}

- (NSMenuItem *)addItemWithTitle:(NSString *)string action:(SEL)selector keyEquivalent:(NSString *)charCode {
    NSMenuItem *item = [[NSMenuItem alloc] initWithTitle:string action:selector keyEquivalent:charCode];
    [self addItem:item];
    return item;
}

- (void)removeItemAtIndex:(NSInteger)index {
    if (index < 0 || index >= [_itemArray count]) {
        return;
    }
    NSMenuItem *item = [_itemArray objectAtIndex:index];
    [item setMenu:nil];
    [_itemArray removeObjectAtIndex:index];
}

- (void)removeItem:(NSMenuItem *)item {
    if (item == nil) {
        return;
    }
    NSUInteger idx = [_itemArray indexOfObjectIdenticalTo:item];
    if (idx != NSNotFound) {
        [self removeItemAtIndex:(NSInteger)idx];
    }
}

- (void)setSubmenu:(NSMenu *)menu forItem:(NSMenuItem *)item {
    if (item != nil) {
        [item setSubmenu:menu];
    }
}

- (void)removeAllItems {
    for (NSMenuItem *item in [_itemArray copy]) {
        [item setMenu:nil];
    }
    [_itemArray removeAllObjects];
}

- (NSArray<NSMenuItem *> *)itemArray {
    return [_itemArray copy];
}

- (void)setItemArray:(NSArray<NSMenuItem *> *)itemArray {
    [_itemArray removeAllObjects];
    if (itemArray != nil) {
        for (NSMenuItem *item in itemArray) {
            [self addItem:item];
        }
    }
}

- (NSInteger)numberOfItems {
    return [_itemArray count];
}

- (NSMenuItem *)itemAtIndex:(NSInteger)index {
    if (index < 0 || index >= [_itemArray count]) {
        return nil;
    }
    return [_itemArray objectAtIndex:index];
}

- (NSInteger)indexOfItem:(NSMenuItem *)item {
    return (NSInteger)[_itemArray indexOfObjectIdenticalTo:item];
}

- (NSInteger)indexOfItemWithTitle:(NSString *)title {
    for (NSUInteger i = 0; i < [_itemArray count]; i++) {
        NSMenuItem *item = [_itemArray objectAtIndex:i];
        if ([[item title] isEqualToString:title]) {
            return (NSInteger)i;
        }
    }
    return -1;
}

- (NSInteger)indexOfItemWithTag:(NSInteger)tag {
    for (NSUInteger i = 0; i < [_itemArray count]; i++) {
        NSMenuItem *item = [_itemArray objectAtIndex:i];
        if ([item tag] == tag) {
            return (NSInteger)i;
        }
    }
    return -1;
}

- (NSInteger)indexOfItemWithRepresentedObject:(id)object {
    for (NSUInteger i = 0; i < [_itemArray count]; i++) {
        NSMenuItem *item = [_itemArray objectAtIndex:i];
        if ([[item representedObject] isEqual:object]) {
            return (NSInteger)i;
        }
    }
    return -1;
}

- (NSInteger)indexOfItemWithSubmenu:(NSMenu *)submenu {
    for (NSUInteger i = 0; i < [_itemArray count]; i++) {
        NSMenuItem *item = [_itemArray objectAtIndex:i];
        if ([item submenu] == submenu) {
            return (NSInteger)i;
        }
    }
    return -1;
}

- (NSInteger)indexOfItemWithTarget:(id)target andAction:(SEL)actionSelector {
    for (NSUInteger i = 0; i < [_itemArray count]; i++) {
        NSMenuItem *item = [_itemArray objectAtIndex:i];
        if ([item target] == target) {
            if (actionSelector == NULL || [item action] == actionSelector) {
                return (NSInteger)i;
            }
        }
    }
    return -1;
}

- (NSMenuItem *)itemWithTitle:(NSString *)title {
    NSInteger idx = [self indexOfItemWithTitle:title];
    return idx >= 0 ? [self itemAtIndex:idx] : nil;
}

- (NSMenuItem *)itemWithTag:(NSInteger)tag {
    NSInteger idx = [self indexOfItemWithTag:tag];
    return idx >= 0 ? [self itemAtIndex:idx] : nil;
}

- (BOOL)autoenablesItems {
    return _autoenablesItems;
}

- (void)setAutoenablesItems:(BOOL)autoenablesItems {
    _autoenablesItems = autoenablesItems;
}

- (void)update {
    if (_delegate && [_delegate respondsToSelector:@selector(menuNeedsUpdate:)]) {
        [_delegate menuNeedsUpdate:self];
    }
}

- (BOOL)performKeyEquivalent:(NSEvent *)event {
    return NO;
}

- (void)itemChanged:(NSMenuItem *)item {
}

- (void)performActionForItemAtIndex:(NSInteger)index {
    NSMenuItem *item = [self itemAtIndex:index];
    if (item == nil) {
        return;
    }
    SEL action = [item action];
    id target = [item target];
    if (action != NULL) {
        if (target != nil && [target respondsToSelector:action]) {
            [target performSelector:action withObject:item];
        } else if ([NSApp respondsToSelector:action]) {
            [NSApp performSelector:action withObject:item];
        }
    }
}

- (id<NSMenuDelegate>)delegate {
    return _delegate;
}

- (void)setDelegate:(id<NSMenuDelegate>)delegate {
    _delegate = delegate;
}

- (CGFloat)menuBarHeight {
    return _menuBarHeight;
}

- (void)cancelTracking {
}

- (void)cancelTrackingWithoutAnimation {
}

- (NSMenuItem *)highlightedItem {
    return nil;
}

- (CGFloat)minimumWidth {
    return _minimumWidth;
}

- (void)setMinimumWidth:(CGFloat)minimumWidth {
    _minimumWidth = minimumWidth;
}

- (NSSize)size {
    return NSMakeSize(0, 0);
}

- (NSFont *)font {
    return _font;
}

- (void)setFont:(NSFont *)font {
    _font = font;
}

- (BOOL)allowsContextMenuPlugIns {
    return _allowsContextMenuPlugIns;
}

- (void)setAllowsContextMenuPlugIns:(BOOL)allowsContextMenuPlugIns {
    _allowsContextMenuPlugIns = allowsContextMenuPlugIns;
}

- (NSUserInterfaceLayoutDirection)userInterfaceLayoutDirection {
    return _userInterfaceLayoutDirection;
}

- (void)setUserInterfaceLayoutDirection:(NSUserInterfaceLayoutDirection)userInterfaceLayoutDirection {
    _userInterfaceLayoutDirection = userInterfaceLayoutDirection;
}

- (void)submenuAction:(id)sender {
}

@end
