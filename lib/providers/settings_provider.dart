/*
 * This file is a part of Bluecherry Client (https://https://github.com/bluecherrydvr/bluecherry_client).
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

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:bluecherry_client/utils/constants.dart';

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

  // Getters.
  ThemeMode get themeMode => _themeMode;
  DateFormat get dateFormat => _dateFormat;
  DateFormat get timeFormat => _timeFormat;
  DateTime get snoozedUntil => _snoozedUntil;
  NotificationClickAction get notificationClickAction =>
      _notificationClickAction;

  // Setters.
  set themeMode(ThemeMode value) {
    _themeMode = value;
    notifyListeners();
    SharedPreferences.getInstance().then((instance) {
      instance.setInt(kSharedPreferencesThemeMode, value.index);
    });
  }

  set dateFormat(DateFormat value) {
    _dateFormat = value;
    notifyListeners();
    SharedPreferences.getInstance().then((instance) {
      instance.setString(kSharedPreferencesDateFormat, value.pattern!);
    });
  }

  set timeFormat(DateFormat value) {
    _timeFormat = value;
    notifyListeners();
    SharedPreferences.getInstance().then((instance) {
      instance.setString(kSharedPreferencesTimeFormat, value.pattern!);
    });
  }

  set snoozedUntil(DateTime value) {
    _snoozedUntil = value;
    notifyListeners();
    SharedPreferences.getInstance().then((instance) {
      instance.setString(
        kSharedPreferencesSnoozedUntil,
        value.toIso8601String(),
      );
    });
  }

  set notificationClickAction(NotificationClickAction value) {
    _notificationClickAction = value;
    notifyListeners();
    SharedPreferences.getInstance().then((instance) {
      instance.setInt(kSharedPreferencesNotificationClickAction, value.index);
    });
  }

  late ThemeMode _themeMode;
  late DateFormat _dateFormat;
  late DateFormat _timeFormat;
  late DateTime _snoozedUntil;
  late NotificationClickAction _notificationClickAction;

  /// Initializes the [ServersProvider] instance & fetches state from `async`
  /// `package:shared_preferences` method-calls. Called before [runApp].
  static Future<SettingsProvider> ensureInitialized() async {
    try {
      instance = SettingsProvider();
      await instance.initialize();
    } catch (exception, stacktrace) {
      debugPrint(exception.toString());
      debugPrint(stacktrace.toString());
    }
    return instance;
  }

  /// Called by [ensureInitialized].
  Future<void> initialize() async {
    final sharedPreferences = await SharedPreferences.getInstance();
    if (sharedPreferences.containsKey(kSharedPreferencesThemeMode)) {
      _themeMode = ThemeMode
          .values[sharedPreferences.getInt(kSharedPreferencesThemeMode)!];
    } else {
      _themeMode = kDefaultThemeMode;
    }
    if (sharedPreferences.containsKey(kSharedPreferencesDateFormat)) {
      _dateFormat = DateFormat(
        sharedPreferences.getString(kSharedPreferencesDateFormat)!,
        'en_US',
      );
    } else {
      _dateFormat = DateFormat(kDefaultDateFormat, 'en_US');
    }
    if (sharedPreferences.containsKey(kSharedPreferencesTimeFormat)) {
      _timeFormat = DateFormat(
        sharedPreferences.getString(kSharedPreferencesTimeFormat)!,
        'en_US',
      );
    } else {
      _timeFormat = DateFormat(kDefaultTimeFormat, 'en_US');
    }
    if (sharedPreferences.containsKey(kSharedPreferencesSnoozedUntil)) {
      _snoozedUntil = DateTime.parse(
        sharedPreferences.getString(kSharedPreferencesSnoozedUntil)!,
      );
    } else {
      _snoozedUntil = defaultSnoozedUntil;
    }
    if (sharedPreferences
        .containsKey(kSharedPreferencesNotificationClickAction)) {
      _notificationClickAction = NotificationClickAction.values[
          sharedPreferences.getInt(kSharedPreferencesNotificationClickAction)!];
    } else {
      _notificationClickAction = kDefaultNotificationClickAction;
    }
  }

  @override
  // ignore: must_call_super
  void dispose() {}
}

enum NotificationClickAction {
  showFullscreenCamera,
  showEventsScreen,
}
