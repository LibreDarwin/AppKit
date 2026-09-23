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

/* NSResponder.h — LibreDarwin reimplementation of Apple's AppKit
 * NSResponder.h. The public interface mirrors the system AppKit header
 * (method names, types, and order) so source written against AppKit and,
 * eventually, the header itself, are drop-in. Availability annotations are
 * recorded in comments rather than spelled with macros. */

#import <Foundation/NSObject.h>
#import <Foundation/NSArray.h>
#import <AppKit/NSEvent.h>
#import <AppKit/NSAccessibilityProtocols.h>
#import <AppKit/NSPasteboard.h>
#import <AppKit/AppKitDefines.h>

@class NSError, NSMenu, NSUndoManager, NSWindow;

NS_ASSUME_NONNULL_BEGIN

@interface NSResponder : NSObject <NSCoding>

- (instancetype)init;
- (nullable instancetype)initWithCoder:(NSCoder *)coder;

@property (nullable, unsafe_unretained) NSResponder *nextResponder;

- (BOOL)tryToPerform:(SEL)action with:(nullable id)object;
- (BOOL)performKeyEquivalent:(NSEvent *)event;
- (nullable id)validRequestorForSendType:(nullable NSPasteboardType)sendType returnType:(nullable NSPasteboardType)returnType;

- (void)mouseDown:(NSEvent *)event;
- (void)rightMouseDown:(NSEvent *)event;
- (void)otherMouseDown:(NSEvent *)event;
- (void)mouseUp:(NSEvent *)event;
- (void)rightMouseUp:(NSEvent *)event;
- (void)otherMouseUp:(NSEvent *)event;
- (void)mouseMoved:(NSEvent *)event;
- (void)mouseDragged:(NSEvent *)event;
- (void)mouseCancelled:(NSEvent *)event; /* macos(26.0) */
- (void)scrollWheel:(NSEvent *)event;
- (void)rightMouseDragged:(NSEvent *)event;
- (void)otherMouseDragged:(NSEvent *)event;
- (void)mouseEntered:(NSEvent *)event;
- (void)mouseExited:(NSEvent *)event;
- (void)keyDown:(NSEvent *)event;
- (void)keyUp:(NSEvent *)event;
- (void)flagsChanged:(NSEvent *)event;
- (void)tabletPoint:(NSEvent *)event;
- (void)tabletProximity:(NSEvent *)event;
- (void)cursorUpdate:(NSEvent *)event;
- (void)magnifyWithEvent:(NSEvent *)event; /* macos(10.7) */
- (void)rotateWithEvent:(NSEvent *)event;  /* macos(10.7) */
- (void)swipeWithEvent:(NSEvent *)event;   /* macos(10.7) */
- (void)beginGestureWithEvent:(NSEvent *)event; /* macos(10.7) */
- (void)endGestureWithEvent:(NSEvent *)event;   /* macos(10.7) */
- (void)smartMagnifyWithEvent:(NSEvent *)event; /* macos(10.8) */
- (void)changeModeWithEvent:(NSEvent *)event;   /* macos(10.15) */
- (void)touchesBeganWithEvent:(NSEvent *)event;   /* macos(10.7) */
- (void)touchesMovedWithEvent:(NSEvent *)event;   /* macos(10.7) */
- (void)touchesEndedWithEvent:(NSEvent *)event;   /* macos(10.7) */
- (void)touchesCancelledWithEvent:(NSEvent *)event; /* macos(10.7) */
- (void)quickLookWithEvent:(NSEvent *)event; /* macos(10.7) */
- (void)pressureChangeWithEvent:(NSEvent *)event; /* macos(10.10.3) */
- (void)contextMenuKeyDown:(NSEvent *)event; /* macos(15.0) */

- (void)noResponderFor:(SEL)eventSelector;
@property (readonly) BOOL acceptsFirstResponder;
- (BOOL)becomeFirstResponder;
- (BOOL)resignFirstResponder;
- (void)interpretKeyEvents:(NSArray<NSEvent *> *)eventArray;
- (void)flushBufferedKeyEvents;
@property (nullable, strong) NSMenu *menu;
- (void)showContextHelp:(nullable id)sender;
- (void)helpRequested:(NSEvent *)eventPtr;
- (BOOL)shouldBeTreatedAsInkEvent:(NSEvent *)event;
- (BOOL)wantsScrollEventsForSwipeTrackingOnAxis:(NSEventGestureAxis)axis;      /* macos(10.7) */
- (BOOL)wantsForwardedScrollEventsForAxis:(NSEventGestureAxis)axis;            /* macos(10.7) */
- (nullable id)supplementalTargetForAction:(SEL)action sender:(nullable id)sender; /* macos(10.7) */

@end

@protocol NSStandardKeyBindingResponding <NSObject>
@optional
- (void)insertText:(id)insertString;
- (void)doCommandBySelector:(SEL)selector;
- (void)moveForward:(nullable id)sender;
- (void)moveRight:(nullable id)sender;
- (void)moveBackward:(nullable id)sender;
- (void)moveLeft:(nullable id)sender;
- (void)moveUp:(nullable id)sender;
- (void)moveDown:(nullable id)sender;
- (void)moveWordForward:(nullable id)sender;
- (void)moveWordBackward:(nullable id)sender;
- (void)moveToBeginningOfLine:(nullable id)sender;
- (void)moveToEndOfLine:(nullable id)sender;
- (void)moveToBeginningOfParagraph:(nullable id)sender;
- (void)moveToEndOfParagraph:(nullable id)sender;
- (void)moveToEndOfDocument:(nullable id)sender;
- (void)moveToBeginningOfDocument:(nullable id)sender;
- (void)pageDown:(nullable id)sender;
- (void)pageUp:(nullable id)sender;
- (void)moveWordRight:(nullable id)sender;
- (void)moveWordLeft:(nullable id)sender;
- (void)moveToLeftEndOfLine:(nullable id)sender;
- (void)moveToRightEndOfLine:(nullable id)sender;
- (void)moveParagraphForward:(nullable id)sender;
- (void)moveParagraphBackward:(nullable id)sender;
- (void)moveBackwardAndModifySelection:(nullable id)sender;
- (void)moveForwardAndModifySelection:(nullable id)sender;
- (void)moveWordForwardAndModifySelection:(nullable id)sender;
- (void)moveWordBackwardAndModifySelection:(nullable id)sender;
- (void)moveUpAndModifySelection:(nullable id)sender;
- (void)moveDownAndModifySelection:(nullable id)sender;
- (void)moveToBeginningOfLineAndModifySelection:(nullable id)sender;
- (void)moveToEndOfLineAndModifySelection:(nullable id)sender;
- (void)moveToBeginningOfParagraphAndModifySelection:(nullable id)sender;
- (void)moveToEndOfParagraphAndModifySelection:(nullable id)sender;
- (void)moveToEndOfDocumentAndModifySelection:(nullable id)sender;
- (void)moveToBeginningOfDocumentAndModifySelection:(nullable id)sender;
- (void)pageDownAndModifySelection:(nullable id)sender;
- (void)pageUpAndModifySelection:(nullable id)sender;
- (void)moveParagraphForwardAndModifySelection:(nullable id)sender;
- (void)moveParagraphBackwardAndModifySelection:(nullable id)sender;
- (void)moveWordRightAndModifySelection:(nullable id)sender;
- (void)moveWordLeftAndModifySelection:(nullable id)sender;
- (void)moveToLeftEndOfLineAndModifySelection:(nullable id)sender;
- (void)moveToRightEndOfLineAndModifySelection:(nullable id)sender;
- (void)scrollPageUp:(nullable id)sender;
- (void)scrollPageDown:(nullable id)sender;
- (void)scrollLineUp:(nullable id)sender;
- (void)scrollLineDown:(nullable id)sender;
- (void)scrollToBeginningOfDocument:(nullable id)sender;
- (void)scrollToEndOfDocument:(nullable id)sender;
- (void)deleteBackward:(nullable id)sender;
- (void)deleteForward:(nullable id)sender;
- (void)deleteWordForward:(nullable id)sender;
- (void)deleteWordBackward:(nullable id)sender;
- (void)deleteToBeginningOfLine:(nullable id)sender;
- (void)deleteToEndOfLine:(nullable id)sender;
- (void)deleteToBeginningOfParagraph:(nullable id)sender;
- (void)deleteToEndOfParagraph:(nullable id)sender;
- (void)deleteToEndOfDocument:(nullable id)sender;
- (void)deleteToBeginningOfDocument:(nullable id)sender;
- (void)transpose:(nullable id)sender;
- (void)transposeWords:(nullable id)sender;
- (void)selectAll:(nullable id)sender;
- (void)selectParagraph:(nullable id)sender;
- (void)selectLine:(nullable id)sender;
- (void)selectWord:(nullable id)sender;
- (void)indent:(nullable id)sender;
- (void)insertTab:(nullable id)sender;
- (void)insertBacktab:(nullable id)sender;
- (void)insertNewline:(nullable id)sender;
- (void)insertNewlineIgnoringFieldEditor:(nullable id)sender;
- (void)insertLineBreak:(nullable id)sender;
- (void)insertContainerBreak:(nullable id)sender;
- (void)insertSingleQuoteIgnoringSubstitution:(nullable id)sender;
- (void)insertDoubleQuoteIgnoringSubstitution:(nullable id)sender;
- (void)cancelOperation:(nullable id)sender;
- (void)capitalizeWord:(nullable id)sender;
- (void)lowercaseWord:(nullable id)sender;
- (void)uppercaseWord:(nullable id)sender;
- (void)delete:(nullable id)sender;
- (void)undo:(nullable id)sender;
- (void)redo:(nullable id)sender;
- (void)showContextMenuForSelection:(nullable id)sender;
@end

@interface NSResponder (NSStandardKeyBindingMethods) <NSStandardKeyBindingResponding>
@end

@interface NSResponder (NSUndoSupport)
@property (nullable, readonly, strong) NSUndoManager *undoManager;
@end

@interface NSResponder (NSControlEditingSupport)
- (BOOL)validateProposedFirstResponder:(NSResponder *)responder forEvent:(nullable NSEvent *)event; /* macos(10.7) */
@end

@interface NSResponder (NSErrorPresentation)
- (void)presentError:(NSError *)error modalForWindow:(NSWindow *)window delegate:(nullable id)delegate didPresentSelector:(nullable SEL)didPresentSelector contextInfo:(nullable void *)contextInfo;
- (BOOL)presentError:(NSError *)error;
- (NSError *)willPresentError:(NSError *)error;
@end

@interface NSResponder (NSTextFinderSupport)
- (void)performTextFinderAction:(nullable id)sender; /* macos(10.7) */
@end

@interface NSResponder (NSWindowTabbing)
- (void)newWindowForTab:(nullable id)sender; /* macos(10.12) */
@end

@interface NSResponder (NSWritingToolsSupport)
- (void)showWritingTools:(nullable id)sender; /* macos(15.2) */
@end

@interface NSResponder (NSDeprecated)
- (BOOL)performMnemonic:(NSString *)string; /* deprecated */
@end

NS_ASSUME_NONNULL_END