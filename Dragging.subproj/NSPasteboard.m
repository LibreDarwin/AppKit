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

/* NSPasteboard.m — process-local pasteboard storage.
 *
 * Apple's pasteboard lives in the pasteboard server (pboard), so contents
 * survive the owning application. LibreDarwin has no pasteboard daemon yet,
 * so each named board is kept in this process: contents, declared owner and
 * change count. Cross-application copy/paste is a FIXME that a future
 * window-server back end will satisfy — the public surface here remains
 * identical. Within-process behavior (the common case for framework code and
 * day-one applications) is faithful, including lazy provision of promised
 * types through NSPasteboardOwner.
 *
 * Storage is item-based: every representation is an NSPasteboardItem, which
 * is also the concrete driver for -writeObjects: and
 * -readObjectsForClasses:options:. */

#import <AppKit/NSPasteboard.h>
#import <AppKit/NSPasteboardItem.h>
#import <Foundation/NSArray.h>
#import <Foundation/NSData.h>
#import <Foundation/NSString.h>
#import <string.h>

NSPasteboardName const NSPasteboardNameGeneral = @"Apple CFPasteboard general";
NSPasteboardName const NSPasteboardNameDrag = @"Apple CFPasteboard drag";
NSPasteboardName const NSPasteboardNameFind = @"Apple CFPasteboard find";
NSPasteboardName const NSPasteboardNameFont = @"Apple CFPasteboard font";
NSPasteboardName const NSPasteboardNameRuler = @"Apple CFPasteboard ruler";

NSPasteboardType const NSPasteboardTypeString = @"public.utf8-plain-text";
NSPasteboardType const NSPasteboardTypeRTF = @"public.rtf";
NSPasteboardType const NSPasteboardTypeRTFD = @"com.apple.rtfd";
NSPasteboardType const NSPasteboardTypeHTML = @"public.html";
NSPasteboardType const NSPasteboardTypeTabularText = @"public.utf8-tab-separated-values-text";
NSPasteboardType const NSPasteboardTypeTIFF = @"public.tiff";
NSPasteboardType const NSPasteboardTypePNG = @"public.png";
NSPasteboardType const NSPasteboardTypePDF = @"com.adobe.pdf";
NSPasteboardType const NSPasteboardTypeURL = @"public.url";
NSPasteboardType const NSPasteboardTypeFileURL = @"public.file-url";

static NSMutableArray *_lbsNamedPasteboards = nil;
static NSInteger _lbsUniquePasteboardCounter = 0;

/* Stands in for a promised type whose data the owner has not provided yet.
 * NSNull is not exported by the minimal Foundation, so a private singleton
 * is used instead. */
@interface _LBSPasteboardPromiseMarker : NSObject
@end
@implementation _LBSPasteboardPromiseMarker
@end
static _LBSPasteboardPromiseMarker *_lbsPromiseMarker = nil;

@interface NSPasteboardItem (LBSPasteboardInternal)
- (id)_lbsPasteboardValue;
- (void)_lbsSetPasteboardValue:(id)value;
@end

static BOOL _LBSPasteboardTypesEqual(NSString *left, NSString *right);

static BOOL _LBSValueIsPromised(id value)
{
    return value == _lbsPromiseMarker;
}

@implementation NSPasteboard {
    NSPasteboardName _name;
    NSInteger _changeCount;
    NSMutableArray *_items; /* NSPasteboardItem, in declaration order */
    id _owner;
}

+ (void)initialize
{
    if (self == [NSPasteboard class]) {
        if (_lbsNamedPasteboards == nil) {
            _lbsNamedPasteboards = [NSMutableArray array];
        }
        if (_lbsPromiseMarker == nil) {
            _lbsPromiseMarker = [_LBSPasteboardPromiseMarker new];
        }
    }
}

+ (NSPasteboard *)generalPasteboard
{
    return [self pasteboardWithName:NSPasteboardNameGeneral];
}

+ (NSPasteboard *)pasteboardWithName:(NSPasteboardName)name
{
    NSInteger count = (NSInteger)[_lbsNamedPasteboards count];
    for (NSInteger i = 0; i < count; i++) {
        NSPasteboard *candidate = [_lbsNamedPasteboards objectAtIndex:i];
        if (_LBSPasteboardTypesEqual(candidate->_name, name)) {
            return candidate;
        }
    }
    NSPasteboard *pboard = [[self alloc] init];
    pboard->_name = [name copy];
    pboard->_items = [NSMutableArray array];
    [_lbsNamedPasteboards addObject:pboard];
    return pboard;
}

+ (NSPasteboard *)pasteboardWithUniqueName
{
    NSString *name = [NSString stringWithFormat:@"LibreDarwin Pasteboard %ld", (long)++_lbsUniquePasteboardCounter];
    return [self pasteboardWithName:name];
}

- (NSInteger)changeCount
{
    return _changeCount;
}

- (NSArray<NSPasteboardType> *)types
{
    NSInteger count = (NSInteger)[_items count];
    NSMutableArray *result = [NSMutableArray arrayWithCapacity:(NSUInteger)count];
    for (NSInteger i = 0; i < count; i++) {
        NSPasteboardItem *item = [_items objectAtIndex:i];
        NSArray *itemTypes = [item types];
        if ([itemTypes count] > 0) {
            [result addObject:[itemTypes objectAtIndex:0]];
        }
    }
    return result;
}

- (NSPasteboardType)availableTypeFromArray:(NSArray<NSPasteboardType> *)types
{
    NSArray *available = [self types];
    NSInteger requestedCount = (NSInteger)[types count];
    NSInteger availableCount = (NSInteger)[available count];
    for (NSInteger i = 0; i < requestedCount; i++) {
        NSString *requested = [types objectAtIndex:i];
        for (NSInteger j = 0; j < availableCount; j++) {
            if (_LBSPasteboardTypesEqual(requested, [available objectAtIndex:j])) {
                return requested;
            }
        }
    }
    return nil;
}

- (NSData *)dataForType:(NSPasteboardType)type
{
    NSPasteboardItem *item = [self _lbsItemForType:type];
    if (item == nil) {
        return nil;
    }
    id value = [item _lbsPasteboardValue];
    if (_LBSValueIsPromised(value) && _owner != nil
        && [_owner respondsToSelector:@selector(pasteboard:provideDataForType:)]) {
        [_owner pasteboard:self provideDataForType:type];
        value = [item _lbsPasteboardValue];
    }
    if (!_LBSValueIsPromised(value) && [value isKindOfClass:[NSData class]]) {
        return value;
    }
    return nil;
}

- (NSString *)stringForType:(NSPasteboardType)type
{
    NSData *data = [self dataForType:type];
    if (data != nil) {
        return [[NSString alloc] initWithBytes:[data bytes] length:[data length]
                                      encoding:NSUnicodeStringEncoding];
    }
    /* -writeObjects: stores NSPasteboardWriting objects as property lists,
     * so a string source surfaces as an NSString value rather than data. */
    id value = [self propertyListForType:type];
    if ([value isKindOfClass:[NSString class]]) {
        return value;
    }
    return nil;
}

- (id)propertyListForType:(NSPasteboardType)type
{
    NSPasteboardItem *item = [self _lbsItemForType:type];
    if (item == nil) {
        return nil;
    }
    id value = [item _lbsPasteboardValue];
    if (_LBSValueIsPromised(value)) {
        return nil;
    }
    return value;
}

- (NSInteger)clearContents
{
    [_items removeAllObjects];
    _changeCount++;
    return _changeCount;
}

- (NSInteger)declareTypes:(NSArray<NSPasteboardType> *)newTypes owner:(id)owner
{
    NSInteger newCount = (NSInteger)[newTypes count];
    [_items removeAllObjects];
    for (NSInteger i = 0; i < newCount; i++) {
        [self _lbsAddPromisedItemForType:[newTypes objectAtIndex:i]];
    }
    [self _lbsNoteOwnerChangeTo:owner];
    _owner = owner;
    _changeCount++;
    return _changeCount;
}

- (NSInteger)addTypes:(NSArray<NSPasteboardType> *)newTypes owner:(id)owner
{
    NSInteger newCount = (NSInteger)[newTypes count];
    for (NSInteger i = 0; i < newCount; i++) {
        NSPasteboardType type = [newTypes objectAtIndex:i];
        if ([self _lbsItemForType:type] == nil) {
            [self _lbsAddPromisedItemForType:type];
        }
    }
    [self _lbsNoteOwnerChangeTo:owner];
    _owner = owner;
    _changeCount++;
    return _changeCount;
}

- (BOOL)setData:(NSData *)data forType:(NSPasteboardType)type
{
    NSPasteboardItem *item = [self _lbsItemForType:type];
    if (item != nil) {
        [item setData:data forType:type];
    } else {
        item = [NSPasteboardItem new];
        [item setData:data forType:type];
        [_items addObject:item];
    }
    _changeCount++;
    return YES;
}

- (BOOL)setString:(NSString *)string forType:(NSPasteboardType)type
{
    NSData *data = [string dataUsingEncoding:NSUnicodeStringEncoding];
    return (data != nil) ? [self setData:data forType:type] : NO;
}

- (BOOL)setPropertyList:(id)plist forType:(NSPasteboardType)type
{
    NSPasteboardItem *item = [self _lbsItemForType:type];
    if (item != nil) {
        [item setPropertyList:plist forType:type];
    } else {
        item = [NSPasteboardItem new];
        [item setPropertyList:plist forType:type];
        [_items addObject:item];
    }
    _changeCount++;
    return YES;
}

/* ----- item-based access --------------------------------------------- */

- (BOOL)writeObjects:(NSArray *)objects
{
    NSInteger count = (NSInteger)[objects count];
    if (count == 0) {
        return NO;
    }
    [self clearContents];
    for (NSInteger i = 0; i < count; i++) {
        id object = [objects objectAtIndex:i];
        if (![object conformsToProtocol:@protocol(NSPasteboardWriting)]) {
            continue;
        }
        NSArray *writableTypes = [object writableTypesForPasteboard:self];
        NSInteger typeCount = (NSInteger)[writableTypes count];
        for (NSInteger j = 0; j < typeCount; j++) {
            NSPasteboardType type = [writableTypes objectAtIndex:j];
            id propertyList = [object pasteboardPropertyListForType:type];
            if ([propertyList isKindOfClass:[NSData class]]) {
                [self setData:propertyList forType:type];
            } else {
                [self setPropertyList:propertyList forType:type];
            }
        }
    }
    return YES;
}

- (NSArray *)readObjectsForClasses:(NSArray<Class> *)classArray options:(NSDictionary *)options
{
    (void)options;
    NSMutableArray *result = [NSMutableArray array];
    NSInteger classCount = (NSInteger)[classArray count];
    for (NSInteger i = 0; i < classCount; i++) {
        Class objectClass = [classArray objectAtIndex:i];
        if (![objectClass conformsToProtocol:@protocol(NSPasteboardReading)]) {
            continue;
        }
        NSArray *readableTypes = [objectClass readableTypesForPasteboard:self];
        NSInteger typeCount = (NSInteger)[readableTypes count];
        for (NSInteger j = 0; j < typeCount; j++) {
            NSPasteboardType type = [readableTypes objectAtIndex:j];
            id value = [self dataForType:type];
            if (value == nil) {
                value = [self propertyListForType:type];
            }
            if (value == nil) {
                continue;
            }
            id object = [(id)objectClass alloc];
            object = [object initWithPasteboardPropertyList:value ofType:type];
            if (object != nil) {
                [result addObject:object];
            }
        }
    }
    return result;
}

- (BOOL)canReadObjectForClasses:(NSArray<Class> *)classArray options:(NSDictionary *)options
{
    (void)options;
    NSInteger classCount = (NSInteger)[classArray count];
    for (NSInteger i = 0; i < classCount; i++) {
        Class objectClass = [classArray objectAtIndex:i];
        if (![objectClass conformsToProtocol:@protocol(NSPasteboardReading)]) {
            continue;
        }
        NSArray *readableTypes = [objectClass readableTypesForPasteboard:self];
        NSInteger typeCount = (NSInteger)[readableTypes count];
        for (NSInteger j = 0; j < typeCount; j++) {
            if ([self _lbsHasValueForType:[readableTypes objectAtIndex:j]]) {
                return YES;
            }
        }
    }
    return NO;
}

- (BOOL)canReadItemWithDataConformingToTypes:(NSArray<NSString *> *)types
{
    NSInteger count = (NSInteger)[types count];
    for (NSInteger i = 0; i < count; i++) {
        if ([self _lbsItemForType:[types objectAtIndex:i]] != nil) {
            return YES;
        }
    }
    return NO;
}

- (NSArray<NSPasteboardItem *> *)pasteboardItems
{
    return [_items copy];
}

- (NSInteger)indexOfPasteboardItem:(NSPasteboardItem *)pasteboardItem
{
    NSInteger count = (NSInteger)[_items count];
    for (NSInteger i = 0; i < count; i++) {
        if ([_items objectAtIndex:i] == pasteboardItem) {
            return i;
        }
    }
    return NSNotFound;
}

- (NSPasteboardItem *)pasteboardItemForType:(NSPasteboardType)type
{
    return [self _lbsItemForType:type];
}

/* ----- private helpers ------------------------------------------------ */

- (NSPasteboardItem *)_lbsItemForType:(NSPasteboardType)type
{
    NSInteger count = (NSInteger)[_items count];
    for (NSInteger i = 0; i < count; i++) {
        NSPasteboardItem *item = [_items objectAtIndex:i];
        NSArray *itemTypes = [item types];
        if ([itemTypes count] > 0 && _LBSPasteboardTypesEqual(type, [itemTypes objectAtIndex:0])) {
            return item;
        }
    }
    return nil;
}

- (BOOL)_lbsHasValueForType:(NSPasteboardType)type
{
    NSPasteboardItem *item = [self _lbsItemForType:type];
    return item != nil && !_LBSValueIsPromised([item _lbsPasteboardValue]);
}

- (void)_lbsAddPromisedItemForType:(NSPasteboardType)type
{
    NSPasteboardItem *item = [NSPasteboardItem new];
    [item setPropertyList:nil forType:type];
    [item _lbsSetPasteboardValue:_lbsPromiseMarker];
    [_items addObject:item];
}

- (void)_lbsNoteOwnerChangeTo:(id)newOwner
{
    if (newOwner != _owner && _owner != nil
        && [_owner respondsToSelector:@selector(pasteboardChangedOwner:)]) {
        [_owner pasteboardChangedOwner:self];
    }
}

static BOOL _LBSPasteboardTypesEqual(NSString *left, NSString *right)
{
    if (left == right) {
        return YES;
    }
    if (left == nil || right == nil) {
        return NO;
    }
    return strcmp([left UTF8String], [right UTF8String]) == 0;
}

@end

/* Plain-text convenience: on Apple's AppKit, NSString conforms to both
 * NSPasteboardWriting and NSPasteboardReading, so -writeObjects:@[string]
 * and -readObjectsForClasses:@[[NSString class]] options:nil round-trip text
 * without NSPasteboardItem plumbing in application code. */
@interface NSString (LBSPasteboardStringSupport) <NSPasteboardWriting, NSPasteboardReading>
@end

@implementation NSString (LBSPasteboardStringSupport)

- (NSArray<NSPasteboardType> *)writableTypesForPasteboard:(NSPasteboard *)pasteboard
{
    (void)pasteboard;
    return [NSArray arrayWithObjects:&NSPasteboardTypeString count:1];
}

- (id)pasteboardPropertyListForType:(NSPasteboardType)type
{
    (void)type;
    return self;
}

+ (NSArray<NSPasteboardType> *)readableTypesForPasteboard:(NSPasteboard *)pasteboard
{
    (void)pasteboard;
    return [NSArray arrayWithObjects:&NSPasteboardTypeString count:1];
}

- (instancetype)initWithPasteboardPropertyList:(id)propertyList ofType:(NSPasteboardType)type
{
    (void)type;
    if ([propertyList isKindOfClass:[NSString class]]) {
        return propertyList;
    }
    if ([propertyList isKindOfClass:[NSData class]]) {
        NSString *decoded = [[NSString alloc] initWithBytes:[propertyList bytes]
                                                     length:[propertyList length]
                                                   encoding:NSUnicodeStringEncoding];
        return decoded;
    }
    return nil;
}

@end