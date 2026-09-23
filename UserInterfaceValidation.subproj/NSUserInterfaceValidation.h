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

/* NSUserInterfaceValidation.h — LibreDarwin reimplementation of Apple's
 * AppKit NSUserInterfaceValidation.h: the protocols backing AppKit's
 * standard UI-validation mechanism. A validated object (menu item, toolbar
 * item, ...) asks its validator how it feels about the item; the validator
 * is found through -[NSApplication targetForAction:to:from:]. */
#ifndef _NSUSERINTERFACEVALIDATION_H
#define _NSUSERINTERFACEVALIDATION_H

#import <Foundation/NSObject.h>
#import <Foundation/NSObjCRuntime.h>

NS_ASSUME_NONNULL_BEGIN

@class NSMenuItem;

/* Protocol implemented by validated objects */
@protocol NSValidatedUserInterfaceItem
@property (readonly, nullable) SEL action;
@property (readonly) NSInteger tag;
@end

/* Protocol implemented by validator objects */
@protocol NSUserInterfaceValidations
- (BOOL)validateUserInterfaceItem:(id <NSValidatedUserInterfaceItem>)item;
@end

/* Protocol implemented by validators of menu items. On Apple's AppKit this
 * lives in NSMenuItem.h; it is seeded here (with @class NSMenuItem) because
 * NSApplication.h already conforms to it and NSMenuItem.subproj does not
 * exist yet. */
@protocol NSMenuItemValidation
- (BOOL)validateMenuItem:(NSMenuItem *)menuItem;
@end

NS_ASSUME_NONNULL_END

#endif /* _NSUSERINTERFACEVALIDATION_H */