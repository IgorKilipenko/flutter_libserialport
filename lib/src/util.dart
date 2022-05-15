/*
 * Based on libserialport (https://sigrok.org/wiki/Libserialport).
 *
 * Copyright (C) 2010-2012 Bert Vermeulen <bert@biot.com>
 * Copyright (C) 2010-2015 Uwe Hermann <uwe@hermann-uwe.de>
 * Copyright (C) 2013-2015 Martin Ling <martin-libserialport@earth.li>
 * Copyright (C) 2013 Matthias Heidbrink <m-sigrok@heidbrink.biz>
 * Copyright (C) 2014 Aurelien Jacobs <aurel@gnuage.org>
 * Copyright (C) 2020 J-P Nurmi <jpnurmi@gmail.com>
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU Lesser General Public License as
 * published by the Free Software Foundation, either version 3 of the
 * License, or (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU Lesser General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 */

import 'dart:ffi' as ffi;
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:flutter_libserialport/src/dylib.dart';
import 'package:windows1251/windows1251.dart';
import 'package:ffi/ffi.dart' as pkg_ffi;
import 'package:flutter_libserialport/src/bindings.dart';
import 'package:flutter_libserialport/src/port.dart';

typedef UtilFunc<T extends ffi.NativeType> = int Function(ffi.Pointer<T> ptr);

class Util {
  static int call(int Function() func) {
    final ret = func();
    if (ret < sp_return.SP_OK &&
        SerialPort.lastError != null &&
        SerialPort.lastError!.errorCode != 0) {
      throw SerialPort.lastError!;
    }
    return ret;
  }

  static Uint8List read(int bytes, UtilFunc<ffi.Uint8> readFunc) {
    final ptr = pkg_ffi.calloc<ffi.Uint8>(bytes);
    final len = call(() => readFunc(ptr));
    final res = Uint8List.fromList(ptr.asTypedList(len));
    pkg_ffi.calloc.free(ptr);
    return res;
  }

  static int write(Uint8List bytes, UtilFunc<ffi.Uint8> writeFunc) {
    final len = bytes.length;
    final ptr = pkg_ffi.calloc<ffi.Uint8>(len);
    ptr.asTypedList(len).setAll(0, bytes);
    final res = call(() => writeFunc(ptr));
    pkg_ffi.calloc.free(ptr);
    return res;
  }


  static ffi.Pointer<ffi.Int8> toUtf8(String str) {
    return pkg_ffi.StringUtf8Pointer(str).toNativeUtf8().cast<ffi.Int8>();
  }

  static int? toInt(UtilFunc<ffi.Int32> getFunc) {
    final ptr = pkg_ffi.calloc<ffi.Int32>();
    final rv = call(() => getFunc(ptr));
    final value = ptr.value;
    pkg_ffi.calloc.free(ptr);
    if (rv != sp_return.SP_OK) return null;
    return value;
  }
}

extension CharPointerUtils on ffi.Pointer<ffi.Char> {
  String? toDartString({int? length}) {
    if (address == 0) return null;
    length ??= this.length;
    final localePtr = dylib.utils_geCurrenttLocaleName();
    final locale = localePtr.cast<pkg_ffi.Utf8>().toDartString();
    if (locale.contains(RegExp(r'\.1251'))) {
      try {
        final chars = cast<ffi.Uint8>().asTypedList(length);
        return windows1251.decode(List.from(chars));
      } catch (e) {
        if (kDebugMode) {
          print('WARN decode Win1251 string with error: $e');
        }
      }
    }
    try {
      return cast<pkg_ffi.Utf8>().toDartString(length: length);
    } catch (e) {
      if (kDebugMode) {
        print('WARN decode UTF8 string with error: $e');
      }
    }

    return null;
  }

  int get length {
    var length = 0;
    while (this[length] != 0) {
      length++;
    }
    return length;
  }
}
