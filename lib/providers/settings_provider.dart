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

import 'package:bluecherry_client/providers/home_provider.dart';
import 'package:bluecherry_client/utils/constants.dart';
import 'package:bluecherry_client/utils/storage.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:unity_video_player/unity_video_player.dart';

/// This class manages & saves the settings inside the application.
///
class SettingsProvider extends ChangeNotifier {
  /// `late` initialized [ServersProvider] instance.
  static late final SettingsProvider instance;

  static const kDefaultThemeMode = ThemeMode.system;
  // TODO(bdlukaa): consider using https://github.com/Nikoro/system_date_time_format
  // to get the system date/time format
  static const kDefaultDateFormat = 'EEEE, dd MMMM yyyy';
  static const kDefaultTimeFormat = 'hh:mm a';
  static final defaultSnoozedUntil = DateTime(1969, 7, 20, 20, 18, 04);
  static const kDefaultNotificationClickAction =
      NotificationClickAction.showFullscreenCamera;
  static const kDefaultCameraViewFit = UnityVideoFit.contain;
  static const kDefaultLayoutCyclingEnabled = false;
  static const kDefaultLayoutCyclingTogglePeriod = Duration(seconds: 30);
  static Future<Directory> kDefaultDownloadsDirectory() async {
    final docsDir = await getApplicationSupportDirectory();
    return Directory(path.join(docsDir.path, 'downloads')).create();
  }

  // Getters.
  ThemeMode get themeMode => _themeMode;
  DateFormat get dateFormat => _dateFormat;
  DateFormat get timeFormat => _timeFormat;
  DateTime get snoozedUntil => _snoozedUntil;
  NotificationClickAction get notificationClickAction =>
      _notificationClickAction;
  UnityVideoFit get cameraViewFit => _cameraViewFit;
  String get downloadsDirectory => _downloadsDirectory;
  bool get layoutCyclingEnabled => _layoutCyclingEnabled;
  Duration get layoutCyclingTogglePeriod => _layoutCyclingTogglePeriod;

  // Setters.
  set themeMode(ThemeMode value) {
    _themeMode = value;
    _save().then((_) {
      HomeProvider.setDefaultStatusBarStyle(
        // we can not do [isLight: value == ThemeMode.light] because theme
        // mode also accepts [ThemeMode.system]. When null is provided, the
        // function will use the system's theme mode.
        isLight: value == ThemeMode.light ? true : null,
      );
    });
  }

  set dateFormat(DateFormat value) {
    _dateFormat = value;
    _save();
  }

  set timeFormat(DateFormat value) {
    _timeFormat = value;
    _save();
  }

  set snoozedUntil(DateTime value) {
    _snoozedUntil = value;
    _save();
  }

  set notificationClickAction(NotificationClickAction value) {
    _notificationClickAction = value;
    _save();
  }

  set cameraViewFit(UnityVideoFit value) {
    _cameraViewFit = value;
    _save();
  }

  set downloadsDirectory(String value) {
    _downloadsDirectory = value;
    _save();
  }

  set layoutCyclingEnabled(bool value) {
    _layoutCyclingEnabled = value;
    _save();
  }

  set layoutCyclingTogglePeriod(Duration value) {
    _layoutCyclingTogglePeriod = value;
    _save();
  }

  late ThemeMode _themeMode;
  late DateFormat _dateFormat;
  late DateFormat _timeFormat;
  late DateTime _snoozedUntil;
  late NotificationClickAction _notificationClickAction;
  late UnityVideoFit _cameraViewFit;
  late String _downloadsDirectory;
  late bool _layoutCyclingEnabled;
  late Duration _layoutCyclingTogglePeriod;

  /// Initializes the [SettingsProvider] instance & fetches state from `async`
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

  Future<void> _save({bool notify = true}) async {
    await settings.write({
      kHiveThemeMode: themeMode.index,
      kHiveDateFormat: dateFormat.pattern!,
      kHiveTimeFormat: timeFormat.pattern!,
      kHiveSnoozedUntil: snoozedUntil.toIso8601String(),
      kHiveNotificationClickAction: notificationClickAction.index,
      kHiveCameraViewFit: cameraViewFit.index,
      kHiveDownloadsDirectorySetting: downloadsDirectory,
      kHiveLayoutCycling: layoutCyclingEnabled,
      kHiveLayoutCyclingPeriod: layoutCyclingTogglePeriod.inMilliseconds,
    });

    if (notify) notifyListeners();
  }

  Future<void> reload() => initialize();

  /// Called by [ensureInitialized].
  Future<void> initialize() async {
    // NOTE: The notification action button click calls are from another isolate.
    // i.e. the state of [Hive] [Box] is not reloaded/reflected immediately in the UI after changing the snooze time from that isolate.
    // To circumvent this, we are closing all the existing opened [Hive] [Box]es and re-opening them again. This fetches the latest data.
    // Though, changes are still not instant.
    final data = await settings.read() as Map;
    if (data.containsKey(kHiveThemeMode)) {
      _themeMode = ThemeMode.values[data[kHiveThemeMode]!];
    } else {
      _themeMode = kDefaultThemeMode;
    }
    if (data.containsKey(kHiveDateFormat)) {
      _dateFormat = DateFormat(
        data[kHiveDateFormat]!,
        'en_US',
      );
    } else {
      _dateFormat = DateFormat(kDefaultDateFormat, 'en_US');
    }
    if (data.containsKey(kHiveTimeFormat)) {
      _timeFormat = DateFormat(
        data[kHiveTimeFormat]!,
        'en_US',
      );
    } else {
      _timeFormat = DateFormat(kDefaultTimeFormat, 'en_US');
    }
    if (data.containsKey(kHiveSnoozedUntil)) {
      _snoozedUntil = DateTime.parse(
        data[kHiveSnoozedUntil]!,
      );
    } else {
      _snoozedUntil = defaultSnoozedUntil;
    }
    if (data.containsKey(kHiveNotificationClickAction)) {
      _notificationClickAction =
          NotificationClickAction.values[data[kHiveNotificationClickAction]!];
    } else {
      _notificationClickAction = kDefaultNotificationClickAction;
    }
    if (data.containsKey(kHiveCameraViewFit)) {
      _cameraViewFit = UnityVideoFit.values[data[kHiveCameraViewFit]!];
    } else {
      _cameraViewFit = kDefaultCameraViewFit;
    }

    if (data.containsKey(kHiveDownloadsDirectorySetting)) {
      _downloadsDirectory = data[kHiveDownloadsDirectorySetting];
    } else {
      _downloadsDirectory = (await kDefaultDownloadsDirectory()).path;
    }

    if (data.containsKey(kHiveLayoutCycling)) {
      _layoutCyclingEnabled = data[kHiveLayoutCycling];
    } else {
      _layoutCyclingEnabled = kDefaultLayoutCyclingEnabled;
    }

    if (data.containsKey(kHiveLayoutCyclingPeriod)) {
      _layoutCyclingTogglePeriod = Duration(
        milliseconds: data[kHiveLayoutCyclingPeriod],
      );
    } else {
      _layoutCyclingTogglePeriod = kDefaultLayoutCyclingTogglePeriod;
    }

    notifyListeners();
  }

  /// Formats the date according to the current [dateFormat].
  ///
  /// [toLocal] defines if the date will be converted to local time. Defaults to `true`
  String formatDate(DateTime date, {bool toLocal = false}) {
    if (toLocal) date = date.toLocal();

    return dateFormat.format(date);
  }

  /// Formats the date according to the current [dateFormat].
  ///
  /// [toLocal] defines if the date will be converted to local time. Defaults to `true`
  String formatTime(DateTime time, {bool toLocal = false}) {
    if (toLocal) time = time.toLocal();

    return timeFormat.format(time);
  }

  void toggleCycling() {
    layoutCyclingEnabled = !layoutCyclingEnabled;
  }

  @override
  // ignore: must_call_super
  void dispose() {}
}

enum NotificationClickAction {
  showFullscreenCamera,
  showEventsScreen,
}
