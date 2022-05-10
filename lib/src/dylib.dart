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
import 'dart:io';

import 'package:flutter_libserialport/src/bindings.dart';
import 'package:dylib/dylib.dart' as importer;

LibSerialPort? _dylib;
LibSerialPort get dylib {
  if (_dylib != null) return _dylib!;
  String? path;
  if (Platform.environment.containsKey("FLUTTER_TEST")) {
    final script =
        File(Platform.script.toFilePath(windows: Platform.isWindows));
    String? platformSpecificPath;
    if (Platform.isLinux) {
      platformSpecificPath = "example/build/linux/x64/debug/bundle/lib";
    } else if (Platform.isWindows) {
      platformSpecificPath = "example/build/windows/runner/Debug";
    }

    if (platformSpecificPath != null) {
      final dir = Directory(
          '${script.parent.path.replaceFirst(RegExp(r'[/\\]example$'), "")}${Platform.pathSeparator}$platformSpecificPath');
      if (dir.existsSync()) {
        path = dir.path;
      }
    }
  }
  _dylib = LibSerialPort(ffi.DynamicLibrary.open(
    importer.resolveDylibPath(
      'serialport',
      path: path,
      dartDefine: 'LIBSERIALPORT_PATH',
      environmentVariable: 'LIBSERIALPORT_PATH',
    ),
  ));

  return _dylib!;
}
