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

/* AppKitDefines.h — LibreDarwin reimplementation of Apple's AppKitDefines.h.
 * The export macros are the same names Apple's headers use so that sources
 * and headers written against the system AppKit compile unchanged against
 * ours. */
#ifndef _APPKITDEFINES_H
#define _APPKITDEFINES_H

#ifdef __cplusplus
#define APPKIT_EXTERN        extern "C"
#define APPKIT_PRIVATE_EXTERN __attribute__((visibility("hidden"))) extern "C"
#define APPKIT_PRIVATE       __attribute__((visibility("hidden")))
#else
#define APPKIT_EXTERN        extern
#define APPKIT_PRIVATE_EXTERN __attribute__((visibility("hidden"))) extern
#define APPKIT_PRIVATE       __attribute__((visibility("hidden")))
#endif

/* NS_NOESCAPE normally comes from Foundation's NSObjCRuntime.h; the
 * LibreDarwin Foundation snapshot this framework builds against does not
 * ship it yet, so provide the guarded fallback here (AppKit headers use it on
 * block parameters). */
#ifndef NS_NOESCAPE
#define NS_NOESCAPE __attribute__((noescape))
#endif

#endif /* _APPKITDEFINES_H */