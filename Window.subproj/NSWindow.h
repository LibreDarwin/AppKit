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

/* NSWindow.h — LibreDarwin reimplementation of Apple's AppKit NSWindow.h.
 * The public interface mirrors the system AppKit header (method names,
 * types, and order) so sources written against AppKit are drop-in.
 * Availability annotations are recorded in comments rather than spelled
 * with macros.
 *
 * The surface below is the core Window.subproj needs on day one: creation
 * from a content rect, frame/content geometry (including the title-bar
 * math), content-view hosting, onscreen visibility flags, key/main state
 * transitions, first-responder assignment, miniaturization state, closing,
 * and event dispatch, all headless. The window-server side (true ordering,
 * screens, backing surfaces, sheets) grows with the display subsystem.
 */
#ifndef _NSWINDOW_H
#define _NSWINDOW_H

#import <Foundation/NSGeometry.h>
#import <Foundation/NSNotification.h>
#import <Foundation/NSObjCRuntime.h>
#import <Foundation/NSString.h>
#import <AppKit/AppKitDefines.h>
#import <AppKit/NSResponder.h>
#import <AppKit/NSView.h>

@class NSScreen;
@protocol NSWindowDelegate;

NS_ASSUME_NONNULL_BEGIN

/* Defines the style of the window. */
typedef NS_OPTIONS(NSUInteger, NSWindowStyleMask) {
    NSWindowStyleMaskBorderless           = 0,
    NSWindowStyleMaskTitled               = 1 << 0,
    NSWindowStyleMaskClosable             = 1 << 1,
    NSWindowStyleMaskMiniaturizable       = 1 << 2,
    NSWindowStyleMaskResizable            = 1 << 3,
    NSWindowStyleMaskUtilityWindow        = 1 << 4,
    NSWindowStyleMaskDocModalWindow       = 1 << 5,
    NSWindowStyleMaskNonactivatingPanel   = 1 << 7,
    NSWindowStyleMaskTexturedBackground   = 1 << 8,
    NSWindowStyleMaskUnifiedTitleAndToolbar = 1 << 12,
    NSWindowStyleMaskHUDWindow            = 1 << 13,
    NSWindowStyleMaskFullScreen           = 1 << 14,
    NSWindowStyleMaskFullSizeContentView  = 1 << 15,
};

/* Backing types. */
typedef NS_ENUM(NSUInteger, NSBackingStoreType) {
    NSBackingStoreRetained    = 0,
    NSBackingStoreNonretained = 1,
    NSBackingStoreBuffered    = 2
};

/* Window levels, matching Apple's AppKit values. Levels above 0 are drawn
 * above all other windows; levels below 0 are drawn below all others.
 * Values mirror the CGWindowLevel constants for the corresponding modes. */
typedef NS_ENUM(NSInteger, NSWindowLevel) {
    NSNormalWindowLevel       = 0,
    NSFloatingWindowLevel     = 3,
    NSSubmenuWindowLevel      = 3,
    NSTornOffMenuWindowLevel  = 3,
    NSModalPanelWindowLevel   = 8,
    NSMainMenuWindowLevel     = 24,
    NSStatusWindowLevel       = 25,
    NSPopUpMenuWindowLevel    = 101,
    NSScreenSaverWindowLevel  = 1000
};

@interface NSWindow : NSResponder

- (instancetype)initWithContentRect:(NSRect)contentRect
                          styleMask:(NSWindowStyleMask)styleMask
                            backing:(NSBackingStoreType)backingType
                              defer:(BOOL)deferCreation;
- (nullable instancetype)initWithContentRect:(NSRect)contentRect
                                   styleMask:(NSWindowStyleMask)styleMask
                                     backing:(NSBackingStoreType)backingType
                                       defer:(BOOL)deferCreation
                                      screen:(nullable NSScreen *)screen;

/* The window's content view. A default content view is created when the
 * window is initialized and rebound on setContentView:. */
@property (nullable, strong) NSView *contentView;

/* Given a frame rectangle, returns the rectangle containing the content
 * (that is, the frame with the title bar removed). */
- (NSRect)contentRectForFrameRect:(NSRect)frameRect;
/* Given a content rectangle, returns the rectangle of the frame (that is,
 * the content rect plus the title bar). */
- (NSRect)frameRectForContentRect:(NSRect)contentRect;
+ (NSRect)contentRectForFrameRect:(NSRect)frameRect styleMask:(NSWindowStyleMask)styleMask;
+ (NSRect)frameRectForContentRect:(NSRect)contentRect styleMask:(NSWindowStyleMask)styleMask;

/* Sets the content size within the frame, preserving the frame origin. */
- (void)setContentSize:(NSSize)size;

/* The mask of the window's style. */
@property NSWindowStyleMask styleMask;
/* The backing store type. */
@property (readonly) NSBackingStoreType backingType;
/* The title of the window. */
@property (copy) NSString *title;

/* The frame rectangle of the window (including the title bar, if any). */
@property NSRect frame;
- (void)setFrame:(NSRect)frameRect display:(BOOL)flag;
- (void)setFrameOrigin:(NSPoint)newOrigin;
- (void)setFrameSize:(NSSize)newSize;

/* A Boolean value that indicates whether the window is onscreen. */
@property (readonly, getter=isVisible) BOOL visible;

/* Order the window to the front / back / offscreen. */
- (void)orderFront:(nullable id)sender;
- (void)orderBack:(nullable id)sender;
- (void)orderOut:(nullable id)sender;

/* These methods order the window as specified and make the window key and/or
 * main, if possible. */
- (void)makeKeyAndOrderFront:(nullable id)sender;
- (void)makeKey:(nullable id)sender;
- (void)makeMain:(nullable id)sender;

/* Changes the key or main window status by making the receiver one. */
- (void)makeKeyWindow;
- (void)makeMainWindow;
/* Received by the window when it becomes or resigns the key or main window. */
- (void)becomeKeyWindow;
- (void)resignKeyWindow;
- (void)becomeMainWindow;
- (void)resignMainWindow;

@property (readonly, getter=isKeyWindow) BOOL keyWindow;
@property (readonly, getter=isMainWindow) BOOL mainWindow;
- (BOOL)canBecomeKeyWindow;
- (BOOL)canBecomeMainWindow;

/* The window's first responder. If none has been set, the window itself is
 * returned. */
@property (readonly, unsafe_unretained) NSResponder *firstResponder;
- (BOOL)makeFirstResponder:(nullable NSResponder *)aResponder;

/* Returns YES (a window always accepts first responder). */
- (BOOL)acceptsFirstResponder;

/* A unique identifier for the window. */
@property (readonly) NSInteger windowNumber;

@property (readonly, getter=isMiniaturized) BOOL miniaturized;
- (void)miniaturize:(nullable id)sender;
- (void)deminiaturize:(nullable id)sender;

/* Closes the window. The window is removed from the screen and unregistered
 * from the application; NSWindowWillCloseNotification is posted. */
- (void)close;
/* Performs a close, honoring the delegate's windowShouldClose:. */
- (void)performClose:(nullable id)sender;

/* Dispatches the event to the window's responder chain. */
- (void)sendEvent:(NSEvent *)event;

@property (getter=isOpaque) BOOL opaque;
@property (nullable, weak) id<NSWindowDelegate> delegate;

@end

@protocol NSWindowDelegate <NSObject>
@optional
- (BOOL)windowShouldClose:(NSWindow *)sender;
- (void)windowWillClose:(NSNotification *)notification;
- (void)windowDidBecomeKey:(NSNotification *)notification;
- (void)windowDidResignKey:(NSNotification *)notification;
- (void)windowDidBecomeMain:(NSNotification *)notification;
- (void)windowDidResignMain:(NSNotification *)notification;
- (void)windowWillMiniaturize:(NSNotification *)notification;
- (void)windowDidMiniaturize:(NSNotification *)notification;
- (void)windowWillDeminiaturize:(NSNotification *)notification;
- (void)windowDidDeminiaturize:(NSNotification *)notification;
- (void)windowWillMove:(NSNotification *)notification;
- (void)windowDidMove:(NSNotification *)notification;
- (void)windowDidResize:(NSNotification *)notification;
- (void)windowDidExpose:(NSNotification *)notification;
@end

#pragma mark - Notifications

/* Sent when the window is closed. */
APPKIT_EXTERN NSNotificationName NSWindowWillCloseNotification;
/* Sent when the window resigns its key-window status. */
APPKIT_EXTERN NSNotificationName NSWindowDidResignKeyNotification;
/* Sent when the window becomes the key window. */
APPKIT_EXTERN NSNotificationName NSWindowDidBecomeKeyNotification;
/* Sent when the window resigns its main-window status. */
APPKIT_EXTERN NSNotificationName NSWindowDidResignMainNotification;
/* Sent when the window becomes the main window. */
APPKIT_EXTERN NSNotificationName NSWindowDidBecomeMainNotification;
/* Sent when the window is about to be miniaturized. */
APPKIT_EXTERN NSNotificationName NSWindowWillMiniaturizeNotification;
/* Sent when the window has been miniaturized. */
APPKIT_EXTERN NSNotificationName NSWindowDidMiniaturizeNotification;
/* Sent when the window is about to be deminiaturized. */
APPKIT_EXTERN NSNotificationName NSWindowWillDeminiaturizeNotification;
/* Sent when the window has been deminiaturized. */
APPKIT_EXTERN NSNotificationName NSWindowDidDeminiaturizeNotification;
/* Sent when the window is about to move. */
APPKIT_EXTERN NSNotificationName NSWindowWillMoveNotification;
/* Sent when the window has moved. */
APPKIT_EXTERN NSNotificationName NSWindowDidMoveNotification;
/* Sent when the window has been resized. */
APPKIT_EXTERN NSNotificationName NSWindowDidResizeNotification;
/* Sent when the window has been exposed. */
APPKIT_EXTERN NSNotificationName NSWindowDidExposeNotification;

NS_ASSUME_NONNULL_END

#endif /* _NSWINDOW_H */