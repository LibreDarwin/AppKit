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

#ifndef _NSFONTMANAGER_H
#define _NSFONTMANAGER_H

#import <Foundation/NSObject.h>
#import <Foundation/NSArray.h>
#import <Foundation/NSDictionary.h>
#import <Foundation/NSGeometry.h>
#import <AppKit/AppKitDefines.h>
#import <AppKit/NSMenu.h>
#import <AppKit/NSUserInterfaceValidation.h>

NS_ASSUME_NONNULL_BEGIN

@class NSFont;
@class NSFontPanel;

typedef NS_OPTIONS(NSUInteger, NSFontTraitMask) {
    NSItalicFontMask                   = 0x00000001,
    NSBoldFontMask                     = 0x00000002,
    NSUnboldFontMask                   = 0x00000004,
    NSNonStandardCharacterSetFontMask  = 0x00000008,
    NSNarrowFontMask                   = 0x00000010,
    NSExpandedFontMask                 = 0x00000020,
    NSCondensedFontMask                = 0x00000040,
    NSSmallCapsFontMask                = 0x00000080,
    NSPosterFontMask                   = 0x00000100,
    NSCompressedFontMask               = 0x00000200,
    NSFixedPitchFontMask               = 0x00000400,
    NSUnitalicFontMask                 = 0x01000000
};

typedef NS_ENUM(NSUInteger, NSFontAction) {
    NSNoFontChangeAction        = 0,
    NSViaPanelFontAction        = 1,
    NSAddTraitFontAction        = 2,
    NSSizeUpFontAction          = 3,
    NSSizeDownFontAction        = 4,
    NSHeavierFontAction         = 5,
    NSLighterFontAction         = 6,
    NSRemoveTraitFontAction     = 7
};

@interface NSFontManager : NSObject <NSMenuItemValidation>

+ (void)setFontPanelFactory:(nullable Class)factoryId;
+ (void)setFontManagerFactory:(nullable Class)factoryId;
@property (class, readonly, strong) NSFontManager *sharedFontManager;

@property (getter=isMultiple, readonly) BOOL multiple;
@property (nullable, readonly, strong) NSFont *selectedFont;
- (void)setSelectedFont:(NSFont *)fontObj isMultiple:(BOOL)flag;
- (void)setFontMenu:(NSMenu *)newMenu;
- (nullable NSMenu *)fontMenu:(BOOL)create;
- (nullable NSFontPanel *)fontPanel:(BOOL)create;
- (nullable NSFont *)fontWithFamily:(NSString *)family traits:(NSFontTraitMask)traits weight:(NSInteger)weight size:(CGFloat)size;
- (NSFontTraitMask)traitsOfFont:(NSFont *)fontObj;
- (NSInteger)weightOfFont:(NSFont *)fontObj;

@property (readonly, copy) NSArray<NSString *> *availableFonts;
@property (readonly, copy) NSArray<NSString *> *availableFontFamilies;
- (nullable NSArray<NSArray *> *)availableMembersOfFontFamily:(NSString *)fam;

- (NSFont *)convertFont:(NSFont *)fontObj;
- (NSFont *)convertFont:(NSFont *)fontObj toSize:(CGFloat)size;
- (nullable NSFont *)convertFont:(NSFont *)fontObj toFace:(NSString *)typeface;
- (NSFont *)convertFont:(NSFont *)fontObj toFamily:(NSString *)family;
- (NSFont *)convertFont:(NSFont *)fontObj toHaveTrait:(NSFontTraitMask)trait;
- (NSFont *)convertFont:(NSFont *)fontObj toNotHaveTrait:(NSFontTraitMask)trait;
- (NSFont *)convertWeight:(BOOL)upFlag ofFont:(NSFont *)fontObj;
@property (getter=isEnabled) BOOL enabled;
@property SEL action;
@property (nullable, assign) id delegate;

- (BOOL)sendAction;

- (NSString *)localizedNameForFamily:(NSString *)family face:(nullable NSString *)faceKey;

- (void)setSelectedAttributes:(NSDictionary<NSString *, id> *)attributes isMultiple:(BOOL)flag;
- (NSDictionary<NSString *, id> *)convertAttributes:(NSDictionary<NSString *, id> *)attributes;

@property (readonly) NSFontAction currentFontAction;
- (NSFontTraitMask)convertFontTraits:(NSFontTraitMask)traits;
@property (nullable, weak) id target;

@end

@interface NSFontManager (NSFontManagerMenuActionMethods)

- (BOOL)fontNamed:(NSString *)fName hasTraits:(NSFontTraitMask)someTraits;
- (nullable NSArray<NSString *> *)availableFontNamesWithTraits:(NSFontTraitMask)someTraits;

- (void)addFontTrait:(nullable id)sender;
- (void)removeFontTrait:(nullable id)sender;
- (void)modifyFontViaPanel:(nullable id)sender;
- (void)modifyFont:(nullable id)sender;
- (void)orderFrontFontPanel:(nullable id)sender;
- (void)orderFrontStylesPanel:(nullable id)sender;

@end

NS_ASSUME_NONNULL_END

#endif /* _NSFONTMANAGER_H */
