/*
 * This file is a part of Bluecherry Client (https://github.com/bluecherrydvr/unity).
 *
 * Copyright 2022 Bluecherry, LLC
 *
 * This program is free software; you can redistribute it and/or
 * modify it under the terms of the GNU General Public License as
 * published by the Free Software Foundation; either version 3 of
 * the License, or (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program. If not, see <http://www.gnu.org/licenses/>.
 */

import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:safe_local_storage/safe_local_storage.dart';

Future<void> configureStorage() async {
  if (kIsWeb) return;

  final dir = (await getApplicationSupportDirectory()).path;

  debugPrint('App working directory: $dir');

  storage = SafeLocalStorage(path.join(dir, 'bluecherry.json'));
  settings = SafeLocalStorage(path.join(dir, 'settings.json'));
  downloads = SafeLocalStorage(path.join(dir, 'downloads.json'));
  eventsPlayback = SafeLocalStorage(path.join(dir, 'eventsPlayback.json'));
  serversStorage = SafeLocalStorage(path.join(dir, 'servers.json'));
  mobileView = SafeLocalStorage(path.join(dir, 'mobileView.json'));
  desktopView = SafeLocalStorage(path.join(dir, 'desktopView.json'));
  updates = SafeLocalStorage(path.join(dir, 'updates.json'));
}

late final SafeLocalStorage storage;
late final SafeLocalStorage downloads;
late final SafeLocalStorage eventsPlayback;
late final SafeLocalStorage serversStorage;
late final SafeLocalStorage settings;
late final SafeLocalStorage mobileView;
late final SafeLocalStorage desktopView;
late final SafeLocalStorage updates;

extension SafeLocalStorageExtension on SafeLocalStorage {
  Future<void> add(Map data) async {
    return write({
      ...(await read()) as Map,
      ...data,
    });
  }
}

enum LogType { video, network }

Future<Directory> errorLogDirectory() async {
  final documentsDir = await getApplicationDocumentsDirectory();
  final logsDir = Directory(path.join(documentsDir.path, 'logs'));
  await logsDir.create(recursive: true);
  return logsDir;
}

Future<File> errorLogFile(LogType type) {
  return errorLogDirectory().then<File>((dir) async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final filename = '${today.toIso8601String()}.log';
    final file = File(path.join(dir.path, type.name, filename));
    await file.create(recursive: true);
    return file;
  });
}

Future<File> errorLog(LogType type, String message) async {
  final file = await errorLogFile(type);

  final now = DateTime.now();
  final timestamp = now.toIso8601String();
  final log = '$timestamp: $message\n';

  await file.writeAsString(log, mode: FileMode.append);

  return file;
}

// TODO(bdlukaa): support for web. Maybe by no longer using safe_local_storage
//                and using other storage methods instead, like shared_preferences.
Future<Map> tryReadStorage(Future Function() callback) async {
  try {
    return (await callback()) as Map;
  } catch (e) {
    // debugPrint(e.toString());
    return Future.value({});
  }
}
