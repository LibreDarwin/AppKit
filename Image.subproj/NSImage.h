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

/* NSImage.h — minimal seed for LibreDarwin's AppKit NSImage reimplementation.
 * Until Drawing/Image.subproj grows a raster pipeline, an NSImage is a named
 * handle for size and data: the identity (name, size, file data) that the
 * rest of the framework wants to remember about an image, with no drawing or
 * decoding yet. The class is what NSApplication, NSMenuItem and NSMenu use to
 * hold a (possibly not-yet-decoded) image object. */
#ifndef _NSIMAGE_H
#define _NSIMAGE_H

#import <Foundation/NSObject.h>
#import <Foundation/NSGeometry.h>
#import <AppKit/AppKitDefines.h>

@class NSData;

NS_ASSUME_NONNULL_BEGIN

/* A string used to identify a named image. */
typedef NSString *NSImageName;

/* System image names. A handful that framework code and common applications
 * reference are seeded; the full catalogue grows with the artwork. */
APPKIT_EXTERN NSImageName const NSImageNameApplicationIcon;
APPKIT_EXTERN NSImageName const NSImageNameComputer;
APPKIT_EXTERN NSImageName const NSImageNameFolder;
APPKIT_EXTERN NSImageName const NSImageNamePreferencesGeneral;
APPKIT_EXTERN NSImageName const NSImageNameUser;

@interface NSImage : NSObject <NSCopying>

/* Returns the image registered under the given name, creating and caching a
 * named placeholder when the system artwork is not yet available. */
+ (nullable NSImage *)imageNamed:(NSImageName)name;

/* Creates an image with an explicit size and no initial contents. */
- (instancetype)initWithSize:(NSSize)size;

/* Creates an image from the given data, holding the bytes until a decoder
 * exists. The image size is unknown until then. */
- (nullable instancetype)initWithData:(NSData *)data;

/* The size of the image. */
@property NSSize size;

/* Names the image, or removes its name when passed nil. Returns YES. */
- (BOOL)setName:(nullable NSImageName)string;
/* The image's name, or nil if unnamed. */
- (nullable NSImageName)name;

@end

NS_ASSUME_NONNULL_END

#endif /* _NSIMAGE_H */