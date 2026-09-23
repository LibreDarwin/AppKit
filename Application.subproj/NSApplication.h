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

/* NSApplication.h — LibreDarwin reimplementation of Apple's AppKit
 * NSApplication.h. The public interface mirrors the system AppKit header
 * (method names, types, and order) so sources written against AppKit are
 * drop-in. Availability annotations are recorded in comments rather than
 * spelled with macros. Types that would drag in headers the framework does
 * not have yet (NSAppearance), or that belong to independent class families
 * (NSRunningApplication, NSMenu, NSWindow, NSDockTile, NSImage), are
 * forward-declared and their conformances/surface grow with their own
 * subprojects. */
#ifndef _NSAPPLICATION_H
#define _NSAPPLICATION_H

#import <Foundation/NSArray.h>
#import <Foundation/NSDictionary.h>
#import <Foundation/NSDate.h>
#import <Foundation/NSError.h>
#import <Foundation/NSException.h>
#import <Foundation/NSNotification.h>
#import <Foundation/NSRunLoop.h>
#import <Foundation/NSURL.h>
#import <AppKit/NSResponder.h>
#import <AppKit/AppKitDefines.h>
#import <AppKit/NSUserInterfaceValidation.h>
#import <AppKit/NSUserInterfaceLayout.h>
#import <AppKit/NSPasteboard.h>
#import <AppKit/NSPrintInfo.h>

@protocol NSApplicationDelegate;
@protocol NSUserActivityRestoring;
@class NSGraphicsContext, NSImage, NSMenu, NSWindow;
@class NSDockTile, NSUserActivity, NSRunningApplication, NSAppearance;
@class CKShareMetadata;
@class INIntent;

NS_ASSUME_NONNULL_BEGIN

/* Application activation policy. On Apple's AppKit this enum is
 * NSActivationPolicy from NSRunningApplication.h; seeded here (under the
 * NSApplicationActivationPolicy spelling Apple's NSApplication.h uses) until
 * RunningApplication.subproj lands. */
typedef NS_ENUM(NSInteger, NSApplicationActivationPolicy) {
    NSApplicationActivationPolicyRegular = 0,
    NSApplicationActivationPolicyAccessory = 1,
    NSApplicationActivationPolicyProhibited = 2
};

typedef double NSAppKitVersion;
/* The version of the AppKit framework */
APPKIT_EXTERN const NSAppKitVersion NSAppKitVersionNumber;
static const NSAppKitVersion NSAppKitVersionNumber10_0 = 577;
static const NSAppKitVersion NSAppKitVersionNumber10_1 = 620;
static const NSAppKitVersion NSAppKitVersionNumber10_2 = 663;
static const NSAppKitVersion NSAppKitVersionNumber10_2_3 = 663.6;
static const NSAppKitVersion NSAppKitVersionNumber10_3 = 743;
static const NSAppKitVersion NSAppKitVersionNumber10_3_2 = 743.14;
static const NSAppKitVersion NSAppKitVersionNumber10_3_3 = 743.2;
static const NSAppKitVersion NSAppKitVersionNumber10_3_5 = 743.24;
static const NSAppKitVersion NSAppKitVersionNumber10_3_7 = 743.33;
static const NSAppKitVersion NSAppKitVersionNumber10_3_9 = 743.36;
static const NSAppKitVersion NSAppKitVersionNumber10_4 = 824;
static const NSAppKitVersion NSAppKitVersionNumber10_4_1 = 824.1;
static const NSAppKitVersion NSAppKitVersionNumber10_4_3 = 824.23;
static const NSAppKitVersion NSAppKitVersionNumber10_4_4 = 824.33;
static const NSAppKitVersion NSAppKitVersionNumber10_4_7 = 824.41;
static const NSAppKitVersion NSAppKitVersionNumber10_5 = 949;
static const NSAppKitVersion NSAppKitVersionNumber10_5_2 = 949.27;
static const NSAppKitVersion NSAppKitVersionNumber10_5_3 = 949.33;
static const NSAppKitVersion NSAppKitVersionNumber10_6 = 1038;
static const NSAppKitVersion NSAppKitVersionNumber10_7 = 1138;
static const NSAppKitVersion NSAppKitVersionNumber10_7_2 = 1138.23;
static const NSAppKitVersion NSAppKitVersionNumber10_7_3 = 1138.32;
static const NSAppKitVersion NSAppKitVersionNumber10_7_4 = 1138.47;
static const NSAppKitVersion NSAppKitVersionNumber10_8 = 1187;
static const NSAppKitVersion NSAppKitVersionNumber10_9 = 1265;
static const NSAppKitVersion NSAppKitVersionNumber10_10 = 1343;
static const NSAppKitVersion NSAppKitVersionNumber10_10_2 = 1344;
static const NSAppKitVersion NSAppKitVersionNumber10_10_3 = 1347;
static const NSAppKitVersion NSAppKitVersionNumber10_10_4 = 1348;
static const NSAppKitVersion NSAppKitVersionNumber10_10_5 = 1348;
static const NSAppKitVersion NSAppKitVersionNumber10_10_Max = 1349;
static const NSAppKitVersion NSAppKitVersionNumber10_11 = 1404;
static const NSAppKitVersion NSAppKitVersionNumber10_11_1 = 1404.13;
static const NSAppKitVersion NSAppKitVersionNumber10_11_2 = 1404.34;
static const NSAppKitVersion NSAppKitVersionNumber10_11_3 = 1404.34;
static const NSAppKitVersion NSAppKitVersionNumber10_12 = 1504;
static const NSAppKitVersion NSAppKitVersionNumber10_12_1 = 1504.6;
static const NSAppKitVersion NSAppKitVersionNumber10_12_2 = 1504.76;
static const NSAppKitVersion NSAppKitVersionNumber10_13 = 1561;
static const NSAppKitVersion NSAppKitVersionNumber10_13_1 = 1561.1;
static const NSAppKitVersion NSAppKitVersionNumber10_13_2 = 1561.2;
static const NSAppKitVersion NSAppKitVersionNumber10_13_4 = 1561.4;
static const NSAppKitVersion NSAppKitVersionNumber10_14 = 1671;
static const NSAppKitVersion NSAppKitVersionNumber10_14_1 = 1671.1;
static const NSAppKitVersion NSAppKitVersionNumber10_14_2 = 1671.2;
static const NSAppKitVersion NSAppKitVersionNumber10_14_3 = 1671.3;
static const NSAppKitVersion NSAppKitVersionNumber10_14_4 = 1671.4;
static const NSAppKitVersion NSAppKitVersionNumber10_14_5 = 1671.5;
static const NSAppKitVersion NSAppKitVersionNumber10_15 = 1894;
static const NSAppKitVersion NSAppKitVersionNumber10_15_1 = 1894.1;
static const NSAppKitVersion NSAppKitVersionNumber10_15_2 = 1894.2;
static const NSAppKitVersion NSAppKitVersionNumber10_15_3 = 1894.3;
static const NSAppKitVersion NSAppKitVersionNumber10_15_4 = 1894.4;
static const NSAppKitVersion NSAppKitVersionNumber10_15_5 = 1894.5;
static const NSAppKitVersion NSAppKitVersionNumber10_15_6 = 1894.6;
static const NSAppKitVersion NSAppKitVersionNumber11_0 = 2022;
static const NSAppKitVersion NSAppKitVersionNumber11_1 = 2022.2;
static const NSAppKitVersion NSAppKitVersionNumber11_2 = 2022.3;
static const NSAppKitVersion NSAppKitVersionNumber11_3 = 2022.4;
static const NSAppKitVersion NSAppKitVersionNumber11_4 = 2022.5;
static const NSAppKitVersion NSAppKitVersionNumber11_5 = 2022.6;
static const NSAppKitVersion NSAppKitVersionNumber12_0 = 2113;
static const NSAppKitVersion NSAppKitVersionNumber12_1 = 2113.2;
static const NSAppKitVersion NSAppKitVersionNumber12_2 = 2113.3;
static const NSAppKitVersion NSAppKitVersionNumber12_3 = 2113.4;
static const NSAppKitVersion NSAppKitVersionNumber12_4 = 2113.5;
static const NSAppKitVersion NSAppKitVersionNumber12_5 = 2113.6;
static const NSAppKitVersion NSAppKitVersionNumber13_0 = 2299;
static const NSAppKitVersion NSAppKitVersionNumber13_1 = 2299.3;
static const NSAppKitVersion NSAppKitVersionNumber13_2 = 2299.3;
static const NSAppKitVersion NSAppKitVersionNumber13_3 = 2299.4;
static const NSAppKitVersion NSAppKitVersionNumber13_4 = 2299.5;
static const NSAppKitVersion NSAppKitVersionNumber13_5 = 2299.6;
static const NSAppKitVersion NSAppKitVersionNumber13_6 = 2299.7;
static const NSAppKitVersion NSAppKitVersionNumber14_0 = 2487;
static const NSAppKitVersion NSAppKitVersionNumber14_1 = 2487.2;

/* Modes passed to NSRunLoop */
APPKIT_EXTERN NSRunLoopMode NSModalPanelRunLoopMode;
APPKIT_EXTERN NSRunLoopMode NSEventTrackingRunLoopMode;

/* Pre-defined return values for -runModalFor: and -runModalSession:. The
 * system also reserves all values below these. Other values can be used. */
typedef NSInteger NSModalResponse;
/* Also used as the default response for sheets */
static const NSModalResponse NSModalResponseStop   /* macos(10.9) */ = (-1000);
static const NSModalResponse NSModalResponseAbort  /* macos(10.9) */ = (-1001);
static const NSModalResponse NSModalResponseContinue /* macos(10.9) */ = (-1002);

/* Used with NSRunLoop's -performSelector:target:argument:order:modes:. */
enum {
    NSUpdateWindowsRunLoopOrdering = 500000
};

/* Flags that comprise an application's presentationOptions. */
typedef NS_OPTIONS(NSUInteger, NSApplicationPresentationOptions) {
    NSApplicationPresentationDefault                        = 0,

    /* Dock appears when moused to. */
    NSApplicationPresentationAutoHideDock                   = (1 <<  0),

    /* Dock is entirely unavailable. */
    NSApplicationPresentationHideDock                       = (1 <<  1),

    /* Menu Bar appears when moused to. */
    NSApplicationPresentationAutoHideMenuBar                = (1 <<  2),

    /* Menu Bar is entirely unavailable. */
    NSApplicationPresentationHideMenuBar                    = (1 <<  3),

    /* All Apple menu items are disabled. */
    NSApplicationPresentationDisableAppleMenu               = (1 <<  4),

    /* Cmd+Tab UI is disabled. */
    NSApplicationPresentationDisableProcessSwitching        = (1 <<  5),

    /* Cmd+Opt+Esc panel is disabled. */
    NSApplicationPresentationDisableForceQuit               = (1 <<  6),

    /* PowerKey panel and Restart/Shut Down/Log Out disabled. */
    NSApplicationPresentationDisableSessionTermination      = (1 <<  7),

    /* Application "Hide" menu item is disabled. */
    NSApplicationPresentationDisableHideApplication         = (1 <<  8),

    /* Menu Bar's transparent appearance is disabled. */
    NSApplicationPresentationDisableMenuBarTransparency     = (1 <<  9),

    /* Application is in fullscreen mode. */
    NSApplicationPresentationFullScreen /* macos(10.7) */ = (1 << 10),

    /* Fullscreen window toolbar is detached from window and hides/shows on
     * rollover. May be used only when both NSApplicationPresentationFullScreen
     * is also set. */
    NSApplicationPresentationAutoHideToolbar /* macos(10.7) */ = (1 << 11),

    /* "Shake mouse pointer to locate" is disabled for this application. */
    NSApplicationPresentationDisableCursorLocationAssistance /* macos(10.11.2) */ = (1 << 12)
} /* macos(10.6) */;

typedef NS_OPTIONS(NSUInteger, NSApplicationOcclusionState) {
    /* If set, at least part of any window owned by this application is
     * visible. If not set, all parts of all windows owned by this
     * application are completely occluded. */
    NSApplicationOcclusionStateVisible = 1UL << 1,
} /* macos(10.9) */;

typedef NS_OPTIONS(NSInteger, NSWindowListOptions) {
    /* Onscreen application windows in front to back order. By default,
     * -[NSApp windows] is used. */
    NSWindowListOrderedFrontToBack = (1 << 0),
} /* macos(10.12) */;

/* Information used by the system during modal sessions. */
typedef struct _NSModalSession *NSModalSession;

@interface NSApplication : NSResponder <NSUserInterfaceValidations, NSMenuItemValidation, NSAccessibilityElement, NSAccessibility>

APPKIT_EXTERN __kindof NSApplication * _Null_unspecified NSApp;

@property (class, readonly, strong) __kindof NSApplication *sharedApplication;
@property (nullable, weak) id<NSApplicationDelegate> delegate;

- (void)hide:(nullable id)sender;
- (void)unhide:(nullable id)sender;
- (void)unhideWithoutActivation;
- (nullable NSWindow *)windowWithWindowNumber:(NSInteger)windowNum;

@property (nullable, readonly, weak) NSWindow *mainWindow;
@property (nullable, readonly, weak) NSWindow *keyWindow;
@property (getter=isActive, readonly) BOOL active;
@property (getter=isHidden, readonly) BOOL hidden;
@property (getter=isRunning, readonly) BOOL running;

/* A boolean value indicating whether your application should suppress HDR
 * content based on established policy. Built-in AppKit components such as
 * NSImageView will automatically behave correctly with HDR content. */
@property (readonly) BOOL applicationShouldSuppressHighDynamicRangeContent /* macos(26.0) */;

#pragma mark - Activation and Deactivation

- (void)deactivate;

/* Makes the receiver the active app. If ignoreOtherApps is NO, the app is
 * activated only if no other app is currently active. deprecated */
- (void)activateIgnoringOtherApps:(BOOL)ignoreOtherApps;

/* Makes the receiver the active app, if possible. */
- (void)activate /* macos(14.0) */;

/* Explicitly allows another application to make itself active. */
- (void)yieldActivationToApplication:(nullable NSRunningApplication *)application /* macos(14.0) */;

/* Same as -yieldActivationToApplication:, but the provided bundle identifier
 * does not have to correspond to a currently running application. */
- (void)yieldActivationToApplicationWithBundleIdentifier:(NSString *)bundleIdentifier /* macos(14.0) */;

#pragma mark - Lifecycle

- (void)hideOtherApplications:(nullable id)sender;
- (void)unhideAllApplications:(nullable id)sender;

- (void)finishLaunching;
- (void)run;
- (NSModalResponse)runModalForWindow:(NSWindow *)window;
- (void)stop:(nullable id)sender;
- (void)stopModal;
- (void)stopModalWithCode:(NSModalResponse)returnCode;
- (void)abortModal;
@property (nullable, readonly, strong) NSWindow *modalWindow;
- (NSModalSession)beginModalSessionForWindow:(NSWindow *)window;
- (NSModalResponse)runModalSession:(NSModalSession)session;
- (void)endModalSession:(NSModalSession)session;
- (void)terminate:(nullable id)sender;

typedef NS_ENUM(NSUInteger, NSRequestUserAttentionType) {
    NSCriticalRequest = 0,
    NSInformationalRequest = 10
};

/* Inform the user that this application needs attention - call this method
 * only if your application is not already active. */
- (NSInteger)requestUserAttention:(NSRequestUserAttentionType)requestType;
- (void)cancelUserAttentionRequest:(NSInteger)request;

/* Execute a block for each of the app's windows. Set *stop = YES if desired,
 * to halt the enumeration early. */
- (void)enumerateWindowsWithOptions:(NSWindowListOptions)options usingBlock:(void (NS_NOESCAPE ^)(NSWindow *window, BOOL *stop))block /* macos(10.12) */;

- (void)preventWindowOrdering;
@property (readonly, copy) NSArray<NSWindow *> *windows;
- (void)setWindowsNeedUpdate:(BOOL)needUpdate;
- (void)updateWindows;

@property (nullable, strong) NSMenu *mainMenu;

/* Set or get the Help menu for the app. */
@property (nullable, strong) NSMenu *helpMenu /* macos(10.6) */;

@property (null_resettable, strong) NSImage *applicationIconImage;

/* @return The activation policy of the application. */
- (NSApplicationActivationPolicy)activationPolicy /* macos(10.6) */;

/* Attempts to modify the application's activation policy. */
- (BOOL)setActivationPolicy:(NSApplicationActivationPolicy)activationPolicy /* macos(10.6) */;

@property (readonly, strong) NSDockTile *dockTile /* macos(10.5) */;

- (void)reportException:(NSException *)exception;
+ (void)detachDrawingThread:(SEL)selector toTarget:(id)target withObject:(nullable id)argument;

/* If an application delegate returns NSTerminateLater from
 * -applicationShouldTerminate:, -replyToApplicationShouldTerminate: must be
 * called with YES or NO once the application decides if it can terminate. */
- (void)replyToApplicationShouldTerminate:(BOOL)shouldTerminate;

typedef NS_ENUM(NSUInteger, NSApplicationDelegateReply) {
    NSApplicationDelegateReplySuccess = 0,
    NSApplicationDelegateReplyCancel = 1,
    NSApplicationDelegateReplyFailure = 2
};

/* If an application delegate encounters an error while handling
 * -application:openFiles: or -application:printFiles:,
 * -replyToOpenOrPrint: should be called with NSApplicationDelegateReplyFailure.
 * If the user cancels the operation, NSApplicationDelegateReplyCancel should
 * be used, and if the operation succeeds, NSApplicationDelegateReplySuccess
 * should be used. */
- (void)replyToOpenOrPrint:(NSApplicationDelegateReply)reply;

/* Opens the character palette. */
- (void)orderFrontCharacterPalette:(nullable id)sender;

/* Gets or sets the presentationOptions that should be in effect for the
 * system when this application is the active application. Only certain
 * combinations of NSApplicationPresentationOptions flags are allowed; when
 * given an invalid combination of option flags, -setPresentationOptions:
 * raises an exception. */
@property NSApplicationPresentationOptions presentationOptions /* macos(10.6) */;

/* @return The set of application presentation options that are currently in
 * effect for the system. */
@property (readonly) NSApplicationPresentationOptions currentSystemPresentationOptions /* macos(10.6) */;

@property (readonly) NSApplicationOcclusionState occlusionState /* macos(10.9) */;

@property (readonly, getter=isProtectedDataAvailable) BOOL protectedDataAvailable /* macos(12.0) */;

@end

/* The appearance conformance (NSAppearanceCustomization) lands with
 * Appearance.subproj; the properties are part of the surface today. */
@interface NSApplication (NSAppearanceCustomization)
@property (nullable, strong) NSAppearance *appearance /* macos(10.14) */;
@property (readonly, strong) NSAppearance *effectiveAppearance /* macos(10.14) */;
@end

@interface NSApplication(NSEvent)
- (void)sendEvent:(NSEvent *)event;
- (void)postEvent:(NSEvent *)event atStart:(BOOL)atStart;
@property (nullable, readonly, strong) NSEvent *currentEvent;
- (nullable NSEvent *)nextEventMatchingMask:(NSEventMask)mask untilDate:(nullable NSDate *)expiration inMode:(NSRunLoopMode)mode dequeue:(BOOL)deqFlag;
- (void)discardEventsMatchingMask:(NSEventMask)mask beforeEvent:(nullable NSEvent *)lastEvent;
@end

@interface NSApplication(NSResponder)
- (BOOL)sendAction:(SEL)action to:(nullable id)target from:(nullable id)sender;
- (nullable id)targetForAction:(SEL)action;
- (nullable id)targetForAction:(SEL)action to:(nullable id)target from:(nullable id)sender;
- (BOOL)tryToPerform:(SEL)action with:(nullable id)object;
- (nullable id)validRequestorForSendType:(nullable NSPasteboardType)sendType returnType:(nullable NSPasteboardType)returnType;
@end

@interface NSApplication(NSWindowsMenu)
@property (nullable, strong) NSMenu *windowsMenu;
- (void)arrangeInFront:(nullable id)sender;
- (void)removeWindowsItem:(NSWindow *)win;
- (void)addWindowsItem:(NSWindow *)win title:(NSString *)string filename:(BOOL)isFilename;
- (void)changeWindowsItem:(NSWindow *)win title:(NSString *)string filename:(BOOL)isFilename;
- (void)updateWindowsItem:(NSWindow *)win;
- (void)miniaturizeAll:(nullable id)sender;
@end

@interface NSApplication(NSFullKeyboardAccess)
/* A Boolean value indicating whether keyboard navigation is enabled in
 * System Settings > Keyboard. */
@property (getter=isFullKeyboardAccessEnabled, readonly) BOOL fullKeyboardAccessEnabled /* macos(10.6) */;
@end

/* Return values for -applicationShouldTerminate:. */
typedef NS_ENUM(NSUInteger, NSApplicationTerminateReply) {
    NSTerminateCancel = 0,
    NSTerminateNow = 1,
    NSTerminateLater = 2
};

/* Return values for -application:printFiles:withSettings:showPrintPanels:. */
typedef NS_ENUM(NSUInteger, NSApplicationPrintReply) {
    NSPrintingCancelled = 0,
    NSPrintingSuccess = 1,
    NSPrintingReplyLater = 2,
    NSPrintingFailure = 3
};

@protocol NSApplicationDelegate <NSObject>
@optional
/* Allowable return values are: NSTerminateNow - it is ok to proceed with
 * termination; NSTerminateCancel - the application should not be terminated;
 * NSTerminateLater - it may be ok to proceed with termination later. The
 * application must call -replyToApplicationShouldTerminate: with YES or NO
 * once the answer is known. */
- (NSApplicationTerminateReply)applicationShouldTerminate:(NSApplication *)sender;

/* This will be called for any URLs your application is asked to open. If
 * this is implemented, -application:openFiles: and -application:openFile:
 * will not be called. */
- (void)application:(NSApplication *)application openURLs:(NSArray<NSURL *> *)urls /* macos(10.13) */;

- (BOOL)application:(NSApplication *)sender openFile:(NSString *)filename;
- (void)application:(NSApplication *)sender openFiles:(NSArray<NSString *> *)filenames;
- (BOOL)application:(NSApplication *)sender openTempFile:(NSString *)filename;
- (BOOL)applicationShouldOpenUntitledFile:(NSApplication *)sender;
- (BOOL)applicationOpenUntitledFile:(NSApplication *)sender;
- (BOOL)application:(id)sender openFileWithoutUI:(NSString *)filename;
- (BOOL)application:(NSApplication *)sender printFile:(NSString *)filename;
- (NSApplicationPrintReply)application:(NSApplication *)application printFiles:(NSArray<NSString *> *)fileNames withSettings:(NSDictionary<NSPrintInfoAttributeKey, id> *)printSettings showPrintPanels:(BOOL)showPrintPanels;
- (BOOL)applicationShouldTerminateAfterLastWindowClosed:(NSApplication *)sender;
- (BOOL)applicationShouldHandleReopen:(NSApplication *)sender hasVisibleWindows:(BOOL)hasVisibleWindows;
- (nullable NSMenu *)applicationDockMenu:(NSApplication *)sender;
- (NSError *)application:(NSApplication *)application willPresentError:(NSError *)error;

- (void)application:(NSApplication *)application didRegisterForRemoteNotificationsWithDeviceToken:(NSData *)deviceToken; /* macos(10.7) */
- (void)application:(NSApplication *)application didFailToRegisterForRemoteNotificationsWithError:(NSError *)error; /* macos(10.7) */
- (void)application:(NSApplication *)application didReceiveRemoteNotification:(NSDictionary<NSString *, id> *)userInfo; /* macos(10.7) */

/* Method to opt-in to secure restorable state. */
- (BOOL)applicationSupportsSecureRestorableState:(NSApplication *)app /* macos(12.0) */;

/* @return The object capable of handling the specified intent. */
- (nullable id)application:(NSApplication *)application handlerForIntent:(INIntent *)intent /* macos(12.0) */;

/* Method called by -[NSApplication encodeRestorableStateWithCoder:] to give
 * the delegate a chance to encode any additional state into the NSCoder. */
- (void)application:(NSApplication *)app willEncodeRestorableState:(NSCoder *)coder; /* macos(10.7) */

/* Method called by -[NSApplication restoreStateWithCoder:] to give the
 * delegate a chance to restore its own state. */
- (void)application:(NSApplication *)app didDecodeRestorableState:(NSCoder *)coder; /* macos(10.7) */

#pragma mark - NSUserActivity support

- (BOOL)application:(NSApplication *)application willContinueUserActivityWithType:(NSString *)userActivityType; /* macos(10.10) */
- (BOOL)application:(NSApplication *)application continueUserActivity:(NSUserActivity *)userActivity restorationHandler:(void(^)(NSArray<id<NSUserActivityRestoring>> *restorableObjects))restorationHandler; /* macos(10.10) */
- (void)application:(NSApplication *)application didFailToContinueUserActivityWithType:(NSString *)userActivityType error:(NSError *)error; /* macos(10.10) */
- (void)application:(NSApplication *)application didUpdateUserActivity:(NSUserActivity *)userActivity; /* macos(10.10) */

- (void)application:(NSApplication *)application userDidAcceptCloudKitShareWithMetadata:(CKShareMetadata *)metadata; /* macos(10.12) */

#pragma mark - Key Value Coding support

/* @return YES if the receiving delegate object can respond to key value
 * coding messages for a specific keyed attribute, to-one relationship, or
 * to-many relationship. Return NO otherwise. */
- (BOOL)application:(NSApplication *)sender delegateHandlesKey:(NSString *)key;

#pragma mark - NSMenu system-wide keyboard shortcut localization support

/* This method will be called once during application launch at
 * -[NSApplication finishLaunching]. Return NO if the receiving delegate
 * object wishes to opt-out of system-wide keyboard shortcut localization for
 * all application-supplied menus. */
- (BOOL)applicationShouldAutomaticallyLocalizeKeyEquivalents:(NSApplication *)application /* macos(12.0) */;

#pragma mark - Notifications

- (void)applicationWillFinishLaunching:(NSNotification *)notification;
- (void)applicationDidFinishLaunching:(NSNotification *)notification;
- (void)applicationWillHide:(NSNotification *)notification;
- (void)applicationDidHide:(NSNotification *)notification;
- (void)applicationWillUnhide:(NSNotification *)notification;
- (void)applicationDidUnhide:(NSNotification *)notification;
- (void)applicationWillBecomeActive:(NSNotification *)notification;
- (void)applicationDidBecomeActive:(NSNotification *)notification;
- (void)applicationWillResignActive:(NSNotification *)notification;
- (void)applicationDidResignActive:(NSNotification *)notification;
- (void)applicationWillUpdate:(NSNotification *)notification;
- (void)applicationDidUpdate:(NSNotification *)notification;
- (void)applicationWillTerminate:(NSNotification *)notification;
- (void)applicationDidChangeScreenParameters:(NSNotification *)notification;
- (void)applicationDidChangeOcclusionState:(NSNotification *)notification; /* macos(10.9) */
- (void)applicationProtectedDataWillBecomeUnavailable:(NSNotification *)notification; /* macos(12.0) */
- (void)applicationProtectedDataDidBecomeAvailable:(NSNotification *)notification; /* macos(12.0) */

@end

@interface NSApplication(NSServicesMenu)
@property (nullable, strong) NSMenu *servicesMenu;
- (void)registerServicesMenuSendTypes:(NSArray<NSPasteboardType> *)sendTypes returnTypes:(NSArray<NSPasteboardType> *)returnTypes;
@end

@protocol NSServicesMenuRequestor <NSObject>
@optional
- (BOOL)writeSelectionToPasteboard:(NSPasteboard *)pboard types:(NSArray<NSPasteboardType> *)types;
- (BOOL)readSelectionFromPasteboard:(NSPasteboard *)pboard;
@end

@interface NSApplication(NSServicesHandling)
@property (nullable, strong) id servicesProvider;
@end

/* Optional keys in -orderFrontStandardAboutPanelWithOptions: optionsDictionary. */
typedef NSString * NSAboutPanelOptionKey;

/* NSAttributedString displayed in the info area of the panel. If not
 * specified, contents obtained from "Credits.rtf" (.rtfd, .html) in
 * [NSBundle mainBundle]; if not available, blank. */
APPKIT_EXTERN NSAboutPanelOptionKey const NSAboutPanelOptionCredits /* macos(10.13) */;
/* NSString displayed in place of the default app name. */
APPKIT_EXTERN NSAboutPanelOptionKey const NSAboutPanelOptionApplicationName /* macos(10.13) */;
/* NSImage displayed in place of NSApplicationIcon. */
APPKIT_EXTERN NSAboutPanelOptionKey const NSAboutPanelOptionApplicationIcon /* macos(10.13) */;
/* NSString containing the build version number of the application. */
APPKIT_EXTERN NSAboutPanelOptionKey const NSAboutPanelOptionVersion /* macos(10.13) */;
/* NSString displayed as the marketing version, before the build version. */
APPKIT_EXTERN NSAboutPanelOptionKey const NSAboutPanelOptionApplicationVersion /* macos(10.13) */;

@interface NSApplication(NSStandardAboutPanel)
- (void)orderFrontStandardAboutPanel:(nullable id)sender;
- (void)orderFrontStandardAboutPanelWithOptions:(NSDictionary<NSAboutPanelOptionKey, id> *)optionsDictionary;
@end

#pragma mark - Bi-directional User Interface

@interface NSApplication (NSApplicationLayoutDirection)
@property (readonly) NSUserInterfaceLayoutDirection userInterfaceLayoutDirection /* macos(10.6) */; // Returns the application-wide user interface layout direction.
@end

@interface NSApplication (NSRestorableUserInterface)

/* Disable or reenable relaunching this app on login, if the app was running
 * at the time the user logged out. These methods increment and decrement a
 * counter respectively; if the counter is 0 at the time the user logs out,
 * then the app may be relaunched when the user logs back in. The counter is
 * initially zero, so by default apps are relaunched. These methods are
 * thread safe. */
- (void)disableRelaunchOnLogin /* macos(10.7) */;
- (void)enableRelaunchOnLogin /* macos(10.7) */;
@end

/* Soft deprecated. Please use NSApplication's -registerForRemoteNotifications
 * along with -requestAuthorizationWithOptions: from the UserNotifications
 * framework to specify allowable notification types. */
typedef NS_OPTIONS(NSUInteger, NSRemoteNotificationType) {
    NSRemoteNotificationTypeNone  /* macos(10.7) */ = 0,
    NSRemoteNotificationTypeBadge /* macos(10.7) */ = 1 << 0,
    NSRemoteNotificationTypeSound /* macos(10.8) */ = 1 << 1,
    NSRemoteNotificationTypeAlert /* macos(10.8) */ = 1 << 2,
};

@interface NSApplication (NSRemoteNotifications)
- (void)registerForRemoteNotifications /* macos(10.14) */;
- (void)unregisterForRemoteNotifications /* macos(10.7) */;

/* @return YES if the application is currently registered for remote
 * notifications, taking into account any systemwide settings; doesn't relate
 * to connectivity. */
@property(readonly, getter=isRegisteredForRemoteNotifications) BOOL registeredForRemoteNotifications; /* macos(10.14) */

/* The following are soft deprecated. */
/* Please use -registerForRemoteNotifications above and
 * -requestAuthorizationWithOptions: from the UserNotifications framework. */
- (void)registerForRemoteNotificationTypes:(NSRemoteNotificationType)types; /* macos(10.7) */
@property (readonly) NSRemoteNotificationType enabledRemoteNotificationTypes; /* macos(10.7) */
@end

/* An Application's startup function. */
APPKIT_EXTERN int NSApplicationMain(int argc, const char *_Nonnull argv[_Nonnull]);

/* NSApplicationLoad should be called when loading a Cocoa bundle in a Carbon
 * app in order to initialize NSApplication and other Cocoa objects. Redundant
 * calls are ignored. */
APPKIT_EXTERN BOOL NSApplicationLoad(void);

/* NSShowsServicesMenuItem() always returns YES.
 * NSSetShowsServicesMenuItem() has no effect, and always returns 0. */
APPKIT_EXTERN BOOL NSShowsServicesMenuItem(NSString *itemName);
APPKIT_EXTERN NSInteger NSSetShowsServicesMenuItem(NSString *itemName, BOOL enabled);

/* NSUpdateDynamicServices() causes the services information for the system
 * to be updated. */
APPKIT_EXTERN void NSUpdateDynamicServices(void);
APPKIT_EXTERN BOOL NSPerformService(NSString *itemName, NSPasteboard * _Nullable pboard);

typedef NSString * NSServiceProviderName;

/* Apps should use -setServicesProvider. */
APPKIT_EXTERN void NSRegisterServicesProvider(id _Nullable provider, NSServiceProviderName name);
APPKIT_EXTERN void NSUnregisterServicesProvider(NSServiceProviderName name);

#pragma mark - Notification Names

APPKIT_EXTERN NSNotificationName NSApplicationDidBecomeActiveNotification;
APPKIT_EXTERN NSNotificationName NSApplicationDidHideNotification;
APPKIT_EXTERN NSNotificationName NSApplicationDidFinishLaunchingNotification;
APPKIT_EXTERN NSNotificationName NSApplicationDidResignActiveNotification;
APPKIT_EXTERN NSNotificationName NSApplicationDidUnhideNotification;
APPKIT_EXTERN NSNotificationName NSApplicationDidUpdateNotification;
APPKIT_EXTERN NSNotificationName NSApplicationWillBecomeActiveNotification;
APPKIT_EXTERN NSNotificationName NSApplicationWillHideNotification;
APPKIT_EXTERN NSNotificationName NSApplicationWillFinishLaunchingNotification;
APPKIT_EXTERN NSNotificationName NSApplicationWillResignActiveNotification;
APPKIT_EXTERN NSNotificationName NSApplicationWillUnhideNotification;
APPKIT_EXTERN NSNotificationName NSApplicationWillUpdateNotification;
APPKIT_EXTERN NSNotificationName NSApplicationWillTerminateNotification;
APPKIT_EXTERN NSNotificationName NSApplicationDidChangeScreenParametersNotification;
APPKIT_EXTERN NSNotificationName NSApplicationProtectedDataWillBecomeUnavailableNotification; /* macos(12.0) */
APPKIT_EXTERN NSNotificationName NSApplicationProtectedDataDidBecomeAvailableNotification; /* macos(12.0) */
/* Notifications that tell an app that it should either begin or end
 * suppressing high dynamic range content. */
APPKIT_EXTERN NSNotificationName NSApplicationShouldBeginSuppressingHighDynamicRangeContentNotification; /* macos(26.0) */
APPKIT_EXTERN NSNotificationName NSApplicationShouldEndSuppressingHighDynamicRangeContentNotification; /* macos(26.0) */

#pragma mark - User info keys for NSApplicationDidFinishLaunchingNotification

/* The following key is present in the userInfo of
 * NSApplicationDidFinishLaunchingNotification. Its value is an NSNumber
 * containing a bool. It will be NO if the app was launched to open or print a
 * file, to perform a Service, if the app had saved state that will be
 * restored, or if the app launch was in some other sense not a "default"
 * launch. Otherwise its value will be YES. */
APPKIT_EXTERN NSString * const NSApplicationLaunchIsDefaultLaunchKey; /* macos(10.7) */

/* The following key is present in the userInfo of
 * NSApplicationDidFinishLaunchingNotification. It will be present if your
 * application was launched because a user activated a notification in the
 * Notification Center. Its value is an NSUserNotification object. */
APPKIT_EXTERN NSString * const NSApplicationLaunchUserNotificationKey; /* macos(10.8) */

#pragma mark - Deprecated keys for NSApplicationDidFinishLaunchingNotification

/* NSApplicationLaunchRemoteNotificationKey is unimplemented. Please use
 * NSApplicationLaunchUserNotificationKey instead. */
APPKIT_EXTERN NSString * const NSApplicationLaunchRemoteNotificationKey; /* deprecated macos(10.7,10.8) */

/* Upon receiving this notification, you can query the NSApplication for its
 * occlusion state. */
APPKIT_EXTERN NSNotificationName const NSApplicationDidChangeOcclusionStateNotification; /* macos(10.9) */

#pragma mark - Deprecated Methods

@interface NSApplication (NSDeprecated)

/* Use -[NSWindow beginSheet:completionHandler:] instead. */
- (NSInteger)runModalForWindow:(null_unspecified NSWindow *)window relativeToWindow:(null_unspecified NSWindow *)docWindow; /* deprecated */

/* Use -[NSWindow beginSheet:completionHandler:] instead. */
- (NSModalSession)beginModalSessionForWindow:(null_unspecified NSWindow *)window relativeToWindow:(null_unspecified NSWindow *)docWindow; /* deprecated */

/* Implement -application:printFiles:withSettings:showPrintPanels: in your
 * application delegate instead. */
- (void)application:(null_unspecified NSApplication *)sender printFiles:(null_unspecified NSArray<NSString *> *)filenames; /* deprecated */

enum {
    NSRunStoppedResponse /* deprecated */ = (-1000),
    NSRunAbortedResponse /* deprecated */ = (-1001),
    NSRunContinuesResponse /* deprecated */ = (-1002)
};

/* NSWindow's -beginSheet:completionHandler: and -endSheet:returnCode: should
 * be used instead. */
- (void)beginSheet:(NSWindow *)sheet modalForWindow:(NSWindow *)docWindow modalDelegate:(nullable id)modalDelegate didEndSelector:(nullable SEL)didEndSelector contextInfo:(null_unspecified void *)contextInfo; /* deprecated */
- (void)endSheet:(NSWindow *)sheet; /* deprecated */
- (void)endSheet:(NSWindow *)sheet returnCode:(NSInteger)returnCode; /* deprecated */

- (nullable NSWindow *)makeWindowsPerform:(SEL)selector inOrder:(BOOL)inOrder; /* deprecated */

/* This method always returns nil. If you need access to the current drawing
 * context, use [NSGraphicsContext currentContext] inside of a draw
 * operation. */
@property (nullable, readonly, strong) NSGraphicsContext *context; /* deprecated */

@end

NS_ASSUME_NONNULL_END

#endif /* _NSAPPLICATION_H */