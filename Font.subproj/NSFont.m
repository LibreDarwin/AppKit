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

#import <AppKit/NSFont.h>
#import <Foundation/NSString.h>

/* Still no CoreText in the tree, so an NSFont is what it knows how to be: a
 * name plus a size. The puppy-mill type metrics below are sane SF-like ratios
 * of the point size, good enough that menu geometry and text heuristics work
 * without a font rasterizer. */

@implementation NSFont {
    NSString *_fontName;
    CGFloat _pointSize;
}

+ (NSFont *)fontWithName:(NSString *)fontName size:(CGFloat)fontSize {
    return [[[self class] alloc] initWithName:fontName size:fontSize];
}

+ (NSFont *)systemFontOfSize:(CGFloat)fontSize {
    return [self fontWithName:@"System" size:fontSize];
}

+ (CGFloat)systemFontSize {
    return 13.0;
}

+ (CGFloat)smallSystemFontSize {
    return 11.0;
}

+ (CGFloat)labelFontSize {
    return 10.0;
}

- (instancetype)initWithName:(NSString *)fontName size:(CGFloat)fontSize {
    if ((self = [super init])) {
        _fontName = [fontName copy];
        _pointSize = fontSize;
    }
    return self;
}

- (id)copyWithZone:(NSZone *)zone {
    return [[[self class] alloc] initWithName:_fontName size:_pointSize];
}

- (NSString *)fontName {
    return _fontName;
}

- (CGFloat)pointSize {
    return _pointSize;
}

- (CGFloat)ascender {
    return _pointSize * 0.85;
}

- (CGFloat)descender {
    return -(_pointSize * 0.25);
}

- (CGFloat)capHeight {
    return _pointSize * 0.70;
}

- (CGFloat)xHeight {
    return _pointSize * 0.50;
}

- (CGFloat)leading {
    return _pointSize * 0.05;
}

@end