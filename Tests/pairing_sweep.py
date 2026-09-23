#!/usr/bin/env python3
"""Full-AppKit pairing sweep.

For every header under the project that declares Objective-C methods (an
@interface or @protocol block), every selector declared there must be
implemented somewhere in the .m sources. Exits non-zero (FAIL) when any
declared selector has no implementation.

Methods declared inside an @optional section of a protocol are explicitly not
part of the required contract and are skipped. Category-declared properties
(whose accessors cannot be synthesized) are checked as ordinary methods when
they have a '-'/'+' signature; @property lines themselves are not scanned.

Non-source directories (build output, local/ reference material, Tests/) and
hidden directories are excluded from the sweep.

Usage:  pairing_sweep.py [ROOT]
        ROOT defaults to the directory containing this script.

Derived from the PureDarwin Foundation project's Tests/pairing_sweep.py
(https://github.com/PureDarwin/Foundation), file-level licensed under the
Mozilla Public License, v. 2.0. This file retains that license. A copy of the
MPL-2.0 text is available at https://mozilla.org/MPL/2.0/.
"""
import os
import re
import sys

ROOT = os.path.dirname(os.path.abspath(__file__)) if len(sys.argv) < 2 else sys.argv[1]

# Directories that hold no framework sources. build/ is generated output,
# local/ is reference material (NeXT sources, etc.), Tests/ holds the test
# harnesses themselves (whose .m files would otherwise count as
# implementations), and hidden directories are bookkeeping.
SKIP_DIRS = {"build", "local", "Tests"}

# Selectors the mechanical parser cannot see as implemented, verified by hand
# to exist in the sources. Each entry: (header basename, selector, where implemented).
ALLOWLIST = [
]


def selectors_header(src):
    out = set()
    # Capturing group: re.split yields [preamble, keyword, body, keyword, body, ...]
    # so we can tell @protocol chunks (whose @optional methods are not contract)
    # apart from @interface/@implementation chunks.
    pieces = re.split(r'^@(interface|implementation|protocol)\b', src, flags=re.M)
    for i in range(1, len(pieces), 2):
        keyword, c = pieces[i], pieces[i + 1]
        if keyword == 'protocol':
            # @optional methods are not a hard contract for the conformer;
            # drop them so they don't show up as missing.
            c = re.sub(r'@optional\b.*?(?=(?:@required\b)|(?:@end\b))', '', c, flags=re.S)
        flat = re.sub(r'-\s*\([^)]*\)(?:[^;\n{}]|\n)+?;?', lambda mo: mo.group(0).replace('\n', ' '), c)
        for k in ('-', '+'):
            for decl in re.findall(re.escape(k) + r'\s*\([^)]*\)\s*([^;{]+?)\s*;', flat):
                parts = re.findall(r'([a-zA-Z_][a-zA-Z0-9_]*):', decl)
                if parts:
                    out.add(''.join(parts))
                else:
                    name = decl.strip().split(' ')[0]
                    if re.match(r'[a-zA-Z_][a-zA-Z0-9_]*$', name):
                        out.add(name)
    return out


def selectors_impls(src):
    out = set()
    flat = src.replace('\n', ' ')
    for k in ('-', '+'):
        for decl in re.findall(re.escape(k) + r'\s*\([^)]*\)\s*([^;{]+?)\s*[{;]', flat):
            parts = re.findall(r'([a-zA-Z_][a-zA-Z0-9_]*):', decl)
            if parts:
                out.add(''.join(parts))
            else:
                name = decl.strip().split(' ')[0]
                if re.match(r'[a-zA-Z_][a-zA-Z0-9_]*$', name):
                    out.add(name)
    return out


def source_dirs(root):
    return sorted(d for d in os.listdir(root)
                  if d not in SKIP_DIRS and not d.startswith('.')
                  and os.path.isdir(os.path.join(root, d)))


def main():
    subdirs = source_dirs(ROOT)
    m_texts = []
    for d in subdirs:
        dd = os.path.join(ROOT, d)
        for f in sorted(os.listdir(dd)):
            if f.endswith('.m'):
                m_texts.append(open(os.path.join(dd, f)).read())
    impl = selectors_impls(' '.join(m_texts))

    failures = 0
    total_decl = 0
    allowlisted = 0
    print('%-30s %5s %6s   missing' % ('header', 'decl', 'missing'))
    for subdir in subdirs:
        dd = os.path.join(ROOT, subdir)
        for f in sorted(os.listdir(dd)):
            if not f.endswith('.h'):
                continue
            hf = os.path.join(dd, f)
            src = open(hf).read()
            if '@interface' not in src and '@protocol' not in src:
                continue
            hs = selectors_header(src)
            if not hs:
                continue
            total_decl += len(hs)
            blocked = {entry[1] for entry in ALLOWLIST if entry[0] == f}
            missing = sorted(s for s in hs if s not in impl)
            real = [s for s in missing if s not in blocked]
            hit = [s + ' [allowlisted]' for s in missing if s in blocked]
            allowlisted += len(hit)
            print('%-30s %5d %6d   %s' % (f, len(hs), len(missing), ' '.join(real + hit)))
            if real:
                failures += 1
    print('PAIRING SWEEP: headers=%d declared=%d allowlisted=%d failing-headers=%d FAIL=%d'
          % (count_headers(ROOT, subdirs), total_decl, allowlisted, failures, int(failures > 0)))
    return 1 if failures else 0


def count_headers(root, subdirs):
    n = 0
    for d in subdirs:
        dd = os.path.join(root, d)
        for f in sorted(os.listdir(dd)):
            if f.endswith('.h'):
                src = open(os.path.join(dd, f)).read()
                if ('@interface' in src or '@protocol' in src) and selectors_header(src):
                    n += 1
    return n


if __name__ == '__main__':
    sys.exit(main())