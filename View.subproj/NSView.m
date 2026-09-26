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

/* NSView.m — LibreDarwin reimplementation of AppKit's NSView.
 *
 * Headless core of the view hierarchy: geometry (frame/bounds), the subview
 * tree with positioning, window binding via the LBSViewPrivate hook NSWindow
 * uses to install its content view, display bookkeeping, hit testing, and
 * coordinate conversion for the unflipped, unrotated, unscaled case. No
 * window-server connection, layers, or drawing primitives yet — drawRect:
 * is the public surface a subclass overrides, and display just walks the
 * tree.
 *
 * Written against the minimal LibreDarwin Foundation NSArray surface
 * (count/objectAtIndex:/addObject:/removeObjectAtIndex: only): no fast
 * enumeration, no reverse enumerators. */

#import <Foundation/NSArray.h>
#import <Foundation/NSGeometry.h>
#import <AppKit/NSView.h>
#import <AppKit/NSView_Private.h>
#import <AppKit/AppKitDefines.h>

@interface NSView () {
    NSWindow *__unsafe_unretained _window;
    NSView *__unsafe_unretained _superview;
    NSMutableArray<NSView *> *_subviews;
    NSRect _frame;
    NSRect _bounds;
    BOOL _hidden;
    BOOL _needsDisplay;
    BOOL _autoresizesSubviews;
    NSAutoresizingMaskOptions _autoresizingMask;
}
@end

@implementation NSView

- (instancetype)init
{
    return [self initWithFrame:NSMakeRect(0, 0, 0, 0)];
}

- (instancetype)initWithFrame:(NSRect)frameRect
{
    if (self = [super init]) {
        _frame = frameRect;
        _bounds = frameRect;
        _window = nil;
        _superview = nil;
        _subviews = nil;
        _hidden = NO;
        _needsDisplay = NO;
        _autoresizesSubviews = YES;
        _autoresizingMask = NSViewNotSizable;
    }
    return self;
}

- (NSWindow *)window
{
    return _window;
}

- (NSResponder *)nextResponder
{
    /* The responder chain runs up through the superview hierarchy and out
     * the window, matching Apple: an unhandled event in a deep view climbs
     * until someone handles it or the window hands it to the application. */
    if (_superview != nil) {
        return _superview;
    }
    return (NSResponder *)_window;
}

- (NSView *)superview
{
    return _superview;
}

- (NSUInteger)_indexOfSubview:(NSView *)subview
{
    for (NSUInteger i = 0; i < [_subviews count]; i++) {
        if ([_subviews objectAtIndex:i] == subview) {
            return i;
        }
    }
    return NSNotFound;
}

- (NSArray<__kindof NSView *> *)subviews
{
    return _subviews ? (NSArray<__kindof NSView *> *)_subviews : @[];
}

- (void)setSubviews:(NSArray<__kindof NSView *> *)subviews
{
    /* Detach everything we currently own first. */
    while ([_subviews count] > 0) {
        NSView *subview = (NSView *)[_subviews objectAtIndex:0];
        [subview removeFromSuperview];
    }
    _subviews = nil;
    for (NSUInteger i = 0; i < [subviews count]; i++) {
        [self addSubview:(NSView *)[subviews objectAtIndex:i]];
    }
}

- (BOOL)isDescendantOf:(NSView *)view
{
    for (NSView *ancestor = self; ancestor != nil; ancestor = ancestor->_superview) {
        if (ancestor == view) {
            return YES;
        }
    }
    return NO;
}

- (BOOL)isHidden
{
    return _hidden;
}

- (void)setHidden:(BOOL)flag
{
    _hidden = flag;
    [self setNeedsDisplay:flag];
}

- (BOOL)isHiddenOrHasHiddenAncestor
{
    for (NSView *view = self; view != nil; view = view->_superview) {
        if (view->_hidden) {
            return YES;
        }
    }
    return NO;
}

- (void)addSubview:(NSView *)view
{
    [self addSubview:view positioned:NSWindowAbove relativeTo:nil];
}

- (void)addSubview:(NSView *)view positioned:(NSWindowOrderingMode)place relativeTo:(nullable NSView *)otherView
{
    if (view == nil || view == self || view == otherView) {
        return;
    }
    if (_subviews == nil) {
        _subviews = [NSMutableArray arrayWithCapacity:4];
    }
    if (view->_superview == self) {
        [self _removeSubviewFromArray:view];
    } else if (view->_superview != nil) {
        [view removeFromSuperview];
    }

    /* Compute the insertion index: above/below the given sibling, or at the
     * end (top) / start (bottom) of the stacking order. */
    NSUInteger insertionIndex = [_subviews count];
    if (otherView != nil) {
        NSUInteger siblingIndex = [self _indexOfSubview:otherView];
        if (siblingIndex != NSNotFound) {
            insertionIndex = (place == NSWindowBelow) ? siblingIndex : siblingIndex + 1;
        } else if (place == NSWindowBelow) {
            insertionIndex = 0;
        }
    } else if (place == NSWindowBelow) {
        insertionIndex = 0;
    }

    [self _insertSubview:view atIndex:insertionIndex];
    view->_superview = self;
    [view _lbsSetInWindow:_window];
}

- (void)_insertSubview:(NSView *)view atIndex:(NSUInteger)index
{
    NSUInteger count = [_subviews count];
    if (index > count) {
        index = count;
    }
    NSMutableArray<NSView *> *reordered = [NSMutableArray arrayWithCapacity:count + 1];
    for (NSUInteger i = 0; i < index; i++) {
        [reordered addObject:(NSView *)[_subviews objectAtIndex:i]];
    }
    [reordered addObject:view];
    for (NSUInteger i = index; i < count; i++) {
        [reordered addObject:(NSView *)[_subviews objectAtIndex:i]];
    }
    _subviews = reordered;
}

- (void)_removeSubviewFromArray:(NSView *)subview
{
    NSUInteger index = [self _indexOfSubview:subview];
    if (index != NSNotFound) {
        [_subviews removeObjectAtIndex:index];
    }
}

- (void)viewWillMoveToWindow:(nullable NSWindow *)newWindow
{
    /* Default no-op; overridable. */
}

- (void)viewDidMoveToWindow
{
    /* Default no-op; overridable. */
}

- (void)removeFromSuperview
{
    NSView *parent = _superview;
    if (parent != nil) {
        [parent _removeSubviewFromArray:self];
    }
    _superview = nil;
    [self _lbsSetInWindow:nil];
}

- (BOOL)autoresizesSubviews
{
    return _autoresizesSubviews;
}

- (void)setAutoresizesSubviews:(BOOL)flag
{
    _autoresizesSubviews = flag;
}

- (NSAutoresizingMaskOptions)autoresizingMask
{
    return _autoresizingMask;
}

- (void)setAutoresizingMask:(NSAutoresizingMaskOptions)mask
{
    _autoresizingMask = mask;
}

- (NSRect)frame
{
    return _frame;
}

- (void)setFrame:(NSRect)frameRect
{
    _frame = frameRect;
}

- (void)setFrameOrigin:(NSPoint)newOrigin
{
    _frame.origin = newOrigin;
}

- (void)setFrameSize:(NSSize)newSize
{
    _frame.size = newSize;
}

- (NSRect)bounds
{
    return _bounds;
}

- (void)setBounds:(NSRect)boundsRect
{
    _bounds = boundsRect;
}

- (void)setBoundsOrigin:(NSPoint)newOrigin
{
    _bounds.origin = newOrigin;
}

- (void)setBoundsSize:(NSSize)newSize
{
    _bounds.size = newSize;
}

- (BOOL)isFlipped
{
    return NO;
}

- (NSPoint)convertPoint:(NSPoint)point fromView:(nullable NSView *)view
{
    NSView *src = (view != nil) ? view : self;
    NSPoint result = point;
    /* Bring the point up from src's coordinates to a common base (the
     * window/content view origin is treated as the top of the tree), then
     * down into our own. Both chains share the root, so the two passes
     * cancel for unrelated trees. */
    for (NSView *v = src; v != nil; v = v->_superview) {
        result.x += v->_frame.origin.x;
        result.y += v->_frame.origin.y;
    }
    for (NSView *v = self; v != nil; v = v->_superview) {
        result.x -= v->_frame.origin.x;
        result.y -= v->_frame.origin.y;
    }
    return result;
}

- (NSPoint)convertPoint:(NSPoint)point toView:(nullable NSView *)view
{
    NSView *dst = (view != nil) ? view : self;
    NSPoint result = point;
    /* Up from self to the shared root, then down into dst. */
    for (NSView *v = self; v != nil; v = v->_superview) {
        result.x += v->_frame.origin.x;
        result.y += v->_frame.origin.y;
    }
    for (NSView *v = dst; v != nil; v = v->_superview) {
        result.x -= v->_frame.origin.x;
        result.y -= v->_frame.origin.y;
    }
    return result;
}

- (NSSize)convertSize:(NSSize)size fromView:(nullable NSView *)view
{
    /* Unscaled coordinate system: sizes are invariant. */
    return size;
}

- (NSSize)convertSize:(NSSize)size toView:(nullable NSView *)view
{
    return size;
}

- (NSRect)convertRect:(NSRect)rect fromView:(nullable NSView *)view
{
    NSPoint origin = [self convertPoint:rect.origin fromView:view];
    return NSMakeRect(origin.x, origin.y, rect.size.width, rect.size.height);
}

- (NSRect)convertRect:(NSRect)rect toView:(nullable NSView *)view
{
    NSPoint origin = [self convertPoint:rect.origin toView:view];
    return NSMakeRect(origin.x, origin.y, rect.size.width, rect.size.height);
}

- (BOOL)needsDisplay
{
    return _needsDisplay;
}

- (void)setNeedsDisplay:(BOOL)flag
{
    _needsDisplay = flag;
}

- (void)setNeedsDisplayInRect:(NSRect)invalidRect
{
    _needsDisplay = YES;
}

- (void)display
{
    if (_hidden) {
        return;
    }
    _needsDisplay = NO;
    [self drawRect:_bounds];
    [self _displaySubviews];
}

- (void)_displaySubviews
{
    for (NSUInteger i = 0; i < [_subviews count]; i++) {
        NSView *subview = (NSView *)[_subviews objectAtIndex:i];
        [subview display];
    }
}

- (void)displayIfNeeded
{
    if (_needsDisplay) {
        [self display];
    }
}

- (void)drawRect:(NSRect)dirtyRect
{
    /* Default no-op; subclasses override. */
}

- (nullable NSView *)hitTest:(NSPoint)point
{
    if (_hidden || ![self mouse:point inRect:_bounds]) {
        return nil;
    }
    /* Topmost subviews draw later, so walk the array back to front. */
    for (NSInteger i = (NSInteger)[_subviews count] - 1; i >= 0; i--) {
        NSView *subview = (NSView *)[_subviews objectAtIndex:(NSUInteger)i];
        NSView *hit = [subview hitTest:[subview convertPoint:point fromView:self]];
        if (hit != nil) {
            return hit;
        }
    }
    return self;
}

- (BOOL)mouse:(NSPoint)point inRect:(NSRect)rect
{
    return NSPointInRect(point, rect);
}

@end

@implementation NSView (LBSViewPrivate)

- (void)_lbsSetInWindow:(nullable NSWindow *)window
{
    if (_window == window) {
        return;
    }
    [self viewWillMoveToWindow:window];
    _window = window;
    for (NSUInteger i = 0; i < [_subviews count]; i++) {
        NSView *subview = (NSView *)[_subviews objectAtIndex:i];
        [subview _lbsSetInWindow:window];
    }
    [self viewDidMoveToWindow];
}

@end