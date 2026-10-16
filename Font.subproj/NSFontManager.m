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

#import "NSFontManager.h"
#import <AppKit/NSFont.h>
#import <AppKit/NSApplication.h>
#import "NSFontDatabase_Internal.h"
#import <Foundation/NSString.h>
#import <Foundation/NSArray.h>
#import <Foundation/NSDictionary.h>
#import <Foundation/NSValue.h>
#import <Foundation/NSSet.h>
#import <Foundation/NSNumber.h>
#import <string.h>

static NSFontManager *g_shared = nil;

@implementation NSFontManager {
    NSFont *_selectedFont;
    NSMenu *_fontMenu;
    BOOL _isMultiple;
    BOOL _enabled;
    SEL _action;
    id _delegate;
    id _target;
}

+ (void)setFontPanelFactory:(Class)factoryId {
    (void)factoryId;
}

+ (void)setFontManagerFactory:(Class)factoryId {
    (void)factoryId;
}

+ (NSFontManager *)sharedFontManager {
    if (!g_shared) {
        g_shared = [[NSFontManager alloc] init];
    }
    return g_shared;
}

- (instancetype)init {
    if ((self = [super init])) {
        _enabled = YES;
        _isMultiple = NO;
    }
    return self;
}

- (BOOL)isMultiple {
    return _isMultiple;
}

- (NSFont *)selectedFont {
    return _selectedFont;
}

- (void)setSelectedFont:(NSFont *)fontObj isMultiple:(BOOL)flag {
    _selectedFont = fontObj;
    _isMultiple = flag;
}

- (void)setFontMenu:(NSMenu *)newMenu {
    _fontMenu = newMenu;
}

- (NSMenu *)fontMenu:(BOOL)create {
    if (!_fontMenu && create) {
        _fontMenu = [[NSMenu alloc] initWithTitle:@"Font"];
    }
    return _fontMenu;
}

- (NSFontPanel *)fontPanel:(BOOL)create {
    (void)create;
    return nil;
}

static NSString *NSStringFromC(const char *s) {
    return s ? [NSString stringWithUTF8String:s] : @"";
}

- (NSFont *)fontWithFamily:(NSString *)family traits:(NSFontTraitMask)traits weight:(NSInteger)weight size:(CGFloat)size {
    if (!family || size <= 0) return nil;
    NXFontMemberInfo *members = NULL;
    size_t count = NXFontMembersOfFamily([family UTF8String], &members);
    if (count == 0 || !members) {
        NXFontMembersFree(members, count);
        return nil;
    }
    int bestIdx = -1;
    int bestDist = 1000000;
    int bestScore = -1;
    for (size_t i = 0; i < count; i++) {
        NXFontMemberInfo *m = &members[i];
        if (strcmp(m->styleName, "Regular") == 0 && count > 1) {
            continue;
        }
        /* require traits subset */
        if ((traits & ~m->traits) != 0) {
            continue;
        }
        int dist = abs((int)weight - m->weight);
        int score = (dist == 0) ? 1000 : (1000 - dist);
        if (bestIdx == -1 || score > bestScore || (score == bestScore && bestIdx == -1)) {
            bestIdx = (int)i;
            bestScore = score;
            bestDist = dist;
        }
    }
    if (bestIdx == -1) {
        bestIdx = 0;
    }
    NSString *name = NSStringFromC(members[bestIdx].postScriptName);
    NSFont *font = [NSFont fontWithName:name size:size];
    NXFontMembersFree(members, count);
    return font;
}

- (NSFontTraitMask)traitsOfFont:(NSFont *)fontObj {
    if (!fontObj) return 0;
    const char *name = [[fontObj fontName] UTF8String];
    return NXFontSymbolicTraitsForName(name);
}

- (NSInteger)weightOfFont:(NSFont *)fontObj {
    if (!fontObj) return 5;
    const char *name = [[fontObj fontName] UTF8String];
    return NXFontWeightClassForName(name);
}

static NSString *systemFontName = @"System";

- (NSArray<NSString *> *)availableFonts {
    NXFontDatabase *db = NXFontDatabaseCreate();
    NSMutableArray *result = [NSMutableArray array];
    if (db) {
        size_t count = NXFontDatabaseFaceCount(db);
        NSMutableSet *set = [NSMutableSet set];
        for (size_t i = 0; i < count; i++) {
            const NXFontFace *f = NXFontDatabaseFaceAtIndex(db, i);
            if (f && f->postScriptName) {
                NSString *n = [NSString stringWithUTF8String:f->postScriptName];
                if (![set containsObject:n]) {
                    [set addObject:n];
                    [result addObject:n];
                }
            }
        }
        NXFontDatabaseFree(db);
    }
    [result sortUsingSelector:@selector(caseInsensitiveCompare:)];
    return result;
}

- (NSArray<NSString *> *)availableFontFamilies {
    NXFontDatabase *db = NXFontDatabaseCreate();
    NSMutableArray *result = [NSMutableArray array];
    if (db) {
        size_t count = NXFontDatabaseFaceCount(db);
        NSMutableSet *set = [NSMutableSet set];
        for (size_t i = 0; i < count; i++) {
            const NXFontFace *f = NXFontDatabaseFaceAtIndex(db, i);
            if (f && f->familyName) {
                NSString *n = [NSString stringWithUTF8String:f->familyName];
                if (![set containsObject:n]) {
                    [set addObject:n];
                    [result addObject:n];
                }
            }
        }
        NXFontDatabaseFree(db);
    }
    [result sortUsingSelector:@selector(caseInsensitiveCompare:)];
    return result;
}

- (NSArray<NSArray *> *)availableMembersOfFontFamily:(NSString *)fam {
    if (!fam) return nil;
    NXFontMemberInfo *members = NULL;
    size_t count = NXFontMembersOfFamily([fam UTF8String], &members);
    NSMutableArray *result = [NSMutableArray array];
    for (size_t i = 0; i < count; i++) {
        NSArray *arr = @[ NSStringFromC(members[i].postScriptName),
                          NSStringFromC(members[i].styleName),
                          [NSNumber numberWithInt:members[i].weight],
                          [NSNumber numberWithInt:members[i].traits] ];
        [result addObject:arr];
    }
    NXFontMembersFree(members, count);
    return result;
}

- (NSFont *)convertFont:(NSFont *)fontObj {
    return fontObj;
}

- (NSFont *)convertFont:(NSFont *)fontObj toSize:(CGFloat)size {
    if (!fontObj) return nil;
    return [NSFont fontWithName:[fontObj fontName] size:size];
}

- (NSFont *)convertFont:(NSFont *)fontObj toFace:(NSString *)typeface {
    if (!fontObj || !typeface) return fontObj;
    return [NSFont fontWithName:typeface size:[fontObj pointSize]];
}

- (NSFont *)convertFont:(NSFont *)fontObj toFamily:(NSString *)family {
    if (!fontObj || !family) return fontObj;
    NSFontTraitMask traits = [self traitsOfFont:fontObj];
    NSInteger weight = [self weightOfFont:fontObj];
    CGFloat size = [fontObj pointSize];
    NSFont *f = [self fontWithFamily:family traits:traits weight:weight size:size];
    return f ? f : fontObj;
}

- (NSFont *)convertFont:(NSFont *)fontObj toHaveTrait:(NSFontTraitMask)trait {
    if (!fontObj) return nil;
    NSFontTraitMask current = [self traitsOfFont:fontObj];
    if ((current & trait) == trait) return fontObj;
    if (trait & NSUnboldFontMask) {
        current &= ~NSBoldFontMask;
    }
    if (trait & NSUnitalicFontMask) {
        current &= ~NSItalicFontMask;
    }
    current |= trait;
    NSString *family = [self familyForFont:fontObj];
    CGFloat size = [fontObj pointSize];
    NSInteger weight = [self weightOfFont:fontObj];
    NSFont *f = [self fontWithFamily:family traits:current weight:weight size:size];
    return f ? f : fontObj;
}

- (NSFont *)convertFont:(NSFont *)fontObj toNotHaveTrait:(NSFontTraitMask)trait {
    if (!fontObj) return nil;
    NSFontTraitMask current = [self traitsOfFont:fontObj];
    current &= ~trait;
    NSString *family = [self familyForFont:fontObj];
    CGFloat size = [fontObj pointSize];
    NSInteger weight = [self weightOfFont:fontObj];
    NSFont *f = [self fontWithFamily:family traits:current weight:weight size:size];
    return f ? f : fontObj;
}

- (NSString *)familyForFont:(NSFont *)fontObj {
    NXFontDatabase *db = NXFontDatabaseCreate();
    if (db) {
        const NXFontFace *face = NXFontDatabaseFaceNamed(db, [[fontObj fontName] UTF8String]);
        if (face && face->familyName) {
            NSString *s = [NSString stringWithUTF8String:face->familyName];
            NXFontDatabaseFree(db);
            return s;
        }
        NXFontDatabaseFree(db);
    }
    NSArray *families = [self availableFontFamilies];
    for (NSString *fam in families) {
        NSArray *members = [self availableMembersOfFontFamily:fam];
        for (NSArray *m in members) {
            if ([m count] > 0 && [m[0] isEqualToString:[fontObj fontName]]) {
                return fam;
            }
        }
    }
    return @"";
}

- (NSFont *)convertWeight:(BOOL)upFlag ofFont:(NSFont *)fontObj {
    if (!fontObj) return nil;
    NSInteger w = [self weightOfFont:fontObj];
    w = upFlag ? w + 1 : w - 1;
    if (w < 1) w = 1;
    if (w > 15) w = 15;
    NSFontTraitMask traits = [self traitsOfFont:fontObj];
    NSString *family = [self familyForFont:fontObj];
    CGFloat size = [fontObj pointSize];
    NSFont *f = [self fontWithFamily:family traits:traits weight:w size:size];
    return f ? f : fontObj;
}

- (BOOL)isEnabled {
    return _enabled;
}

- (void)setEnabled:(BOOL)enabled {
    _enabled = enabled;
}

- (SEL)action {
    return _action;
}

- (void)setAction:(SEL)action {
    _action = action;
}

- (id)delegate {
    return _delegate;
}

- (void)setDelegate:(id)delegate {
    _delegate = delegate;
}

- (id)target {
    return _target;
}

- (void)setTarget:(id)target {
    _target = target;
}

- (BOOL)sendAction {
    if (_target && _action) {
        return [[NSApplication sharedApplication] sendAction:_action to:_target from:self];
    }
    return NO;
}

- (NSString *)localizedNameForFamily:(NSString *)family face:(NSString *)faceKey {
    return [self familyForFont:[NSFont fontWithName:faceKey?:family size:[NSFont systemFontSize]]] ?: family;
}

- (void)setSelectedAttributes:(NSDictionary<NSString *, id> *)attributes isMultiple:(BOOL)flag {
    _isMultiple = flag;
}

- (NSDictionary<NSString *, id> *)convertAttributes:(NSDictionary<NSString *, id> *)attributes {
    return attributes ?: @{};
}

- (NSFontAction)currentFontAction {
    return NSNoFontChangeAction;
}

- (NSFontTraitMask)convertFontTraits:(NSFontTraitMask)traits {
    return traits;
}

@end

@implementation NSFontManager (NSFontManagerMenuActionMethods)

- (BOOL)fontNamed:(NSString *)fName hasTraits:(NSFontTraitMask)someTraits {
    if (!fName) return NO;
    NSFont *font = [NSFont fontWithName:fName size:[NSFont systemFontSize]];
    if (!font) return NO;
    NSFontTraitMask t = [self traitsOfFont:font];
    return (t & someTraits) == someTraits;
}

- (NSArray<NSString *> *)availableFontNamesWithTraits:(NSFontTraitMask)someTraits {
    NSMutableArray *result = [NSMutableArray array];
    NSArray *fonts = [self availableFonts];
    for (NSString *n in fonts) {
        NSFont *f = [NSFont fontWithName:n size:[NSFont systemFontSize]];
        if (f) {
            NSFontTraitMask t = [self traitsOfFont:f];
            if ((t & someTraits) == someTraits) {
                [result addObject:n];
            }
        }
    }
    [result sortUsingSelector:@selector(caseInsensitiveCompare:)];
    return result;
}

- (void)addFontTrait:(id)sender { (void)sender; }
- (void)removeFontTrait:(id)sender { (void)sender; }
- (void)modifyFontViaPanel:(id)sender { (void)sender; }
- (void)modifyFont:(id)sender { (void)sender; }
- (void)orderFrontFontPanel:(id)sender { (void)sender; }
- (void)orderFrontStylesPanel:(id)sender { (void)sender; }

- (BOOL)validateMenuItem:(NSMenuItem *)menuItem {
    (void)menuItem;
    return YES;
}

@end
