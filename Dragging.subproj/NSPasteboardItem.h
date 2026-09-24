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

/* NSPasteboardItem.h — item-based pasteboard surface for LibreDarwin's
 * AppKit reimplementation.
 *
 * NSPasteboardItem is AppKit's concrete implementer of both the writing and
 * reading protocols, and it is the object -[NSPasteboard writeObjects:] and
 * -[NSPasteboard readObjectsForClasses:options:] are built around. A single
 * item here carries one representation (one type and its value), which keeps
 * the minimal-Foundation storage simple while preserving the API contract. */

#ifndef _NSPASTEBOARDITEM_H
#define _NSPASTEBOARDITEM_H

#import <Foundation/NSObject.h>
#import <AppKit/NSPasteboard.h>

/* Implemented by objects that can put their contents on a pasteboard. */
@protocol NSPasteboardWriting <NSObject>
@required
/* The types this object can provide on the given pasteboard. */
- (NSArray<NSPasteboardType> *)writableTypesForPasteboard:(NSPasteboard *)pasteboard;
/* A pasteboard property list (data, string, number, date, ...) for type. */
- (id)pasteboardPropertyListForType:(NSPasteboardType)type;
@end

/* Implemented by classes that can reconstruct their contents from a
 * pasteboard. The required methods are class methods; instances are created
 * with -initWithPasteboardPropertyList:ofType:. */
@protocol NSPasteboardReading <NSObject>
@required
/* The types this class can read from the given pasteboard. */
+ (NSArray<NSPasteboardType> *)readableTypesForPasteboard:(NSPasteboard *)pasteboard;
@optional
/* Reconstruct an instance from a pasteboard property list. */
- (instancetype)initWithPasteboardPropertyList:(id)propertyList ofType:(NSPasteboardType)type;
@end

@interface NSPasteboardItem : NSObject <NSPasteboardWriting, NSPasteboardReading>

@property (readonly, copy) NSArray<NSPasteboardType> *types;

- (NSData *)dataForType:(NSPasteboardType)type;
- (NSString *)stringForType:(NSPasteboardType)type;
- (id)propertyListForType:(NSPasteboardType)type;

- (BOOL)setData:(NSData *)data forType:(NSPasteboardType)type;
- (BOOL)setString:(NSString *)string forType:(NSPasteboardType)type;
- (BOOL)setPropertyList:(id)propertyList forType:(NSPasteboardType)type;

@end

#endif /* _NSPASTEBOARDITEM_H */