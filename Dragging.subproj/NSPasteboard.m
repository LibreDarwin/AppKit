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
 * types through NSPasteboardOwner. */

#import <AppKit/NSPasteboard.h>
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

static BOOL _LBSPasteboardTypesEqual(NSString *left, NSString *right);

static BOOL _LBSValueIsPromised(id value)
{
    return value == _lbsPromiseMarker;
}

@implementation NSPasteboard {
    NSPasteboardName _name;
    NSInteger _changeCount;
    NSMutableArray *_types; /* NSPasteboardType, in declaration order */
    NSMutableArray *_values; /* parallel to _types: NSData or id plist, NSNull when promised */
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
    pboard->_types = [NSMutableArray array];
    pboard->_values = [NSMutableArray array];
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
    return [_types copy];
}

- (NSPasteboardType)availableTypeFromArray:(NSArray<NSPasteboardType> *)types
{
    NSInteger requestedCount = (NSInteger)[types count];
    NSInteger availableCount = (NSInteger)[_types count];
    for (NSInteger i = 0; i < requestedCount; i++) {
        NSString *requested = [types objectAtIndex:i];
        for (NSInteger j = 0; j < availableCount; j++) {
            if (_LBSPasteboardTypesEqual(requested, [_types objectAtIndex:j])) {
                return requested;
            }
        }
    }
    return nil;
}

- (NSData *)dataForType:(NSPasteboardType)type
{
    NSInteger index = [self _lbsIndexOfType:type];
    if (index == NSNotFound) {
        return nil;
    }
    id value = [_values objectAtIndex:index];
    if (_LBSValueIsPromised(value) && _owner != nil
        && [_owner respondsToSelector:@selector(pasteboard:provideDataForType:)]) {
        [_owner pasteboard:self provideDataForType:type];
        value = [_values objectAtIndex:index];
    }
    if (!_LBSValueIsPromised(value) && [value isKindOfClass:[NSData class]]) {
        return value;
    }
    return nil;
}

- (NSString *)stringForType:(NSPasteboardType)type
{
    NSData *data = [self dataForType:type];
    if (data == nil) {
        return nil;
    }
    return [[NSString alloc] initWithBytes:[data bytes] length:[data length]
                                  encoding:NSUnicodeStringEncoding];
}

- (id)propertyListForType:(NSPasteboardType)type
{
    NSInteger index = [self _lbsIndexOfType:type];
    if (index == NSNotFound) {
        return nil;
    }
    id value = [_values objectAtIndex:index];
    if (_LBSValueIsPromised(value)) {
        return nil;
    }
    return value;
}

- (NSInteger)clearContents
{
    [_types removeAllObjects];
    [_values removeAllObjects];
    _changeCount++;
    return _changeCount;
}

- (NSInteger)declareTypes:(NSArray<NSPasteboardType> *)newTypes owner:(id)owner
{
    NSInteger newCount = (NSInteger)[newTypes count];
    [_types removeAllObjects];
    [_values removeAllObjects];
    for (NSInteger i = 0; i < newCount; i++) {
        [_types addObject:[newTypes objectAtIndex:i]];
        [_values addObject:_lbsPromiseMarker];
    }
    if (owner != _owner && _owner != nil
        && [_owner respondsToSelector:@selector(pasteboardChangedOwner:)]) {
        [_owner pasteboardChangedOwner:self];
    }
    _owner = owner;
    _changeCount++;
    return _changeCount;
}

- (NSInteger)addTypes:(NSArray<NSPasteboardType> *)newTypes owner:(id)owner
{
    NSInteger newCount = (NSInteger)[newTypes count];
    for (NSInteger i = 0; i < newCount; i++) {
        NSString *type = [newTypes objectAtIndex:i];
        if ([self _lbsIndexOfType:type] == NSNotFound) {
            [_types addObject:type];
            [_values addObject:_lbsPromiseMarker];
        }
    }
    if (owner != _owner && _owner != nil
        && [_owner respondsToSelector:@selector(pasteboardChangedOwner:)]) {
        [_owner pasteboardChangedOwner:self];
    }
    _owner = owner;
    _changeCount++;
    return _changeCount;
}

- (BOOL)setData:(NSData *)data forType:(NSPasteboardType)type
{
    [self _lbsSetValue:data forType:type];
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
    [self _lbsSetValue:plist forType:type];
    _changeCount++;
    return YES;
}

/* ----- private helpers ------------------------------------------------ */

/* Sets the value for type, appending the pair when the type is new. The
 * minimal Foundation cannot replace array elements in place, so the values
 * array is rebuilt once per write; the parallel order with _types is kept. */
- (void)_lbsSetValue:(id)value forType:(NSPasteboardType)type
{
    NSInteger index = [self _lbsIndexOfType:type];
    if (index == NSNotFound) {
        [_types addObject:type];
        [_values addObject:value];
        return;
    }
    NSInteger count = (NSInteger)[_values count];
    NSMutableArray *rebuilt = [NSMutableArray arrayWithCapacity:(NSUInteger)count];
    for (NSInteger i = 0; i < count; i++) {
        if (i == index) {
            [rebuilt addObject:value];
        } else {
            [rebuilt addObject:[_values objectAtIndex:i]];
        }
    }
    _values = rebuilt;
}

- (NSInteger)_lbsIndexOfType:(NSPasteboardType)type
{
    NSInteger count = (NSInteger)[_types count];
    for (NSInteger i = 0; i < count; i++) {
        if (_LBSPasteboardTypesEqual(type, [_types objectAtIndex:i])) {
            return i;
        }
    }
    return NSNotFound;
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