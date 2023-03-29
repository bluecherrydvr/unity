import 'package:bluecherry_client/utils/constants.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:safe_local_storage/safe_local_storage.dart';

Future<void> configureStorage() async {
  final dir = (await getApplicationSupportDirectory()).path;

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
        desktopView._replaceIfNotNull(
            kHiveDesktopCycling, hive.get(kHiveDesktopCycling)),
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
