#include <utils.h>

/*extern _locale_t createLocale() {
	char* localeStr = setlocale(LC_ALL, "");
	if (!localeStr) localeStr = "en_us.utf8";
	return _create_locale(LC_ALL, localeStr);
}*/

extern char* utils_geCurrenttLocaleName() {
	char* localeStr = setlocale(LC_ALL, "");
	return localeStr;
}

extern void utils_printf(const char *format, ...) {
	va_list args;
	va_start(args, format);
	int len = vsnprintf(NULL, 0, format, args);
	va_end(args);
	if (len <= 0) {
		return;
	}
	char * str = (char *) calloc(len+1, sizeof(char));
	va_start(args, format);
	vsnprintf(str, len, format, args);
	va_end(args);
	utils_debug_handler(str, len);

	free(str);
}

extern void utils_set_debug_handler(void (*handler)(const char *str, size_t length)) {
	utils_debug_handler = handler;
}

extern void utils_init_debug() {
	if (utils_debug_handler != NULL) {
		sp_set_debug_handler(utils_printf);
	}
}

