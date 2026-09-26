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

/* NSWindow.m — LibreDarwin reimplementation of AppKit's NSWindow.
 *
 * Headless core of the window subsystem: creation from a content rect,
 * frame/content geometry (including the title-bar math), content-view
 * hosting via the LBSViewPrivate hook, onscreen visibility flags, key/main
 * state transitions wired to NSApplication's registry through the
 * LBSWindowPrivate category, first-responder assignment, miniaturization
 * state, closing, and event dispatch into the responder chain. No
 * window-server connection, ordering, or backing surfaces yet — the display
 * subsystem owns those, and the ordering methods only track an onscreen
 * flag. The key/main transition pair follows Apple's contract: becoming key
 * or main resigns the previous holder, resigning clears the application's
 * pointer and posts the notification pair around each change.
 *
 * Written against the minimal LibreDarwin Foundation NSArray/NSGeometry
 * surface: no fast enumeration, no reverse enumerators. */

#import <Foundation/NSGeometry.h>
#import <Foundation/NSNotification.h>
#import <Foundation/NSNotificationCenter.h>
#import <Foundation/NSString.h>
#import <AppKit/NSWindow.h>
#import <AppKit/NSApplication.h>
#import <AppKit/NSApplication_Private.h>
#import <AppKit/NSEvent.h>
#import <AppKit/NSView_Private.h>

NSNotificationName NSWindowWillCloseNotification = @"NSWindowWillCloseNotification";
NSNotificationName NSWindowDidResignKeyNotification = @"NSWindowDidResignKeyNotification";
NSNotificationName NSWindowDidBecomeKeyNotification = @"NSWindowDidBecomeKeyNotification";
NSNotificationName NSWindowDidResignMainNotification = @"NSWindowDidResignMainNotification";
NSNotificationName NSWindowDidBecomeMainNotification = @"NSWindowDidBecomeMainNotification";
NSNotificationName NSWindowWillMiniaturizeNotification = @"NSWindowWillMiniaturizeNotification";
NSNotificationName NSWindowDidMiniaturizeNotification = @"NSWindowDidMiniaturizeNotification";
NSNotificationName NSWindowWillDeminiaturizeNotification = @"NSWindowWillDeminiaturizeNotification";
NSNotificationName NSWindowDidDeminiaturizeNotification = @"NSWindowDidDeminiaturizeNotification";
NSNotificationName NSWindowWillMoveNotification = @"NSWindowWillMoveNotification";
NSNotificationName NSWindowDidMoveNotification = @"NSWindowDidMoveNotification";
NSNotificationName NSWindowDidResizeNotification = @"NSWindowDidResizeNotification";
NSNotificationName NSWindowDidExposeNotification = @"NSWindowDidExposeNotification";

/* Height of the title bar added above the content area for titled windows.
 * The display subsystem will refine this with real metrics. */
static const CGFloat LBSTitleBarHeight = 28.0;

/* Monotonic window numbers, starting at 1 like the window server's. */
static NSInteger LBSWindowNumberSequence = 0;

/* Maps an NSEventType to the responder method NSWindow dispatches. Mirrors
 * NSApplication's own table; the window routes the same families to its
 * first responder. */
static SEL LBSWindowActionForEventType(NSEventType type)
{
    switch (type) {
        case NSEventTypeLeftMouseDown:      return @selector(mouseDown:);
        case NSEventTypeLeftMouseUp:        return @selector(mouseUp:);
        case NSEventTypeRightMouseDown:     return @selector(rightMouseDown:);
        case NSEventTypeRightMouseUp:       return @selector(rightMouseUp:);
        case NSEventTypeMouseMoved:         return @selector(mouseMoved:);
        case NSEventTypeLeftMouseDragged:   return @selector(mouseDragged:);
        case NSEventTypeRightMouseDragged:  return @selector(rightMouseDragged:);
        case NSEventTypeMouseEntered:       return @selector(mouseEntered:);
        case NSEventTypeMouseExited:        return @selector(mouseExited:);
        case NSEventTypeKeyDown:            return @selector(keyDown:);
        case NSEventTypeKeyUp:              return @selector(keyUp:);
        case NSEventTypeFlagsChanged:       return @selector(flagsChanged:);
        case NSEventTypeOtherMouseDown:     return @selector(otherMouseDown:);
        case NSEventTypeOtherMouseUp:       return @selector(otherMouseUp:);
        case NSEventTypeOtherMouseDragged:  return @selector(otherMouseDragged:);
        case NSEventTypeScrollWheel:        return @selector(scrollWheel:);
        case NSEventTypeTabletPoint:        return @selector(tabletPoint:);
        case NSEventTypeTabletProximity:    return @selector(tabletProximity:);
        case NSEventTypeCursorUpdate:       return @selector(cursorUpdate:);
        case NSEventTypeGesture:            return @selector(beginGestureWithEvent:);
        case NSEventTypeMagnify:            return @selector(magnifyWithEvent:);
        case NSEventTypeSwipe:              return @selector(swipeWithEvent:);
        case NSEventTypeRotate:             return @selector(rotateWithEvent:);
        case NSEventTypeBeginGesture:       return @selector(beginGestureWithEvent:);
        case NSEventTypeEndGesture:         return @selector(endGestureWithEvent:);
        case NSEventTypeSmartMagnify:       return @selector(smartMagnifyWithEvent:);
        case NSEventTypeQuickLook:          return @selector(quickLookWithEvent:);
        case NSEventTypePressure:           return @selector(pressureChangeWithEvent:);
        case NSEventTypeDirectTouch:        return @selector(touchesBeganWithEvent:);
        case NSEventTypeChangeMode:         return @selector(changeModeWithEvent:);
        default:                            return NULL;
    }
}

/* Pointing and scrolling events are located in the window and hit-test into
 * the content view hierarchy; only genuine keyboard events hold no location
 * and must go to the first responder. */
static BOOL LBSWindowEventIsKeyboardType(NSEventType type)
{
    return (type == NSEventTypeKeyDown ||
            type == NSEventTypeKeyUp ||
            type == NSEventTypeFlagsChanged);
}

@interface NSWindow () {
    NSRect _frame;
    NSWindowStyleMask _styleMask;
    NSBackingStoreType _backingType;
    NSString *_title;
    NSView *_contentView;
    id<NSWindowDelegate> __unsafe_unretained _delegate;
    NSResponder *__unsafe_unretained _firstResponder;
    BOOL _visible;
    BOOL _isKeyWindow;
    BOOL _isMainWindow;
    BOOL _miniaturized;
    BOOL _opaque;
    NSInteger _windowNumber;
}

- (void)_lbsRelayoutContent;

@end

@implementation NSWindow

- (instancetype)initWithContentRect:(NSRect)contentRect
                          styleMask:(NSWindowStyleMask)styleMask
                            backing:(NSBackingStoreType)backingType
                              defer:(BOOL)deferCreation
{
    return [self initWithContentRect:contentRect
                           styleMask:styleMask
                             backing:backingType
                               defer:deferCreation
                              screen:nil];
}

- (nullable instancetype)initWithContentRect:(NSRect)contentRect
                                   styleMask:(NSWindowStyleMask)styleMask
                                     backing:(NSBackingStoreType)backingType
                                       defer:(BOOL)deferCreation
                                      screen:(nullable NSScreen *)screen
{
    if (self = [super init]) {
        _styleMask = styleMask;
        _backingType = backingType;
        _frame = [self frameRectForContentRect:contentRect];
        _title = @"";
        _delegate = nil;
        _firstResponder = nil;
        _visible = NO;
        _isKeyWindow = NO;
        _isMainWindow = NO;
        _miniaturized = NO;
        _opaque = YES;

        _windowNumber = ++LBSWindowNumberSequence;

        NSView *content = [[NSView alloc] initWithFrame:[self contentRectForFrameRect:_frame]];
        [content _lbsSetInWindow:self];
        _contentView = content;

        /* Register with the application so -[NSApp windows],
         * windowWithWindowNumber:, and the key/main machinery see it. */
        [[NSApplication sharedApplication] _lbsRegisterWindow:self];
    }
    return self;
}

/* ------------------------------------------------------------------ */
/*  Geometry                                                           */
/* ------------------------------------------------------------------ */

- (NSRect)contentRectForFrameRect:(NSRect)frameRect
{
    return [NSWindow contentRectForFrameRect:frameRect styleMask:_styleMask];
}

- (NSRect)frameRectForContentRect:(NSRect)contentRect
{
    return [NSWindow frameRectForContentRect:contentRect styleMask:_styleMask];
}

+ (NSRect)contentRectForFrameRect:(NSRect)frameRect styleMask:(NSWindowStyleMask)styleMask
{
    NSRect rect = frameRect;
    if (styleMask & NSWindowStyleMaskTitled) {
        rect.origin.y += LBSTitleBarHeight;
        rect.size.height -= LBSTitleBarHeight;
    }
    return rect;
}

+ (NSRect)frameRectForContentRect:(NSRect)contentRect styleMask:(NSWindowStyleMask)styleMask
{
    NSRect rect = contentRect;
    if (styleMask & NSWindowStyleMaskTitled) {
        rect.origin.y -= LBSTitleBarHeight;
        rect.size.height += LBSTitleBarHeight;
    }
    return rect;
}

- (NSRect)frame
{
    return _frame;
}

- (void)setFrame:(NSRect)frameRect
{
    [self setFrame:frameRect display:YES];
}

- (void)setFrame:(NSRect)frameRect display:(BOOL)flag
{
    if (NSEqualRects(frameRect, _frame)) {
        return;
    }
    BOOL moved = (frameRect.origin.x != _frame.origin.x || frameRect.origin.y != _frame.origin.y);
    BOOL resized = (frameRect.size.width != _frame.size.width || frameRect.size.height != _frame.size.height);
    _frame = frameRect;
    [self _lbsRelayoutContent];
    if (moved) {
        [self _lbsNoteMove];
    }
    if (resized) {
        [[NSNotificationCenter defaultCenter] postNotificationName:NSWindowDidResizeNotification object:self];
    }
}

- (void)setFrameOrigin:(NSPoint)newOrigin
{
    if (newOrigin.x == _frame.origin.x && newOrigin.y == _frame.origin.y) {
        return;
    }
    _frame.origin = newOrigin;
    [self _lbsRelayoutContent];
    [self _lbsNoteMove];
}

- (void)setFrameSize:(NSSize)newSize
{
    if (newSize.width == _frame.size.width && newSize.height == _frame.size.height) {
        return;
    }
    _frame.size = newSize;
    [self _lbsRelayoutContent];
    [[NSNotificationCenter defaultCenter] postNotificationName:NSWindowDidResizeNotification object:self];
}

- (void)setContentSize:(NSSize)size
{
    NSRect frame = _frame;
    frame.size = [self frameRectForContentRect:NSMakeRect(0, 0, size.width, size.height)].size;
    [self setFrame:frame display:YES];
}

- (void)_lbsNoteMove
{
    [[NSNotificationCenter defaultCenter] postNotificationName:NSWindowWillMoveNotification object:self];
    [[NSNotificationCenter defaultCenter] postNotificationName:NSWindowDidMoveNotification object:self];
}

- (void)_lbsRelayoutContent
{
    [_contentView setFrame:[self contentRectForFrameRect:_frame]];
}

/* ------------------------------------------------------------------ */
/*  Content view                                                       */
/* ------------------------------------------------------------------ */

- (NSView *)contentView
{
    return _contentView;
}

- (void)setContentView:(NSView *)contentView
{
    if (contentView == _contentView) {
        return;
    }
    [_contentView _lbsSetInWindow:nil];
    _contentView = contentView;
    [contentView _lbsSetInWindow:self];
    if (contentView != nil) {
        [contentView setFrame:[self contentRectForFrameRect:_frame]];
    }
}

/* ------------------------------------------------------------------ */
/*  Attributes                                                         */
/* ------------------------------------------------------------------ */

- (NSWindowStyleMask)styleMask
{
    return _styleMask;
}

- (void)setStyleMask:(NSWindowStyleMask)styleMask
{
    if (_styleMask == styleMask) {
        return;
    }
    _styleMask = styleMask;
    /* Changing the titled bit changes the content area derived from the
     * unchanged frame. */
    [self _lbsRelayoutContent];
}

- (NSBackingStoreType)backingType
{
    return _backingType;
}

- (NSString *)title
{
    return _title;
}

- (void)setTitle:(NSString *)title
{
    _title = [title copy];
}

- (BOOL)isVisible
{
    return _visible;
}

- (BOOL)isOpaque
{
    return _opaque;
}

- (void)setOpaque:(BOOL)flag
{
    _opaque = flag;
}

- (id<NSWindowDelegate>)delegate
{
    return _delegate;
}

- (void)setDelegate:(id<NSWindowDelegate>)delegate
{
    _delegate = delegate;
}

/* ------------------------------------------------------------------ */
/*  Ordering (onscreen flag only; server ordering lands later)         */
/* ------------------------------------------------------------------ */

- (void)orderFront:(id)sender
{
    /* FIXME(macos): real ordering against the window server. */
    _visible = YES;
}

- (void)orderBack:(id)sender
{
    /* FIXME(macos): real ordering against the window server. */
    _visible = YES;
}

- (void)orderOut:(id)sender
{
    if (!_visible) {
        return;
    }
    _visible = NO;
    /* A window off the screen cannot hold the key or main status. */
    if ([self isKeyWindow]) {
        [self resignKeyWindow];
    }
    if ([self isMainWindow]) {
        [self resignMainWindow];
    }
}

/* ------------------------------------------------------------------ */
/*  Key and main window                                                */
/* ------------------------------------------------------------------ */

- (void)makeKeyAndOrderFront:(id)sender
{
    [self orderFront:sender];
    [self makeKeyWindow];
}

- (void)makeKey:(id)sender
{
    [self makeKeyWindow];
}

- (void)makeMain:(id)sender
{
    [self makeMainWindow];
}

- (void)makeKeyWindow
{
    if ([self isKeyWindow]) {
        return;
    }
    NSApplication *app = [NSApplication sharedApplication];
    NSWindow *oldKey = [app keyWindow];
    /* oldKey can be self or a fallback when the application has no stored
     * key pointer; only resign a genuinely different, genuinely key window. */
    if (oldKey != nil && oldKey != self && [oldKey isKeyWindow]) {
        [oldKey resignKeyWindow];
    }
    [app _lbsSetKeyWindow:self];
    [self becomeKeyWindow];
}

- (void)makeMainWindow
{
    if ([self isMainWindow]) {
        return;
    }
    NSApplication *app = [NSApplication sharedApplication];
    NSWindow *oldMain = [app mainWindow];
    if (oldMain != nil && oldMain != self && [oldMain isMainWindow]) {
        [oldMain resignMainWindow];
    }
    [app _lbsSetMainWindow:self];
    [self becomeMainWindow];
}

- (BOOL)isKeyWindow
{
    return _isKeyWindow;
}

- (BOOL)isMainWindow
{
    return _isMainWindow;
}

- (void)becomeKeyWindow
{
    if (_isKeyWindow) {
        return;
    }
    _isKeyWindow = YES;
    [[NSNotificationCenter defaultCenter] postNotificationName:NSWindowDidBecomeKeyNotification object:self];
}

- (void)resignKeyWindow
{
    if (!_isKeyWindow) {
        return;
    }
    _isKeyWindow = NO;
    [[NSApplication sharedApplication] _lbsSetKeyWindow:nil];
    [[NSNotificationCenter defaultCenter] postNotificationName:NSWindowDidResignKeyNotification object:self];
}

- (void)becomeMainWindow
{
    if (_isMainWindow) {
        return;
    }
    _isMainWindow = YES;
    [[NSNotificationCenter defaultCenter] postNotificationName:NSWindowDidBecomeMainNotification object:self];
}

- (void)resignMainWindow
{
    if (!_isMainWindow) {
        return;
    }
    _isMainWindow = NO;
    [[NSApplication sharedApplication] _lbsSetMainWindow:nil];
    [[NSNotificationCenter defaultCenter] postNotificationName:NSWindowDidResignMainNotification object:self];
}

- (BOOL)canBecomeKeyWindow
{
    return YES;
}

- (BOOL)canBecomeMainWindow
{
    return YES;
}

/* ------------------------------------------------------------------ */
/*  Responder chain                                                    */
/* ------------------------------------------------------------------ */

- (NSResponder *)nextResponder
{
    return [NSApplication sharedApplication];
}

- (NSResponder *)firstResponder
{
    return _firstResponder != nil ? _firstResponder : self;
}

- (BOOL)makeFirstResponder:(NSResponder *)aResponder
{
    NSResponder *current = [self firstResponder];
    NSResponder *desired = aResponder != nil ? aResponder : self;

    if (current == desired) {
        return YES;
    }
    if (![current resignFirstResponder]) {
        return NO;
    }
    if (desired != self && ![desired acceptsFirstResponder]) {
        return NO;
    }
    if (![desired becomeFirstResponder]) {
        return NO;
    }
    _firstResponder = aResponder;
    return YES;
}

- (BOOL)acceptsFirstResponder
{
    return YES;
}

- (NSInteger)windowNumber
{
    return _windowNumber;
}

/* ------------------------------------------------------------------ */
/*  Miniaturization                                                    */
/* ------------------------------------------------------------------ */

- (BOOL)isMiniaturized
{
    return _miniaturized;
}

- (void)miniaturize:(id)sender
{
    if (_miniaturized) {
        return;
    }
    [[NSNotificationCenter defaultCenter] postNotificationName:NSWindowWillMiniaturizeNotification object:self];
    _miniaturized = YES;
    [[NSNotificationCenter defaultCenter] postNotificationName:NSWindowDidMiniaturizeNotification object:self];
}

- (void)deminiaturize:(id)sender
{
    if (!_miniaturized) {
        return;
    }
    [[NSNotificationCenter defaultCenter] postNotificationName:NSWindowWillDeminiaturizeNotification object:self];
    _miniaturized = NO;
    [[NSNotificationCenter defaultCenter] postNotificationName:NSWindowDidDeminiaturizeNotification object:self];
}

/* ------------------------------------------------------------------ */
/*  Closing                                                            */
/* ------------------------------------------------------------------ */

- (void)close
{
    if (_firstResponder != nil) {
        [self makeFirstResponder:nil];
    }
    [self resignKeyWindow];
    [self resignMainWindow];
    _visible = NO;
    [[NSApplication sharedApplication] _lbsUnregisterWindow:self];
    if (_delegate != nil && [_delegate respondsToSelector:@selector(windowWillClose:)]) {
        [_delegate windowWillClose:[NSNotification notificationWithName:NSWindowWillCloseNotification object:self]];
    }
    [[NSNotificationCenter defaultCenter] postNotificationName:NSWindowWillCloseNotification object:self];
}

- (void)performClose:(id)sender
{
    if (_delegate != nil && [_delegate respondsToSelector:@selector(windowShouldClose:)]) {
        if (![_delegate windowShouldClose:self]) {
            return;
        }
    }
    [self close];
}

/* ------------------------------------------------------------------ */
/*  Event dispatch                                                     */
/* ------------------------------------------------------------------ */

- (void)sendEvent:(NSEvent *)event
{
    if (event == nil) {
        return;
    }
    NSEventType type = [event type];
    SEL handler = LBSWindowActionForEventType(type);
    if (handler == NULL) {
        /* AppKit/system/application-defined events are consumed elsewhere. */
        return;
    }
    NSResponder *target = [self firstResponder];
    if (!LBSWindowEventIsKeyboardType(type)) {
        /* Mouse/scroll/gesture events carry a location: hit-test the content
         * view so the deepest view under the pointer handles the event, and
         * the responder chain climbs to the window when views decline. */
        NSView *content = _contentView;
        if (content != nil) {
            NSPoint windowPoint = [event locationInWindow];
            NSPoint localPoint = NSMakePoint(windowPoint.x - [content frame].origin.x,
                                             windowPoint.y - [content frame].origin.y);
            NSView *hit = [content hitTest:localPoint];
            if (hit != nil) {
                target = hit;
            }
        }
    }
    if (![target tryToPerform:handler with:event]) {
        [target noResponderFor:handler];
    }
}

@end