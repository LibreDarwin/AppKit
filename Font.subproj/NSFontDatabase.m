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

/* NSFontDatabase.m — the installed fonts, and what the writers call them.
 *
 * Two halves.  The scan half is deliberately self-contained: opendir over the
 * standard directories, a per-file parse of the sfnt offset table (or the
 * `ttcf` collection header that precedes one or more of them), and the handful
 * of tables a font's name and traits live in.  The naming half — the port of
 * `+[NSHTMLWriter fontNameForFont:]` — asks CoreText for the family's members
 * and traits, since AppKit resolves members and bold/italic through it and no
 * amount of sfnt parsing reproduces its weight classes.  See the header for
 * the interface and its consumer. */

#include "NSFontDatabase_Internal.h"

#import <CoreFoundation/CoreFoundation.h>

#include <dirent.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/stat.h>

/* ---- CoreText surface --------------------------------------------------
 *
 * Naming a face the way `+[NSHTMLWriter fontNameForFont:]` does needs the
 * family's member table and each member's traits, which only CoreText
 * carries.  The project's Internal SDK predates CoreText and its MacTypes.h
 * omits the `Fixed` typedef that CoreText's public headers rely on, so the
 * handful of CoreText entry points this file uses are declared here rather
 * than pulled in through <CoreText/CoreText.h>.  They resolve against the
 * host CoreText.framework at link time. */
typedef uint32_t CTFontSymbolicTraits;
typedef const struct __CTFont *CTFontRef;
typedef const struct __CTFontDescriptor *CTFontDescriptorRef;

extern const CFStringRef kCTFontSymbolicTrait;
extern CFTypeRef CTFontCopyAttribute(CTFontRef font, CFStringRef attribute);
extern const CFStringRef kCTFontWeightTrait;
extern const CFStringRef kCTFontFamilyNameAttribute;
extern const CFStringRef kCTFontNameAttribute;
extern const CFStringRef kCTFontStyleNameAttribute;

extern CTFontRef CTFontCreateWithName(CFStringRef name, double size, const void *matrix);
extern CTFontRef CTFontCreateWithFontDescriptor(CTFontDescriptorRef descriptor, double size, const void *matrix);
extern CTFontDescriptorRef CTFontCopyFontDescriptor(CTFontRef font);
extern CFStringRef CTFontCopyFamilyName(CTFontRef font);
extern CFDictionaryRef CTFontCopyTraits(CTFontRef font);
extern CTFontRef CTFontCreateCopyWithSymbolicTraits(CTFontRef font, double size, const void *matrix,
                                                   CTFontSymbolicTraits traitValue,
                                                   CTFontSymbolicTraits traitMask);
extern double CTFontGetSize(CTFontRef font);
extern CFStringRef CTFontCopyPostScriptName(CTFontRef font);
extern CTFontDescriptorRef CTFontDescriptorCreateWithAttributes(CFDictionaryRef attributes);
extern CFArrayRef CTFontDescriptorCreateMatchingFontDescriptors(CTFontDescriptorRef descriptor,
                                                               CFSetRef mandatoryAttributes);
extern CFTypeRef CTFontDescriptorCopyAttribute(CTFontDescriptorRef descriptor, CFStringRef attribute);

#define NX_CT_FONT_TRAIT_ITALIC ((CTFontSymbolicTraits)1)
#define NX_CT_FONT_TRAIT_BOLD ((CTFontSymbolicTraits)2)

struct NXFontDatabase {
    NXFontFace *faces;
    size_t count;
};

/* ---- big-endian readers ------------------------------------------------ */

static uint16_t be16(const uint8_t *p) { return (uint16_t)((p[0] << 8) | p[1]); }
static uint32_t be32(const uint8_t *p) {
    return ((uint32_t)p[0] << 24) | ((uint32_t)p[1] << 16) |
           ((uint32_t)p[2] << 8) | (uint32_t)p[3];
}

static uint32_t tag4(char a, char b, char c, char d) {
    return ((uint32_t)(uint8_t)a << 24) | ((uint32_t)(uint8_t)b << 16) |
           ((uint32_t)(uint8_t)c << 8) | (uint32_t)(uint8_t)d;
}

/* ---- growable lists ---------------------------------------------------- */

typedef struct {
    NXFontFace *items;
    size_t count;
    size_t cap;
} FaceList;

static void faceListAppend(FaceList *list, const NXFontFace *face) {
    if (list->count == list->cap) {
        size_t cap = list->cap ? list->cap * 2 : 64;
        list->items = realloc(list->items, cap * sizeof(*list->items));
        list->cap = cap;
    }
    list->items[list->count++] = *face;
}

typedef struct {
    char **items;
    size_t count;
    size_t cap;
} StrList;

static void strListAppend(StrList *list, const char *s) {
    if (list->count == list->cap) {
        size_t cap = list->cap ? list->cap * 2 : 64;
        list->items = realloc(list->items, cap * sizeof(*list->items));
        list->cap = cap;
    }
    list->items[list->count++] = strdup(s);
}

static void strListFree(StrList *list) {
    for (size_t i = 0; i < list->count; i++) free(list->items[i]);
    free(list->items);
}

static int strPtrCmp(const void *a, const void *b) {
    return strcmp(*(const char *const *)a, *(const char *const *)b);
}

/* ---- file helpers ------------------------------------------------------ */

static uint8_t *readWholeFile(const char *path, size_t *outSize) {
    FILE *f = fopen(path, "rb");
    if (!f) return NULL;
    if (fseek(f, 0, SEEK_END) != 0) { fclose(f); return NULL; }
    long size = ftell(f);
    if (size <= 0) { fclose(f); return NULL; }
    rewind(f);
    uint8_t *data = malloc((size_t)size);
    if (!data) { fclose(f); return NULL; }
    if (fread(data, 1, (size_t)size, f) != (size_t)size) {
        free(data);
        fclose(f);
        return NULL;
    }
    fclose(f);
    *outSize = (size_t)size;
    return data;
}

static int hasFontExtension(const char *name) {
    const char *dot = strrchr(name, '.');
    if (!dot) return 0;
    return strcasecmp(dot, ".ttf") == 0 || strcasecmp(dot, ".otf") == 0 ||
           strcasecmp(dot, ".ttc") == 0 || strcasecmp(dot, ".otc") == 0;
}

static void collectFontPaths(const char *dir, StrList *out) {
    DIR *d = opendir(dir);
    if (!d) return;
    struct dirent *entry;
    while ((entry = readdir(d)) != NULL) {
        if (entry->d_name[0] == '.') continue;
        size_t len = strlen(dir) + strlen(entry->d_name) + 2;
        char *child = malloc(len);
        snprintf(child, len, "%s/%s", dir, entry->d_name);
        struct stat st;
        if (stat(child, &st) == 0) {
            if (S_ISDIR(st.st_mode)) {
                collectFontPaths(child, out);
            } else if (S_ISREG(st.st_mode) && hasFontExtension(entry->d_name)) {
                strListAppend(out, child);
            }
        }
        free(child);
    }
    closedir(d);
}

/* ---- name table -------------------------------------------------------- */

typedef struct {
    uint16_t nameID;
    uint16_t platformID;
    uint16_t encodingID;
    uint16_t languageID;
    const uint8_t *bytes;
    size_t length;
} NameRecord;

/* The platform/language a record comes from, best-first, so a face with
 * records in several encodings picks the one Apple's tooling shows. An
 * English record always beats a non-English one regardless of platform:
 * CTFontCopyFamilyName returns the English name for a non-localized
 * (en_US) process, even when a Windows record carries, say, Arabic. */
static int nameRecordRank(const NameRecord *r) {
    int english = 0;
    if (r->platformID == 3)
        english = (r->languageID == 0x409);
    else if (r->platformID == 1)
        english = (r->languageID == 0);
    else if (r->platformID == 0)
        english = 1; /* language-neutral */
    int platform;
    switch (r->platformID) {
        case 3: /* Windows */
            platform = 300 + ((r->encodingID == 1 || r->encodingID == 10) ? 10 : 0);
            break;
        case 0: /* Unicode */
            platform = 200;
            break;
        case 1: /* Macintosh */
            platform = 100;
            break;
        default:
            platform = 50;
            break;
    }
    return (english ? 1000 : 0) + platform;
}

static char *decodeUTF16BE(const uint8_t *p, size_t length) {
    size_t units = length / 2;
    char *out = malloc(units * 4 + 1);
    size_t n = 0;
    for (size_t i = 0; i < units; i++) {
        uint32_t cp = be16(p + i * 2);
        if (cp >= 0xD800 && cp <= 0xDBFF && i + 1 < units) {
            uint32_t lo = be16(p + (i + 1) * 2);
            if (lo >= 0xDC00 && lo <= 0xDFFF) {
                cp = 0x10000 + ((cp - 0xD800) << 10) + (lo - 0xDC00);
                i++;
            }
        }
        if (cp < 0x80) {
            out[n++] = (char)cp;
        } else if (cp < 0x800) {
            out[n++] = (char)(0xC0 | (cp >> 6));
            out[n++] = (char)(0x80 | (cp & 0x3F));
        } else if (cp < 0x10000) {
            out[n++] = (char)(0xE0 | (cp >> 12));
            out[n++] = (char)(0x80 | ((cp >> 6) & 0x3F));
            out[n++] = (char)(0x80 | (cp & 0x3F));
        } else {
            out[n++] = (char)(0xF0 | (cp >> 18));
            out[n++] = (char)(0x80 | ((cp >> 12) & 0x3F));
            out[n++] = (char)(0x80 | ((cp >> 6) & 0x3F));
            out[n++] = (char)(0x80 | (cp & 0x3F));
        }
    }
    out[n] = '\0';
    return out;
}

/* MacRoman shares ASCII with everything below 0x80; the high half is rare in
 * the names a font table carries, so a byte-for-byte copy is close enough and
 * never mangles the ASCII the writers key on. */
static char *decodeNameRecord(const NameRecord *r) {
    if (r->platformID == 0 || r->platformID == 3) {
        return decodeUTF16BE(r->bytes, r->length);
    }
    char *out = malloc(r->length + 1);
    memcpy(out, r->bytes, r->length);
    out[r->length] = '\0';
    return out;
}

static char *pickName(const NameRecord *records, size_t count, uint16_t nameID) {
    const NameRecord *best = NULL;
    int bestRank = -1;
    for (size_t i = 0; i < count; i++) {
        if (records[i].nameID != nameID || records[i].length == 0) continue;
        int rank = nameRecordRank(&records[i]);
        if (rank > bestRank) { bestRank = rank; best = &records[i]; }
    }
    return best ? decodeNameRecord(best) : NULL;
}

/* ---- table access ------------------------------------------------------ */

typedef struct {
    uint32_t tag;
    uint32_t offset;
    uint32_t length;
} TableRecord;

static const uint8_t *findTable(const uint8_t *data, size_t size, const TableRecord *tables,
                                size_t tableCount, uint32_t tag, uint32_t *outLength) {
    for (size_t i = 0; i < tableCount; i++) {
        if (tables[i].tag == tag) {
            uint64_t end = (uint64_t)tables[i].offset + tables[i].length;
            if (end > size || tables[i].offset > size) return NULL;
            if (outLength) *outLength = tables[i].length;
            return data + tables[i].offset;
        }
    }
    return NULL;
}

/* ---- face parsing ------------------------------------------------------ */

static void freeFaceStrings(NXFontFace *face) {
    free(face->postScriptName);
    free(face->familyName);
    free(face->styleName);
    free(face->fullName);
    free(face->sourcePath);
}

/* Parses one sfnt face beginning at `base` inside `data`, filling `out`
 * (zeroed by the caller). Returns 1 on success. */
static int parseSfntFace(const uint8_t *data, size_t size, size_t base, const char *path,
                         uint32_t faceIndex, NXFontFace *out) {
    if (base + 12 > size) return 0;
    const uint8_t *h = data + base;
    uint32_t version = be32(h);
    if (version != 0x00010000 && version != tag4('O', 'T', 'T', 'O') &&
        version != tag4('t', 'r', 'u', 'e') && version != tag4('t', 'y', 'p', '1')) {
        return 0;
    }
    uint16_t numTables = be16(h + 4);
    if ((size_t)base + 12 + (size_t)numTables * 16 > size) return 0;

    TableRecord *tables = calloc(numTables, sizeof(*tables));
    for (uint16_t i = 0; i < numTables; i++) {
        const uint8_t *r = h + 12 + (size_t)i * 16;
        tables[i].tag = be32(r);
        tables[i].offset = be32(r + 8);
        tables[i].length = be32(r + 12);
    }

    char *family = NULL, *style = NULL, *full = NULL, *ps = NULL;

    uint32_t nameLen = 0;
    const uint8_t *name = findTable(data, size, tables, numTables, tag4('n', 'a', 'm', 'e'), &nameLen);
    if (name && nameLen >= 6) {
        uint16_t count = be16(name + 2);
        uint16_t stringOffset = be16(name + 4);
        if ((size_t)6 + (size_t)count * 12 <= nameLen) {
            NameRecord *records = malloc((size_t)count * sizeof(*records));
            size_t n = 0;
            for (uint16_t i = 0; i < count; i++) {
                const uint8_t *r = name + 6 + (size_t)i * 12;
                uint16_t length = be16(r + 8);
                uint16_t offset = be16(r + 10);
                size_t abs = (size_t)stringOffset + offset;
                if (abs > nameLen || length > nameLen - abs) continue;
                records[n].nameID = be16(r + 6);
                records[n].platformID = be16(r + 0);
                records[n].encodingID = be16(r + 2);
                records[n].languageID = be16(r + 4);
                records[n].bytes = name + abs;
                records[n].length = length;
                n++;
            }
            char *typoFamily = pickName(records, n, 16);
            char *typoStyle = pickName(records, n, 17);
            char *baseFamily = pickName(records, n, 1);
            char *baseStyle = pickName(records, n, 2);
            family = typoFamily ? typoFamily : baseFamily;
            if (typoFamily && baseFamily && baseFamily != typoFamily) free(baseFamily);
            style = typoStyle ? typoStyle : baseStyle;
            if (typoStyle && baseStyle && baseStyle != typoStyle) free(baseStyle);
            full = pickName(records, n, 4);
            ps = pickName(records, n, 6);
            free(records);
        }
    }

    if (!ps && !family) {
        free(tables);
        free(family); free(style); free(full);
        return 0;
    }
    if (!ps) ps = family ? strdup(family) : NULL;
    if (!family) family = ps ? strdup(ps) : NULL;
    if (!style) style = strdup("Regular");
    if (!full) full = strdup(family);

    uint16_t weight = 0, width = 0;
    uint8_t bold = 0, italic = 0, fixedPitch = 0;

    uint32_t headLen = 0;
    const uint8_t *head = findTable(data, size, tables, numTables, tag4('h', 'e', 'a', 'd'), &headLen);
    if (head && headLen >= 46) {
        uint16_t macStyle = be16(head + 44);
        bold |= (macStyle & 0x01) != 0;
        italic |= (macStyle & 0x02) != 0;
    }

    uint32_t os2Len = 0;
    const uint8_t *os2 = findTable(data, size, tables, numTables, tag4('O', 'S', '/', '2'), &os2Len);
    if (os2 && os2Len >= 8) {
        weight = be16(os2 + 4);
        width = be16(os2 + 6);
        if (os2Len >= 64) {
            uint16_t fsSelection = be16(os2 + 62);
            bold |= (fsSelection & 0x20) != 0;
            italic |= (fsSelection & 0x01) != 0;
            italic |= (fsSelection & 0x200) != 0;   /* OBLIQUE */
        }
    }

    uint32_t postLen = 0;
    const uint8_t *post = findTable(data, size, tables, numTables, tag4('p', 'o', 's', 't'), &postLen);
    if (post && postLen >= 16) fixedPitch = be32(post + 12) != 0;

    free(tables);

    out->postScriptName = ps;
    out->familyName = family;
    out->styleName = style;
    out->fullName = full;
    out->weight = weight;
    out->width = width;
    out->bold = bold;
    out->italic = italic;
    out->fixedPitch = fixedPitch;
    out->sourcePath = strdup(path);
    out->faceIndex = faceIndex;
    return 1;
}

NXFontDatabase *NXFontDatabaseCreate(void) {
    static const char *dirs[] = {
        "/System/Library/Fonts",
        "/System/Library/Fonts/Supplemental",
        "/Library/Fonts",
        /* Apple ships the optional families as mobile assets rather than in
         * /System/Library/Fonts; the preinstalled tier is what shows up in
         * the enabled set, the top-level tier holds anything since installed. */
        "/System/Library/AssetsV2/PreinstalledAssetsV2/InstallWithOs/com_apple_MobileAsset_Font7",
        "/System/Library/AssetsV2/com_apple_MobileAsset_Font8",
        NULL,
    };
    char homeFonts[4096];
    const char *home = getenv("HOME");
    const char *search[8];
    size_t n = 0;
    for (size_t i = 0; dirs[i]; i++) search[n++] = dirs[i];
    if (home) {
        snprintf(homeFonts, sizeof(homeFonts), "%s/Library/Fonts", home);
        search[n++] = homeFonts;
    }
    search[n] = NULL;
    return NXFontDatabaseCreateWithDirectories(search);
}

NXFontDatabase *NXFontDatabaseCreateWithDirectories(const char *const *directories) {
    StrList paths = {0};
    for (size_t i = 0; directories[i]; i++) collectFontPaths(directories[i], &paths);
    if (paths.count == 0) { strListFree(&paths); return NULL; }
    qsort(paths.items, paths.count, sizeof(*paths.items), strPtrCmp);

    FaceList faces = {0};
    for (size_t i = 0; i < paths.count; i++) {
        NXFontFace *fileFaces = NULL;
        size_t n = NXFontFacesFromFile(paths.items[i], &fileFaces);
        /* Take ownership of the faces (and their strings); only the array
         * returned by NXFontFacesFromFile is released here. */
        for (size_t j = 0; j < n; j++) faceListAppend(&faces, &fileFaces[j]);
        free(fileFaces);
        free(paths.items[i]);
    }
    free(paths.items);

    NXFontDatabase *db = calloc(1, sizeof(*db));
    db->faces = faces.items;
    db->count = faces.count;
    return db;
}

size_t NXFontFacesFromFile(const char *path, NXFontFace **outFaces) {
    *outFaces = NULL;
    size_t size = 0;
    uint8_t *data = readWholeFile(path, &size);
    if (!data) return 0;

    FaceList faces = {0};
    if (size >= 12 && be32(data) == tag4('t', 't', 'c', 'f')) {
        uint32_t numFonts = be32(data + 8);
        for (uint32_t i = 0; i < numFonts; i++) {
            if ((size_t)12 + (size_t)i * 4 + 4 > size) break;
            uint32_t offset = be32(data + 12 + (size_t)i * 4);
            NXFontFace face = {0};
            if (parseSfntFace(data, size, offset, path, i, &face)) faceListAppend(&faces, &face);
        }
    } else {
        NXFontFace face = {0};
        if (parseSfntFace(data, size, 0, path, 0, &face)) faceListAppend(&faces, &face);
    }
    free(data);

    *outFaces = faces.items;
    return faces.count;
}

void NXFontDatabaseFreeFaces(NXFontFace *faces, size_t count) {
    if (!faces) return;
    for (size_t i = 0; i < count; i++) freeFaceStrings(&faces[i]);
    free(faces);
}

void NXFontDatabaseFree(NXFontDatabase *db) {
    if (!db) return;
    NXFontDatabaseFreeFaces(db->faces, db->count);
    free(db);
}

size_t NXFontDatabaseFaceCount(const NXFontDatabase *db) { return db ? db->count : 0; }

const NXFontFace *NXFontDatabaseFaceAtIndex(const NXFontDatabase *db, size_t index) {
    if (!db || index >= db->count) return NULL;
    return &db->faces[index];
}

const NXFontFace *NXFontDatabaseFaceNamed(const NXFontDatabase *db, const char *postScriptName) {
    if (!db || !postScriptName) return NULL;
    for (size_t i = 0; i < db->count; i++) {
        if (db->faces[i].postScriptName &&
            strcmp(db->faces[i].postScriptName, postScriptName) == 0) {
            return &db->faces[i];
        }
    }
    return NULL;
}

size_t NXFontDatabaseMembersOfFamily(const NXFontDatabase *db, const char *family,
                                     const NXFontFace **members, size_t capacity) {
    if (!db || !family) return 0;
    size_t total = 0;
    for (size_t i = 0; i < db->count; i++) {
        if (db->faces[i].familyName && strcmp(db->faces[i].familyName, family) == 0) {
            if (total < capacity && members) members[total] = &db->faces[i];
            total++;
        }
    }
    return total;
}

/* ---- font naming ------------------------------------------------------- */
/*
 * The name the writers put in a font table for a face — the port of
 * `+[NSHTMLWriter fontNameForFont:]`.  The name is the face's family,
 * unless one of the family's plain members carries a style the writers
 * bother to keep — Condensed, ExtraBlack, Light, Ornaments, SemiBold or
 * UltraLight — in which case the style is appended.  The member table and
 * the traits come from CoreText, exactly as AppKit resolves them: the face
 * is first reduced to its non-bold, non-italic "core" member with
 * CTFontCreateCopyWithSymbolicTraits before the members are consulted.
 */

static char *copyCFString(CFStringRef string) {
    if (!string) return NULL;
    CFIndex size =
        CFStringGetMaximumSizeForEncoding(CFStringGetLength(string), kCFStringEncodingUTF8) + 1;
    char *buffer = malloc((size_t)size);
    if (!buffer) return NULL;
    if (!CFStringGetCString(string, buffer, size, kCFStringEncodingUTF8)) {
        free(buffer);
        return NULL;
    }
    return buffer;
}

static int isAppendStyle(const char *style) {
    static const char *const styles[] = {
        "Condensed", "ExtraBlack", "Light", "Ornaments", "SemiBold", "UltraLight",
    };
    for (size_t i = 0; i < sizeof(styles) / sizeof(styles[0]); i++) {
        if (strcasecmp(style, styles[i]) == 0) return 1;
    }
    return 0;
}

static int hasSuffix(const char *s, const char *suffix) {
    size_t ls = strlen(s), lf = strlen(suffix);
    return lf <= ls && strcmp(s + ls - lf, suffix) == 0;
}

static int weightClassFromStyleName(const char *styleName, double weight, int *flagOut) {
    if (flagOut) *flagOut = 0;
    if (!styleName) {
        int q = (int)(weight * 10.0);
        if (q >= 8) return 14;
        if (q >= 3) return q + 5;
        if (q >= 1) return q + 4;
        if (q >= -1) return 5;
        if (q >= -3) return 4;
        if (q >= -6) return 3;
        return 2;
    }
    if (strcmp(styleName, "Regular") == 0 || strcmp(styleName, "Plain") == 0 ||
        strcmp(styleName, "Italic") == 0 || strcmp(styleName, "Oblique") == 0) {
        return 5;
    }
    if (strcmp(styleName, "Light") == 0) return 3;
    if (strcmp(styleName, "Thin") == 0) { if (flagOut) *flagOut = 1; return 3; }
    if (strcmp(styleName, "Medium") == 0 || strcmp(styleName, "Medium Italic") == 0) return 6;
    if (strcmp(styleName, "Bold") == 0 || strcmp(styleName, "Bold Italic") == 0 ||
        strcmp(styleName, "Bold Oblique") == 0) return 9;
    if (strcmp(styleName, "W2") == 0) return 3;
    if (strcmp(styleName, "W3") == 0) return 4;
    if (strcmp(styleName, "W4") == 0) return 5;
    if (strcmp(styleName, "W5") == 0) return 6;
    if (strcmp(styleName, "W6") == 0) return 8;
    if (strcmp(styleName, "W7") == 0) return 9;
    if (strcmp(styleName, "W8") == 0) return 10;
    if (strcmp(styleName, "W9") == 0) return 12;
    int q = (int)(weight * 10.0);
    if (q == -6) { if (flagOut) *flagOut = 1; return 3; }
    if (q >= 8) return 14;
    if (q >= 3) return q + 5;
    if (q >= 1) return q + 4;
    if (q >= -1) return 5;
    if (q >= -3) return 4;
    if (q >= -6) return 3;
    return 2;
}


/* The member "traits" word AppKit's -[NSFontManager availableMembersOfFontFamily:]
 * publishes: the low 16 bits are the CoreText symbolic traits and bit 16 is the
 * out-flag from ___NSWeightFromStyle (set for thin faces). */
/* The PostScript name a face falls back to once its bold and italic traits
 * are read off, using CoreText's own copy-with-traits the way AppKit's
 * -[NSFontManager convertFont:toNotHaveTrait:] does. */
static double getWeight(CTFontRef f){
    double w=0.0;CFDictionaryRef t=CTFontCopyTraits(f);
    if(t){CFNumberRef nw=(CFNumberRef)CFDictionaryGetValue(t,kCTFontWeightTrait);
        if(nw)CFNumberGetValue(nw,kCFNumberDoubleType,&w);CFRelease(t);}return w;}
static int getSym(CTFontRef f){
    int s=0;CFDictionaryRef t=CTFontCopyTraits(f);
    if(t){CFNumberRef ns=(CFNumberRef)CFDictionaryGetValue(t,kCTFontSymbolicTrait);
        if(ns){SInt32 v=0;CFNumberGetValue(ns,kCFNumberSInt32Type,&v);s=v;}CFRelease(t);}return s;}

static int memberTraits(CTFontRef f){
    CFStringRef st=CTFontCopyAttribute(f,kCTFontStyleNameAttribute);
    char *sc=st?copyCFString(st):NULL;int flag=0;
    weightClassFromStyleName(sc,getWeight(f),&flag);
    free(sc);if(st)CFRelease(st);
    return (getSym(f)&0xffff)|(flag?0x10000:0);}

/* -[NSFontManager availableMembersOfFontFamily:] keeps only the first CoreText
 * descriptor seen for each style name, so PostScript aliases that share a style
 * (FiraCodeRoman-*, FiraCodeNerdFontComplete*) are dropped. */
static CFArrayRef copyUniqueMembers(CFArrayRef members){
    if(!members)return NULL;
    CFMutableArrayRef out=CFArrayCreateMutable(NULL,0,&kCFTypeArrayCallBacks);
    CFMutableArrayRef styles=CFArrayCreateMutable(NULL,0,&kCFTypeArrayCallBacks);
    if(!out||!styles){if(out)CFRelease(out);if(styles)CFRelease(styles);return NULL;}
    CFIndex n=CFArrayGetCount(members);
    for(CFIndex i=0;i<n;i++){
        CTFontDescriptorRef md=(CTFontDescriptorRef)CFArrayGetValueAtIndex(members,i);
        CFStringRef st=(CFStringRef)CTFontDescriptorCopyAttribute(md,kCTFontStyleNameAttribute);
        if(!st)continue;
        int dup=0;
        for(CFIndex j=0,m=CFArrayGetCount(styles);j<m;j++){
            if(CFEqual(CFArrayGetValueAtIndex(styles,j),st)){dup=1;break;}
        }
        if(!dup){CFArrayAppendValue(out,md);CFArrayAppendValue(styles,st);}
        CFRelease(st);
    }
    CFRelease(styles);
    return out;}

static CFStringRef copyStrippedPostScriptName(CTFontRef font) {
    CFStringRef familyRef = CTFontCopyFamilyName(font);
    if (!familyRef) return CTFontCopyPostScriptName(font);
    CFDictionaryRef famAttr = CFDictionaryCreate(NULL, (const void **)&kCTFontFamilyNameAttribute,
                                                 (const void **)&familyRef, 1,
                                                 &kCFTypeDictionaryKeyCallBacks, &kCFTypeDictionaryValueCallBacks);
    CTFontDescriptorRef desc = CTFontDescriptorCreateWithAttributes(famAttr);
    CFArrayRef all = NULL;
    if (desc) {
        all = CTFontDescriptorCreateMatchingFontDescriptors(desc, NULL);
        CFRelease(desc);
    }
    CFRelease(famAttr);
    CFRelease(familyRef);
    CFStringRef resultName = NULL;
    CFArrayRef members = copyUniqueMembers(all);
    if (all) CFRelease(all);
    if (members) {
        /* The traits AppKit publishes come from a font built from the member
         * descriptor (fixed pitch and the other descriptor-only traits are
         * lost when a face is rebuilt from its PostScript name). */
        CTFontDescriptorRef fdesc = CTFontCopyFontDescriptor(font);
        CTFontRef cur = fdesc ? CTFontCreateWithFontDescriptor(fdesc, 12.0, NULL)
                              : (CTFontRef)CFRetain(font);
        if (fdesc) CFRelease(fdesc);
        if (!cur) cur = (CTFontRef)CFRetain(font);
        int curSym = getSym(cur);
        int curTraits = memberTraits(cur);
        CFStringRef sref = CTFontCopyAttribute(cur, kCTFontStyleNameAttribute);
        char *sstr = sref ? copyCFString(sref) : NULL;
        if (sref) CFRelease(sref);
        int curClass = weightClassFromStyleName(sstr, getWeight(cur), NULL);
        free(sstr);
        /* Strip bold then italic, matching -[NSFontManager convertFont:toNotHaveTrait:]:
         * the replacement member shares the font's class when possible, otherwise
         * the plain (class 5) member, else the first member with the wanted traits. */
        for (int pass = 0; pass < 2; pass++) {
            int mask = pass == 0 ? NX_CT_FONT_TRAIT_BOLD : NX_CT_FONT_TRAIT_ITALIC;
            if (!(curSym & mask)) continue;
            int want = curTraits & ~mask;
            int best = -1, base = -1, first = -1;
            CFIndex n = CFArrayGetCount(members);
            for (CFIndex i = 0; i < n; i++) {
                CTFontDescriptorRef md = (CTFontDescriptorRef)CFArrayGetValueAtIndex(members, i);
                CTFontRef mf = CTFontCreateWithFontDescriptor(md, 12.0, NULL);
                if (!mf) continue;
                if (memberTraits(mf) == want) {
                    CFStringRef mst = CTFontCopyAttribute(mf, kCTFontStyleNameAttribute);
                    char *msc = mst ? copyCFString(mst) : NULL;
                    if (mst) CFRelease(mst);
                    int mc = weightClassFromStyleName(msc, getWeight(mf), NULL);
                    free(msc);
                    if (first < 0) first = (int)i;
                    if (best < 0 && mc == curClass) best = (int)i;
                    if (base < 0 && mc == 5) base = (int)i;
                }
                CFRelease(mf);
            }
            int pk = best >= 0 ? best : (base >= 0 ? base : first);
            if (pk >= 0) {
                CTFontDescriptorRef md = (CTFontDescriptorRef)CFArrayGetValueAtIndex(members, pk);
                CTFontRef nxt = CTFontCreateWithFontDescriptor(md, 12.0, NULL);
                if (nxt) {
                    CFRelease(cur);
                    cur = nxt;
                    curSym = getSym(cur);
                    curTraits = memberTraits(cur);
                    CFStringRef sr = CTFontCopyAttribute(cur, kCTFontStyleNameAttribute);
                    char *sc = sr ? copyCFString(sr) : NULL;
                    if (sr) CFRelease(sr);
                    curClass = weightClassFromStyleName(sc, getWeight(cur), NULL);
                    free(sc);
                }
            }
        }
        resultName = CTFontCopyPostScriptName(cur);
        CFRelease(cur);
        CFRelease(members);
    } else {
        resultName = CTFontCopyPostScriptName(font);
    }
    return resultName;
}

char *NXFontNameForFontInDatabase(const NXFontDatabase *db, const char *postScriptName,
                                  int plainMode) {
    (void)db;
    if (!postScriptName) return NULL;
    CFStringRef name = CFStringCreateWithCString(NULL, postScriptName, kCFStringEncodingUTF8);
    if (!name) return NULL;
    CTFontRef font = CTFontCreateWithName(name, 12.0, NULL);
    if (!font) {
        CFRelease(name);
        return NULL;
    }
    CFStringRef familyRef = CTFontCopyFamilyName(font);
    char *family = copyCFString(familyRef);
    if (strcmp(postScriptName, "LastResort") == 0 ||
        (family && strcmp(family, "LastResort") == 0)) {
        free(family);
        CFRelease(familyRef);
        CFRelease(font);
        CFRelease(name);
        return NULL;
    }

    char *result = NULL;
    if (plainMode) {
        result = (family && strncmp(family, ".SF", 3) == 0) ? strdup("system-ui")
                                                            : strdup(family ? family : "");
    } else {
        CFStringRef strippedName = copyStrippedPostScriptName(font);
        CFStringRef key = kCTFontFamilyNameAttribute;
        CFDictionaryRef query =
            CFDictionaryCreate(NULL, (const void **)&key, (const void **)&familyRef, 1,
                               &kCFTypeDictionaryKeyCallBacks, &kCFTypeDictionaryValueCallBacks);
        CTFontDescriptorRef descriptor = CTFontDescriptorCreateWithAttributes(query);
        CFArrayRef allMembers = CTFontDescriptorCreateMatchingFontDescriptors(descriptor, NULL);
        CFArrayRef members = copyUniqueMembers(allMembers);
        if (allMembers) CFRelease(allMembers);
        if (members) {
            for (CFIndex i = 0; i < CFArrayGetCount(members); i++) {
                CTFontDescriptorRef member = (CTFontDescriptorRef)CFArrayGetValueAtIndex(members, i);
                CFStringRef memberName = (CFStringRef)CTFontDescriptorCopyAttribute(member, kCTFontNameAttribute);
                int matches =
                    memberName &&
                    ((CFStringCompare(memberName, name, 0) == kCFCompareEqualTo) ||
                     (strippedName && CFStringCompare(memberName, strippedName, 0) == kCFCompareEqualTo));
                if (memberName) CFRelease(memberName);
                if (!matches) continue;
                CFStringRef styleRef = (CFStringRef)CTFontDescriptorCopyAttribute(member, kCTFontStyleNameAttribute);
                if (!styleRef) continue;
                char *style = copyCFString(styleRef);
                if (style && family && isAppendStyle(style) && !hasSuffix(family, style)) {
                    size_t length = strlen(family) + strlen(style) + 2;
                    result = malloc(length);
                    snprintf(result, length, "%s %s", family, style);
                }
                free(style);
                CFRelease(styleRef);
                if (result) break;
            }
            CFRelease(members);
        }
        if (strippedName) CFRelease(strippedName);
        if (descriptor) CFRelease(descriptor);
        if (query) CFRelease(query);
        if (!result) result = strdup(family ? family : "");
    }

    free(family);
    CFRelease(familyRef);
    CFRelease(font);
    CFRelease(name);
    return result;
}

char *NXFontNameForFont(const char *postScriptName, int plainMode) {
    return NXFontNameForFontInDatabase(NULL, postScriptName, plainMode);
}

size_t NXFontMembersOfFamily(const char *family, NXFontMemberInfo **outMembers) {
    if (!family || !outMembers) return 0;
    CFStringRef familyRef = CFStringCreateWithCString(NULL, family, kCFStringEncodingUTF8);
    if (!familyRef) return 0;
    CFDictionaryRef query = CFDictionaryCreate(NULL, (const void **)&kCTFontFamilyNameAttribute,
                                              (const void **)&familyRef, 1,
                                              &kCFTypeDictionaryKeyCallBacks, &kCFTypeDictionaryValueCallBacks);
    CTFontDescriptorRef desc = CTFontDescriptorCreateWithAttributes(query);
    CFArrayRef all = desc ? CTFontDescriptorCreateMatchingFontDescriptors(desc, NULL) : NULL;
    CFArrayRef members = copyUniqueMembers(all);
    size_t count = 0;
    NXFontMemberInfo *infos = NULL;
    if (members) {
        CFIndex n = CFArrayGetCount(members);
        infos = calloc(n, sizeof(*infos));
        count = 0;
        for (CFIndex i = 0; i < n; i++) {
            CTFontDescriptorRef md = (CTFontDescriptorRef)CFArrayGetValueAtIndex(members, i);
            CFStringRef psRef = (CFStringRef)CTFontDescriptorCopyAttribute(md, kCTFontNameAttribute);
            CFStringRef styleRef = (CFStringRef)CTFontDescriptorCopyAttribute(md, kCTFontStyleNameAttribute);
            if (!psRef) continue;
            char *ps = copyCFString(psRef);
            char *style = styleRef ? copyCFString(styleRef) : strdup("");
            CFRelease(psRef);
            if (styleRef) CFRelease(styleRef);
            if (!ps) { free(style); continue; }
            CTFontRef f = CTFontCreateWithFontDescriptor(md, 12.0, NULL);
            int weight = f ? (int)CTFontGetSize(f) ? 0 : 0 : 0; /* dummy to avoid unused in some cases? */
            /* compute weight/tratis properly */
            int traits = 0;
            int weightClass = 5;
            int thinFlag = 0;
            if (f) {
                CFStringRef s2 = CTFontCopyAttribute(f, kCTFontStyleNameAttribute);
                char *sc = s2 ? copyCFString(s2) : NULL;
                double w = getWeight(f);
                weightClassFromStyleName(sc, w, &thinFlag);
                free(sc);
                if (s2) CFRelease(s2);
                traits = memberTraits(f);
                weightClass = weightClassFromStyleName(style, getWeight(f), &thinFlag);
                CFRelease(f);
            }
            infos[count].postScriptName = ps;
            infos[count].styleName = style;
            infos[count].weight = weightClass;
            infos[count].traits = traits;
            count++;
        }
        CFRelease(members);
    }
    if (all) CFRelease(all);
    if (desc) CFRelease(desc);
    if (query) CFRelease(query);
    CFRelease(familyRef);
    *outMembers = infos;
    return count;
}

void NXFontMembersFree(NXFontMemberInfo *members, size_t count) {
    if (!members) return;
    for (size_t i = 0; i < count; i++) {
        free(members[i].postScriptName);
        free(members[i].styleName);
    }
    free(members);
}

static CTFontRef fontRefForName(const char *postScriptName) {
    if (!postScriptName) return NULL;
    CFStringRef name = CFStringCreateWithCString(NULL, postScriptName, kCFStringEncodingUTF8);
    if (!name) return NULL;
    CTFontRef f = CTFontCreateWithName(name, 12.0, NULL);
    CFRelease(name);
    return f;
}

int NXFontSymbolicTraitsForName(const char *postScriptName) {
    CTFontRef f = fontRefForName(postScriptName);
    if (!f) return 0;
    int sym = getSym(f) & 0xffff;
    if (!(sym & 2)) {
        CFStringRef s = CTFontCopyAttribute(f, kCTFontStyleNameAttribute);
        char *sc = s ? copyCFString(s) : NULL;
        int flag = 0;
        weightClassFromStyleName(sc, getWeight(f), &flag);
        free(sc);
        if (s) CFRelease(s);
        sym |= (flag ? 0x10000 : 0);
    }
    CFRelease(f);
    return sym;
}

int NXFontWeightClassForName(const char *postScriptName) {
    CTFontRef f = fontRefForName(postScriptName);
    if (!f) return 5;
    CFStringRef s = CTFontCopyAttribute(f, kCTFontStyleNameAttribute);
    char *sc = s ? copyCFString(s) : NULL;
    int flag = 0;
    int w = weightClassFromStyleName(sc, getWeight(f), &flag);
    free(sc);
    if (s) CFRelease(s);
    CFRelease(f);
    return w;
}
