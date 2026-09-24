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

/* NSEvent.m — stored-value event objects.
 *
 * Apple's NSEvent instances are opaque, allocated by the window server's
 * event-creation machinery. LibreDarwin has no such backend yet, so events
 * are plain holders created through the system-parity factory methods below;
 * every value the accessors return is exactly what was stored. This gives
 * NSApplication's queue/dispatch path and NSMenu/NSView hit-testing realistic
 * events to work with today, and the factories keep call sites stable when a
 * true input backend lands. NSEvent is still subclassable for extra
 * custom-event payloads (see NSEventTypeApplicationDefined use in
 * NSApplication's termination marker). */

#import <AppKit/NSEvent.h>
#import <Foundation/NSString.h>

@implementation NSEvent {
    NSEventType _type;
    __unsafe_unretained NSWindow *_window;
    NSInteger _windowNumber;
    NSEventModifierFlags _modifierFlags;
    NSPoint _locationInWindow;
    NSString *_characters;
    NSString *_charactersIgnoringModifiers;
    BOOL _aRepeat;
    unsigned short _keyCode;
    NSInteger _clickCount;
    NSInteger _buttonNumber;
    float _pressure;
    NSTimeInterval _timestamp;
    NSInteger _eventNumber;
    short _subtype;
    CGFloat _deltaX;
    CGFloat _deltaY;
    CGFloat _deltaZ;
    BOOL _directionInvertedFromDevice;
    NSInteger _data1;
    NSInteger _data2;
    NSInteger _trackingNumber;
    void *_userData;
}

+ (NSEvent *)mouseEventWithType:(NSEventType)type
                       location:(NSPoint)location
                  modifierFlags:(NSEventModifierFlags)flags
                      timestamp:(NSTimeInterval)time
                   windowNumber:(NSInteger)windowNum
                        context:(NSGraphicsContext *)context
                    eventNumber:(NSInteger)eventNum
                     clickCount:(NSInteger)clickCount
                       pressure:(float)pressure
{
    (void)context;
    NSEvent *event = [NSEvent new];
    event->_type = type;
    event->_locationInWindow = location;
    event->_modifierFlags = flags;
    event->_timestamp = time;
    event->_windowNumber = windowNum;
    event->_eventNumber = eventNum;
    event->_clickCount = clickCount;
    event->_buttonNumber = (type == NSEventTypeLeftMouseDown || type == NSEventTypeLeftMouseUp) ? 0 : 1;
    event->_pressure = pressure;
    event->_subtype = 0;
    return event;
}

+ (NSEvent *)keyEventWithType:(NSEventType)type
                     location:(NSPoint)location
                modifierFlags:(NSEventModifierFlags)flags
                    timestamp:(NSTimeInterval)time
                 windowNumber:(NSInteger)windowNum
                      context:(NSGraphicsContext *)context
                   characters:(NSString *)chars
      charactersIgnoringModifiers:(NSString *)charsIgnoringModifiers
                    isARepeat:(BOOL)flag
                      keyCode:(unsigned short)code
{
    (void)context;
    NSEvent *event = [NSEvent new];
    event->_type = type;
    event->_locationInWindow = location;
    event->_modifierFlags = flags;
    event->_timestamp = time;
    event->_windowNumber = windowNum;
    event->_characters = [chars copy];
    event->_charactersIgnoringModifiers = [charsIgnoringModifiers copy];
    event->_aRepeat = flag;
    event->_keyCode = code;
    event->_subtype = 0;
    return event;
}

+ (NSEvent *)otherEventWithType:(NSEventType)type
                       location:(NSPoint)location
                  modifierFlags:(NSEventModifierFlags)flags
                      timestamp:(NSTimeInterval)time
                   windowNumber:(NSInteger)windowNum
                        context:(NSGraphicsContext *)context
                        subtype:(short)subtype
                          data1:(NSInteger)data1
                          data2:(NSInteger)data2
{
    (void)context;
    NSEvent *event = [NSEvent new];
    event->_type = type;
    event->_locationInWindow = location;
    event->_modifierFlags = flags;
    event->_timestamp = time;
    event->_windowNumber = windowNum;
    event->_subtype = subtype;
    event->_data1 = data1;
    event->_data2 = data2;
    return event;
}

+ (NSEvent *)enterExitEventWithType:(NSEventType)type
                           location:(NSPoint)location
                      modifierFlags:(NSEventModifierFlags)flags
                          timestamp:(NSTimeInterval)time
                       windowNumber:(NSInteger)windowNum
                            context:(NSGraphicsContext *)context
                        eventNumber:(NSInteger)eventNum
                     trackingNumber:(NSInteger)trackingNum
                           userData:(void *)userData
{
    (void)context;
    NSEvent *event = [NSEvent new];
    event->_type = type;
    event->_locationInWindow = location;
    event->_modifierFlags = flags;
    event->_timestamp = time;
    event->_windowNumber = windowNum;
    event->_eventNumber = eventNum;
    event->_trackingNumber = trackingNum;
    event->_userData = userData;
    /* NSTrackingAreaEnabled (1), mirroring AppKit's enter/exit events. The
     * NSTrackingAreaOptions enum lands with TrackingArea.subproj. */
    event->_subtype = 1;
    return event;
}

/* ----- accessors ------------------------------------------------------ */

- (NSEventType)type {
    return _type;
}

- (NSWindow *)window {
    return _window;
}

- (NSInteger)windowNumber {
    return _windowNumber;
}

- (NSEventModifierFlags)modifierFlags {
    return _modifierFlags;
}

- (NSPoint)locationInWindow {
    return _locationInWindow;
}

- (NSString *)characters {
    return _characters;
}

- (NSString *)charactersIgnoringModifiers {
    return _charactersIgnoringModifiers;
}

- (BOOL)isARepeat {
    return _aRepeat;
}

- (unsigned short)keyCode {
    return _keyCode;
}

- (NSInteger)clickCount {
    return _clickCount;
}

- (NSInteger)buttonNumber {
    return _buttonNumber;
}

- (float)pressure {
    return _pressure;
}

- (NSTimeInterval)timestamp {
    return _timestamp;
}

- (NSInteger)eventNumber {
    return _eventNumber;
}

- (short)subtype {
    return _subtype;
}

- (CGFloat)deltaX {
    return _deltaX;
}

- (CGFloat)deltaY {
    return _deltaY;
}

- (CGFloat)deltaZ {
    return _deltaZ;
}

- (BOOL)isDirectionInvertedFromDevice {
    return _directionInvertedFromDevice;
}

- (NSInteger)data1 {
    return _data1;
}

- (NSInteger)data2 {
    return _data2;
}

- (NSInteger)trackingNumber {
    return _trackingNumber;
}

- (void *)userData {
    return _userData;
}

@end