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

/* NSEvent.h — LibreDarwin reimplementation of Apple's AppKit NSEvent.h.
 * The constants below are ABI-mandated values (event type ids, event-mask
 * bits, device-independent modifier-flag bits, and the function-key
 * unicodes) and must not change; sources written against the system AppKit
 * depend on them. Availability annotations are recorded in comments rather
 * than spelled with macros. The NSEvent class interface carries only the
 * accessors the framework needs at compile time today; the full event
 * surface lands with Event.subproj. */
#ifndef _NSEVENT_H
#define _NSEVENT_H

#import <Foundation/NSDate.h>
#import <Foundation/NSGeometry.h>
#import <Foundation/NSObject.h>

@class NSWindow, NSGraphicsContext, NSTrackingArea;

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSInteger, NSEventGestureAxis) {
    NSEventGestureAxisNone = 0,
    NSEventGestureAxisHorizontal = 1,
    NSEventGestureAxisVertical = 2,
};

/* Function-key character constants (Unicode private-use block F700..F747).
 * These are ABI-mandated page-up/down/arrow/function-key unicodes. */
enum {
    NSUpArrowFunctionKey = 0xF700,
    NSDownArrowFunctionKey = 0xF701,
    NSLeftArrowFunctionKey = 0xF702,
    NSRightArrowFunctionKey = 0xF703,
    NSF1FunctionKey = 0xF704,
    NSF2FunctionKey = 0xF705,
    NSF3FunctionKey = 0xF706,
    NSF4FunctionKey = 0xF707,
    NSF5FunctionKey = 0xF708,
    NSF6FunctionKey = 0xF709,
    NSF7FunctionKey = 0xF70A,
    NSF8FunctionKey = 0xF70B,
    NSF9FunctionKey = 0xF70C,
    NSF10FunctionKey = 0xF70D,
    NSF11FunctionKey = 0xF70E,
    NSF12FunctionKey = 0xF70F,
    NSF13FunctionKey = 0xF710,
    NSF14FunctionKey = 0xF711,
    NSF15FunctionKey = 0xF712,
    NSF16FunctionKey = 0xF713,
    NSF17FunctionKey = 0xF714,
    NSF18FunctionKey = 0xF715,
    NSF19FunctionKey = 0xF716,
    NSF20FunctionKey = 0xF717,
    NSF21FunctionKey = 0xF718,
    NSF22FunctionKey = 0xF719,
    NSF23FunctionKey = 0xF71A,
    NSF24FunctionKey = 0xF71B,
    NSF25FunctionKey = 0xF71C,
    NSF26FunctionKey = 0xF71D,
    NSF27FunctionKey = 0xF71E,
    NSF28FunctionKey = 0xF71F,
    NSF29FunctionKey = 0xF720,
    NSF30FunctionKey = 0xF721,
    NSF31FunctionKey = 0xF722,
    NSF32FunctionKey = 0xF723,
    NSF33FunctionKey = 0xF724,
    NSF34FunctionKey = 0xF725,
    NSF35FunctionKey = 0xF726,
    NSInsertFunctionKey = 0xF727,
    NSDeleteFunctionKey = 0xF728,
    NSHomeFunctionKey = 0xF729,
    NSEndFunctionKey = 0xF72A,
    NSPageUpFunctionKey = 0xF72B,
    NSPageDownFunctionKey = 0xF72C,
    NSPrintScreenFunctionKey = 0xF72D,
    NSScrollLockFunctionKey = 0xF72E,
    NSPauseFunctionKey = 0xF72F,
    NSSysReqFunctionKey = 0xF730,
    NSBreakFunctionKey = 0xF731,
    NSResetFunctionKey = 0xF732,
    NSStopFunctionKey = 0xF733,
    NSMenuFunctionKey = 0xF734,
    NSUserFunctionKey = 0xF735,
    NSSystemFunctionKey = 0xF736,
    NSPrintFunctionKey = 0xF737,
    NSClearLineFunctionKey = 0xF738,
    NSClearDisplayFunctionKey = 0xF739,
    NSInsertLineFunctionKey = 0xF73A,
    NSDeleteLineFunctionKey = 0xF73B,
    NSInsertCharFunctionKey = 0xF73C,
    NSDeleteCharFunctionKey = 0xF73D,
    NSPrevFunctionKey = 0xF73E,
    NSNextFunctionKey = 0xF73F,
    NSSelectFunctionKey = 0xF740,
    NSExecuteFunctionKey = 0xF741,
    NSUndoFunctionKey = 0xF742,
    NSRedoFunctionKey = 0xF743,
    NSFindFunctionKey = 0xF744,
    NSHelpFunctionKey = 0xF745,
    NSModeSwitchFunctionKey = 0xF747,
};

typedef NS_ENUM(NSUInteger, NSEventType) {        /* various types of events */
    NSEventTypeLeftMouseDown             = 1,
    NSEventTypeLeftMouseUp               = 2,
    NSEventTypeRightMouseDown            = 3,
    NSEventTypeRightMouseUp              = 4,
    NSEventTypeMouseMoved                = 5,
    NSEventTypeLeftMouseDragged          = 6,
    NSEventTypeRightMouseDragged         = 7,
    NSEventTypeMouseEntered              = 8,
    NSEventTypeMouseExited               = 9,
    NSEventTypeKeyDown                   = 10,
    NSEventTypeKeyUp                     = 11,
    NSEventTypeFlagsChanged              = 12,
    NSEventTypeAppKitDefined             = 13,
    NSEventTypeSystemDefined             = 14,
    NSEventTypeApplicationDefined        = 15,
    NSEventTypePeriodic                  = 16,
    NSEventTypeCursorUpdate              = 17,
    NSEventTypeScrollWheel               = 22,
    NSEventTypeTabletPoint               = 23,
    NSEventTypeTabletProximity           = 24,
    NSEventTypeOtherMouseDown            = 25,
    NSEventTypeOtherMouseUp              = 26,
    NSEventTypeOtherMouseDragged         = 27,
    /* The following event types are available on some hardware on 10.5.2 and later */
    NSEventTypeGesture API_AVAILABLE(macos(10.5))       = 29,
    NSEventTypeMagnify API_AVAILABLE(macos(10.5))       = 30,
    NSEventTypeSwipe   API_AVAILABLE(macos(10.5))       = 31,
    NSEventTypeRotate  API_AVAILABLE(macos(10.5))       = 18,
    NSEventTypeBeginGesture API_AVAILABLE(macos(10.5))  = 19,
    NSEventTypeEndGesture API_AVAILABLE(macos(10.5))    = 20,

    NSEventTypeSmartMagnify API_AVAILABLE(macos(10.8)) = 32,
    NSEventTypeQuickLook API_AVAILABLE(macos(10.8)) = 33,

    NSEventTypePressure API_AVAILABLE(macos(10.10.3)) = 34,
    NSEventTypeDirectTouch API_AVAILABLE(macos(10.10)) = 37,

    NSEventTypeChangeMode API_AVAILABLE(macos(10.15)) = 38,

    NSEventTypeMouseCancelled API_AVAILABLE(macos(26.0)) = 40,
};

/* Deprecated 10.12 synonyms for the NSEventType constants. */
static const NSEventType NSLeftMouseDown       = NSEventTypeLeftMouseDown;
static const NSEventType NSLeftMouseUp         = NSEventTypeLeftMouseUp;
static const NSEventType NSRightMouseDown      = NSEventTypeRightMouseDown;
static const NSEventType NSRightMouseUp        = NSEventTypeRightMouseUp;
static const NSEventType NSMouseMoved          = NSEventTypeMouseMoved;
static const NSEventType NSLeftMouseDragged    = NSEventTypeLeftMouseDragged;
static const NSEventType NSRightMouseDragged   = NSEventTypeRightMouseDragged;
static const NSEventType NSMouseEntered        = NSEventTypeMouseEntered;
static const NSEventType NSMouseExited         = NSEventTypeMouseExited;
static const NSEventType NSKeyDown             = NSEventTypeKeyDown;
static const NSEventType NSKeyUp               = NSEventTypeKeyUp;
static const NSEventType NSFlagsChanged        = NSEventTypeFlagsChanged;
static const NSEventType NSAppKitDefined       = NSEventTypeAppKitDefined;
static const NSEventType NSSystemDefined       = NSEventTypeSystemDefined;
static const NSEventType NSApplicationDefined  = NSEventTypeApplicationDefined;
static const NSEventType NSPeriodic            = NSEventTypePeriodic;
static const NSEventType NSCursorUpdate        = NSEventTypeCursorUpdate;
static const NSEventType NSScrollWheel         = NSEventTypeScrollWheel;
static const NSEventType NSTabletPoint         = NSEventTypeTabletPoint;
static const NSEventType NSTabletProximity     = NSEventTypeTabletProximity;
static const NSEventType NSOtherMouseDown      = NSEventTypeOtherMouseDown;
static const NSEventType NSOtherMouseUp        = NSEventTypeOtherMouseUp;
static const NSEventType NSOtherMouseDragged   = NSEventTypeOtherMouseDragged;

/* For APIs introduced in Mac OS X 10.6 and later, this type is used with
 * NS*Mask constants to indicate the events of interest. */
typedef NS_OPTIONS(unsigned long long, NSEventMask) { /* masks for the types of events */
    NSEventMaskLeftMouseDown         = 1ULL << NSEventTypeLeftMouseDown,
    NSEventMaskLeftMouseUp           = 1ULL << NSEventTypeLeftMouseUp,
    NSEventMaskRightMouseDown        = 1ULL << NSEventTypeRightMouseDown,
    NSEventMaskRightMouseUp          = 1ULL << NSEventTypeRightMouseUp,
    NSEventMaskMouseMoved            = 1ULL << NSEventTypeMouseMoved,
    NSEventMaskLeftMouseDragged      = 1ULL << NSEventTypeLeftMouseDragged,
    NSEventMaskRightMouseDragged     = 1ULL << NSEventTypeRightMouseDragged,
    NSEventMaskMouseEntered          = 1ULL << NSEventTypeMouseEntered,
    NSEventMaskMouseExited           = 1ULL << NSEventTypeMouseExited,
    NSEventMaskKeyDown               = 1ULL << NSEventTypeKeyDown,
    NSEventMaskKeyUp                 = 1ULL << NSEventTypeKeyUp,
    NSEventMaskFlagsChanged          = 1ULL << NSEventTypeFlagsChanged,
    NSEventMaskAppKitDefined         = 1ULL << NSEventTypeAppKitDefined,
    NSEventMaskSystemDefined         = 1ULL << NSEventTypeSystemDefined,
    NSEventMaskApplicationDefined    = 1ULL << NSEventTypeApplicationDefined,
    NSEventMaskPeriodic              = 1ULL << NSEventTypePeriodic,
    NSEventMaskCursorUpdate          = 1ULL << NSEventTypeCursorUpdate,
    NSEventMaskScrollWheel           = 1ULL << NSEventTypeScrollWheel,
    NSEventMaskTabletPoint           = 1ULL << NSEventTypeTabletPoint,
    NSEventMaskTabletProximity       = 1ULL << NSEventTypeTabletProximity,
    NSEventMaskOtherMouseDown        = 1ULL << NSEventTypeOtherMouseDown,
    NSEventMaskOtherMouseUp          = 1ULL << NSEventTypeOtherMouseUp,
    NSEventMaskOtherMouseDragged     = 1ULL << NSEventTypeOtherMouseDragged,
    /* The following event masks are available on some hardware on 10.5.2 and later */
    NSEventMaskGesture API_AVAILABLE(macos(10.5))          = 1ULL << NSEventTypeGesture,
    NSEventMaskMagnify API_AVAILABLE(macos(10.5))          = 1ULL << NSEventTypeMagnify,
    NSEventMaskSwipe API_AVAILABLE(macos(10.5))            = 1ULL << NSEventTypeSwipe,
    NSEventMaskRotate API_AVAILABLE(macos(10.5))           = 1ULL << NSEventTypeRotate,
    NSEventMaskBeginGesture API_AVAILABLE(macos(10.5))     = 1ULL << NSEventTypeBeginGesture,
    NSEventMaskEndGesture API_AVAILABLE(macos(10.5))       = 1ULL << NSEventTypeEndGesture,

    /* Note: You can only use these event masks on 64 bit. In other words,
     * you cannot setup a local, nor global, event monitor for these event
     * types on 32 bit. Also, you cannot search the event queue for them
     * (nextEventMatchingMask:...) on 32 bit. */
    NSEventMaskSmartMagnify API_AVAILABLE(macos(10.8)) = 1ULL << NSEventTypeSmartMagnify,
    NSEventMaskPressure API_AVAILABLE(macos(10.10.3)) = 1ULL << NSEventTypePressure,
    NSEventMaskDirectTouch API_AVAILABLE(macos(10.12.2)) = 1ULL << NSEventTypeDirectTouch,

    NSEventMaskChangeMode API_AVAILABLE(macos(10.15)) = 1ULL << NSEventTypeChangeMode,

    NSEventMaskMouseCancelled API_AVAILABLE(macos(26.0)) = 1ULL << NSEventTypeMouseCancelled,

    NSEventMaskAny              = NSUIntegerMax,
};

/* Deprecated 10.12 synonyms for the NSEventMask constants. */
static const NSEventMask NSLeftMouseDownMask       = NSEventMaskLeftMouseDown;
static const NSEventMask NSLeftMouseUpMask         = NSEventMaskLeftMouseUp;
static const NSEventMask NSRightMouseDownMask      = NSEventMaskRightMouseDown;
static const NSEventMask NSRightMouseUpMask        = NSEventMaskRightMouseUp;
static const NSEventMask NSMouseMovedMask          = NSEventMaskMouseMoved;
static const NSEventMask NSLeftMouseDraggedMask    = NSEventMaskLeftMouseDragged;
static const NSEventMask NSRightMouseDraggedMask   = NSEventMaskRightMouseDragged;
static const NSEventMask NSMouseEnteredMask        = NSEventMaskMouseEntered;
static const NSEventMask NSMouseExitedMask         = NSEventMaskMouseExited;
static const NSEventMask NSKeyDownMask             = NSEventMaskKeyDown;
static const NSEventMask NSKeyUpMask               = NSEventMaskKeyUp;
static const NSEventMask NSFlagsChangedMask        = NSEventMaskFlagsChanged;
static const NSEventMask NSAppKitDefinedMask       = NSEventMaskAppKitDefined;
static const NSEventMask NSSystemDefinedMask       = NSEventMaskSystemDefined;
static const NSEventMask NSApplicationDefinedMask  = NSEventMaskApplicationDefined;
static const NSEventMask NSPeriodicMask            = NSEventMaskPeriodic;
static const NSEventMask NSCursorUpdateMask        = NSEventMaskCursorUpdate;
static const NSEventMask NSScrollWheelMask         = NSEventMaskScrollWheel;
static const NSEventMask NSTabletPointMask         = NSEventMaskTabletPoint;
static const NSEventMask NSTabletProximityMask     = NSEventMaskTabletProximity;
static const NSEventMask NSOtherMouseDownMask      = NSEventMaskOtherMouseDown;
static const NSEventMask NSOtherMouseUpMask        = NSEventMaskOtherMouseUp;
static const NSEventMask NSOtherMouseDraggedMask   = NSEventMaskOtherMouseDragged;
static const NSEventMask NSAnyEventMask            = NSUIntegerMax;

NS_INLINE NSEventMask NSEventMaskFromType(NSEventType type) { return (1UL << type); }

/* Device-independent bits found in event modifier flags */
typedef NS_OPTIONS(NSUInteger, NSEventModifierFlags) {
    NSEventModifierFlagCapsLock           = 1 << 16, // Set if Caps Lock key is pressed.
    NSEventModifierFlagShift              = 1 << 17, // Set if Shift key is pressed.
    NSEventModifierFlagControl            = 1 << 18, // Set if Control key is pressed.
    NSEventModifierFlagOption             = 1 << 19, // Set if Option or Alternate key is pressed.
    NSEventModifierFlagCommand            = 1 << 20, // Set if Command key is pressed.
    NSEventModifierFlagNumericPad         = 1 << 21, // Set if any key in the numeric keypad is pressed.
    NSEventModifierFlagHelp               = 1 << 22, // Set if the Help key is pressed.
    NSEventModifierFlagFunction           = 1 << 23, // Set if any function key is pressed.

    // Used to retrieve only the device-independent modifier flags, allowing
    // applications to mask off the device-dependent modifier flags,
    // including event coalescing information.
    NSEventModifierFlagDeviceIndependentFlagsMask    = 0xffff0000UL
};

/* Deprecated 10.12 synonyms for the NSEventModifierFlags constants. */
static const NSEventModifierFlags NSAlphaShiftKeyMask                   = NSEventModifierFlagCapsLock;
static const NSEventModifierFlags NSShiftKeyMask                        = NSEventModifierFlagShift;
static const NSEventModifierFlags NSControlKeyMask                      = NSEventModifierFlagControl;
static const NSEventModifierFlags NSAlternateKeyMask                    = NSEventModifierFlagOption;
static const NSEventModifierFlags NSCommandKeyMask                      = NSEventModifierFlagCommand;
static const NSEventModifierFlags NSNumericPadKeyMask                   = NSEventModifierFlagNumericPad;
static const NSEventModifierFlags NSHelpKeyMask                         = NSEventModifierFlagHelp;
static const NSEventModifierFlags NSFunctionKeyMask                     = NSEventModifierFlagFunction;
static const NSEventModifierFlags NSDeviceIndependentModifierFlagsMask  = NSEventModifierFlagDeviceIndependentFlagsMask;

/* Gesture momentum and scroll phases (macos 10.7); a bitmask so several can
 * be reported at once. */
typedef NS_OPTIONS(NSUInteger, NSEventPhase) {
    NSEventPhaseNone        = 0x0,
    NSEventPhaseBegan       = 0x1 << 0,
    NSEventPhaseStationary  = 0x1 << 1,
    NSEventPhaseChanged     = 0x1 << 2,
    NSEventPhaseEnded       = 0x1 << 3,
    NSEventPhaseCancelled   = 0x1 << 4,
    NSEventPhaseMayBegin    = 0x1 << 5,
};

/* Event objects are created with the factory methods below, matching the
 * system AppKit. All accessors are plain stored values (there is no window
 * server or input backend yet), so the full mouse/key/other surface is
 * available to framework code and tests immediately. */
@interface NSEvent : NSObject

@property (readonly) NSEventType type;
@property (nullable, readonly, unsafe_unretained) NSWindow *window;
@property (readonly) NSInteger windowNumber;
@property (readonly) NSEventModifierFlags modifierFlags;
@property (readonly) NSPoint locationInWindow;
@property (nullable, readonly, copy) NSString *characters;
@property (nullable, readonly, copy) NSString *charactersIgnoringModifiers;
@property (getter=isARepeat, readonly) BOOL aRepeat;
@property (readonly) unsigned short keyCode;
@property (readonly) NSInteger clickCount;
@property (readonly) NSInteger buttonNumber;
@property (readonly) float pressure;
@property (readonly) NSTimeInterval timestamp;
@property (readonly) NSInteger eventNumber;
@property (readonly) short subtype;
@property (readonly) CGFloat deltaX;
@property (readonly) CGFloat deltaY;
@property (readonly) CGFloat deltaZ;
@property (readonly) CGFloat scrollingDeltaX;
@property (readonly) CGFloat scrollingDeltaY;
@property (getter=hasPreciseScrollingDeltas, readonly) BOOL preciseScrollingDeltas;
@property (readonly) NSEventPhase phase;
@property (readonly) NSEventPhase momentumPhase;
@property (readonly, getter=isDirectionInvertedFromDevice) BOOL directionInvertedFromDevice;
@property (readonly) NSInteger data1;
@property (readonly) NSInteger data2;
@property (readonly) NSInteger trackingNumber;
@property (nullable, readonly) void *userData;

+ (NSEvent *)mouseEventWithType:(NSEventType)type
                       location:(NSPoint)location
                  modifierFlags:(NSEventModifierFlags)flags
                      timestamp:(NSTimeInterval)time
                   windowNumber:(NSInteger)windowNum
                        context:(nullable NSGraphicsContext *)context
                    eventNumber:(NSInteger)eventNum
                     clickCount:(NSInteger)clickCount
                       pressure:(float)pressure;

+ (NSEvent *)keyEventWithType:(NSEventType)type
                     location:(NSPoint)location
                modifierFlags:(NSEventModifierFlags)flags
                    timestamp:(NSTimeInterval)time
                 windowNumber:(NSInteger)windowNum
                      context:(nullable NSGraphicsContext *)context
                   characters:(NSString *)chars
      charactersIgnoringModifiers:(NSString *)charsIgnoringModifiers
                    isARepeat:(BOOL)flag
                      keyCode:(unsigned short)code;

+ (NSEvent *)otherEventWithType:(NSEventType)type
                       location:(NSPoint)location
                  modifierFlags:(NSEventModifierFlags)flags
                      timestamp:(NSTimeInterval)time
                   windowNumber:(NSInteger)windowNum
                        context:(nullable NSGraphicsContext *)context
                        subtype:(short)subtype
                          data1:(NSInteger)data1
                          data2:(NSInteger)data2;

+ (NSEvent *)enterExitEventWithType:(NSEventType)type
                           location:(NSPoint)location
                      modifierFlags:(NSEventModifierFlags)flags
                          timestamp:(NSTimeInterval)time
                       windowNumber:(NSInteger)windowNum
                            context:(nullable NSGraphicsContext *)context
                        eventNumber:(NSInteger)eventNum
                     trackingNumber:(NSInteger)trackingNum
                           userData:(nullable void *)userData;

+ (NSEvent *)scrollWheelEventWithTimestamp:(NSTimeInterval)timestamp
                                  location:(NSPoint)location
                             modifierFlags:(NSEventModifierFlags)flags
                                 timestamp:(NSTimeInterval)time
                              windowNumber:(NSInteger)windowNum
                                   context:(nullable NSGraphicsContext *)context
                                    deltaX:(CGFloat)deltaX
                                    deltaY:(CGFloat)deltaY
                                    deltaZ:(CGFloat)deltaZ;

@end

NS_ASSUME_NONNULL_END

#endif /* _NSEVENT_H */