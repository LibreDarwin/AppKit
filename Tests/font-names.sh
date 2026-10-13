#!/bin/sh
#
# Copyright (C) 2026, LibreDarwin.
#
# Font-name parity: every installed face is named twice, once by the system's
# `+[NSHTMLWriter fontNameForFont:]` and once by the port's own font database,
# and the two lists are diffed line for line. Build the framework first
# (make release). Usage: font-names.sh  [show|all]   (default: report only)
#
set -e

cd "$(dirname "$0")/.."
ROOT="$PWD"

RN="/Users/sunneva/xnuports-root/devel/xcode-tools/build/release/Developer/Platforms/MacOSX.platform/Developer/SDKs/MacOSX.Internal.sdk"
TMP="/var/folders/rl/j819t0wj451c1l81w697mmv00000gn/T/opencode/font-names"
mkdir -p "$TMP"

# The reference: the system's AppKit and CoreText, from the default SDK.
clang -fobjc-arc \
    -framework AppKit -framework CoreText \
    "$ROOT/Tests/font-names-oracle.m" -o "$TMP/oracle" \
    || { echo "ORACLE BUILD FAILED"; exit 1; }
"$TMP/oracle" > "$TMP/expected.txt"

# The port: the LibreDarwin AppKit.framework just built, ahead of the system
# one on the search path; headers and CoreText come from the default SDK.
clang -fobjc-arc \
    -F "$ROOT/build/release" \
    -I "$ROOT/build/gen" \
    -framework AppKit -framework CoreText \
    -Wl,-rpath,"$ROOT/build/release" \
    "$ROOT/Tests/font-names-main.m" -o "$TMP/main" \
    || { echo "PORT BUILD FAILED"; exit 1; }
"$TMP/main" > "$TMP/actual.txt"

total=$(wc -l < "$TMP/expected.txt" | tr -d ' ')
if diff -u "$TMP/expected.txt" "$TMP/actual.txt" > "$TMP/diff.txt"; then
    echo "FONT NAMES PASS=$total FAIL=0"
else
    fail=$(grep -c '^-[^-]' "$TMP/diff.txt" || true)
    echo "FONT NAMES PASS=$((total - fail)) FAIL=$fail"
    case "${1:-report}" in
        show|all) sed -n '1,200p' "$TMP/diff.txt" ;;
        *) echo "  (diff at $TMP/diff.txt; run with 'show')" ;;
    esac
    exit 1
fi
