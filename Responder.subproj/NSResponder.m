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

/* NSResponder.m — responder chain backbone for LibreDarwin's AppKit.
 *
 * The overriding contract of NSResponder, and of this reimplementation, is
 * the responder chain itself: a message an object can't handle is forwarded
 * to its nextResponder. The default implementations below follow Apple's
 * documented chain semantics, informed by the behavior notes attached to
 * each method. Problem events that reach the end of the chain bounce back
 * through noResponderFor:. */

#import <AppKit/NSResponder.h>
#import <AppKit/NSEvent.h>
#import <AppKit/NSGraphics.h>
#import <Foundation/NSArray.h>
#import <Foundation/NSCoder.h>
#import <Foundation/NSError.h>
#import <Foundation/NSString.h>
#import <objc/message.h>

@implementation NSResponder {
    NSResponder *__unsafe_unretained _nextResponder;
    NSMenu *_menu;
}

- (instancetype)init
{
    if ((self = [super init])) {
        _nextResponder = nil;
        _menu = nil;
    }
    return self;
}

- (nullable instancetype)initWithCoder:(NSCoder *)coder
{
    if ((self = [super init])) {
        _nextResponder = nil;
        _menu = nil;
        if ([coder allowsKeyedCoding]) {
            _nextResponder = [coder decodeObjectForKey:@"NSNextResponder"];
        }
    }
    return self;
}

- (void)encodeWithCoder:(NSCoder *)coder
{
    if ([coder allowsKeyedCoding]) {
        [coder encodeObject:_nextResponder forKey:@"NSNextResponder"];
    }
}

- (NSResponder *)nextResponder
{
    return _nextResponder;
}

- (void)setNextResponder:(NSResponder *)responder
{
    _nextResponder = responder;
}

- (NSMenu *)menu
{
    return _menu;
}

- (void)setMenu:(NSMenu *)menu
{
    _menu = menu;
}

- (BOOL)tryToPerform:(SEL)action with:(id)object
{
    if ([self respondsToSelector:action]) {
        /* performSelector:withObject: trips -Warc-performSelector-leaks; the
         * typed-messaging form keeps ARC happy and matches Apple's own
         * responder-chain trampolines. */
        void (*perform)(id, SEL, id) = (void (*)(id, SEL, id))objc_msgSend;
        perform(self, action, object);
        return YES;
    }
    return [[self nextResponder] tryToPerform:action with:object];
}

- (BOOL)performKeyEquivalent:(NSEvent *)event
{
    return NO;
}

- (id)validRequestorForSendType:(NSPasteboardType)sendType returnType:(NSPasteboardType)returnType
{
    return [[self nextResponder] validRequestorForSendType:sendType returnType:returnType];
}

/* Mouse and tracking events forward up the responder chain. */
- (void)mouseDown:(NSEvent *)event                { [[self nextResponder] mouseDown:event]; }
- (void)rightMouseDown:(NSEvent *)event           { [[self nextResponder] rightMouseDown:event]; }
- (void)otherMouseDown:(NSEvent *)event           { [[self nextResponder] otherMouseDown:event]; }
- (void)mouseUp:(NSEvent *)event                  { [[self nextResponder] mouseUp:event]; }
- (void)rightMouseUp:(NSEvent *)event             { [[self nextResponder] rightMouseUp:event]; }
- (void)otherMouseUp:(NSEvent *)event             { [[self nextResponder] otherMouseUp:event]; }
- (void)mouseMoved:(NSEvent *)event               { [[self nextResponder] mouseMoved:event]; }
- (void)mouseDragged:(NSEvent *)event             { [[self nextResponder] mouseDragged:event]; }
- (void)mouseCancelled:(NSEvent *)event           { [[self nextResponder] mouseCancelled:event]; }
- (void)scrollWheel:(NSEvent *)event              { [[self nextResponder] scrollWheel:event]; }
- (void)rightMouseDragged:(NSEvent *)event        { [[self nextResponder] rightMouseDragged:event]; }
- (void)otherMouseDragged:(NSEvent *)event        { [[self nextResponder] otherMouseDragged:event]; }
- (void)mouseEntered:(NSEvent *)event             { [[self nextResponder] mouseEntered:event]; }
- (void)mouseExited:(NSEvent *)event              { [[self nextResponder] mouseExited:event]; }
- (void)keyDown:(NSEvent *)event                  { [[self nextResponder] keyDown:event]; }
- (void)keyUp:(NSEvent *)event                    { [[self nextResponder] keyUp:event]; }
- (void)flagsChanged:(NSEvent *)event             { [[self nextResponder] flagsChanged:event]; }
- (void)tabletPoint:(NSEvent *)event              { [[self nextResponder] tabletPoint:event]; }
- (void)tabletProximity:(NSEvent *)event          { [[self nextResponder] tabletProximity:event]; }
- (void)cursorUpdate:(NSEvent *)event             { [[self nextResponder] cursorUpdate:event]; }
- (void)magnifyWithEvent:(NSEvent *)event         { [[self nextResponder] magnifyWithEvent:event]; }
- (void)rotateWithEvent:(NSEvent *)event          { [[self nextResponder] rotateWithEvent:event]; }
- (void)swipeWithEvent:(NSEvent *)event           { [[self nextResponder] swipeWithEvent:event]; }
- (void)beginGestureWithEvent:(NSEvent *)event    { [[self nextResponder] beginGestureWithEvent:event]; }
- (void)endGestureWithEvent:(NSEvent *)event      { [[self nextResponder] endGestureWithEvent:event]; }
- (void)smartMagnifyWithEvent:(NSEvent *)event    { [[self nextResponder] smartMagnifyWithEvent:event]; }
- (void)changeModeWithEvent:(NSEvent *)event      { [[self nextResponder] changeModeWithEvent:event]; }
- (void)touchesBeganWithEvent:(NSEvent *)event    { [[self nextResponder] touchesBeganWithEvent:event]; }
- (void)touchesMovedWithEvent:(NSEvent *)event    { [[self nextResponder] touchesMovedWithEvent:event]; }
- (void)touchesEndedWithEvent:(NSEvent *)event    { [[self nextResponder] touchesEndedWithEvent:event]; }
- (void)touchesCancelledWithEvent:(NSEvent *)event { [[self nextResponder] touchesCancelledWithEvent:event]; }
- (void)quickLookWithEvent:(NSEvent *)event       { [[self nextResponder] quickLookWithEvent:event]; }
- (void)pressureChangeWithEvent:(NSEvent *)event  { [[self nextResponder] pressureChangeWithEvent:event]; }
- (void)contextMenuKeyDown:(NSEvent *)event       { [[self nextResponder] contextMenuKeyDown:event]; }

/* An unhandled event whose selector is named by an unmade event method
 * reaches the end of the responder chain here. */
- (void)noResponderFor:(SEL)eventSelector
{
    if (eventSelector == @selector(keyDown:))
        NSBeep();
    /* FIXME(macos): an unhandled mouse event should also flash the menu bar
     * selection; that needs the menu/application subsystem. */
}

- (BOOL)acceptsFirstResponder
{
    return NO;
}

- (BOOL)becomeFirstResponder
{
    return YES;
}

- (BOOL)resignFirstResponder
{
    return YES;
}

/* Key is interpreted by the responder that can act on it (NSView, NSTextView,
 * NSWindow...). At the plain NSResponder level the interpretation machinery
 * has nothing to consume, so the events travel up the chain. */
- (void)interpretKeyEvents:(NSArray<NSEvent *> *)eventArray
{
    /* FIXME(macos): when a key-binding manager exists, resolve each event
     * against the standard key bindings here. Until then, forward. */
    [[self nextResponder] interpretKeyEvents:eventArray];
}

- (void)flushBufferedKeyEvents
{
    /* Buffered hardware events are owned by the window/event subsystems and
     * are flushed there; nothing to do at the plain responder level. */
}

- (void)showContextHelp:(id)sender
{
    [[self nextResponder] showContextHelp:sender];
}

- (void)helpRequested:(NSEvent *)eventPtr
{
    [[self nextResponder] helpRequested:eventPtr];
}

- (BOOL)shouldBeTreatedAsInkEvent:(NSEvent *)event
{
    return NO;
}

- (BOOL)wantsScrollEventsForSwipeTrackingOnAxis:(NSEventGestureAxis)axis
{
    return NO;
}

- (BOOL)wantsForwardedScrollEventsForAxis:(NSEventGestureAxis)axis
{
    return NO;
}

- (id)supplementalTargetForAction:(SEL)action sender:(id)sender
{
    return nil;
}

@end

@implementation NSResponder (NSUndoSupport)

/* The undo manager is provided by the nearest responder in the chain that
 * has one (NSWindow/NSUndoManager wiring); the plain responder simply passes
 * the request upward. */
- (NSUndoManager *)undoManager
{
    return [[self nextResponder] undoManager];
}

@end

@implementation NSResponder (NSControlEditingSupport)

- (BOOL)validateProposedFirstResponder:(NSResponder *)responder forEvent:(NSEvent *)event
{
    NSResponder *next = [self nextResponder];
    if (next == nil)
        return YES;
    return [next validateProposedFirstResponder:responder forEvent:event];
}

@end

@implementation NSResponder (NSErrorPresentation)

- (NSError *)willPresentError:(NSError *)error
{
    return error;
}

- (BOOL)presentError:(NSError *)error
{
    NSError *customized = [self willPresentError:error];
    return [[self nextResponder] presentError:customized];
}

- (void)presentError:(NSError *)error
       modalForWindow:(NSWindow *)window
             delegate:(id)delegate
   didPresentSelector:(SEL)didPresentSelector
          contextInfo:(void *)contextInfo
{
    NSError *customized = [self willPresentError:error];
    [[self nextResponder] presentError:customized
                         modalForWindow:window
                               delegate:delegate
                     didPresentSelector:didPresentSelector
                            contextInfo:contextInfo];
}

@end

@implementation NSResponder (NSTextFinderSupport)

- (void)performTextFinderAction:(id)sender
{
    [[self nextResponder] tryToPerform:_cmd with:sender];
}

@end

@implementation NSResponder (NSWindowTabbing)

- (void)newWindowForTab:(id)sender
{
    [[self nextResponder] tryToPerform:_cmd with:sender];
}

@end

@implementation NSResponder (NSWritingToolsSupport)

- (void)showWritingTools:(id)sender
{
    [[self nextResponder] tryToPerform:_cmd with:sender];
}

@end

@implementation NSResponder (NSDeprecated)

- (BOOL)performMnemonic:(NSString *)string
{
    return NO;
}

@end