#ifndef _SP_UTILS_H
#define _SP_UTILS_H

#include <locale.h>

#ifdef __cplusplus
extern "C" {
#endif

#ifdef LIBSERIALPORT_MSBUILD
#define EXPORT __declspec(dllexport) // for Windows DLL
#else
#define EXPORT
#endif


//EXPORT _locale_t createLocale();
EXPORT char* utils_geCurrenttLocaleName();

#ifdef __cplusplus
}
#endif

#endif // _SP_UTILS_H