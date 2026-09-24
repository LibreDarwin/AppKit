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

/* NSApplication_Private.h — private companion to NSApplication.h. Declares
 * the window-management hooks the NSApplication/NSWindow pair use to keep
 * the application's window registry, main-window pointer, and key-window
 * pointer consistent as windows are created, made key/main, and closed.
 * Not part of the public API and therefore excluded from the generated
 * umbrella header; the selectors below still count against the pairing
 * sweep, so each needs an implementation in the .m sources. */
#ifndef _NSAPPLICATION_PRIVATE_H
#define _NSAPPLICATION_PRIVATE_H

#import <AppKit/NSApplication.h>

@interface NSApplication (LBSWindowPrivate)

/* Adds the window to the application's ordered window list if not already
 * present (registration happens at window creation). */
- (void)_lbsRegisterWindow:(nonnull NSWindow *)window;
/* Removes the window from the application's list and, when it was the main
 * or key window, forgets the corresponding pointer. */
- (void)_lbsUnregisterWindow:(nonnull NSWindow *)window;
/* Records which window is the application's main window. */
- (void)_lbsSetMainWindow:(nullable NSWindow *)window;
/* Records which window is the application's key window. */
- (void)_lbsSetKeyWindow:(nullable NSWindow *)window;

@end

#endif /* _NSAPPLICATION_PRIVATE_H */