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

import 'dart:convert';
import 'dart:io';

import 'package:bluecherry_client/utils/logging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:safe_local_storage/safe_local_storage.dart';

bool _isStorageConfigured = false;

Future<void> configureStorage() async {
  if (kIsWeb || _isStorageConfigured) return;

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
  events = SafeLocalStorage(path.join(dir, 'events.json'));

  try {
    await migrate(storage, secureStorage);
    await migrate(settings, secureStorage);
    await migrate(downloads, secureStorage);
    await migrate(eventsPlayback, secureStorage);
    await migrate(serversStorage, secureStorage);
    await migrate(mobileView, secureStorage);
    await migrate(desktopView, secureStorage);
    await migrate(updates, secureStorage);
    await migrate(events, secureStorage);
  } catch (_) {}

  _isStorageConfigured = true;
}

Future<void> migrate(SafeLocalStorage from, FlutterSecureStorage to) async {
  try {
    final fromData = await from.read() as Map;
    final keys = fromData.keys;

    for (final key in keys) {
      final value = fromData[key];
      if (value is Map || value is List) {
        final encoded = jsonEncode(value);
        await to.write(key: key, value: encoded);
      } else {
        await to.write(key: key, value: value?.toString());
      }
    }

    try {
      await from.delete();
    } catch (_) {}
  } catch (error, stackTrace) {
    handleError(
      error,
      stackTrace,
      'Failed to migrate storage from $from to $to',
    );
  }
}

final secureStorage = FlutterSecureStorage();

late final SafeLocalStorage storage;
late final SafeLocalStorage downloads;
late final SafeLocalStorage eventsPlayback;
late final SafeLocalStorage serversStorage;
late final SafeLocalStorage settings;
late final SafeLocalStorage mobileView;
late final SafeLocalStorage desktopView;
late final SafeLocalStorage updates;
late final SafeLocalStorage events;

extension FlutterSecureStorageExtension on FlutterSecureStorage {
  Future<int?> readInt({required String key}) async {
    final value = await read(key: key);
    return int.tryParse(value ?? '');
  }

  Future<double?> readDouble({required String key}) async {
    final value = await read(key: key);
    return double.tryParse(value ?? '');
  }

  Future<bool?> readBool({required String key}) async {
    final value = await read(key: key);
    return value == 'true';
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
