#ifndef _SP_UTILS_H
#define _SP_UTILS_H

#include <stdlib.h>
#include <stdio.h>
#include <locale.h>
#include "libserialport_internal.h"

#ifdef __cplusplus
extern "C" {
#endif

#ifdef LIBSERIALPORT_MSBUILD
#define EXPORT __declspec(dllexport) // for Windows DLL
#else
#define EXPORT
#endif

void (*utils_debug_handler)(const char *format, size_t length);
//EXPORT _locale_t createLocale();
EXPORT char* utils_geCurrenttLocaleName();
EXPORT void utils_printf(const char *format, ...) ;
EXPORT void utils_set_debug_handler(void (const char *str, size_t length));
EXPORT void utils_init_debug();

#ifdef __cplusplus
}
#endif

#endif // _SP_UTILS_H
