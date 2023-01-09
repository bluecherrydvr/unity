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
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/intl.dart';
import 'package:unity_video_player/unity_video_player.dart';

/// This class manages & saves the settings inside the application.
///
class SettingsProvider extends ChangeNotifier {
  /// `late` initialized [ServersProvider] instance.
  static late final SettingsProvider instance;

  static const kDefaultThemeMode = ThemeMode.system;
  static const kDefaultDateFormat = 'EEEE, dd MMMM yyyy';
  static const kDefaultTimeFormat = 'hh:mm a';
  static final defaultSnoozedUntil = DateTime(1969, 7, 20, 20, 18, 04);
  static const kDefaultNotificationClickAction =
      NotificationClickAction.showFullscreenCamera;
  static const kDefaultCameraViewFit = UnityVideoFit.contain;

  // Getters.
  ThemeMode get themeMode => _themeMode;
  DateFormat get dateFormat => _dateFormat;
  DateFormat get timeFormat => _timeFormat;
  DateTime get snoozedUntil => _snoozedUntil;
  NotificationClickAction get notificationClickAction =>
      _notificationClickAction;
  UnityVideoFit get cameraViewFit => _cameraViewFit;

  // Setters.
  set themeMode(ThemeMode value) {
    _themeMode = value;
    notifyListeners();
    Hive.openBox('hive').then((instance) {
      instance.put(kHiveThemeMode, value.index);
    });
  }

  set dateFormat(DateFormat value) {
    _dateFormat = value;
    notifyListeners();
    Hive.openBox('hive').then((instance) {
      instance.put(kHiveDateFormat, value.pattern!);
    });
  }

  set timeFormat(DateFormat value) {
    _timeFormat = value;
    notifyListeners();
    Hive.openBox('hive').then((instance) {
      instance.put(kHiveTimeFormat, value.pattern!);
    });
  }

  set snoozedUntil(DateTime value) {
    _snoozedUntil = value;
    notifyListeners();
    Hive.openBox('hive').then((instance) {
      instance.put(
        kHiveSnoozedUntil,
        value.toIso8601String(),
      );
    });
  }

  set notificationClickAction(NotificationClickAction value) {
    _notificationClickAction = value;
    notifyListeners();
    Hive.openBox('hive').then((instance) {
      instance.put(
        kHiveNotificationClickAction,
        value.index,
      );
    });
  }

  set cameraViewFit(UnityVideoFit value) {
    _cameraViewFit = value;
    notifyListeners();
    Hive.openBox('hive').then((instance) {
      instance.put(
        kHiveCameraViewFit,
        value.index,
      );
    });
  }

  late ThemeMode _themeMode;
  late DateFormat _dateFormat;
  late DateFormat _timeFormat;
  late DateTime _snoozedUntil;
  late NotificationClickAction _notificationClickAction;
  late UnityVideoFit _cameraViewFit;

  /// Initializes the [ServersProvider] instance & fetches state from `async`
  /// `package:hive` method-calls. Called before [runApp].
  static Future<SettingsProvider> ensureInitialized() async {
    try {
      instance = SettingsProvider();
      await instance.initialize();
    } catch (exception, stacktrace) {
      debugPrint(exception.toString());
      debugPrint(stacktrace.toString());
    }
    await instance.reload();
    return instance;
  }

  Future<void> reload() => initialize();

  /// Called by [ensureInitialized].
  Future<void> initialize() async {
    // NOTE: The notification action button click calls are from another isolate.
    // i.e. the state of [Hive] [Box] is not reloaded/reflected immediately in the UI after changing the snooze time from that isolate.
    // To circumvent this, we are closing all the existing opened [Hive] [Box]es and re-opening them again. This fetches the latest data.
    // Though, changes are still not instant.
    await Hive.close();
    final hive = await Hive.openBox('hive');
    if (hive.containsKey(kHiveThemeMode)) {
      _themeMode = ThemeMode.values[hive.get(kHiveThemeMode)!];
    } else {
      _themeMode = kDefaultThemeMode;
    }
    if (hive.containsKey(kHiveDateFormat)) {
      _dateFormat = DateFormat(
        hive.get(kHiveDateFormat)!,
        'en_US',
      );
    } else {
      _dateFormat = DateFormat(kDefaultDateFormat, 'en_US');
    }
    if (hive.containsKey(kHiveTimeFormat)) {
      _timeFormat = DateFormat(
        hive.get(kHiveTimeFormat)!,
        'en_US',
      );
    } else {
      _timeFormat = DateFormat(kDefaultTimeFormat, 'en_US');
    }
    if (hive.containsKey(kHiveSnoozedUntil)) {
      _snoozedUntil = DateTime.parse(
        hive.get(kHiveSnoozedUntil)!,
      );
    } else {
      _snoozedUntil = defaultSnoozedUntil;
    }
    if (hive.containsKey(kHiveNotificationClickAction)) {
      _notificationClickAction = NotificationClickAction
          .values[hive.get(kHiveNotificationClickAction)!];
    } else {
      _notificationClickAction = kDefaultNotificationClickAction;
    }
    if (hive.containsKey(kHiveCameraViewFit)) {
      _cameraViewFit = UnityVideoFit.values[hive.get(kHiveCameraViewFit)!];
    } else {
      _cameraViewFit = kDefaultCameraViewFit;
    }
    notifyListeners();
  }

  @override
  // ignore: must_call_super
  void dispose() {}
}

enum NotificationClickAction {
  showFullscreenCamera,
  showEventsScreen,
}
