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

import 'package:bluecherry_client/providers/downloads_provider.dart';
import 'package:bluecherry_client/providers/home_provider.dart';
import 'package:bluecherry_client/utils/constants.dart';
import 'package:bluecherry_client/utils/storage.dart';
import 'package:bluecherry_client/utils/video_player.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';
import 'package:system_date_time_format/system_date_time_format.dart';
import 'package:unity_video_player/unity_video_player.dart';

/// This class manages & saves the settings inside the application.
class SettingsProvider extends ChangeNotifier {
  static late final SettingsProvider instance;

  static const kDefaultThemeMode = ThemeMode.system;
  static const kDefaultDateFormat = 'EEEE, dd MMMM yyyy';
  static const kDefaultTimeFormat = 'hh:mm a';
  static final defaultSnoozedUntil = DateTime(1969, 7, 20, 20, 18, 04);
  static const kDefaultNotificationClickBehavior =
      NotificationClickBehavior.showFullscreenCamera;
  static const kDefaultCameraViewFit = UnityVideoFit.contain;
  static const kDefaultLayoutCyclingEnabled = false;
  static const kDefaultLayoutCyclingTogglePeriod = Duration(seconds: 30);
  static Future<Directory> get kDefaultDownloadsDirectory =>
      DownloadsManager.kDefaultDownloadsDirectory;
  static const kDefaultStreamingType = StreamingType.rtsp;
  static const kDefaultRTSPProtocol = RTSPProtocol.tcp;
  static const kDefaultVideoQuality = RenderingQuality.automatic;
  static const kDefaultWakelockEnabled = true;
  static const kDefaultBetaMatrixedZoomEnabled = false;

  late Locale _locale;
  late ThemeMode _themeMode;
  late DateFormat _dateFormat;
  late DateFormat _timeFormat;
  late DateTime _snoozedUntil;
  late NotificationClickBehavior _notificationClickBehavior;
  late UnityVideoFit _cameraViewFit;
  late String _downloadsDirectory;
  late bool _layoutCyclingEnabled;
  late Duration _layoutCyclingTogglePeriod;
  late StreamingType _streamingType;
  late RTSPProtocol _rtspProtocol;
  late RenderingQuality _videoQuality;
  late bool _wakelockEnabled;
  late bool _betaMatrixedZoomEnabled;

  // Getters.
  Locale get locale => _locale;
  ThemeMode get themeMode => _themeMode;
  DateFormat get dateFormat => _dateFormat;
  DateFormat get timeFormat => _timeFormat;
  DateTime get snoozedUntil => _snoozedUntil;
  NotificationClickBehavior get notificationClickBehavior =>
      _notificationClickBehavior;
  UnityVideoFit get cameraViewFit => _cameraViewFit;
  String get downloadsDirectory => _downloadsDirectory;
  bool get layoutCyclingEnabled => _layoutCyclingEnabled;
  Duration get layoutCyclingTogglePeriod => _layoutCyclingTogglePeriod;
  StreamingType get streamingType => _streamingType;
  RTSPProtocol get rtspProtocol => _rtspProtocol;
  RenderingQuality get videoQuality => _videoQuality;
  bool get wakelockEnabled => _wakelockEnabled;
  bool get betaMatrixedZoomEnabled => _betaMatrixedZoomEnabled;

  // Setters.
  set locale(Locale value) {
    _locale = value;
    _save();
  }

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

  set notificationClickBehavior(NotificationClickBehavior value) {
    _notificationClickBehavior = value;
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

  set streamingType(StreamingType value) {
    _streamingType = value;
    _save();
    UnityPlayers.reloadAll();
  }

  set rtspProtocol(RTSPProtocol value) {
    _rtspProtocol = value;
    _save();
    UnityPlayers.reloadAll();
  }

  set videoQuality(RenderingQuality value) {
    _videoQuality = value;
    _save();
  }

  set wakelockEnabled(bool value) {
    _wakelockEnabled = value;
    UnityVideoPlayerInterface.wakelockEnabled = value;
    _save();
  }

  set betaMatrixedZoomEnabled(bool value) {
    _betaMatrixedZoomEnabled = value;
    _save();
  }

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
      kHiveLocale: locale.toLanguageTag(),
      kHiveThemeMode: themeMode.index,
      kHiveDateFormat: dateFormat.pattern!,
      kHiveTimeFormat: timeFormat.pattern!,
      kHiveSnoozedUntil: snoozedUntil.toIso8601String(),
      kHiveNotificationClickBehavior: notificationClickBehavior.index,
      kHiveCameraViewFit: cameraViewFit.index,
      kHiveDownloadsDirectorySetting: downloadsDirectory,
      kHiveLayoutCycling: layoutCyclingEnabled,
      kHiveLayoutCyclingPeriod: layoutCyclingTogglePeriod.inMilliseconds,
      kHiveStreamingType: streamingType.index,
      kHiveStreamingProtocol: rtspProtocol.index,
      kHiveVideoQuality: videoQuality.index,
      kHiveWakelockEnabled: wakelockEnabled,
      kHiveBetaMatrixedZoom: betaMatrixedZoomEnabled,
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
    if (data.containsKey(kHiveLocale)) {
      _locale = Locale(data[kHiveLocale]!);
    } else {
      _locale = Locale(Intl.getCurrentLocale());
    }
    if (data.containsKey(kHiveThemeMode)) {
      _themeMode = ThemeMode.values[data[kHiveThemeMode]!];
    } else {
      _themeMode = kDefaultThemeMode;
    }
    final format = SystemDateTimeFormat();
    initializeDateFormatting(_locale.languageCode);
    Intl.defaultLocale = _locale.toLanguageTag();

    final systemLocale = Intl.getCurrentLocale();
    final timePattern = await format.getTimePattern();
    _dateFormat = DateFormat(
      data[kHiveDateFormat] ?? kDefaultDateFormat,
      systemLocale,
    );
    _timeFormat = DateFormat(
      data[kHiveTimeFormat] ?? timePattern ?? kDefaultTimeFormat,
      systemLocale,
    );
    _snoozedUntil =
        DateTime.tryParse((data[kHiveSnoozedUntil] as String?) ?? '') ??
            defaultSnoozedUntil;
    _notificationClickBehavior = NotificationClickBehavior.values[
        data[kHiveNotificationClickBehavior] ??
            kDefaultNotificationClickBehavior.index];
    _cameraViewFit = UnityVideoFit
        .values[data[kHiveCameraViewFit] ?? kDefaultCameraViewFit.index];
    _downloadsDirectory = data[kHiveDownloadsDirectorySetting] ??
        ((await kDefaultDownloadsDirectory).path);
    _layoutCyclingEnabled =
        data[kHiveLayoutCycling] ?? kDefaultLayoutCyclingEnabled;
    _layoutCyclingTogglePeriod = Duration(
      milliseconds: data[kHiveLayoutCyclingPeriod] ??
          kDefaultLayoutCyclingTogglePeriod.inMilliseconds,
    );
    _streamingType = StreamingType
        .values[data[kHiveStreamingType] ?? kDefaultStreamingType.index];
    _rtspProtocol = RTSPProtocol
        .values[data[kHiveStreamingProtocol] ?? kDefaultRTSPProtocol.index];
    _videoQuality = RenderingQuality
        .values[data[kHiveVideoQuality] ?? kDefaultVideoQuality.index];
    _wakelockEnabled = data[kHiveWakelockEnabled] ?? kDefaultWakelockEnabled;
    _betaMatrixedZoomEnabled =
        data[kHiveBetaMatrixedZoom] ?? kDefaultBetaMatrixedZoomEnabled;

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

  bool toggleCycling() {
    layoutCyclingEnabled = !layoutCyclingEnabled;
    return layoutCyclingEnabled;
  }
}

enum NotificationClickBehavior {
  showFullscreenCamera,
  showEventsScreen;

  IconData get icon {
    return switch (this) {
      NotificationClickBehavior.showEventsScreen =>
        Icons.featured_play_list_outlined,
      NotificationClickBehavior.showFullscreenCamera =>
        Icons.screenshot_monitor,
    };
  }

  String locale(BuildContext context) {
    final loc = AppLocalizations.of(context);
    return switch (this) {
      NotificationClickBehavior.showEventsScreen => loc.showFullscreenCamera,
      NotificationClickBehavior.showFullscreenCamera => loc.showEventsScreen,
    };
  }
}

enum RenderingQuality {
  automatic,
  p4k,
  p1080,
  p720,
  p480,
  p360,
  p240;

  String locale(BuildContext context) {
    final loc = AppLocalizations.of(context);
    return switch (this) {
      RenderingQuality.p4k => loc.p4k,
      RenderingQuality.p1080 => loc.p1080,
      RenderingQuality.p720 => loc.p720,
      RenderingQuality.p480 => loc.p480,
      RenderingQuality.p360 => loc.p360,
      RenderingQuality.p240 => loc.p240,
      RenderingQuality.automatic => loc.automaticResolution,
    };
  }
}

enum StreamingType {
  rtsp,
  hls,
  mjpeg;
}
