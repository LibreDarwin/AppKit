#
# Copyright (C) 2026, LibreDarwin.
#
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions are met:
#
# 1. Redistributions of source code must retain the above copyright notice,
#    this list of conditions and the following disclaimer.
# 2. Redistributions in binary form must reproduce the above copyright notice,
#    this list of conditions and the following disclaimer in the documentation
#    and/or other materials provided with the distribution.
# 3. Neither the name of the copyright holder nor the names of its
#    contributors may be used to endorse or promote products derived from
#    this software without specific prior written permission.
#
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
# AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
# IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
# ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE
# LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
# CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
# SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
# INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
# CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
# ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
# POSSIBILITY OF SUCH DAMAGE.

# =====================================================================
#  AppKit.framework — bmake build
# ---------------------------------------------------------------------
#  Main build file for the LibreDarwin AppKit.framework.
#
#  * Generates an umbrella header in build/gen/ from the subprojects'
#    own public headers, so <AppKit/...> includes resolve here.
#  * Compiles every .m file under the subprojects (ARC by default; the
#    sources listed in MRC_SOURCES are written for MRC and get
#    -fno-objc-arc) and links against the LibreDarwin Foundation and
#    CoreFoundation.
#  * Verification gates mirror the sibling Foundation build: the
#    pairing-sweep (declared selectors must have implementations) runs
#    as part of `all`; the behavior-gate will join it later.
#
#  Subproject layout: one *.subproj directory per AppKit class family,
#  mirroring the family groupings of the porting references (NeXTSrc,
#  Cocotron, ravynOS).  Private implementation headers carry a _Private
#  or _Internal suffix (or a leading underscore) and are excluded from
#  the public umbrella.
#
#  Uses bmake constructs only (.for loops, := and != assignments; no
#  GNU make functions or modifiers).
# =====================================================================

# ---- toolchain ----
# Builds against the LibreDarwin Internal SDK (the macOS SDK this framework
# drops into). Point RN elsewhere on the command line (bmake RN=...) for a
# dev build against Apple's SDK.
CC  != xcrun --find clang
RN  = /Users/sunneva/xnuports-root/devel/xcode-tools/build/release/Developer/Platforms/MacOSX.platform/Developer/SDKs/MacOSX.Internal.sdk

# ---- framework locations ----
FW      = build/release/AppKit.framework
DYLIB   = ${FW}/Versions/A/AppKit

# Public umbrella includes every subproject header EXCEPT the private
# implementation-only ones.  An internal header that must be reachable
# anyway (like Foundation's internal NSCFTypeID.h) is an explicit opt-in:
# it still ships in the framework and is included by name.
UMBRELLA_HDRS = ${HDRS:N*_Private.h:N*_Internal.h:N*/_*}

# ---- sources ----
# bmake != assigns the shell output; it is evaluated each run.
HDRS != find . \( -path './build' -o -path './local' \) -prune -o -name '*.h' -type f -print | sort
MSRC != find . \( -path './build' -o -path './local' \) -prune -o -name '*.m' -type f -print | sort
# Object paths mirror the source tree under build/objects/.
OBJECTS != find . \( -path './build' -o -path './local' \) -prune -o -name '*.m' -type f -print | sed 's|^\./|build/objects/|; s|\.m$$|.o|' | sort

# ---- compiler flags ----
# NSBUILDING_APPKIT is this project's counterpart of Foundation's
# NSBUILDINGFOUNDATION: the private implementation headers honour it so
# their declarations become visible when the framework compiles itself.
# Sources resolve Foundation and CoreFoundation from the Internal SDK.
CFLAGS  = -fobjc-arc -fblocks -fobjc-runtime=macosx \
          -isysroot ${RN} \
          -DNSBUILDING_APPKIT \
          -I${RN}/System/Library/Frameworks/Foundation.framework/Headers \
          -I${RN}/System/Library/Frameworks/CoreFoundation.framework/Headers \
          -I build/gen
LDFLAGS = -dynamiclib -fobjc-arc -isysroot ${RN} \
          -F${RN}/System/Library/Frameworks \
          -framework Foundation -framework CoreFoundation \
          -install_name @rpath/AppKit.framework/Versions/A/AppKit

.PHONY: all verify pairing-sweep release umbrella clean gitignore

all: release verify

verify: pairing-sweep

# Every selector declared in a public header must be implemented somewhere
# in the .m sources; see Tests/pairing_sweep.py for the contract (including
# what it deliberately does not require).
pairing-sweep:
	@cd ${.CURDIR} && python3 Tests/pairing_sweep.py .

# =====================================================================
#  Umbrella header: copied from the subprojects' own headers and
#  gathered into build/gen/AppKit/AppKit.h.
# =====================================================================
umbrella: build/gen/AppKit/AppKit.h

build/gen/AppKit/AppKit.h:
	@mkdir -p build/gen/AppKit
	@rm -f $@
	@for h in ${HDRS}; do hb="$${h##*/}"; cp "$$h" build/gen/AppKit/; done
	@{  echo '// AppKit.h — generated from this project'"'"'s subproject headers'; \
	    for h in ${UMBRELLA_HDRS}; do hb="$${h##*/}"; echo "#include <AppKit/$$hb>"; done; \
	} > $@

# =====================================================================
#  Object files: one .o per .m source. Most sources are ARC; the few
#  written for MRC (they cast raw CF objects without __bridge) get
#  -fno-objc-arc.  The :C modifiers turn './X.m' into
#  'build/objects/X.o' for the target, and the umbrella header is a
#  prerequisite because every source includes <AppKit/...> from
#  build/gen.
# =====================================================================
MRC_SOURCES =

.for src in ${MSRC}
${src:C|^\./|build/objects/|:C|\.m$|.o|}: ${src} build/gen/AppKit/AppKit.h
	@mkdir -p ${.TARGET:H}
	@FLAGS=; if test "${MRC_SOURCES:M${src}}" != ""; then FLAGS=-fno-objc-arc; fi; \
	 ${CC} ${CFLAGS} $${FLAGS} -c ${src} -o ${.TARGET}
.endfor

# =====================================================================
#  Framework bundle
# =====================================================================
release: umbrella ${DYLIB}

${DYLIB}: ${OBJECTS}
	@mkdir -p ${DYLIB:H} ${FW}/Versions/A/Headers ${FW}/Versions/A/Resources
	@if test -n "${OBJECTS}"; then \
	    ${CC} ${LDFLAGS} -o $@ ${OBJECTS}; \
	 fi
	@for h in build/gen/AppKit/*.h; do test -f "$$h" && cp "$$h" ${FW}/Versions/A/Headers/; done
	@cp Info.plist ${FW}/Versions/A/Resources/
	@ln -sfn A ${FW}/Versions/Current
	@ln -sfn Versions/Current/AppKit ${FW}/AppKit
	@ln -sfn Versions/Current/Headers ${FW}/Headers

clean:
	@rm -rf build

gitignore:
	@grep -q '^build/$$' .gitignore || printf 'build/\n' >> .gitignore