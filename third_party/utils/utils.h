#ifndef _SP_UTILS_H
#define _SP_UTILS_H

#include <locale.h>

/** @cond */
#ifdef _MSC_VER
/* Microsoft Visual C/C++ compiler in use */
#ifdef LIBSERIALPORT_MSBUILD
/* Building the library - need to export DLL symbols */
#define EXPORT __declspec(dllexport)
#else
/* Using the library - need to import DLL symbols */
#define EXPORT __declspec(dllimport)
#endif
#else
/* Some other compiler in use */
#ifndef LIBSERIALPORT_ATBUILD
/* Not building the library itself - don't need any special prefixes. */
#define EXPORT
#endif
#endif
/** @endcond */


//EXPORT _locale_t createLocale();
EXPORT char* utils_geCurrenttLocaleName();


#endif // _SP_UTILS_H