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

#import <AppKit/NSImage.h>
#import <Foundation/NSArray.h>
#import <Foundation/NSData.h>
#import <Foundation/NSString.h>
#import <string.h>

/* Name lookup uses textual equality: the minimal Foundation's NSDictionary
 * key mechanism is not relied on, and the seeded catalogue has no duplicate
 * names. A static array of named images serves as the name→image registry. */
static NSMutableArray *_lbsNamedImages = nil;

static BOOL _LBSImageNamesEqual(NSString *left, NSString *right);

@implementation NSImage {
    NSSize _size;
    NSString *_name;
    NSData *_data;
}

NSImageName const NSImageNameApplicationIcon = @"NSApplicationIcon";
NSImageName const NSImageNameComputer = @"NSComputer";
NSImageName const NSImageNameFolder = @"NSFolder";
NSImageName const NSImageNamePreferencesGeneral = @"NSPreferencesGeneral";
NSImageName const NSImageNameUser = @"NSUser";

+ (NSImage *)imageNamed:(NSImageName)name
{
    if (_lbsNamedImages == nil) {
        _lbsNamedImages = [NSMutableArray array];
    }
    NSInteger count = (NSInteger)[_lbsNamedImages count];
    for (NSInteger i = 0; i < count; i++) {
        NSImage *image = [_lbsNamedImages objectAtIndex:i];
        if (_LBSImageNamesEqual([image name], name)) {
            return image;
        }
    }
    NSImage *image = [[self alloc] initWithSize:NSMakeSize(0, 0)];
    [image setName:name];
    [_lbsNamedImages addObject:image];
    return image;
}

- (instancetype)initWithSize:(NSSize)size
{
    self = [super init];
    if (self) {
        _size = size;
    }
    return self;
}

- (instancetype)initWithData:(NSData *)data
{
    self = [self initWithSize:NSMakeSize(0, 0)];
    if (self) {
        _data = [data copy];
    }
    return self;
}

- (void)dealloc
{
    _name = nil;
    _data = nil;
}

- (id)copyWithZone:(NSZone *)zone
{
    NSImage *copy = [[NSImage allocWithZone:zone] initWithSize:_size];
    [copy setName:_name];
    copy->_data = _data;
    return copy;
}

- (NSSize)size
{
    return _size;
}

- (void)setSize:(NSSize)size
{
    _size = size;
}

- (BOOL)setName:(NSImageName)string
{
    _name = [string copy];
    return YES;
}

- (NSImageName)name
{
    return _name;
}

static BOOL _LBSImageNamesEqual(NSString *left, NSString *right)
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