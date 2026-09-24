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

/* NSPasteboard.h — clipboard interface for LibreDarwin's AppKit
 * reimplementation. Storage is process-local for now (see NSPasteboard.m);
 * the surface mirrors Apple's so a window-server-backed implementation can
 * drop in later. */

#ifndef _NSPASTEBOARD_H
#define _NSPASTEBOARD_H

#import <Foundation/NSObject.h>
#import <Foundation/NSArray.h>
#import <Foundation/NSData.h>
#import <Foundation/NSDictionary.h>
#import <Foundation/NSString.h>
#import <AppKit/AppKitDefines.h>

typedef NSString * NSPasteboardType;
typedef NSString * NSPasteboardName;

@class NSPasteboard, NSPasteboardItem;

/* Pasteboard names. The general, drag, find, font and ruler boards are the
 * named boards AppKit itself queries. */
APPKIT_EXTERN NSPasteboardName const NSPasteboardNameGeneral;
APPKIT_EXTERN NSPasteboardName const NSPasteboardNameDrag;
APPKIT_EXTERN NSPasteboardName const NSPasteboardNameFind;
APPKIT_EXTERN NSPasteboardName const NSPasteboardNameFont;
APPKIT_EXTERN NSPasteboardName const NSPasteboardNameRuler;

/* Standard pasteboard types (UTI-backed, matching Apple's public values). */
APPKIT_EXTERN NSPasteboardType const NSPasteboardTypeString;
APPKIT_EXTERN NSPasteboardType const NSPasteboardTypeRTF;
APPKIT_EXTERN NSPasteboardType const NSPasteboardTypeRTFD;
APPKIT_EXTERN NSPasteboardType const NSPasteboardTypeHTML;
APPKIT_EXTERN NSPasteboardType const NSPasteboardTypeTabularText;
APPKIT_EXTERN NSPasteboardType const NSPasteboardTypeTIFF;
APPKIT_EXTERN NSPasteboardType const NSPasteboardTypePNG;
APPKIT_EXTERN NSPasteboardType const NSPasteboardTypePDF;
APPKIT_EXTERN NSPasteboardType const NSPasteboardTypeURL;
APPKIT_EXTERN NSPasteboardType const NSPasteboardTypeFileURL;

/* Implemented by declared owners of promised types on a pasteboard; every
 * method is optional and consulted via -respondsToSelector:. */
@protocol NSPasteboardOwner <NSObject>
@optional
/* Fill in data for a type promised via -declareTypes:owner:. */
- (void)pasteboard:(NSPasteboard *)sender provideDataForType:(NSPasteboardType)type;
/* Sent when another object declares over this owner's contents. */
- (void)pasteboardChangedOwner:(NSPasteboard *)sender;
@end

@interface NSPasteboard : NSObject

+ (NSPasteboard *)generalPasteboard;
+ (NSPasteboard *)pasteboardWithName:(NSPasteboardName)name;
+ (NSPasteboard *)pasteboardWithUniqueName;

- (NSInteger)changeCount;
- (NSArray<NSPasteboardType> *)types;
- (NSPasteboardType)availableTypeFromArray:(NSArray<NSPasteboardType> *)types;

- (NSData *)dataForType:(NSPasteboardType)type;
- (NSString *)stringForType:(NSPasteboardType)type;
- (id)propertyListForType:(NSPasteboardType)type;

- (NSInteger)clearContents;
- (NSInteger)declareTypes:(NSArray<NSPasteboardType> *)newTypes owner:(id)owner;
- (NSInteger)addTypes:(NSArray<NSPasteboardType> *)newTypes owner:(id)owner;

- (BOOL)setData:(NSData *)data forType:(NSPasteboardType)type;
- (BOOL)setString:(NSString *)string forType:(NSPasteboardType)type;
- (BOOL)setPropertyList:(id)plist forType:(NSPasteboardType)type;

/* Item-based access. writeObjects: takes any objects that implement
 * NSPasteboardWriting; readObjectsForClasses:options: instantiates classes
 * that implement NSPasteboardReading from the board's contents. */
- (BOOL)writeObjects:(NSArray *)objects;
- (NSArray *)readObjectsForClasses:(NSArray<Class> *)classArray options:(NSDictionary *)options;
- (BOOL)canReadObjectForClasses:(NSArray<Class> *)classArray options:(NSDictionary *)options;
- (BOOL)canReadItemWithDataConformingToTypes:(NSArray<NSString *> *)types;

- (NSArray<NSPasteboardItem *> *)pasteboardItems;
- (NSInteger)indexOfPasteboardItem:(NSPasteboardItem *)pasteboardItem;
- (NSPasteboardItem *)pasteboardItemForType:(NSPasteboardType)type;

@end

#endif /* _NSPASTEBOARD_H */