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

import 'package:bluecherry_client/providers/app_provider_interface.dart';
import 'package:bluecherry_client/providers/downloads_provider.dart';
import 'package:bluecherry_client/screens/layouts/desktop/external_stream.dart';
import 'package:bluecherry_client/utils/storage.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:intl/intl.dart';
import 'package:unity_video_player/unity_video_player.dart';

enum NetworkUsage { auto, wifiOnly, never }

enum TimelineIntialPoint { beggining, firstEvent, lastEvent }

enum EnabledPreference { on, ask, never }

class SettingsOption<T> {
  final String key;
  final T def;

  late final String Function(T value) saveAs;
  late final T Function(String value) loadFrom;

  late T value;

  SettingsOption({
    required this.key,
    required this.def,
    String Function(T value)? saveAs,
    T Function(String value)? loadFrom,
  }) {
    value = def;

    if (saveAs != null) {
      this.saveAs = saveAs;
    } else if (T == bool) {
      this.saveAs = (value) => value.toString();
    } else if (T == Duration) {
      this.saveAs = (value) => (value as Duration).inMilliseconds.toString();
    } else if (T == Enum) {
      this.saveAs = (value) => (value as Enum).index.toString();
    } else if (T == DateFormat) {
      this.saveAs = (value) => (value as DateFormat).pattern ?? '';
    } else if (T == Locale) {
      this.saveAs = (value) => (value as Locale).toLanguageTag();
    } else if (T == DateTime) {
      this.saveAs = (value) => (value as DateTime).toIso8601String();
    } else {
      this.saveAs = (value) => value.toString();
    }

    if (loadFrom != null) {
      this.loadFrom = loadFrom;
    } else if (T == bool) {
      this.loadFrom = (value) => (bool.tryParse(value) ?? def) as T;
    } else if (T == Duration) {
      this.loadFrom = (value) => Duration(milliseconds: int.parse(value)) as T;
    } else if (T == Enum) {
      throw UnsupportedError('Enum type must provide a loadFrom function');
    } else if (T == DateFormat) {
      this.loadFrom = (value) => DateFormat(value) as T;
    } else if (T == Locale) {
      this.loadFrom = (value) => Locale.fromSubtags(languageCode: value) as T;
    } else if (T == DateTime) {
      this.loadFrom = (value) => DateTime.parse(value) as T;
    } else if (T == double) {
      this.loadFrom = (value) => double.parse(value) as T;
    } else {
      this.loadFrom = (value) => value as T;
    }
  }

  String get defAsString => saveAs(def);
}

class SettingsProvider extends UnityProvider {
  SettingsProvider._();
  static late SettingsProvider instance;

  // General settings
  final kLayoutCyclePeriod = SettingsOption(
    def: const Duration(seconds: 5),
    key: 'general.cycle_period',
  );
  final kLayoutCycleEnabled = SettingsOption(
    def: true,
    key: 'general.cycle_enabled',
  );
  final kWakelock = SettingsOption(
    def: true,
    key: 'general.wakelock',
  );

  // Notifications
  final kNotificationsEnabled = SettingsOption(
    def: true,
    key: 'notifications.enabled',
  );
  final kSnoozeNotificationsUntil = SettingsOption<DateTime>(
    def: DateTime.utc(1969, 7, 20, 20, 18, 04),
    key: 'notifications.snooze_until',
  );
  final kNotificationClickBehavior = SettingsOption(
    def: NotificationClickBehavior.showEventsScreen,
    key: 'notifications.click_behavior',
    loadFrom: (value) => NotificationClickBehavior.values[int.parse(value)],
    saveAs: (value) => value.index.toString(),
  );

  // Data usage
  final kAutomaticStreaming = SettingsOption(
    def: NetworkUsage.wifiOnly,
    key: 'data_usage.automatic_streaming',
    loadFrom: (value) => NetworkUsage.values[int.parse(value)],
    saveAs: (value) => value.index.toString(),
  );
  final kStreamOnBackground = SettingsOption(
    def: NetworkUsage.wifiOnly,
    key: 'data_usage.stream_on_background',
    loadFrom: (value) => NetworkUsage.values[int.parse(value)],
    saveAs: (value) => value.index.toString(),
  );

  // Streaming settings
  final kStreamingType = SettingsOption(
    def: kIsWeb ? StreamingType.hls : StreamingType.rtsp,
    key: 'streaming.type',
    loadFrom: (value) => StreamingType.values[int.parse(value)],
    saveAs: (value) => value.index.toString(),
  );
  final kRTSPProtocol = SettingsOption(
    def: RTSPProtocol.tcp,
    key: 'streaming.rtsp_protocol',
    loadFrom: (value) => RTSPProtocol.values[int.parse(value)],
    saveAs: (value) => value.index.toString(),
  );
  final kRenderingQuality = SettingsOption(
    def: RenderingQuality.automatic,
    key: 'streaming.rendering_quality',
    loadFrom: (value) => RenderingQuality.values[int.parse(value)],
    saveAs: (value) => value.index.toString(),
  );
  final kVideoFit = SettingsOption(
    def: UnityVideoFit.contain,
    key: 'streaming.video_fit',
    loadFrom: (value) => UnityVideoFit.values[int.parse(value)],
    saveAs: (value) => value.index.toString(),
  );
  final kRefreshRate = SettingsOption(
    def: const Duration(minutes: 5),
    key: 'streaming.refresh_rate',
  );
  final kLateStreamBehavior = SettingsOption(
    def: LateVideoBehavior.automatic,
    key: 'streaming.late_video_behavior',
    loadFrom: (value) => LateVideoBehavior.values[int.parse(value)],
    saveAs: (value) => value.index.toString(),
  );
  final kReloadTimedOutStreams = SettingsOption(
    def: true,
    key: 'streaming.reload_timed_out_streams',
  );
  final kUseHardwareDecoding = SettingsOption(
    def: true,
    key: 'streaming.use_hardware_decoding',
  );

  // Downloads
  final kDownloadOnMobileData = SettingsOption(
    def: false,
    key: 'downloads.download_on_mobile_data',
  );
  final kChooseLocationEveryTime = SettingsOption(
    def: false,
    key: 'downloads.choose_location_every_time',
  );
  final kAllowAppCloseWhenDownloading = SettingsOption(
    def: false,
    key: 'downloads.allow_app_close_when_downloading',
  );
  final kDownloadsDirectory = SettingsOption(
    def: '',
    key: 'downloads.directory',
  );

  // Events
  final kPictureInPicture = SettingsOption(
    def: false,
    key: 'events.picture_in_picture',
  );
  final kEventsSpeed = SettingsOption(
    def: 1.0,
    key: 'events.speed',
  );
  final kEventsVolume = SettingsOption(
    def: 1.0,
    key: 'events.volume',
  );

  // Timeline of Events
  final kShowDifferentColorsForEvents = SettingsOption(
    def: false,
    key: 'timeline.show_different_colors_for_events',
  );
  final kPauseToBuffer = SettingsOption(
    def: false,
    key: 'timeline.pause_to_buffer',
  );
  final kTimelineInitialPoint = SettingsOption(
    def: TimelineIntialPoint.beggining,
    key: 'timeline.initial_point',
    loadFrom: (value) => TimelineIntialPoint.values[int.parse(value)],
    saveAs: (value) => value.index.toString(),
  );

  // Application
  final kThemeMode = SettingsOption(
    def: ThemeMode.system,
    key: 'application.theme_mode',
    loadFrom: (value) => ThemeMode.values[int.parse(value)],
    saveAs: (value) => value.index.toString(),
  );
  final kLanguageCode = SettingsOption(
    def: Locale.fromSubtags(languageCode: Intl.getCurrentLocale()),
    key: 'application.language_code',
  );
  final kDateFormat = SettingsOption(
    def: DateFormat('EEEE, dd MMMM yyyy'),
    key: 'application.date_format',
  );
  final kTimeFormat = SettingsOption(
    def: DateFormat('hh:mm a'),
    key: 'application.time_format',
  );

  // Window
  final kLaunchAppOnStartup = SettingsOption(
    def: false,
    key: 'window.launch_app_on_startup',
  );
  final kMinimizeToTray = SettingsOption(
    def: false,
    key: 'window.minimize_to_tray',
  );

  // Acessibility
  final kAnimationsEnabled = SettingsOption(
    def: true,
    key: 'accessibility.animations_enabled',
  );
  final kHighContrast = SettingsOption(
    def: false,
    key: 'accessibility.high_contrast',
  );
  final kLargeFont = SettingsOption(
    def: false,
    key: 'accessibility.large_font',
  );

  // Privacy and Security
  final kAllowDataCollection = SettingsOption(
    def: true,
    key: 'privacy.allow_data_collection',
  );
  final kAllowCrashReports = SettingsOption(
    def: true,
    key: 'privacy.allow_crash_reports',
  );

  // Updates
  final kAutoUpdate = SettingsOption(
    def: true,
    key: 'updates.auto_update',
  );
  final kShowReleaseNotes = SettingsOption(
    def: true,
    key: 'updates.show_release_notes',
  );

  // Other
  final kDefaultBetaMatrixedZoomEnabled = SettingsOption(
    def: false,
    key: 'other.matrixed_zoom_enabled',
  );
  final kMatrixSize = SettingsOption(
    def: MatrixType.t16,
    key: 'other.matrix_size',
    loadFrom: (value) => MatrixType.values[int.parse(value)],
    saveAs: (value) => value.index.toString(),
  );
  final kShowDebugInfo = SettingsOption(
    def: false,
    key: 'other.show_debug_info',
  );
  final kShowNetworkUsage = SettingsOption(
    def: false,
    key: 'other.show_network_usage',
  );

  /// Initializes the [SettingsProvider] instance & fetches state from `async`
  /// `package:hive` method-calls. Called before [runApp].
  static Future<SettingsProvider> ensureInitialized() async {
    instance = SettingsProvider._();
    await instance.initialize();
    return instance;
  }

  @override
  Future<void> initialize() async {
    final data = await tryReadStorage(() => settings.read());

    kLayoutCyclePeriod.value = kLayoutCyclePeriod.loadFrom(
      data[kLayoutCyclePeriod.key] ?? kLayoutCyclePeriod.defAsString,
    );
    kLayoutCycleEnabled.value = kLayoutCycleEnabled.loadFrom(
      data[kLayoutCycleEnabled.key] ?? kLayoutCycleEnabled.defAsString,
    );
    kWakelock.value = kWakelock.loadFrom(
      data[kWakelock.key] ?? kWakelock.defAsString,
    );
    kNotificationsEnabled.value = kNotificationsEnabled.loadFrom(
      data[kNotificationsEnabled.key] ?? kNotificationsEnabled.defAsString,
    );
    kSnoozeNotificationsUntil.value = kSnoozeNotificationsUntil.loadFrom(
      data[kSnoozeNotificationsUntil.key] ??
          kSnoozeNotificationsUntil.defAsString,
    );
    kNotificationClickBehavior.value = kNotificationClickBehavior.loadFrom(
      data[kNotificationClickBehavior.key] ??
          kNotificationClickBehavior.defAsString,
    );
    kAutomaticStreaming.value = kAutomaticStreaming.loadFrom(
      data[kAutomaticStreaming.key] ?? kAutomaticStreaming.defAsString,
    );
    kStreamOnBackground.value = kStreamOnBackground.loadFrom(
      data[kStreamOnBackground.key] ?? kStreamOnBackground.defAsString,
    );
    kStreamingType.value = kStreamingType.loadFrom(
      data[kStreamingType.key] ?? kStreamingType.defAsString,
    );
    kRTSPProtocol.value = kRTSPProtocol.loadFrom(
      data[kRTSPProtocol.key] ?? kRTSPProtocol.defAsString,
    );
    kRenderingQuality.value = kRenderingQuality.loadFrom(
      data[kRenderingQuality.key] ?? kRenderingQuality.defAsString,
    );
    kVideoFit.value = kVideoFit.loadFrom(
      data[kVideoFit.key] ?? kVideoFit.defAsString,
    );
    kRefreshRate.value = kRefreshRate.loadFrom(
      data[kRefreshRate.key] ?? kRefreshRate.defAsString,
    );
    kLateStreamBehavior.value = kLateStreamBehavior.loadFrom(
      data[kLateStreamBehavior.key] ?? kLateStreamBehavior.defAsString,
    );
    kReloadTimedOutStreams.value = kReloadTimedOutStreams.loadFrom(
      data[kReloadTimedOutStreams.key] ?? kReloadTimedOutStreams.defAsString,
    );
    kUseHardwareDecoding.value = kUseHardwareDecoding.loadFrom(
      data[kUseHardwareDecoding.key] ?? kUseHardwareDecoding.defAsString,
    );
    kDownloadOnMobileData.value = kDownloadOnMobileData.loadFrom(
      data[kDownloadOnMobileData.key] ?? kDownloadOnMobileData.defAsString,
    );
    kChooseLocationEveryTime.value = kChooseLocationEveryTime.loadFrom(
      data[kChooseLocationEveryTime.key] ??
          kChooseLocationEveryTime.defAsString,
    );
    kDownloadsDirectory.value = kDownloadsDirectory.loadFrom(
      data[kDownloadsDirectory.key] ??
          (await DownloadsManager.kDefaultDownloadsDirectory).path,
    );
    kAllowAppCloseWhenDownloading.value =
        kAllowAppCloseWhenDownloading.loadFrom(
      data[kAllowAppCloseWhenDownloading.key] ??
          kAllowAppCloseWhenDownloading.defAsString,
    );
    kPictureInPicture.value = kPictureInPicture.loadFrom(
      data[kPictureInPicture.key] ?? kPictureInPicture.defAsString,
    );
    kEventsSpeed.value = kEventsSpeed.loadFrom(
      data[kEventsSpeed.key] ?? kEventsSpeed.defAsString,
    );
    kEventsVolume.value = kEventsVolume.loadFrom(
      data[kEventsVolume.key] ?? kEventsVolume.defAsString,
    );
    kShowDifferentColorsForEvents.value =
        kShowDifferentColorsForEvents.loadFrom(
      data[kShowDifferentColorsForEvents.key] ??
          kShowDifferentColorsForEvents.defAsString,
    );
    kPauseToBuffer.value = kPauseToBuffer.loadFrom(
      data[kPauseToBuffer.key] ?? kPauseToBuffer.defAsString,
    );
    kTimelineInitialPoint.value = kTimelineInitialPoint.loadFrom(
      data[kTimelineInitialPoint.key] ?? kTimelineInitialPoint.defAsString,
    );
    kThemeMode.value = kThemeMode.loadFrom(
      data[kThemeMode.key] ?? kThemeMode.defAsString,
    );
    kLanguageCode.value = kLanguageCode.loadFrom(
      data[kLanguageCode.key] ?? kLanguageCode.defAsString,
    );
    kDateFormat.value = kDateFormat.loadFrom(
      data[kDateFormat.key] ?? kDateFormat.defAsString,
    );
    kTimeFormat.value = kTimeFormat.loadFrom(
      data[kTimeFormat.key] ?? kTimeFormat.defAsString,
    );
    kLaunchAppOnStartup.value = kLaunchAppOnStartup.loadFrom(
      data[kLaunchAppOnStartup.key] ?? kLaunchAppOnStartup.defAsString,
    );
    kMinimizeToTray.value = kMinimizeToTray.loadFrom(
      data[kMinimizeToTray.key] ?? kMinimizeToTray.defAsString,
    );
    kAnimationsEnabled.value = kAnimationsEnabled.loadFrom(
      data[kAnimationsEnabled.key] ?? kAnimationsEnabled.defAsString,
    );
    kHighContrast.value = kHighContrast.loadFrom(
      data[kHighContrast.key] ?? kHighContrast.defAsString,
    );
    kLargeFont.value = kLargeFont.loadFrom(
      data[kLargeFont.key] ?? kLargeFont.defAsString,
    );
    kAllowDataCollection.value = kAllowDataCollection.loadFrom(
      data[kAllowDataCollection.key] ?? kAllowDataCollection.defAsString,
    );
    kAllowCrashReports.value = kAllowCrashReports.loadFrom(
      data[kAllowCrashReports.key] ?? kAllowCrashReports.defAsString,
    );
    kAutoUpdate.value = kAutoUpdate.loadFrom(
      data[kAutoUpdate.key] ?? kAutoUpdate.defAsString,
    );
    kShowReleaseNotes.value = kShowReleaseNotes.loadFrom(
      data[kShowReleaseNotes.key] ?? kShowReleaseNotes.defAsString,
    );
    kDefaultBetaMatrixedZoomEnabled.value =
        kDefaultBetaMatrixedZoomEnabled.loadFrom(
      data[kDefaultBetaMatrixedZoomEnabled.key] ??
          kDefaultBetaMatrixedZoomEnabled.defAsString,
    );
    kMatrixSize.value = kMatrixSize.loadFrom(
      data[kMatrixSize.key] ?? kMatrixSize.defAsString,
    );
    kShowDebugInfo.value = kShowDebugInfo.loadFrom(
      data[kShowDebugInfo.key] ?? kShowDebugInfo.defAsString,
    );
    kShowNetworkUsage.value = kShowNetworkUsage.loadFrom(
      data[kShowNetworkUsage.key] ?? kShowNetworkUsage.defAsString,
    );
  }

  @override
  Future<void> save({bool notifyListeners = true}) async {
    try {
      await settings.write({
        kLayoutCyclePeriod.key:
            kLayoutCyclePeriod.saveAs(kLayoutCyclePeriod.value),
        kLayoutCycleEnabled.key:
            kLayoutCycleEnabled.saveAs(kLayoutCycleEnabled.value),
        kWakelock.key: kWakelock.saveAs(kWakelock.value),
        kNotificationsEnabled.key:
            kNotificationsEnabled.saveAs(kNotificationsEnabled.value),
        kSnoozeNotificationsUntil.key:
            kSnoozeNotificationsUntil.saveAs(kSnoozeNotificationsUntil.value),
        kNotificationClickBehavior.key:
            kNotificationClickBehavior.saveAs(kNotificationClickBehavior.value),
        kAutomaticStreaming.key:
            kAutomaticStreaming.saveAs(kAutomaticStreaming.value),
        kStreamOnBackground.key:
            kStreamOnBackground.saveAs(kStreamOnBackground.value),
        kStreamingType.key: kStreamingType.saveAs(kStreamingType.value),
        kRTSPProtocol.key: kRTSPProtocol.saveAs(kRTSPProtocol.value),
        kRenderingQuality.key:
            kRenderingQuality.saveAs(kRenderingQuality.value),
        kVideoFit.key: kVideoFit.saveAs(kVideoFit.value),
        kRefreshRate.key: kRefreshRate.saveAs(kRefreshRate.value),
        kLateStreamBehavior.key:
            kLateStreamBehavior.saveAs(kLateStreamBehavior.value),
        kReloadTimedOutStreams.key:
            kReloadTimedOutStreams.saveAs(kReloadTimedOutStreams.value),
        kUseHardwareDecoding.key:
            kUseHardwareDecoding.saveAs(kUseHardwareDecoding.value),
        kDownloadOnMobileData.key:
            kDownloadOnMobileData.saveAs(kDownloadOnMobileData.value),
        kChooseLocationEveryTime.key:
            kChooseLocationEveryTime.saveAs(kChooseLocationEveryTime.value),
        kAllowAppCloseWhenDownloading.key: kAllowAppCloseWhenDownloading
            .saveAs(kAllowAppCloseWhenDownloading.value),
        kPictureInPicture.key:
            kPictureInPicture.saveAs(kPictureInPicture.value),
        kEventsSpeed.key: kEventsSpeed.saveAs(kEventsSpeed.value),
        kEventsVolume.key: kEventsVolume.saveAs(kEventsVolume.value),
        kShowDifferentColorsForEvents.key: kShowDifferentColorsForEvents
            .saveAs(kShowDifferentColorsForEvents.value),
        kPauseToBuffer.key: kPauseToBuffer.saveAs(kPauseToBuffer.value),
        kTimelineInitialPoint.key:
            kTimelineInitialPoint.saveAs(kTimelineInitialPoint.value),
        kThemeMode.key: kThemeMode.saveAs(kThemeMode.value),
        kLanguageCode.key: kLanguageCode.saveAs(kLanguageCode.value),
      });
    } catch (e) {
      debugPrint('Error saving settings: $e');
    }
    super.save(notifyListeners: notifyListeners);
  }

  /// Formats the date according to the current [dateFormat].
  ///
  /// [toLocal] defines if the date will be converted to local time. Defaults to `true`
  String formatDate(DateTime date, {bool toLocal = false}) {
    if (toLocal) date = date.toLocal();

    return kDateFormat.value.format(date);
  }

  /// Formats the date according to the current [dateFormat].
  ///
  /// [toLocal] defines if the date will be converted to local time. Defaults to `true`
  String formatTime(DateTime time, {bool toLocal = false}) {
    if (toLocal) time = time.toLocal();

    return kTimeFormat.value.format(time);
  }

  void toggleCycling() {
    kLayoutCycleEnabled.value = !kLayoutCycleEnabled.value;
    save();
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

/// How to handle late video streams.
extension LateVideoBehaviorExtension on LateVideoBehavior {
  IconData get icon {
    return switch (this) {
      LateVideoBehavior.automatic => Icons.auto_awesome,
      LateVideoBehavior.manual => Icons.badge,
      LateVideoBehavior.never => Icons.close,
    };
  }

  String locale(BuildContext context) {
    final loc = AppLocalizations.of(context);
    return switch (this) {
      LateVideoBehavior.automatic => loc.automaticBehavior,
      LateVideoBehavior.manual => loc.manualBehavior,
      LateVideoBehavior.never => loc.never,
    };
  }
}
