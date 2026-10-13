/*
 * Copyright (C) 2026, LibreDarwin.
 *
 * The reference side of the font-name parity check: links the system's
 * AppKit and prints, for every installed PostScript name, what
 * `+[NSHTMLWriter fontNameForFont:]` calls it. The port's own driver
 * (font-names-main.m) prints the same shape from the LibreDarwin framework,
 * and the shell harness diffs the two.
 */

#import <AppKit/AppKit.h>
#import <CoreText/CoreText.h>
#include <stdio.h>

@interface NSHTMLWriter : NSObject
+ (NSString *)fontNameForFont:(NSFont *)font;
@end

int main(void) {
    @autoreleasepool {
        NSArray *names = (__bridge_transfer NSArray *)CTFontManagerCopyAvailablePostScriptNames();
        names = [names sortedArrayUsingSelector:@selector(compare:)];
        for (NSString *ps in names) {
            NSFont *f = [NSFont fontWithName:ps size:12];
            if (!f) continue;
            NSString *out = [NSHTMLWriter fontNameForFont:f];
            printf("%s\t%s\n", [ps UTF8String], out ? [out UTF8String] : "(null)");
        }
    }
    return 0;
}
