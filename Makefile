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
#  AppKit.framework — portable build (GNU make AND bmake)
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
#  Portability: this file sticks to the construct subset shared by GNU
#  make and bmake (=, +=, ?=, := assignments; explicit rules; .PHONY;
#  automatic variables; recipes with backslash continuations).  It uses
#  no GNU-only features (functions, % pattern rules) and no bmake-only
#  ones (!=, .for/.endfor, :M/:N/:C modifiers, ${.CURDIR}).  All file
#  discovery and freshness checks happen inside the shell recipes, so
#  the two make implementations only supply the target ordering.  Run
#  make/bmake from the project root.
# =====================================================================

# ---- toolchain ----
# Builds against the LibreDarwin Internal SDK (the macOS SDK this framework
# drops into). Point RN elsewhere on the command line (make RN=...) for a
# dev build against Apple's SDK.
CC  ?= clang
RN  = /Users/sunneva/xnuports-root/devel/xcode-tools/build/release/Developer/Platforms/MacOSX.platform/Developer/SDKs/MacOSX.Internal.sdk

# ---- framework locations ----
FW    = build/release/AppKit.framework
DYLIB = ${FW}/Versions/A/AppKit

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

# Sources written for MRC (they cast raw CF objects without __bridge).
MRC_SOURCES =

# ---- targets ----
.PHONY: all verify pairing-sweep release umbrella objects link clean gitignore

all: release verify

verify: pairing-sweep

# Every selector declared in a public header must be implemented somewhere
# in the .m sources; see Tests/pairing_sweep.py for the contract (including
# what it deliberately does not require).
pairing-sweep:
	@python3 Tests/pairing_sweep.py .

# =====================================================================
#  Umbrella header.  Copies every subproject header into build/gen/AppKit/
#  and gathers the non-private ones into AppKit.h.  Regenerates only when
#  a header is newer than the current umbrella (or the umbrella is
#  missing), so unchanged trees stay no-op.
# =====================================================================
umbrella:
	@mkdir -p build/gen/AppKit
	@if test -f build/gen/AppKit/AppKit.h; then \
	    newer=$$(find . \( -path './build' -o -path './local' \) -prune -o -name '*.h' -type f -newer build/gen/AppKit/AppKit.h -print | sort); \
	 else \
	    newer=force; \
	 fi; \
	 if test -n "$$newer"; then \
	    rm -f build/gen/AppKit/*.h; \
	    for h in $$(find . \( -path './build' -o -path './local' \) -prune -o -name '*.h' -type f -print | sort); do \
	        cp "$$h" build/gen/AppKit/; \
	    done; \
	    { \
	        echo '// AppKit.h — generated from this project'"'"'s subproject headers'; \
	        for h in $$(find . \( -path './build' -o -path './local' \) -prune -o -name '*.h' -type f -print | sort); do \
	            hb="$${h##*/}"; \
	            case "$$hb" in \
	                *_Private.h|*_Internal.h|_*) ;; \
	                *) echo "#include <AppKit/$$hb>";; \
	            esac; \
	        done; \
	    } > build/gen/AppKit/AppKit.h; \
	 fi

# =====================================================================
#  Object files.  One .o per .m source, mirroring the source tree under
#  build/objects/.  Most sources are ARC; the few written for MRC get
#  -fno-objc-arc.  A source is recompiled when it (or the umbrella any
#  source includes) is newer than the object.  Discovery and freshness
#  live in the shell so both make implementations see identical rules.
# =====================================================================
objects:
	@mkdir -p build/objects
	@for src in $$(find . \( -path './build' -o -path './local' \) -prune -o -name '*.m' -type f -print | sort); do \
	    obj=build/objects/$${src#./}; \
	    obj=$${obj%.m}.o; \
	    mkdir -p $$(dirname "$$obj"); \
	    flags=; \
	    if test -n "${MRC_SOURCES}"; then \
	        for m in ${MRC_SOURCES}; do test "$$m" = "$$src" && flags=-fno-objc-arc; done; \
	    fi; \
	    if test -f "$$obj" && test "$$obj" -nt "$$src" && test "$$obj" -nt build/gen/AppKit/AppKit.h; then \
	        continue; \
	    fi; \
	    ${CC} ${CFLAGS} $${flags} -c "$$src" -o "$$obj" || exit 1; \
	done

# =====================================================================
#  Framework bundle.  Links the objects into the dylib (only when an
#  object is newer than the current binary, or the binary is missing),
#  then installs the generated headers, Info.plist and the standard
#  framework symlink layout.
# =====================================================================
link:
	@mkdir -p ${FW}/Versions/A/Headers ${FW}/Versions/A/Resources
	@objs=$$(find build/objects -name '*.o' -type f | sort); \
	if test -n "$$objs"; then \
	    if test ! -f ${DYLIB} || test -n "$$(find build/objects -name '*.o' -type f -newer ${DYLIB} | sed -n 1p)"; then \
	        ${CC} ${LDFLAGS} -o ${DYLIB} $$objs; \
	    fi; \
	 fi; \
	for h in build/gen/AppKit/*.h; do test -f "$$h" && cp "$$h" ${FW}/Versions/A/Headers/; done; \
	cp Info.plist ${FW}/Versions/A/Resources/; \
	ln -sfn A ${FW}/Versions/Current; \
	ln -sfn Versions/Current/AppKit ${FW}/AppKit; \
	ln -sfn Versions/Current/Headers ${FW}/Headers

release: umbrella objects link

clean:
	@rm -rf build

gitignore:
	@grep -q '^build/$$' .gitignore || printf 'build/\n' >> .gitignore