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

import 'package:bluecherry_client/utils/constants.dart';
import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:safe_local_storage/safe_local_storage.dart';

Future<void> configureStorage() async {
  final dir = (await getApplicationSupportDirectory()).path;

  debugPrint('App working directory: $dir');

  storage = SafeLocalStorage(path.join(dir, 'bluecherry.json'));
  settings = SafeLocalStorage(path.join(dir, 'settings.json'));
  downloads = SafeLocalStorage(path.join(dir, 'downloads.json'));
  eventsPlayback = SafeLocalStorage(path.join(dir, 'eventsPlayback.json'));
  serversStorage = SafeLocalStorage(path.join(dir, 'servers.json'));
  mobileView = SafeLocalStorage(path.join(dir, 'mobileView.json'));
  desktopView = SafeLocalStorage(path.join(dir, 'desktopView.json'));

  // Migrate from hive to new storage system

  await Hive.initFlutter(dir);
  if (await Hive.boxExists('hive')) {
    final hive = await Hive.openBox('hive');
    if (hive.isEmpty) {
      hive.close();
    } else {
      await Future.wait([
        storage._replaceIfNotNull(
            kHiveNotificationToken, hive.get(kHiveNotificationToken)),
        desktopView._replaceIfNotNull(
            kHiveDesktopLayouts, hive.get(kHiveDesktopLayouts)),
        desktopView._replaceIfNotNull(
            kHiveDesktopCurrentLayout, hive.get(kHiveDesktopCurrentLayout)),
        downloads._replaceIfNotNull(kHiveDownloads, hive.get(kHiveDownloads)),
        eventsPlayback._replaceIfNotNull(
            kHiveEventsPlayback, hive.get(kHiveEventsPlayback)),
        mobileView._replaceIfNotNull(
            kHiveMobileView, hive.get(kHiveMobileView)),
        mobileView._replaceIfNotNull(
            kHiveMobileViewTab, hive.get(kHiveMobileViewTab)),
        serversStorage._replaceIfNotNull(kHiveServers, hive.get(kHiveServers)),
        settings._replaceIfNotNull(kHiveThemeMode, hive.get(kHiveThemeMode)),
        settings._replaceIfNotNull(kHiveDateFormat, hive.get(kHiveDateFormat)),
        settings._replaceIfNotNull(kHiveTimeFormat, hive.get(kHiveTimeFormat)),
        settings._replaceIfNotNull(
            kHiveSnoozedUntil, hive.get(kHiveSnoozedUntil)),
        settings._replaceIfNotNull(
          kHiveNotificationClickAction,
          hive.get(kHiveNotificationClickAction),
        ),
        settings._replaceIfNotNull(
          kHiveCameraViewFit,
          hive.get(kHiveCameraViewFit),
        ),
        settings._replaceIfNotNull(
          kHiveDownloadsDirectorySetting,
          hive.get(kHiveDownloadsDirectorySetting),
        ),
      ]);
      await Hive.deleteBoxFromDisk('hive');
    }
  }
}

late final SafeLocalStorage storage;
late final SafeLocalStorage downloads;
late final SafeLocalStorage eventsPlayback;
late final SafeLocalStorage serversStorage;
late final SafeLocalStorage settings;
late final SafeLocalStorage mobileView;
late final SafeLocalStorage desktopView;

extension SafeLocalStorageExtension on SafeLocalStorage {
  Future<void> add(Map data) async {
    return write({
      ...(await read()) as Map,
      ...data,
    });
  }

  Future<void> _replaceIfNotNull(String key, dynamic value) {
    if (value != null) return add({key: value});

    return Future.value();
  }
}
