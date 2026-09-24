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

/* NSApplication.m — the application object for LibreDarwin's AppKit.
 *
 * Authored fresh for this project, with Apple's documented semantics as the
 * reference and Cocotron/NeXTSrc consulted only for behavior notes.  The
 * pieces that belong to the window-server and window machinery (real event
 * sourcing, window ordering, the standard About panel, remote-notification
 * delivery, default menu construction) carry FIXMEs and are kept off the
 * headless-verifiable core: the event queue, the run/terminate state
 * machine, activation/hide/deactivate notification posting, target-for-action
 * resolution, UI validation, and modal sessions all work without a display. */

#import <AppKit/NSApplication.h>
#import <AppKit/NSApplication_Private.h>
#import <AppKit/NSEvent.h>
#import <AppKit/NSGraphics.h>
#import <AppKit/NSPasteboard.h>
#import <AppKit/NSPrintInfo.h>
#import <AppKit/NSWindow.h>
#import <Foundation/NSArray.h>
#import <Foundation/NSBundle.h>
#import <Foundation/NSDate.h>
#import <Foundation/NSDictionary.h>
#import <Foundation/NSException.h>
#import <Foundation/NSNotification.h>
#import <Foundation/NSNotificationCenter.h>
#import <Foundation/NSNumber.h>
#import <Foundation/NSObjCRuntime.h>
#import <Foundation/NSRunLoop.h>
#import <Foundation/NSThread.h>
#import <Foundation/NSURL.h>
#import <Foundation/NSUserDefaults.h>
#import <Foundation/NSValue.h>
#import <objc/message.h>

@class NSWindow;

/* ------------------------------------------------------------------ */
/*  Private classes                                                    */
/* ------------------------------------------------------------------ */

/* The private record behind the opaque NSModalSession pointer. */
@interface _NSModalSessionState : NSObject
- (instancetype)initWithWindow:(NSWindow *)window;
- (NSWindow *)window;
- (NSInteger)returnCode;
- (void)terminateWithCode:(NSInteger)code;
- (BOOL)isTerminated;
@end

@implementation _NSModalSessionState {
    NSWindow *__unsafe_unretained _window;
    NSInteger _returnCode;
    BOOL _terminated;
}

- (instancetype)initWithWindow:(NSWindow *)window
{
    if ((self = [super init])) {
        _window = window;
        _returnCode = NSModalResponseContinue;
        _terminated = NO;
    }
    return self;
}

- (NSWindow *)window
{
    return _window;
}

- (NSInteger)returnCode
{
    return _returnCode;
}

- (void)terminateWithCode:(NSInteger)code
{
    if (!_terminated) {
        _returnCode = code;
        _terminated = YES;
    }
}

- (BOOL)isTerminated
{
    return _terminated;
}

@end

/* Marker posted into the event queue to wake a blocked event wait when the
 * app is told to stop or terminate. */
@interface _NSApplicationTerminationEvent : NSEvent
@end

@implementation _NSApplicationTerminationEvent
@end

/* A row in the action/dispatch table consulted by targetForAction:. */
@interface _NSActionDispatchEntry : NSObject
- (instancetype)initWithAction:(SEL)action target:(id)target;
- (SEL)action;
- (id)target;
@end

@implementation _NSActionDispatchEntry {
    NSValue *_action;
    id _target;
}

- (instancetype)initWithAction:(SEL)action target:(id)target
{
    if ((self = [super init])) {
        _action = [NSValue valueWithPointer:action];
        _target = target;
    }
    return self;
}

- (SEL)action
{
    return (SEL)[_action pointerValue];
}

- (id)target
{
    return _target;
}

@end

/* ------------------------------------------------------------------ */
/*  Class extension: state + private helpers                           */
/* ------------------------------------------------------------------ */

@interface NSApplication () {
    id<NSApplicationDelegate> __unsafe_unretained _delegate;
    NSWindow *__unsafe_unretained _mainWindow;
    NSWindow *__unsafe_unretained _keyWindow;
    NSMutableArray<NSWindow *> *_windows;
    NSMenu *_mainMenu;
    NSMenu *_helpMenu;
    NSMenu *_windowsMenu;
    NSMenu *_servicesMenu;
    NSImage *_applicationIconImage;
    NSImage *_cachedApplicationIcon;
    NSAppearance *_appearance;
    NSAppearance *_effectiveAppearance;
    NSMutableArray<NSEvent *> *_eventQueue;
    NSMutableArray<NSRunLoopMode> *_eventQueueModes;
    NSEvent *_currentEvent;
    NSRunLoopMode _eventMode;
    _NSModalSessionState *_modalSession;
    NSApplicationPresentationOptions _presentationOptions;
    NSApplicationOcclusionState _occlusionState;
    BOOL _protectedDataAvailable;
    NSApplicationActivationPolicy _activationPolicy;
    BOOL _active;
    BOOL _hidden;
    BOOL _running;
    BOOL _finishedLaunching;
    BOOL _shouldTerminateLaterPending;
    BOOL _registeredForRemoteNotifications;
    NSRemoteNotificationType _remoteNotificationTypes;
    NSArray<NSPasteboardType> *_serviceSendTypes;
    NSArray<NSPasteboardType> *_serviceReturnTypes;
    id _servicesProvider;
    NSInteger _relaunchOnLoginCounter;
    NSInteger _attentionRequestCount;
    NSMutableArray<_NSActionDispatchEntry *> *_dispatchTable;
}

- (void)_setActive:(BOOL)active;
- (void)_reallyTerminate;
- (void)_postTerminationMarker;
- (NSEvent *)_nextQueuedEventMatchingMask:(NSEventMask)mask inMode:(NSRunLoopMode)mode dequeue:(BOOL)deqFlag;
- (id)_eventTargetForType:(NSEventType)type;
- (void)_openURLs:(NSArray<NSURL *> *)urls;
- (void)_openFiles:(NSArray<NSString *> *)filenames;
- (BOOL)_delegateApplicationShouldOpenUntitledFile;
- (BOOL)_delegateApplicationOpenUntitledFile;
- (NSArray *)_responderChainFrom:(NSResponder *)start;
- (void)_dispatchAdd:(id)target forAction:(SEL)action;
- (void)_dispatchRemove:(id)target forAction:(SEL)action;

@end

/* ------------------------------------------------------------------ */
/*  Module state                                                       */
/* ------------------------------------------------------------------ */

NSApplication *NSApp = nil;

const NSAppKitVersion NSAppKitVersionNumber = NSAppKitVersionNumber14_1;

NSRunLoopMode NSModalPanelRunLoopMode = @"NSModalPanel";
NSRunLoopMode NSEventTrackingRunLoopMode = @"NSEventTracking";

NSAboutPanelOptionKey const NSAboutPanelOptionCredits = @"NSAboutPanelOptionCredits";
NSAboutPanelOptionKey const NSAboutPanelOptionApplicationName = @"NSAboutPanelOptionApplicationName";
NSAboutPanelOptionKey const NSAboutPanelOptionApplicationIcon = @"NSAboutPanelOptionApplicationIcon";
NSAboutPanelOptionKey const NSAboutPanelOptionVersion = @"NSAboutPanelOptionVersion";
NSAboutPanelOptionKey const NSAboutPanelOptionApplicationVersion = @"NSAboutPanelOptionApplicationVersion";

NSNotificationName NSApplicationDidBecomeActiveNotification = @"NSApplicationDidBecomeActiveNotification";
NSNotificationName NSApplicationDidHideNotification = @"NSApplicationDidHideNotification";
NSNotificationName NSApplicationDidFinishLaunchingNotification = @"NSApplicationDidFinishLaunchingNotification";
NSNotificationName NSApplicationDidResignActiveNotification = @"NSApplicationDidResignActiveNotification";
NSNotificationName NSApplicationDidUnhideNotification = @"NSApplicationDidUnhideNotification";
NSNotificationName NSApplicationDidUpdateNotification = @"NSApplicationDidUpdateNotification";
NSNotificationName NSApplicationWillBecomeActiveNotification = @"NSApplicationWillBecomeActiveNotification";
NSNotificationName NSApplicationWillHideNotification = @"NSApplicationWillHideNotification";
NSNotificationName NSApplicationWillFinishLaunchingNotification = @"NSApplicationWillFinishLaunchingNotification";
NSNotificationName NSApplicationWillResignActiveNotification = @"NSApplicationWillResignActiveNotification";
NSNotificationName NSApplicationWillUnhideNotification = @"NSApplicationWillUnhideNotification";
NSNotificationName NSApplicationWillUpdateNotification = @"NSApplicationWillUpdateNotification";
NSNotificationName NSApplicationWillTerminateNotification = @"NSApplicationWillTerminateNotification";
NSNotificationName NSApplicationDidChangeScreenParametersNotification = @"NSApplicationDidChangeScreenParametersNotification";
NSNotificationName NSApplicationProtectedDataWillBecomeUnavailableNotification = @"NSApplicationProtectedDataWillBecomeUnavailableNotification";
NSNotificationName NSApplicationProtectedDataDidBecomeAvailableNotification = @"NSApplicationProtectedDataDidBecomeAvailableNotification";
NSNotificationName NSApplicationShouldBeginSuppressingHighDynamicRangeContentNotification = @"NSApplicationShouldBeginSuppressingHighDynamicRangeContentNotification";
NSNotificationName NSApplicationShouldEndSuppressingHighDynamicRangeContentNotification = @"NSApplicationShouldEndSuppressingHighDynamicRangeContentNotification";

NSString * const NSApplicationLaunchIsDefaultLaunchKey = @"NSApplicationLaunchIsDefaultLaunchKey";
NSString * const NSApplicationLaunchUserNotificationKey = @"NSApplicationLaunchUserNotificationKey";
NSString * const NSApplicationLaunchRemoteNotificationKey = @"NSApplicationLaunchRemoteNotificationKey";

NSNotificationName const NSApplicationDidChangeOcclusionStateNotification = @"NSApplicationDidChangeOcclusionStateNotification";

/* Maps an NSEventType to the responder method that handles it. Events a
 * responder handles (mouse, key, gesture, tablet, ...) always map; the
 * AppKit/system/application-defined families are consumed by the application
 * itself and map to NULL. */
static SEL _LBSEActionForEventType(NSEventType type)
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

/* A date far enough in the future that run-loop waits effectively block
 * forever. LibreDarwin Foundation does not expose [NSDate distantFuture]
 * yet, so build one from the reference date API it does provide. */
static NSDate *LBSAppKitFarFuture(void)
{
    return [NSDate dateWithTimeIntervalSinceReferenceDate:1e12];
}

/* ------------------------------------------------------------------ */
/*  NSApplication                                                      */
/* ------------------------------------------------------------------ */

@implementation NSApplication

+ (instancetype)sharedApplication
{
    if (NSApp == nil) {
        Class principalClass = [self class];
        NSString *principalName = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"NSPrincipalClass"];
        if (principalName != nil) {
            Class candidate = NSClassFromString(principalName);
            if (candidate != Nil && [candidate isSubclassOfClass:[NSApplication class]]) {
                principalClass = candidate;
            }
        }
        NSApp = [[principalClass alloc] init];
    }
    return (id)NSApp;
}

- (instancetype)init
{
    if (NSApp != nil && NSApp != self) {
        [NSException raise:NSInternalInconsistencyException
                    format:@"An NSApplication instance already exists (%@); only one may be created.", NSApp];
    }
    if ((self = [super init])) {
        _windows = [[NSMutableArray alloc] init];
        _eventQueue = [[NSMutableArray alloc] init];
        _eventQueueModes = [[NSMutableArray alloc] init];
        _dispatchTable = [[NSMutableArray alloc] init];
        _eventMode = NSDefaultRunLoopMode;
        _occlusionState = NSApplicationOcclusionStateVisible;
        _protectedDataAvailable = YES;
        _activationPolicy = NSApplicationActivationPolicyRegular;
        if (NSApp == nil) {
            NSApp = self;
        }
    }
    return self;
}

- (id<NSApplicationDelegate>)delegate
{
    return _delegate;
}

- (void)setDelegate:(id<NSApplicationDelegate>)delegate
{
    _delegate = delegate;
}

#pragma mark - Activation / deactivation

- (void)activate
{
    [self activateIgnoringOtherApps:NO];
}

- (void)activateIgnoringOtherApps:(BOOL)ignoreOtherApps
{
    [self _setActive:YES];
}

- (void)deactivate
{
    [self _setActive:NO];
}

- (void)yieldActivationToApplication:(NSRunningApplication *)application
{
    /* FIXME(macos): real activation handoff needs the window server. */
    [self _setActive:NO];
}

- (void)yieldActivationToApplicationWithBundleIdentifier:(NSString *)bundleIdentifier
{
    [self _setActive:NO];
}

- (void)_setActive:(BOOL)active
{
    if (_active == active) {
        return;
    }
    _active = active;
    if (active) {
        [[NSNotificationCenter defaultCenter] postNotificationName:NSApplicationWillBecomeActiveNotification object:self];
        if (_delegate && [_delegate respondsToSelector:@selector(applicationWillBecomeActive:)]) {
            [_delegate applicationWillBecomeActive:[NSNotification notificationWithName:NSApplicationWillBecomeActiveNotification object:self]];
        }
        [[NSNotificationCenter defaultCenter] postNotificationName:NSApplicationDidBecomeActiveNotification object:self];
        if (_delegate && [_delegate respondsToSelector:@selector(applicationDidBecomeActive:)]) {
            [_delegate applicationDidBecomeActive:[NSNotification notificationWithName:NSApplicationDidBecomeActiveNotification object:self]];
        }
    } else {
        [[NSNotificationCenter defaultCenter] postNotificationName:NSApplicationWillResignActiveNotification object:self];
        if (_delegate && [_delegate respondsToSelector:@selector(applicationWillResignActive:)]) {
            [_delegate applicationWillResignActive:[NSNotification notificationWithName:NSApplicationWillResignActiveNotification object:self]];
        }
        [[NSNotificationCenter defaultCenter] postNotificationName:NSApplicationDidResignActiveNotification object:self];
        if (_delegate && [_delegate respondsToSelector:@selector(applicationDidResignActive:)]) {
            [_delegate applicationDidResignActive:[NSNotification notificationWithName:NSApplicationDidResignActiveNotification object:self]];
        }
    }
}

- (BOOL)isActive
{
    return _active;
}

#pragma mark - Hide / unhide

- (void)hide:(id)sender
{
    if (_hidden) {
        return;
    }
    _hidden = YES;
    [[NSNotificationCenter defaultCenter] postNotificationName:NSApplicationWillHideNotification object:self];
    if (_delegate && [_delegate respondsToSelector:@selector(applicationWillHide:)]) {
        [_delegate applicationWillHide:[NSNotification notificationWithName:NSApplicationWillHideNotification object:self]];
    }
    [[NSNotificationCenter defaultCenter] postNotificationName:NSApplicationDidHideNotification object:self];
    if (_delegate && [_delegate respondsToSelector:@selector(applicationDidHide:)]) {
        [_delegate applicationDidHide:[NSNotification notificationWithName:NSApplicationDidHideNotification object:self]];
    }
}

- (void)unhide:(id)sender
{
    [self unhideWithoutActivation];
}

- (void)unhideWithoutActivation
{
    if (!_hidden) {
        return;
    }
    _hidden = NO;
    [[NSNotificationCenter defaultCenter] postNotificationName:NSApplicationWillUnhideNotification object:self];
    if (_delegate && [_delegate respondsToSelector:@selector(applicationWillUnhide:)]) {
        [_delegate applicationWillUnhide:[NSNotification notificationWithName:NSApplicationWillUnhideNotification object:self]];
    }
    [[NSNotificationCenter defaultCenter] postNotificationName:NSApplicationDidUnhideNotification object:self];
    if (_delegate && [_delegate respondsToSelector:@selector(applicationDidUnhide:)]) {
        [_delegate applicationDidUnhide:[NSNotification notificationWithName:NSApplicationDidUnhideNotification object:self]];
    }
}

- (BOOL)isHidden
{
    return _hidden;
}

- (void)hideOtherApplications:(id)sender
{
    /* FIXME(macos): other applications live on the window server. */
}

- (void)unhideAllApplications:(id)sender
{
    /* FIXME(macos): ditto. */
}

#pragma mark - Windows

- (NSWindow *)windowWithWindowNumber:(NSInteger)windowNum
{
    if (windowNum <= 0) {
        return nil;
    }
    for (NSUInteger i = 0; i < [_windows count]; i++) {
        NSWindow *window = [_windows objectAtIndex:i];
        if (window != nil && [window windowNumber] == windowNum) {
            return window;
        }
    }
    return nil;
}

- (NSWindow *)mainWindow
{
    if (_mainWindow != nil) {
        return _mainWindow;
    }
    return [_windows count] > 0 ? [_windows objectAtIndex:0] : nil;
}

- (NSWindow *)keyWindow
{
    if (_keyWindow != nil) {
        return _keyWindow;
    }
    return [self mainWindow];
}

- (NSArray<NSWindow *> *)windows
{
    return [_windows copy];
}

- (void)setWindowsNeedUpdate:(BOOL)needUpdate
{
    /* FIXME(macos): window ordering refresh; nothing to do headless. */
}

- (void)updateWindows
{
    [[NSNotificationCenter defaultCenter] postNotificationName:NSApplicationWillUpdateNotification object:self];
    if (_delegate && [_delegate respondsToSelector:@selector(applicationWillUpdate:)]) {
        [_delegate applicationWillUpdate:[NSNotification notificationWithName:NSApplicationWillUpdateNotification object:self]];
    }
    [[NSNotificationCenter defaultCenter] postNotificationName:NSApplicationDidUpdateNotification object:self];
    if (_delegate && [_delegate respondsToSelector:@selector(applicationDidUpdate:)]) {
        [_delegate applicationDidUpdate:[NSNotification notificationWithName:NSApplicationDidUpdateNotification object:self]];
    }
}

- (void)enumerateWindowsWithOptions:(NSWindowListOptions)options usingBlock:(void (NS_NOESCAPE ^)(NSWindow *window, BOOL *stop))block
{
    NSArray<NSWindow *> *ordered = _windows;
    if ((options & NSWindowListOrderedFrontToBack) != 0) {
        NSMutableArray<NSWindow *> *reversed = [NSMutableArray arrayWithCapacity:[_windows count]];
        for (NSInteger i = [_windows count] - 1; i >= 0; i--) {
            [reversed addObject:[_windows objectAtIndex:i]];
        }
        ordered = reversed;
    }
    for (NSUInteger i = 0; i < [ordered count]; i++) {
        NSWindow *window = [ordered objectAtIndex:i];
        BOOL stop = NO;
        block(window, &stop);
        if (stop) {
            break;
        }
    }
}

- (void)preventWindowOrdering
{
    /* FIXME(macos). */
}

#pragma mark - Menus

- (NSMenu *)mainMenu
{
    /* FIXME(macos): construct the standard application menu structure
     * (Apple, File, Edit, Window, Help) once Menu.subproj lands. */
    return _mainMenu;
}

- (void)setMainMenu:(NSMenu *)mainMenu
{
    _mainMenu = mainMenu;
}

- (NSMenu *)helpMenu
{
    return _helpMenu;
}

- (void)setHelpMenu:(NSMenu *)helpMenu
{
    _helpMenu = helpMenu;
}

#pragma mark - Icon / dock

- (NSImage *)applicationIconImage
{
    if (_applicationIconImage == nil) {
        /* FIXME(macos): NSImage.subproj provides the NSApplicationIcon
         * image; until then, ask for it only if the class exists. */
        Class imageClass = NSClassFromString(@"NSImage");
        if (imageClass != Nil && [imageClass respondsToSelector:@selector(imageNamed:)]) {
            id (*imageNamed)(Class, SEL, NSString *) = (id (*)(Class, SEL, NSString *))objc_msgSend;
            id icon = imageNamed(imageClass, @selector(imageNamed:), @"NSApplicationIcon");
            if (icon != nil) {
                _cachedApplicationIcon = icon;
            }
        }
        return _cachedApplicationIcon;
    }
    return _applicationIconImage;
}

- (void)setApplicationIconImage:(NSImage *)image
{
    _applicationIconImage = image;
    _cachedApplicationIcon = nil;
}

- (NSDockTile *)dockTile
{
    /* FIXME(macos): DockTile.subproj supplies NSDockTile. */
    return nil;
}

#pragma mark - Activation policy

- (NSApplicationActivationPolicy)activationPolicy
{
    return _activationPolicy;
}

- (BOOL)setActivationPolicy:(NSApplicationActivationPolicy)activationPolicy
{
    _activationPolicy = activationPolicy;
    return YES;
}

#pragma mark - Exceptions and threads

- (void)reportException:(NSException *)exception
{
    /* FIXME(macos): route to a crash-reporting service. Until then, be loud. */
    NSLog(@"NSApplication reported an unhandled exception: %@", exception);
}

+ (void)detachDrawingThread:(SEL)selector toTarget:(id)target withObject:(id)argument
{
    [NSThread detachNewThreadSelector:selector toTarget:target withObject:argument];
}

#pragma mark - Attention requests

- (NSInteger)requestUserAttention:(NSRequestUserAttentionType)requestType
{
    _attentionRequestCount++;
    /* FIXME(macos): bounce the Dock icon / play the attention sound. */
    return _attentionRequestCount;
}

- (void)cancelUserAttentionRequest:(NSInteger)request
{
    /* FIXME(macos). */
}

#pragma mark - Termination

- (void)terminate:(id)sender
{
    NSApplicationTerminateReply reply = NSTerminateNow;
    if (_delegate && [_delegate respondsToSelector:@selector(applicationShouldTerminate:)]) {
        reply = [_delegate applicationShouldTerminate:self];
    }
    if (reply == NSTerminateLater) {
        _shouldTerminateLaterPending = YES;
        return;
    }
    if (reply == NSTerminateCancel) {
        return;
    }
    [self _reallyTerminate];
}

- (void)replyToApplicationShouldTerminate:(BOOL)shouldTerminate
{
    if (!_shouldTerminateLaterPending) {
        return;
    }
    _shouldTerminateLaterPending = NO;
    if (shouldTerminate) {
        [self _reallyTerminate];
    }
}

- (void)_reallyTerminate
{
    if (!_running) {
        return;
    }
    _running = NO;
    if (_modalSession != nil) {
        [_modalSession terminateWithCode:NSModalResponseAbort];
    }
    [[NSNotificationCenter defaultCenter] postNotificationName:NSApplicationWillTerminateNotification object:self];
    if (_delegate && [_delegate respondsToSelector:@selector(applicationWillTerminate:)]) {
        [_delegate applicationWillTerminate:[NSNotification notificationWithName:NSApplicationWillTerminateNotification object:self]];
    }
    [self _postTerminationMarker];
}

- (void)_postTerminationMarker
{
    if (_eventMode == nil) {
        _eventMode = NSDefaultRunLoopMode;
    }
    [self postEvent:[[_NSApplicationTerminationEvent alloc] init] atStart:NO];
}

#pragma mark - Run / stop / modal sessions

- (void)run
{
    _running = YES;
    while (_running) {
        NSEvent *event = [self nextEventMatchingMask:NSAnyEventMask
                                           untilDate:LBSAppKitFarFuture()
                                              inMode:NSDefaultRunLoopMode
                                             dequeue:YES];
        if (event != nil) {
            [self sendEvent:event];
        }
    }
    _running = NO;
    [self discardEventsMatchingMask:NSAnyEventMask beforeEvent:nil];
}

- (BOOL)isRunning
{
    return _running;
}

- (void)stop:(id)sender
{
    if (!_running) {
        return;
    }
    _running = NO;
    [self _postTerminationMarker];
}

- (NSModalSession)beginModalSessionForWindow:(NSWindow *)window
{
    _modalSession = [[_NSModalSessionState alloc] initWithWindow:window];
    return (__bridge NSModalSession)_modalSession;
}

- (NSModalResponse)runModalSession:(NSModalSession)session
{
    _NSModalSessionState *state = (__bridge _NSModalSessionState *)session;
    if (state == nil) {
        return NSModalResponseAbort;
    }
    if ([state isTerminated]) {
        return [state returnCode];
    }
    return NSModalResponseContinue;
}

- (void)endModalSession:(NSModalSession)session
{
    _NSModalSessionState *state = (__bridge _NSModalSessionState *)session;
    if (state == nil) {
        return;
    }
    [state terminateWithCode:NSModalResponseStop];
    if (state == _modalSession) {
        _modalSession = nil;
    }
}

- (void)stopModal
{
    [self stopModalWithCode:NSModalResponseStop];
}

- (void)stopModalWithCode:(NSModalResponse)returnCode
{
    if (_modalSession != nil) {
        [_modalSession terminateWithCode:returnCode];
    }
}

- (void)abortModal
{
    [self stopModalWithCode:NSModalResponseAbort];
}

- (NSWindow *)modalWindow
{
    return (_modalSession != nil) ? [_modalSession window] : nil;
}

- (NSModalResponse)runModalForWindow:(NSWindow *)window
{
    NSModalSession session = [self beginModalSessionForWindow:window];
    NSModalResponse response;
    while ((response = [self runModalSession:session]) == NSModalResponseContinue) {
        NSEvent *event = [self nextEventMatchingMask:NSAnyEventMask
                                           untilDate:LBSAppKitFarFuture()
                                              inMode:NSModalPanelRunLoopMode
                                             dequeue:YES];
        if (event != nil) {
            [self sendEvent:event];
        }
    }
    [self endModalSession:session];
    return response;
}

#pragma mark - Launch

- (void)finishLaunching
{
    if (_finishedLaunching) {
        return;
    }
    _finishedLaunching = YES;

    [[NSNotificationCenter defaultCenter] postNotificationName:NSApplicationWillFinishLaunchingNotification object:self];
    if (_delegate && [_delegate respondsToSelector:@selector(applicationWillFinishLaunching:)]) {
        [_delegate applicationWillFinishLaunching:[NSNotification notificationWithName:NSApplicationWillFinishLaunchingNotification object:self]];
    }

    /* Open files requested at launch time — the NSOpen user default holds
     * the paths a document-based launch should open. */
    BOOL launchedToOpenFiles = NO;
    NSArray<NSString *> *openFiles = [[NSUserDefaults standardUserDefaults] arrayForKey:@"NSOpen"];
    if ([openFiles count] > 0) {
        launchedToOpenFiles = YES;
        [self _openFiles:openFiles];
    }

    /* The untitled-file flow, mirroring AppKit's behavior after launch when
     * no documents were requested. */
    if (!launchedToOpenFiles && [self _delegateApplicationShouldOpenUntitledFile]) {
        [self _delegateApplicationOpenUntitledFile];
    }

    NSDictionary *userInfo = @{ NSApplicationLaunchIsDefaultLaunchKey: @(!launchedToOpenFiles) };
    NSNotification *didLaunch = [NSNotification notificationWithName:NSApplicationDidFinishLaunchingNotification object:self userInfo:userInfo];
    [[NSNotificationCenter defaultCenter] postNotification:didLaunch];
    if (_delegate && [_delegate respondsToSelector:@selector(applicationDidFinishLaunching:)]) {
        [_delegate applicationDidFinishLaunching:didLaunch];
    }
}

- (void)replyToOpenOrPrint:(NSApplicationDelegateReply)reply
{
    /* FIXME(macos): stored for the pending open/print operation. */
}

- (void)orderFrontCharacterPalette:(id)sender
{
    /* FIXME(macos): requires the system character palette. */
}

- (BOOL)applicationShouldSuppressHighDynamicRangeContent
{
    /* FIXME(macos): consult display policy; conservative default is NO. */
    return NO;
}

#pragma mark - Presentation options / occlusion / protected data

- (void)setPresentationOptions:(NSApplicationPresentationOptions)presentationOptions
{
    /* Mirror Apple's validation: the auto-hide and hide groups are mutually
     * exclusive. */
    if ((presentationOptions & (NSApplicationPresentationAutoHideDock | NSApplicationPresentationAutoHideMenuBar)) != 0 &&
        (presentationOptions & (NSApplicationPresentationHideDock | NSApplicationPresentationHideMenuBar)) != 0) {
        [NSException raise:NSInvalidArgumentException
                    format:@"Invalid presentationOptions combination: auto-hide and hide are mutually exclusive."];
    }
    _presentationOptions = presentationOptions;
}

- (NSApplicationPresentationOptions)presentationOptions
{
    return _presentationOptions;
}

- (NSApplicationPresentationOptions)currentSystemPresentationOptions
{
    /* FIXME(macos): merge with the window server's view. */
    return _presentationOptions;
}

- (NSApplicationOcclusionState)occlusionState
{
    return _occlusionState;
}

- (BOOL)isProtectedDataAvailable
{
    return _protectedDataAvailable;
}

#pragma mark - UI validation

- (BOOL)validateUserInterfaceItem:(id<NSValidatedUserInterfaceItem>)item
{
    SEL action = [item action];
    if (action == NULL) {
        return YES;
    }
    id target = [self targetForAction:action to:nil from:(id)item];
    if (target == nil) {
        return NO;
    }
    if ([target respondsToSelector:@selector(validateUserInterfaceItem:)]) {
        return [target validateUserInterfaceItem:item];
    }
    return YES;
}

- (BOOL)validateMenuItem:(NSMenuItem *)menuItem
{
    SEL action = [(id)menuItem action];
    if (action == NULL) {
        return YES;
    }
    id target = [self targetForAction:action to:nil from:menuItem];
    if (target == nil) {
        return NO;
    }
    if ([target respondsToSelector:@selector(validateMenuItem:)]) {
        return [target validateMenuItem:menuItem];
    }
    if ([target respondsToSelector:@selector(validateUserInterfaceItem:)]) {
        return [target validateUserInterfaceItem:(id)menuItem];
    }
    return YES;
}

#pragma mark - Private helpers

- (NSEvent *)_nextQueuedEventMatchingMask:(NSEventMask)mask inMode:(NSRunLoopMode)mode dequeue:(BOOL)deqFlag
{
    for (NSUInteger i = 0; i < [_eventQueue count]; i++) {
        NSEvent *event = [_eventQueue objectAtIndex:i];
        if (CFStringCompare((CFStringRef)[_eventQueueModes objectAtIndex:i], (CFStringRef)mode, 0) != kCFCompareEqualTo) {
            continue;
        }
        NSEventType type = [event type];
        if ((mask & NSEventMaskFromType(type)) == 0) {
            continue;
        }
        if (deqFlag) {
            [_eventQueue removeObjectAtIndex:i];
            [_eventQueueModes removeObjectAtIndex:i];
        }
        return event;
    }
    return nil;
}

/* The responder that receives events today is the key window's first
 * responder, else the key window itself, else the application. */
- (id)_eventTargetForType:(NSEventType)type
{
    NSWindow *window = _keyWindow;
    if (window == nil) {
        window = _mainWindow;
    }
    if (window == nil) {
        return self;
    }
    if ([(id)window respondsToSelector:@selector(firstResponder)]) {
        id (*getFirstResponder)(id, SEL) = (id (*)(id, SEL))objc_msgSend;
        id firstResponder = getFirstResponder(window, @selector(firstResponder));
        if (firstResponder != nil) {
            return firstResponder;
        }
    }
    return window;
}

- (void)_openURLs:(NSArray<NSURL *> *)urls
{
    if ([_delegate respondsToSelector:@selector(application:openURLs:)]) {
        [_delegate application:self openURLs:urls];
        return;
    }
    NSMutableArray<NSString *> *paths = [NSMutableArray arrayWithCapacity:[urls count]];
    for (NSUInteger i = 0; i < [urls count]; i++) {
        NSString *path = [[urls objectAtIndex:i] path];
        if (path != nil) {
            [paths addObject:path];
        }
    }
    [self _openFiles:paths];
}

- (void)_openFiles:(NSArray<NSString *> *)filenames
{
    if ([filenames count] == 0) {
        return;
    }
    if ([_delegate respondsToSelector:@selector(application:openFiles:)]) {
        [_delegate application:self openFiles:filenames];
        return;
    }
    if ([_delegate respondsToSelector:@selector(application:openFile:)]) {
        for (NSUInteger i = 0; i < [filenames count]; i++) {
            [_delegate application:self openFile:[filenames objectAtIndex:i]];
        }
    }
}

- (BOOL)_delegateApplicationShouldOpenUntitledFile
{
    if (_delegate && [_delegate respondsToSelector:@selector(applicationShouldOpenUntitledFile:)]) {
        return [_delegate applicationShouldOpenUntitledFile:self];
    }
    return YES;
}

- (BOOL)_delegateApplicationOpenUntitledFile
{
    if (_delegate && [_delegate respondsToSelector:@selector(applicationOpenUntitledFile:)]) {
        return [_delegate applicationOpenUntitledFile:self];
    }
    return NO;
}

- (NSArray *)_responderChainFrom:(NSResponder *)start
{
    NSMutableArray *chain = [NSMutableArray array];
    id current = start;
    while (current != nil && [current respondsToSelector:@selector(nextResponder)]) {
        [chain addObject:current];
        current = [current nextResponder];
    }
    return chain;
}

- (void)_dispatchAdd:(id)target forAction:(SEL)action
{
    if (action == NULL || target == nil) {
        return;
    }
    [_dispatchTable addObject:[[_NSActionDispatchEntry alloc] initWithAction:action target:target]];
}

- (void)_dispatchRemove:(id)target forAction:(SEL)action
{
    NSMutableArray *remaining = [NSMutableArray array];
    for (NSUInteger i = 0; i < [_dispatchTable count]; i++) {
        _NSActionDispatchEntry *entry = [_dispatchTable objectAtIndex:i];
        if ([entry target] == target && [entry action] == action) {
            continue;
        }
        [remaining addObject:entry];
    }
    _dispatchTable = remaining;
}

@end

/* ------------------------------------------------------------------ */
/*  NSApplication (LBSWindowPrivate) — window registry + key/main      */
/* ------------------------------------------------------------------ */

@implementation NSApplication (LBSWindowPrivate)

- (void)_lbsRegisterWindow:(NSWindow *)window
{
    if (window != nil && ![_windows containsObject:window]) {
        [_windows addObject:window];
        if (_windowsMenu != nil && [(id)_windowsMenu respondsToSelector:@selector(addItemWithTitle:action:keyEquivalent:)]) {
            /* FIXME(macos): add a Window-menu row once Menu.subproj lands. */
        }
    }
}

- (void)_lbsUnregisterWindow:(NSWindow *)window
{
    if (window != nil) {
        for (NSUInteger i = [_windows count]; i > 0; i--) {
            if ([_windows objectAtIndex:i - 1] == window) {
                [_windows removeObjectAtIndex:i - 1];
                break;
            }
        }
    }
    if (_mainWindow == window) {
        _mainWindow = nil;
    }
    if (_keyWindow == window) {
        _keyWindow = nil;
    }
}

- (void)_lbsSetMainWindow:(NSWindow *)window
{
    _mainWindow = window;
}

- (void)_lbsSetKeyWindow:(NSWindow *)window
{
    _keyWindow = window;
}

@end

/* ------------------------------------------------------------------ */
/*  NSApplication (NSEvent) — event queue and dispatch                 */
/* ------------------------------------------------------------------ */

@implementation NSApplication (NSEvent)

- (void)sendEvent:(NSEvent *)event
{
    if (event == nil || [event isKindOfClass:[_NSApplicationTerminationEvent class]]) {
        return;
    }
    _currentEvent = event;

    NSEventType type = [event type];
    SEL handler = _LBSEActionForEventType(type);
    if (handler == NULL) {
        /* AppKit/system/application-defined events are consumed by the
         * application itself. */
        return;
    }

    NSResponder *target = (NSResponder *)[self _eventTargetForType:type];
    if (target == nil) {
        target = self;
    }
    if ([target respondsToSelector:handler]) {
        [target tryToPerform:handler with:event];
    } else {
        [self noResponderFor:handler];
    }
}

- (void)postEvent:(NSEvent *)event atStart:(BOOL)atStart
{
    if (event == nil) {
        return;
    }
    NSRunLoopMode mode = _eventMode != nil ? _eventMode : NSDefaultRunLoopMode;
    if (atStart) {
        NSMutableArray<NSEvent *> *newEvents = [NSMutableArray arrayWithCapacity:[_eventQueue count] + 1];
        [newEvents addObject:event];
        [newEvents addObjectsFromArray:_eventQueue];
        _eventQueue = newEvents;
        NSMutableArray<NSRunLoopMode> *newModes = [NSMutableArray arrayWithCapacity:[_eventQueueModes count] + 1];
        [newModes addObject:mode];
        [newModes addObjectsFromArray:_eventQueueModes];
        _eventQueueModes = newModes;
    } else {
        [_eventQueue addObject:event];
        [_eventQueueModes addObject:mode];
    }
}

- (NSEvent *)currentEvent
{
    return _currentEvent;
}

- (NSEvent *)nextEventMatchingMask:(NSEventMask)mask untilDate:(NSDate *)expiration inMode:(NSRunLoopMode)mode dequeue:(BOOL)deqFlag
{
    if (mode == nil) {
        mode = NSDefaultRunLoopMode;
    }
    _eventMode = mode;
    NSDate *limit = expiration != nil ? expiration : LBSAppKitFarFuture();

    for (;;) {
        NSEvent *match = [self _nextQueuedEventMatchingMask:mask inMode:mode dequeue:deqFlag];
        if (match != nil) {
            _currentEvent = match;
            return match;
        }
        /* No queued event matches: give the run loop a chance to deliver
         * timers and sources, which may in turn post events. Because LibreDarwin
         * has no server-driven event source yet, every event arrives through
         * -postEvent:, so the wait is bounded and the queue re-polled. */
        NSDate *now = [NSDate date];
        if ([limit timeIntervalSinceDate:now] <= 0.0) {
            return nil;
        }
        NSDate *pollDeadline = limit;
        NSTimeInterval remaining = [limit timeIntervalSinceDate:now];
        if (remaining > 0.05) {
            pollDeadline = [NSDate dateWithTimeIntervalSinceNow:0.05];
        }
        BOOL ran = [[NSRunLoop currentRunLoop] runMode:mode beforeDate:pollDeadline];
        if (!ran) {
            [NSThread sleepForTimeInterval:0.005];
        }
    }
}

- (void)discardEventsMatchingMask:(NSEventMask)mask beforeEvent:(NSEvent *)lastEvent
{
    NSUInteger i = 0;
    while (i < [_eventQueue count]) {
        NSEvent *event = [_eventQueue objectAtIndex:i];
        if (lastEvent != nil && event == lastEvent) {
            break;
        }
        NSEventType type = [event type];
        if ((mask & NSEventMaskFromType(type)) != 0) {
            [_eventQueue removeObjectAtIndex:i];
            [_eventQueueModes removeObjectAtIndex:i];
        } else {
            i++;
        }
    }
}

@end

/* ------------------------------------------------------------------ */
/*  NSApplication (NSResponder) — action dispatch                      */
/* ------------------------------------------------------------------ */

@implementation NSApplication (NSResponder)

- (id)targetForAction:(SEL)action
{
    return [self targetForAction:action to:nil from:nil];
}

- (id)targetForAction:(SEL)action to:(id)target from:(id)sender
{
    if (action == NULL) {
        return nil;
    }
    if (target != nil) {
        return [target respondsToSelector:action] ? target : nil;
    }

    /* 1. The sender and its responder chain. */
    if (sender != nil) {
        NSArray<NSResponder *> *chain = [self _responderChainFrom:(NSResponder *)sender];
        for (NSUInteger ci = 0; ci < [chain count]; ci++) {
            if ([[chain objectAtIndex:ci] respondsToSelector:action]) {
                return [chain objectAtIndex:ci];
            }
        }
        /* 2. The sender's window, and that window's first-responder chain. */
        if ([sender respondsToSelector:@selector(window)]) {
            id (*getWindow)(id, SEL) = (id (*)(id, SEL))objc_msgSend;
            NSWindow *senderWindow = getWindow(sender, @selector(window));
            id (*getFirstResponder)(id, SEL) = (id (*)(id, SEL))objc_msgSend;
            id firstResponder = senderWindow != nil ? getFirstResponder(senderWindow, @selector(firstResponder)) : nil;
            if (senderWindow != nil && [(id)senderWindow respondsToSelector:action]) {
                return senderWindow;
            }
            NSArray<NSResponder *> *chain2 = [self _responderChainFrom:(NSResponder *)firstResponder];
            for (NSUInteger ci = 0; ci < [chain2 count]; ci++) {
                if ([[chain2 objectAtIndex:ci] respondsToSelector:action]) {
                    return [chain2 objectAtIndex:ci];
                }
            }
        }
    }

    /* 3. The key window's chain, then the main window's, then the rest. */
    NSArray<NSWindow *> *ordered = [self windows];
    for (NSUInteger i = 0; i < [ordered count]; i++) {
        NSWindow *window = [ordered objectAtIndex:i];
        if ([(id)window respondsToSelector:action]) {
            return window;
        }
        if ([(id)window respondsToSelector:@selector(firstResponder)]) {
            id (*getFirstResponder)(id, SEL) = (id (*)(id, SEL))objc_msgSend;
            id firstResponder = getFirstResponder(window, @selector(firstResponder));
            NSArray<NSResponder *> *chain2 = [self _responderChainFrom:(NSResponder *)firstResponder];
            for (NSUInteger ci = 0; ci < [chain2 count]; ci++) {
                if ([[chain2 objectAtIndex:ci] respondsToSelector:action]) {
                    return [chain2 objectAtIndex:ci];
                }
            }
        }
    }

    /* 4. The action dispatch table. */
    for (NSUInteger i = 0; i < [_dispatchTable count]; i++) {
        _NSActionDispatchEntry *entry = [_dispatchTable objectAtIndex:i];
        if ([entry action] == action) {
            return [entry target];
        }
    }

    /* 5. The services provider. */
    if (_servicesProvider != nil && [_servicesProvider respondsToSelector:action]) {
        return _servicesProvider;
    }

    return nil;
}

- (BOOL)sendAction:(SEL)action to:(id)target from:(id)sender
{
    if (action == NULL) {
        return NO;
    }
    id resolved = (target != nil) ? target : [self targetForAction:action to:nil from:sender];
    if (resolved == nil) {
        return NO;
    }
    return [resolved tryToPerform:action with:sender];
}

- (BOOL)tryToPerform:(SEL)action with:(id)object
{
    return [super tryToPerform:action with:object];
}

- (id)validRequestorForSendType:(NSPasteboardType)sendType returnType:(NSPasteboardType)returnType
{
    return [super validRequestorForSendType:sendType returnType:returnType];
}

@end

/* ------------------------------------------------------------------ */
/*  NSApplication (NSWindowsMenu)                                       */
/* ------------------------------------------------------------------ */

@implementation NSApplication (NSWindowsMenu)

- (NSMenu *)windowsMenu
{
    return _windowsMenu;
}

- (void)setWindowsMenu:(NSMenu *)windowsMenu
{
    _windowsMenu = windowsMenu;
}

- (void)arrangeInFront:(id)sender
{
    /* FIXME(macos): window ordering. */
}

- (void)removeWindowsItem:(NSWindow *)win
{
    /* FIXME(macos): Window-menu row maintenance awaits Menu.subproj. */
}

- (void)addWindowsItem:(NSWindow *)win title:(NSString *)string filename:(BOOL)isFilename
{
    /* FIXME(macos). */
}

- (void)changeWindowsItem:(NSWindow *)win title:(NSString *)string filename:(BOOL)isFilename
{
    /* FIXME(macos). */
}

- (void)updateWindowsItem:(NSWindow *)win
{
    /* FIXME(macos). */
}

- (void)miniaturizeAll:(id)sender
{
    /* FIXME(macos). */
}

@end

/* ------------------------------------------------------------------ */
/*  NSApplication (NSFullKeyboardAccess)                                */
/* ------------------------------------------------------------------ */

@implementation NSApplication (NSFullKeyboardAccess)

- (BOOL)isFullKeyboardAccessEnabled
{
    return [[NSUserDefaults standardUserDefaults] integerForKey:@"AppleKeyboardUIMode"] >= 2;
}

@end

/* ------------------------------------------------------------------ */
/*  NSApplication (NSServicesMenu)                                      */
/* ------------------------------------------------------------------ */

@implementation NSApplication (NSServicesMenu)

- (NSMenu *)servicesMenu
{
    return _servicesMenu;
}

- (void)setServicesMenu:(NSMenu *)servicesMenu
{
    _servicesMenu = servicesMenu;
}

- (void)registerServicesMenuSendTypes:(NSArray<NSPasteboardType> *)sendTypes returnTypes:(NSArray<NSPasteboardType> *)returnTypes
{
    _serviceSendTypes = [sendTypes copy];
    _serviceReturnTypes = [returnTypes copy];
}

@end

/* ------------------------------------------------------------------ */
/*  NSApplication (NSServicesHandling)                                  */
/* ------------------------------------------------------------------ */

@implementation NSApplication (NSServicesHandling)

- (id)servicesProvider
{
    return _servicesProvider;
}

- (void)setServicesProvider:(id)servicesProvider
{
    _servicesProvider = servicesProvider;
}

@end

/* ------------------------------------------------------------------ */
/*  NSApplication (NSStandardAboutPanel)                                */
/* ------------------------------------------------------------------ */

@implementation NSApplication (NSStandardAboutPanel)

- (void)orderFrontStandardAboutPanel:(id)sender
{
    [self orderFrontStandardAboutPanelWithOptions:@{}];
}

- (void)orderFrontStandardAboutPanelWithOptions:(NSDictionary<NSAboutPanelOptionKey, id> *)optionsDictionary
{
    /* FIXME(macos): an actual About panel needs Window.subproj. */
}

@end

/* ------------------------------------------------------------------ */
/*  NSApplication (NSApplicationLayoutDirection)                        */
/* ------------------------------------------------------------------ */

@implementation NSApplication (NSApplicationLayoutDirection)

- (NSUserInterfaceLayoutDirection)userInterfaceLayoutDirection
{
    return [[NSUserDefaults standardUserDefaults] integerForKey:@"AppleTextDirection"] == 1
        ? NSUserInterfaceLayoutDirectionRightToLeft
        : NSUserInterfaceLayoutDirectionLeftToRight;
}

@end

/* ------------------------------------------------------------------ */
/*  NSApplication (NSRestorableUserInterface)                           */
/* ------------------------------------------------------------------ */

@implementation NSApplication (NSRestorableUserInterface)

- (void)disableRelaunchOnLogin
{
    _relaunchOnLoginCounter++;
}

- (void)enableRelaunchOnLogin
{
    if (_relaunchOnLoginCounter > 0) {
        _relaunchOnLoginCounter--;
    }
}

@end

/* ------------------------------------------------------------------ */
/*  NSApplication (NSRemoteNotifications)                               */
/* ------------------------------------------------------------------ */

@implementation NSApplication (NSRemoteNotifications)

- (void)registerForRemoteNotifications
{
    /* FIXME(macos): a remote-notification daemon must supply the push token. */
    _registeredForRemoteNotifications = YES;
    _remoteNotificationTypes = NSRemoteNotificationTypeBadge | NSRemoteNotificationTypeSound | NSRemoteNotificationTypeAlert;
}

- (void)unregisterForRemoteNotifications
{
    _registeredForRemoteNotifications = NO;
    _remoteNotificationTypes = NSRemoteNotificationTypeNone;
}

- (BOOL)isRegisteredForRemoteNotifications
{
    return _registeredForRemoteNotifications;
}

- (void)registerForRemoteNotificationTypes:(NSRemoteNotificationType)types
{
    [self registerForRemoteNotifications];
    _remoteNotificationTypes = types;
}

- (NSRemoteNotificationType)enabledRemoteNotificationTypes
{
    return _remoteNotificationTypes;
}

@end

/* ------------------------------------------------------------------ */
/*  NSApplication (NSAppearanceCustomization)                           */
/* ------------------------------------------------------------------ */

@implementation NSApplication (NSAppearanceCustomization)

- (NSAppearance *)appearance
{
    return _appearance;
}

- (void)setAppearance:(NSAppearance *)appearance
{
    _appearance = appearance;
}

- (NSAppearance *)effectiveAppearance
{
    /* FIXME(macos): Appearance.subproj supplies the system default. */
    return _appearance != nil ? _appearance : _effectiveAppearance;
}

@end

/* ------------------------------------------------------------------ */
/*  NSApplication (NSDeprecated)                                        */
/* ------------------------------------------------------------------ */

@implementation NSApplication (NSDeprecated)

- (NSModalResponse)runModalForWindow:(NSWindow *)window relativeToWindow:(NSWindow *)docWindow
{
    return [self runModalForWindow:window];
}

- (NSModalSession)beginModalSessionForWindow:(NSWindow *)window relativeToWindow:(NSWindow *)docWindow
{
    return [self beginModalSessionForWindow:window];
}

- (void)application:(NSApplication *)sender printFiles:(NSArray<NSString *> *)filenames
{
    if (_delegate && [_delegate respondsToSelector:@selector(application:printFiles:withSettings:showPrintPanels:)]) {
        [_delegate application:self printFiles:filenames withSettings:@{} showPrintPanels:YES];
    }
}

- (void)beginSheet:(NSWindow *)sheet modalForWindow:(NSWindow *)docWindow modalDelegate:(id)modalDelegate didEndSelector:(SEL)didEndSelector contextInfo:(void *)contextInfo
{
    /* FIXME(macos): sheets need Window.subproj. */
}

- (void)endSheet:(NSWindow *)sheet
{
    [self endSheet:sheet returnCode:NSModalResponseStop];
}

- (void)endSheet:(NSWindow *)sheet returnCode:(NSInteger)returnCode
{
    /* FIXME(macos). */
}

- (NSWindow *)makeWindowsPerform:(SEL)selector inOrder:(BOOL)inOrder
{
    for (NSUInteger i = 0; i < [_windows count]; i++) {
        NSWindow *window = [_windows objectAtIndex:i];
        if ([(id)window respondsToSelector:selector]) {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
            [(id)window performSelector:selector];
#pragma clang diagnostic pop
        }
    }
    return nil;
}

- (NSGraphicsContext *)context
{
    return nil;
}

@end

/* ------------------------------------------------------------------ */
/*  C functions                                                        */
/* ------------------------------------------------------------------ */

int NSApplicationMain(int argc, const char *argv[])
{
    /* FIXME(macos): load the main nib, honor the NSPrincipalClass /
     * NSMainNibFile / NSApplicationDelegateClass Info.plist keys, and build
     * the default menu structure. Headless bootstrap for now. */
    NSApplication *app = [NSApplication sharedApplication];
    [app finishLaunching];
    [app run];
    return 0;
}

BOOL NSApplicationLoad(void)
{
    static BOOL loaded = NO;
    if (!loaded) {
        [NSApplication sharedApplication];
        loaded = YES;
    }
    return YES;
}

BOOL NSShowsServicesMenuItem(NSString *itemName)
{
    return YES;
}

NSInteger NSSetShowsServicesMenuItem(NSString *itemName, BOOL enabled)
{
    return 0;
}

void NSUpdateDynamicServices(void)
{
    /* FIXME(macos): notify the services daemon. */
}

BOOL NSPerformService(NSString *itemName, NSPasteboard *pboard)
{
    /* FIXME(macos): requires the services registry. */
    return NO;
}

void NSRegisterServicesProvider(id provider, NSServiceProviderName name)
{
    /* FIXME(macos). */
}

void NSUnregisterServicesProvider(NSServiceProviderName name)
{
    /* FIXME(macos). */
}