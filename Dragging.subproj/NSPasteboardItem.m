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

#import <AppKit/NSPasteboardItem.h>
#import <Foundation/NSArray.h>
#import <Foundation/NSData.h>
#import <Foundation/NSString.h>
#import <string.h>

@interface NSPasteboardItem (LBSPasteboardInternal)
- (id)_lbsPasteboardValue;
- (void)_lbsSetPasteboardValue:(id)value;
@end

@implementation NSPasteboardItem {
    NSPasteboardType _type;
    id _value;
}

- (NSArray<NSPasteboardType> *)types
{
    if (_type == nil) {
        return [NSArray array];
    }
    return [NSArray arrayWithObjects:&_type count:1];
}

- (NSData *)dataForType:(NSPasteboardType)type
{
    if (![self _LBSItemHasType:type] || ![_value isKindOfClass:[NSData class]]) {
        return nil;
    }
    return _value;
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
    if (![self _LBSItemHasType:type]) {
        return nil;
    }
    return _value;
}

- (BOOL)setData:(NSData *)data forType:(NSPasteboardType)type
{
    _type = type;
    _value = data;
    return YES;
}

- (BOOL)setString:(NSString *)string forType:(NSPasteboardType)type
{
    NSData *data = [string dataUsingEncoding:NSUnicodeStringEncoding];
    if (data == nil) {
        return NO;
    }
    return [self setData:data forType:type];
}

- (BOOL)setPropertyList:(id)propertyList forType:(NSPasteboardType)type
{
    _type = type;
    _value = propertyList;
    return YES;
}

/* ----- NSPasteboardWriting ------------------------------------------- */

- (NSArray<NSPasteboardType> *)writableTypesForPasteboard:(NSPasteboard *)pasteboard
{
    return [self types];
}

- (id)pasteboardPropertyListForType:(NSPasteboardType)type
{
    return [self propertyListForType:type];
}

/* ----- NSPasteboardReading ------------------------------------------- */

+ (NSArray<NSPasteboardType> *)readableTypesForPasteboard:(NSPasteboard *)pasteboard
{
    /* Items consume whatever they hold; the concrete read path of an item
     * is exercised via its instances. */
    return [NSArray array];
}

- (instancetype)initWithPasteboardPropertyList:(id)propertyList ofType:(NSPasteboardType)type
{
    self = [super init];
    if (self) {
        _type = type;
        _value = propertyList;
    }
    return self;
}

/* ----- LBSPasteboardInternal ------------------------------------------ */

- (id)_lbsPasteboardValue
{
    return _value;
}

- (void)_lbsSetPasteboardValue:(id)value
{
    _value = value;
}

/* ----- private helpers ------------------------------------------------ */

- (BOOL)_LBSItemHasType:(NSPasteboardType)type
{
    if (_type == nil || type == nil) {
        return NO;
    }
    return strcmp([_type UTF8String], [type UTF8String]) == 0;
}

@end