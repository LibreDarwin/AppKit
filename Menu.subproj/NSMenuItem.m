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

#import <AppKit/NSMenuItem.h>
#import <AppKit/NSMenu.h>
#import <Foundation/NSAttributedString.h>
#import <Foundation/NSString.h>

@implementation NSMenuItem {
    NSMenu *_menu;
    NSString *_title;
    NSAttributedString *_attributedTitle;
    NSString *_subtitle;
    id _target;
    SEL _action;
    NSString *_keyEquivalent;
    NSUInteger _keyEquivalentModifierMask;
    NSMenu *_submenu;
    NSInteger _tag;
    NSInteger _indentationLevel;
    BOOL _enabled;
    BOOL _hidden;
    NSControlStateValue _state;
    id _representedObject;
    NSImage *_image;
    NSImage *_onStateImage;
    NSImage *_offStateImage;
    NSImage *_mixedStateImage;
    BOOL _alternate;
    BOOL _sectionHeader;
}

+ (NSMenuItem *)separatorItem {
    NSMenuItem *item = [[NSMenuItem alloc] initWithTitle:@"" action:NULL keyEquivalent:@""];
    item->_title = nil;
    return item;
}

+ (instancetype)sectionHeaderWithTitle:(NSString *)title {
    NSMenuItem *item = [[NSMenuItem alloc] initWithTitle:title action:NULL keyEquivalent:@""];
    item->_sectionHeader = YES;
    return item;
}

- (instancetype)initWithTitle:(NSString *)title action:(SEL)action keyEquivalent:(NSString *)keyEquivalent {
    self = [super init];
    if (self) {
        _title = [title copy];
        _action = action;
        _keyEquivalent = [keyEquivalent copy];
        _keyEquivalentModifierMask = 0;
        _enabled = YES;
        _hidden = NO;
        _state = NSControlStateValueOff;
        _indentationLevel = 0;
        _tag = -1;
    }
    return self;
}

- (void)dealloc {
    _target = nil;
}

- (NSMenu *)menu {
    return _menu;
}

- (void)setMenu:(NSMenu *)menu {
    _menu = menu;
}

- (BOOL)hasSubmenu {
    return _submenu != nil;
}

- (NSMenu *)submenu {
    return _submenu;
}

- (void)setSubmenu:(NSMenu *)submenu {
    if (_submenu != submenu) {
        if (_submenu != nil) {
            [_submenu setSupermenu:nil];
        }
        _submenu = submenu;
        if (_submenu != nil) {
            [_submenu setSupermenu:_menu];
        }
    }
}

- (NSMenuItem *)parentItem {
    return nil;
}

- (NSString *)title {
    return _title;
}

- (void)setTitle:(NSString *)title {
    _title = [title copy];
    if (_menu != nil) {
        [_menu itemChanged:self];
    }
}

- (NSAttributedString *)attributedTitle {
    return _attributedTitle;
}

- (void)setAttributedTitle:(NSAttributedString *)attributedTitle {
    _attributedTitle = [attributedTitle copy];
}

- (NSString *)subtitle {
    return _subtitle;
}

- (void)setSubtitle:(NSString *)subtitle {
    _subtitle = [subtitle copy];
}

- (BOOL)isSeparatorItem {
    return _title == nil;
}

- (BOOL)isSectionHeader {
    return _sectionHeader;
}

- (NSString *)keyEquivalent {
    return _keyEquivalent;
}

- (void)setKeyEquivalent:(NSString *)keyEquivalent {
    _keyEquivalent = [keyEquivalent copy];
}

- (NSUInteger)keyEquivalentModifierMask {
    return _keyEquivalentModifierMask;
}

- (void)setKeyEquivalentModifierMask:(NSUInteger)keyEquivalentModifierMask {
    _keyEquivalentModifierMask = keyEquivalentModifierMask;
}

- (NSImage *)image {
    return _image;
}

- (void)setImage:(NSImage *)image {
    _image = image;
    if (_menu != nil) {
        [_menu itemChanged:self];
    }
}

- (NSControlStateValue)state {
    return _state;
}

- (void)setState:(NSControlStateValue)state {
    _state = state;
}

- (NSImage *)onStateImage {
    return _onStateImage;
}

- (void)setOnStateImage:(NSImage *)onStateImage {
    _onStateImage = onStateImage;
}

- (NSImage *)offStateImage {
    return _offStateImage;
}

- (void)setOffStateImage:(NSImage *)offStateImage {
    _offStateImage = offStateImage;
}

- (NSImage *)mixedStateImage {
    return _mixedStateImage;
}

- (void)setMixedStateImage:(NSImage *)mixedStateImage {
    _mixedStateImage = mixedStateImage;
}

- (BOOL)isEnabled {
    return _enabled;
}

- (void)setEnabled:(BOOL)enabled {
    _enabled = enabled;
}

- (BOOL)isAlternate {
    return _alternate;
}

- (void)setAlternate:(BOOL)alternate {
    _alternate = alternate;
}

- (NSInteger)indentationLevel {
    return _indentationLevel;
}

- (void)setIndentationLevel:(NSInteger)indentationLevel {
    _indentationLevel = indentationLevel;
}

- (id)target {
    return _target;
}

- (void)setTarget:(id)target {
    _target = target;
}

- (SEL)action {
    return _action;
}

- (void)setAction:(SEL)action {
    _action = action;
}

- (NSInteger)tag {
    return _tag;
}

- (void)setTag:(NSInteger)tag {
    _tag = tag;
}

- (id)representedObject {
    return _representedObject;
}

- (void)setRepresentedObject:(id)representedObject {
    _representedObject = representedObject;
}

- (BOOL)isHidden {
    return _hidden;
}

- (void)setHidden:(BOOL)hidden {
    _hidden = hidden;
}

- (BOOL)isHiddenOrHasHiddenAncestor {
    return _hidden;
}

- (NSString *)toolTip {
    return nil;
}

- (void)setToolTip:(NSString *)toolTip {
}

- (id)copyWithZone:(NSZone *)zone {
    NSMenuItem *copy = [[NSMenuItem allocWithZone:zone] initWithTitle:_title ? _title : @"" action:_action keyEquivalent:_keyEquivalent];
    copy->_title = _title ? [_title copy] : nil;
    copy.attributedTitle = _attributedTitle;
    copy.subtitle = _subtitle;
    copy.keyEquivalentModifierMask = _keyEquivalentModifierMask;
    copy.image = _image;
    copy.state = _state;
    copy.onStateImage = _onStateImage;
    copy.offStateImage = _offStateImage;
    copy.mixedStateImage = _mixedStateImage;
    copy.enabled = _enabled;
    copy.indentationLevel = _indentationLevel;
    copy.target = _target;
    copy.tag = _tag;
    copy.representedObject = _representedObject;
    copy.hidden = _hidden;
    copy->_alternate = _alternate;
    copy->_sectionHeader = _sectionHeader;
    if (_submenu != nil) {
        copy.submenu = [_submenu copy];
    }
    return copy;
}

@end
