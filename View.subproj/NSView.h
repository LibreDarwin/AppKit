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

/* NSView.h — LibreDarwin reimplementation of Apple's AppKit NSView.h. The
 * public interface mirrors the system AppKit header (method names, types,
 * and order) so sources written against AppKit are drop-in. Availability
 * annotations are recorded in comments rather than spelled with macros.
 * The surface below is the core a view hierarchy needs on day one —
 * geometry, the subview tree, window binding, display bookkeeping, hit
 * testing, and coordinate conversion. The rich layers/dragging/NSCell
 * surface grows with its own subprojects as those land. NSView must not
 * redeclare anything inherited from NSResponder; only NSView-specific
 * API is declared here. */
#ifndef _NSVIEW_H
#define _NSVIEW_H

#import <Foundation/NSArray.h>
#import <Foundation/NSGeometry.h>
#import <AppKit/AppKitDefines.h>
#import <AppKit/NSGraphics.h>
#import <AppKit/NSResponder.h>

@class NSWindow;

/* Bitset options for the autoresizingMask. */
typedef NS_OPTIONS(NSUInteger, NSAutoresizingMaskOptions) {
    NSViewNotSizable		=  0,
    NSViewMinXMargin		=  1,
    NSViewWidthSizable		=  2,
    NSViewMaxXMargin		=  4,
    NSViewMinYMargin		=  8,
    NSViewHeightSizable		= 16,
    NSViewMaxYMargin		= 32
};

NS_ASSUME_NONNULL_BEGIN

@interface NSView : NSResponder

- (instancetype)initWithFrame:(NSRect)frameRect;

@property (nullable, readonly, unsafe_unretained) NSWindow *window;
@property (nullable, readonly, unsafe_unretained) NSView *superview;
@property (copy) NSArray<__kindof NSView *> *subviews;
- (BOOL)isDescendantOf:(NSView *)view;

@property (getter=isHidden) BOOL hidden;
@property (getter=isHiddenOrHasHiddenAncestor, readonly) BOOL hiddenOrHasHiddenAncestor;

- (void)addSubview:(NSView *)view;
- (void)addSubview:(NSView *)view positioned:(NSWindowOrderingMode)place relativeTo:(nullable NSView *)otherView;

- (void)viewWillMoveToWindow:(nullable NSWindow *)newWindow;
- (void)viewDidMoveToWindow;

- (void)removeFromSuperview;

@property BOOL autoresizesSubviews;
@property NSAutoresizingMaskOptions autoresizingMask;

- (void)setFrameOrigin:(NSPoint)newOrigin;
- (void)setFrameSize:(NSSize)newSize;
@property NSRect frame;

- (void)setBoundsOrigin:(NSPoint)newOrigin;
- (void)setBoundsSize:(NSSize)newSize;
@property NSRect bounds;

@property (getter=isFlipped, readonly) BOOL flipped;

- (NSPoint)convertPoint:(NSPoint)point fromView:(nullable NSView *)view;
- (NSPoint)convertPoint:(NSPoint)point toView:(nullable NSView *)view;
- (NSSize)convertSize:(NSSize)size fromView:(nullable NSView *)view;
- (NSSize)convertSize:(NSSize)size toView:(nullable NSView *)view;
- (NSRect)convertRect:(NSRect)rect fromView:(nullable NSView *)view;
- (NSRect)convertRect:(NSRect)rect toView:(nullable NSView *)view;

@property BOOL needsDisplay;
- (void)setNeedsDisplayInRect:(NSRect)invalidRect;
- (void)display;
- (void)displayIfNeeded;
- (void)drawRect:(NSRect)dirtyRect;

- (nullable NSView *)hitTest:(NSPoint)point;
- (BOOL)mouse:(NSPoint)point inRect:(NSRect)rect;

@end

NS_ASSUME_NONNULL_END

#endif /* _NSVIEW_H */