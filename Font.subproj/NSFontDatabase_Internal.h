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

/* NSFontDatabase_Internal.h — the port's in-process font database.
 *
 * This is the private core the font-management classes will sit on: it scans
 * the standard font directories, parses each face's `name`, `head`, `OS/2`
 * and `post` tables straight out of the sfnt (both single faces and `.ttc`
 * collections), and answers the questions NSFontManager is asked about a
 * family — its members, and what a member is called once its traits are read
 * off it. It is private: no Apple header declares it, so the umbrella leaves
 * it out, but it is a plain C interface so the UIFoundation writer, which is
 * C, can use it too. */

#ifndef _NSFONTDATABASE_INTERNAL_H
#define _NSFONTDATABASE_INTERNAL_H

#include <stddef.h>
#include <stdint.h>

/* One face of one font. Every string is owned by the face and is NUL
 * terminated; names are UTF-8. */
typedef struct NXFontFace {
    char *postScriptName;   /* name table ID 6 */
    char *familyName;       /* ID 16 (typographic) if present, else ID 1 */
    char *styleName;        /* ID 17 (typographic) if present, else ID 2 */
    char *fullName;         /* ID 4 */
    uint16_t weight;        /* OS/2 usWeightClass, 0 if unknown */
    uint16_t width;         /* OS/2 usWidthClass, 0 if unknown */
    uint8_t bold;           /* head.macStyle bit 0 or OS/2 fsSelection bit 5 */
    uint8_t italic;         /* head.macStyle bit 1 or fsSelection bits 0x1/0x200 */
    uint8_t fixedPitch;     /* post.isFixedPitch != 0 */
    char *sourcePath;       /* file the face was read from */
    uint32_t faceIndex;     /* index within a collection, else 0 */
} NXFontFace;

/* AppKit-style member info: [postScriptName, styleName, weight, traits] */
typedef struct NXFontMemberInfo {
    char *postScriptName; /* element 0 */
    char *styleName;      /* element 1 */
    int   weight;         /* element 2 */
    int   traits;         /* element 3 */
} NXFontMemberInfo;

typedef struct NXFontDatabase NXFontDatabase;

/* Scans the standard font directories and returns a database, or NULL if
 * nothing could be read. */
NXFontDatabase *NXFontDatabaseCreate(void);

/* The same scan, but over an explicit, NUL terminated list of directories. */
NXFontDatabase *NXFontDatabaseCreateWithDirectories(const char *const *directories);

void NXFontDatabaseFree(NXFontDatabase *db);

size_t NXFontDatabaseFaceCount(const NXFontDatabase *db);
const NXFontFace *NXFontDatabaseFaceAtIndex(const NXFontDatabase *db, size_t index);
const NXFontFace *NXFontDatabaseFaceNamed(const NXFontDatabase *db, const char *postScriptName);

/* The faces whose family name is `family`, in scan order. Writes at most
 * `capacity` pointers and returns the total number that matched. */
size_t NXFontDatabaseMembersOfFamily(const NXFontDatabase *db, const char *family,
                                     const NXFontFace **members, size_t capacity);

/* Parses every face in a single font file (`.ttf`, `.otf`, `.ttc`). Returns
 * the number of faces; `*outFaces` receives a malloc'd array to be released
 * with NXFontDatabaseFreeFaces(). */
size_t NXFontFacesFromFile(const char *path, NXFontFace **outFaces);
void NXFontDatabaseFreeFaces(NXFontFace *faces, size_t count);

/* --------------------------------------------------------------------
 *  Font naming
 *
 *  Reproduces `+[NSHTMLWriter fontNameForFont:]`: the name the writers
 *  put in a font table for a face. In AppKit (`plainMode` 0) a face is
 *  its family, unless the family's plain members carry a style the
 *  writers bother to keep — Condensed, ExtraBlack, Light, Ornaments,
 *  SemiBold or UltraLight — in which case the style is appended. The
 *  plain-mode branch (non-zero) instead maps a `.SF`-prefixed family to
 *  `system-ui`. Resolution goes through CoreText, as AppKit's does, so
 *  the `db` argument is unused. Returns a malloc'd string to be released
 *  with free(), or NULL if the face is unknown or names nothing
 *  (PostScript name `LastResort`). */
char *NXFontNameForFontInDatabase(const NXFontDatabase *db, const char *postScriptName, int plainMode);

/* The same, without a database. */
char *NXFontNameForFont(const char *postScriptName, int plainMode);

/* Members of family (AppKit-style). Free with NXFontMembersFree. */
size_t NXFontMembersOfFamily(const char *family, NXFontMemberInfo **outMembers);
void NXFontMembersFree(NXFontMemberInfo *members, size_t count);

/* Query traits/weight for a PostScript name via CoreText. */
int NXFontSymbolicTraitsForName(const char *postScriptName);
int NXFontWeightClassForName(const char *postScriptName);

#endif /* _NSFONTDATABASE_INTERNAL_H */
