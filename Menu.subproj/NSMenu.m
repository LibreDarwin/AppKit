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
#import <AppKit/NSApplication.h>
#import <AppKit/NSEvent.h>
#import <Foundation/NSArray.h>
#import <Foundation/NSCoder.h>
#import <Foundation/NSString.h>
#import <string.h>

/* Equality is spelled textually: the minimal Foundation's NSString exposes
 * -length/-characterAtIndex:/-UTF8String but no -isEqualToString:. Only the
 * declared surface of this project's Foundation is used. */
static BOOL _LDStringsEqual(NSString *left, NSString *right);

@implementation NSMenu {
    NSMenu *_supermenu;
    NSString *_title;
    NSMutableArray *_itemArray;
    BOOL _autoenablesItems;
    id<NSMenuDelegate> _delegate;
    CGFloat _minimumWidth;
    NSFont *_font;
    BOOL _allowsContextMenuPlugIns;
    NSUserInterfaceLayoutDirection _userInterfaceLayoutDirection;
}

+ (void)popUpContextMenu:(NSMenu *)menu withEvent:(NSEvent *)event forView:(NSView *)view {
    /* FIXME(macos): requires window/menu-window machinery. */
}

- (instancetype)initWithTitle:(NSString *)title {
    self = [super init];
    if (self) {
        _title = [title copy];
        _itemArray = [[NSMutableArray alloc] init];
        _autoenablesItems = YES;
        _minimumWidth = 0;
        _allowsContextMenuPlugIns = YES;
        _userInterfaceLayoutDirection = NSUserInterfaceLayoutDirectionLeftToRight;
    }
    return self;
}

- (instancetype)initWithCoder:(NSCoder *)coder {
    self = [self initWithTitle:@""];
    if (self) {
        [self setTitle:[coder decodeObjectForKey:@"title"]];
    }
    return self;
}

- (void)encodeWithCoder:(NSCoder *)coder {
    [coder encodeObject:_title forKey:@"title"];
}

- (id)copyWithZone:(NSZone *)zone {
    NSMenu *copy = [[NSMenu allocWithZone:zone] initWithTitle:_title];
    [copy setAutoenablesItems:_autoenablesItems];
    [copy setMinimumWidth:_minimumWidth];
    [copy setAllowsContextMenuPlugIns:_allowsContextMenuPlugIns];
    [copy setUserInterfaceLayoutDirection:_userInterfaceLayoutDirection];
    [copy setFont:_font];
    NSInteger count = (NSInteger)[_itemArray count];
    for (NSInteger i = 0; i < count; i++) {
        [copy addItem:[[_itemArray objectAtIndex:i] copyWithZone:zone]];
    }
    return copy;
}

- (void)dealloc {
    _delegate = nil;
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
    NSInteger count = (NSInteger)[_itemArray count];
    if (index < 0) {
        index = 0;
    }
    if (index > count) {
        index = count;
    }
    NSMutableArray *rebuilt = [NSMutableArray arrayWithCapacity:count + 1];
    NSInteger i;
    for (i = 0; i < index; i++) {
        [rebuilt addObject:[_itemArray objectAtIndex:i]];
    }
    [rebuilt addObject:newItem];
    for (; i < count; i++) {
        [rebuilt addObject:[_itemArray objectAtIndex:i]];
    }
    [_itemArray removeAllObjects];
    for (i = 0; i < count + 1; i++) {
        [_itemArray addObject:[rebuilt objectAtIndex:i]];
    }
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
    if (index < 0 || index >= (NSInteger)[_itemArray count]) {
        return;
    }
    [[_itemArray objectAtIndex:index] setMenu:nil];
    [_itemArray removeObjectAtIndex:index];
}

- (void)removeItem:(NSMenuItem *)item {
    if (item == nil) {
        return;
    }
    NSInteger count = (NSInteger)[_itemArray count];
    for (NSInteger i = 0; i < count; i++) {
        if ([_itemArray objectAtIndex:i] == item) {
            [item setMenu:nil];
            [_itemArray removeObjectAtIndex:i];
            return;
        }
    }
}

- (void)setSubmenu:(NSMenu *)menu forItem:(NSMenuItem *)item {
    if (item != nil) {
        [item setSubmenu:menu];
    }
}

- (void)removeAllItems {
    NSInteger count = (NSInteger)[_itemArray count];
    for (NSInteger i = 0; i < count; i++) {
        [[_itemArray objectAtIndex:i] setMenu:nil];
    }
    [_itemArray removeAllObjects];
}

- (NSArray<NSMenuItem *> *)itemArray {
    return [_itemArray copy];
}

- (void)setItemArray:(NSArray<NSMenuItem *> *)itemArray {
    [self removeAllItems];
    NSInteger count = (NSInteger)[itemArray count];
    for (NSInteger i = 0; i < count; i++) {
        [self addItem:[itemArray objectAtIndex:i]];
    }
}

- (NSInteger)numberOfItems {
    return (NSInteger)[_itemArray count];
}

- (NSMenuItem *)itemAtIndex:(NSInteger)index {
    if (index < 0 || index >= (NSInteger)[_itemArray count]) {
        return nil;
    }
    return [_itemArray objectAtIndex:index];
}

- (NSInteger)indexOfItem:(NSMenuItem *)item {
    NSInteger count = (NSInteger)[_itemArray count];
    for (NSInteger i = 0; i < count; i++) {
        if ([_itemArray objectAtIndex:i] == item) {
            return i;
        }
    }
    return -1;
}

- (NSInteger)indexOfItemWithTitle:(NSString *)title {
    NSInteger count = (NSInteger)[_itemArray count];
    for (NSInteger i = 0; i < count; i++) {
        NSMenuItem *item = [_itemArray objectAtIndex:i];
        if (_LDStringsEqual([item title], title)) {
            return i;
        }
    }
    return -1;
}

- (NSInteger)indexOfItemWithTag:(NSInteger)tag {
    NSInteger count = (NSInteger)[_itemArray count];
    for (NSInteger i = 0; i < count; i++) {
        if ([[_itemArray objectAtIndex:i] tag] == tag) {
            return i;
        }
    }
    return -1;
}

- (NSInteger)indexOfItemWithRepresentedObject:(id)object {
    /* Compared by identity: the minimal Foundation's correction for isEqual:
     * on arbitrary represented objects is not guaranteed to reach AppKit's
     * behavior, and identity matches how menu clients pair an object they
     * put in with the item they get back. */
    NSInteger count = (NSInteger)[_itemArray count];
    for (NSInteger i = 0; i < count; i++) {
        if ([[_itemArray objectAtIndex:i] representedObject] == object) {
            return i;
        }
    }
    return -1;
}

- (NSInteger)indexOfItemWithSubmenu:(NSMenu *)submenu {
    NSInteger count = (NSInteger)[_itemArray count];
    for (NSInteger i = 0; i < count; i++) {
        if ([[_itemArray objectAtIndex:i] submenu] == submenu) {
            return i;
        }
    }
    return -1;
}

- (NSInteger)indexOfItemWithTarget:(id)target andAction:(SEL)actionSelector {
    NSInteger count = (NSInteger)[_itemArray count];
    for (NSInteger i = 0; i < count; i++) {
        NSMenuItem *item = [_itemArray objectAtIndex:i];
        if ([item target] == target && (actionSelector == NULL || [item action] == actionSelector)) {
            return i;
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
    /* FIXME(macos): key-equivalent matching walks the menu tree and needs
     * modifier-mask handling once key events reach the app loop. */
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
    return 0;
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

static BOOL _LDStringsEqual(NSString *left, NSString *right) {
    if (left == right) {
        return YES;
    }
    if (left == nil || right == nil) {
        return NO;
    }
    return strcmp([left UTF8String], [right UTF8String]) == 0;
}

@end