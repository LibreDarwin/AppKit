/*
 * Copyright (C) 2026, LibreDarwin.
 *
 * The port side of the font-name parity check: links the LibreDarwin
 * AppKit.framework and prints, for every installed PostScript name, what the
 * port's own font database calls it. Diffed against font-names-oracle.m. */

#import <Foundation/Foundation.h>
#import <AppKit/NSFontDatabase_Internal.h>
#import <CoreText/CoreText.h>
#include <stdio.h>

int main(void) {
    @autoreleasepool {
        NSArray *names = (__bridge_transfer NSArray *)CTFontManagerCopyAvailablePostScriptNames();
        names = [names sortedArrayUsingSelector:@selector(compare:)];
        for (NSString *ps in names) {
            char *out = NXFontNameForFont([ps UTF8String], 0);
            printf("%s\t%s\n", [ps UTF8String], out ? out : "(null)");
            free(out);
        }
    }
    return 0;
}
