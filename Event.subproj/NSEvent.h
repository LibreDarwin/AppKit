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

/* NSEvent.h — minimal seed for LibreDarwin's AppKit reimplementation.
 * This is a deliberately small first slice of the public NSEvent interface:
 * just enough surface for NSResponder and friends to compile against. The
 * rest of NSEvent (event subclasses, NSEventType, NSEventModifierFlags,
 * window/coordinates, etc.) lands with Event.subproj. The constants below
 * are ABI-mandated values that must not change. */
#ifndef _NSEVENT_H
#define _NSEVENT_H

#import <Foundation/NSObject.h>

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

@interface NSEvent : NSObject
@end

#endif /* _NSEVENT_H */