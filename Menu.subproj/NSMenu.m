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
#import <AppKit/NSFont.h>
#import <AppKit/NSImage.h>
#import <Foundation/NSArray.h>
#import <Foundation/NSCoder.h>
#import <Foundation/NSString.h>
#import <objc/message.h>
#import <string.h>
#import <strings.h>

/* Equality is spelled textually: the minimal Foundation's NSString exposes
 * -length/-characterAtIndex:/-UTF8String but no -isEqualToString:. Only the
 * declared surface of this project's Foundation is used. */
static BOOL _LDStringsEqual(NSString *left, NSString *right);
static void _LDMenuClearTargets(NSMenu *menu);

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
    BOOL _updating;
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
    /* Apple's documented menu-copy rule: every copied item — including those
     * nested in copied submenus — comes out with a nil target, so a copied
     * menu never performs actions against the original's controller. */
    _LDMenuClearTargets(copy);
    return copy;
}

static void _LDMenuClearTargets(NSMenu *menu) {
    NSInteger count = [menu numberOfItems];
    for (NSInteger i = 0; i < count; i++) {
        NSMenuItem *item = [menu itemAtIndex:i];
        if (item == nil) {
            continue;
        }
        [item setTarget:nil];
        if ([item submenu] != nil) {
            _LDMenuClearTargets([item submenu]);
        }
    }
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
    NSMenu *attachedSubmenu = [newItem submenu];
    if (attachedSubmenu != nil) {
        [attachedSubmenu setSupermenu:self];
    }
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
    NSMenu *attachedSubmenu = [newItem submenu];
    if (attachedSubmenu != nil) {
        [attachedSubmenu setSupermenu:self];
    }
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
    NSMenuItem *item = [_itemArray objectAtIndex:index];
    [item setMenu:nil];
    if ([item submenu] != nil) {
        [[item submenu] setSupermenu:nil];
    }
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
    if (_updating) {
        return;
    }
    _updating = YES;
    if (_autoenablesItems) {
        NSInteger count = (NSInteger)[_itemArray count];
        for (NSInteger i = 0; i < count; i++) {
            NSMenuItem *item = [_itemArray objectAtIndex:i];
            if ([item isSeparatorItem] || [item isSectionHeader]) {
                [item setEnabled:YES];
                continue;
            }
            if ([item hasSubmenu]) {
                /* Submenu owners stay live so the bar can open them; their own
                 * items validate when the submenu itself updates. */
                [item setEnabled:YES];
                continue;
            }
            SEL action = [item action];
            if (action == NULL) {
                [item setEnabled:NO];
                continue;
            }
            if ([[item target] respondsToSelector:action] || [NSApp respondsToSelector:action]) {
                [item setEnabled:YES];
            } else {
                [item setEnabled:NO];
            }
        }
    }
    if (_delegate && [_delegate respondsToSelector:@selector(menuNeedsUpdate:)]) {
        [_delegate menuNeedsUpdate:self];
    }
    _updating = NO;
}

- (BOOL)performKeyEquivalent:(NSEvent *)event {
    /* Only key-command events are routed through the menu bar; any other event
     * type is a no-op, matching Apple's entry check. */
    if ([event type] != NSEventTypeKeyDown) {
        return NO;
    }
    if (_autoenablesItems) {
        [self update];
    }
    return [self _LDPerformKeyEquivalentWithDelegate:event];
}

- (BOOL)_LDPerformKeyEquivalentWithDelegate:(NSEvent *)event {
    /* The delegate gets the first shot at the keystroke, mirroring Apple's
     * -_performKeyEquivalentWithDelegate:. The modern
     * menuHasKeyEquivalent:forEvent:target:action: hands back a target/action
     * pair that we dispatch; a plain YES with no action claims the key, so the
     * menu tree stops looking but performs nothing. */
    id target = nil;
    SEL action = NULL;
    if (_delegate != nil &&
        [_delegate respondsToSelector:@selector(menuHasKeyEquivalent:forEvent:target:action:)]) {
        if ([_delegate menuHasKeyEquivalent:self forEvent:event target:&target action:&action]) {
            if (action != NULL && target != nil) {
                return _LDMenuSendAction(action, target, self);
            }
            return YES;
        }
    }

    NSString *characters = [event charactersIgnoringModifiers];
    if (characters == nil) {
        return NO;
    }

    NSEventModifierFlags flags = [event modifierFlags];

    /* Pass 1: an item that hosts a submenu lets that submenu try first, so a
     * shortcut on a deeper item beats one on the item that owns the submenu.
     * This is what lets menu-bar trees honor a duplicated command. */
    NSInteger count = (NSInteger)[_itemArray count];
    for (NSInteger i = 0; i < count; i++) {
        NSMenuItem *item = [_itemArray objectAtIndex:i];
        if ([item isHidden] || ![item isEnabled]) {
            continue;
        }
        if ([item submenu] != nil &&
            [[item submenu] _LDPerformKeyEquivalentWithDelegate:event]) {
            return YES;
        }
    }

    /* Pass 2: reverse scan, so a later plain item beats an earlier one with
     * the same keystroke. Menu-bar duplicates put the "master" key on the
     * front item and the sourced variant later; AppKit's table prefers the
     * last match, and so do we. */
    for (NSInteger i = count - 1; i >= 0; i--) {
        NSMenuItem *item = [_itemArray objectAtIndex:i];
        NSString *keyEquivalent = [item keyEquivalent];
        if (keyEquivalent == nil || [keyEquivalent length] == 0 ||
            [item isHidden] || ![item isEnabled] || [item hasSubmenu]) {
            continue;
        }

        NSUInteger mask = [item keyEquivalentModifierMask];
        if (mask == 0) {
            /* Init-with-key-equivalent defaults to Command, matching Apple. */
            mask = NSCommandKeyMask;
        }
        if ((flags & mask) != mask) {
            continue;
        }
        if (!_LDMenuKeyEquivalentMatches(characters, keyEquivalent)) {
            continue;
        }

        return _LDMenuExecuteItem(item);
    }
    return NO;
}

/* Key equivalents are single characters. Compare the event's (modifier-free)
 * character against the item's key-equivalent string case-insensitively, like
 * the system kit does; key equivalents are ASCII in practice, so a byte-wise
 * comparison is exact. */
/* Compare the event's (modifier-free) character against the item's
 * key-equivalent string case-insensitively, like the system kit does; key
 * equivalents are ASCII in practice, so a byte-wise comparison is exact. */
static BOOL _LDMenuKeyEquivalentMatches(NSString *characters, NSString *keyEquivalent) {
    return strcasecmp([characters UTF8String], [keyEquivalent UTF8String]) == 0;
}

/* Dispatch to an arbitrary target/action pair, falling back to the
 * application unless the target already carries the selector. Returns whether
 * someone actually performed it. */
static BOOL _LDMenuSendAction(SEL action, id target, id sender) {
    if (action == NULL) {
        return NO;
    }
    /* objc_msgSend with a typed cast avoids the ARC unknown-selector leak
     * warning; the receiver is always an object. */
    void (*sendAction)(id, SEL, id) = (void (*)(id, SEL, id))objc_msgSend;
    if (target != nil && [target respondsToSelector:action]) {
        sendAction(target, action, sender);
        return YES;
    }
    if ([NSApp respondsToSelector:action]) {
        sendAction(NSApp, action, sender);
        return YES;
    }
    return NO;
}

static BOOL _LDMenuExecuteItem(NSMenuItem *item) {
    return _LDMenuSendAction([item action], [item target], item);
}

- (void)itemChanged:(NSMenuItem *)item {
    /* An item's appearance can flip its validity; re-run autoenabling rather
     * than trusting a stale enabled state. update's re-entry guard means menu
     * edits from menuNeedsUpdate: will not re-trigger a pass. */
    if (_autoenablesItems) {
        [self update];
    }
}

- (void)performActionForItemAtIndex:(NSInteger)index {
    NSMenuItem *item = [self itemAtIndex:index];
    if (item != nil) {
        _LDMenuExecuteItem(item);
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

static CGFloat _LDEstimatedTextWidth(NSString *text, NSFont *font) {
    if (text == nil || [text length] == 0) {
        return 0;
    }
    return (CGFloat)[text length] * [font pointSize] * 0.5;
}

- (NSSize)size {
    NSFont *font = [self font];
    CGFloat lineHeight = [font ascender] - [font descender];
    CGFloat itemHeight = ceil(lineHeight) + 12;
    CGFloat width = 0;
    CGFloat height = 0;

    NSInteger count = (NSInteger)[_itemArray count];
    for (NSInteger i = 0; i < count; i++) {
        NSMenuItem *item = [_itemArray objectAtIndex:i];
        if ([item isSeparatorItem]) {
            height += 9;
            continue;
        }
        CGFloat itemWidth = (CGFloat)[item indentationLevel] * 14;
        itemWidth += _LDEstimatedTextWidth([item title], font) + 24;
        NSImage *image = [item image];
        if (image != nil) {
            itemWidth += [image size].width + 8;
        }
        NSString *keyEquivalent = [item keyEquivalent];
        if (keyEquivalent != nil && [keyEquivalent length] > 0) {
            itemWidth += _LDEstimatedTextWidth(keyEquivalent, font) + 32;
        }
        if ([item hasSubmenu]) {
            itemWidth += 16;
        }
        if (itemWidth > width) {
            width = itemWidth;
        }
        height += itemHeight;
    }
    if (_minimumWidth > 0 && width < _minimumWidth) {
        width = _minimumWidth;
    }
    return NSMakeSize(ceil(width), ceil(height));
}

- (NSFont *)font {
    /* null_resettable: a cleared font falls back to the system font rather
     * than nil, so menus always have a real face to lay out against. */
    return _font != nil ? _font : [NSFont systemFontOfSize:[NSFont systemFontSize]];
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