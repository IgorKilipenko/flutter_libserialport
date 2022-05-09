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