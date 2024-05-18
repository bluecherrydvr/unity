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

import 'package:bluecherry_client/models/server.dart';
import 'package:bluecherry_client/providers/app_provider_interface.dart';
import 'package:bluecherry_client/providers/downloads_provider.dart';
import 'package:bluecherry_client/providers/update_provider.dart';
import 'package:bluecherry_client/screens/events_timeline/desktop/timeline.dart';
import 'package:bluecherry_client/utils/storage.dart';
import 'package:bluecherry_client/utils/video_player.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:intl/intl.dart';
import 'package:unity_video_player/unity_video_player.dart';

enum NetworkUsage {
  auto,
  wifiOnly,
  never;

  String locale(BuildContext context) {
    final loc = AppLocalizations.of(context);
    return switch (this) {
      NetworkUsage.auto => loc.automatic,
      NetworkUsage.wifiOnly => loc.wifiOnly,
      NetworkUsage.never => loc.never,
    };
  }
}

enum EnabledPreference { on, ask, never }

class _SettingsOption<T> {
  final String key;
  final T def;
  final Future<T> Function()? getDefault;

  late final String Function(T value) saveAs;
  late final T Function(String value) loadFrom;
  final ValueChanged<T>? onChanged;
  final T Function()? valueOverrider;

  late T _value;

  T get value => valueOverrider?.call() ?? _value;
  set value(T newValue) {
    SettingsProvider.instance.updateProperty(() {
      _value = newValue;
      onChanged?.call(value);
    });
  }

  T call() {
    return value;
  }

  final T? min;
  final T? max;

  _SettingsOption({
    required this.key,
    required this.def,
    this.getDefault,
    String Function(T value)? saveAs,
    T Function(String value)? loadFrom,
    this.min,
    this.max,
    this.onChanged,
    this.valueOverrider,
  }) {
    Future.microtask(() async {
      _value = getDefault != null ? await getDefault!() : def;

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
        this.loadFrom =
            (value) => Duration(milliseconds: int.parse(value)) as T;
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
    });
  }

  String get defAsString => saveAs(def);

  Future<void> loadData(Map data) async {
    String? serializedData = data[key];
    if (getDefault != null) serializedData ??= saveAs(await getDefault!());
    serializedData ??= defAsString;

    try {
      _value = loadFrom(serializedData);
    } catch (e) {
      debugPrint('Error loading data for $key: $e\nFallback to default');
      _value = (await getDefault?.call()) ?? def;
    }
  }

  @override
  String toString() {
    return 'SettingsOption<$T>($key: $_value)';
  }
}

class SettingsProvider extends UnityProvider {
  SettingsProvider._();
  static late SettingsProvider instance;

  // General settings
  final kLayoutCyclePeriod = _SettingsOption(
    def: const Duration(seconds: 5),
    key: 'general.cycle_period',
  );
  final kLayoutCycleEnabled = _SettingsOption(
    def: true,
    key: 'general.cycle_enabled',
  );
  final kWakelock = _SettingsOption(
    def: true,
    key: 'general.wakelock',
  );

  // Notifications
  final kNotificationsEnabled = _SettingsOption(
    def: true,
    key: 'notifications.enabled',
  );
  final kSnoozeNotificationsUntil = _SettingsOption<DateTime>(
    def: DateTime.utc(1969, 7, 20, 20, 18, 04),
    key: 'notifications.snooze_until',
  );
  final kNotificationClickBehavior = _SettingsOption(
    def: NotificationClickBehavior.showEventsScreen,
    key: 'notifications.click_behavior',
    loadFrom: (value) => NotificationClickBehavior.values[int.parse(value)],
    saveAs: (value) => value.index.toString(),
  );

  // Data usage
  final kAutomaticStreaming = _SettingsOption(
    def: NetworkUsage.wifiOnly,
    key: 'data_usage.automatic_streaming',
    loadFrom: (value) => NetworkUsage.values[int.parse(value)],
    saveAs: (value) => value.index.toString(),
  );
  final kStreamOnBackground = _SettingsOption(
    def: NetworkUsage.wifiOnly,
    key: 'data_usage.stream_on_background',
    loadFrom: (value) => NetworkUsage.values[int.parse(value)],
    saveAs: (value) => value.index.toString(),
  );

  // Server settings
  final kConnectAutomaticallyAtStartup = _SettingsOption(
    def: true,
    key: 'server.connect_automatically_at_startup',
  );
  final kAllowUntrustedCertificates = _SettingsOption(
    def: true,
    key: 'server.allow_untrusted_certificates',
  );

  // Streaming settings
  final kStreamingType = _SettingsOption(
    def: kIsWeb ? StreamingType.hls : StreamingType.rtsp,
    key: 'streaming.type',
    loadFrom: (value) => StreamingType.values[int.parse(value)],
    saveAs: (value) => value.index.toString(),
  );
  final kRTSPProtocol = _SettingsOption(
    def: RTSPProtocol.tcp,
    key: 'streaming.rtsp_protocol',
    loadFrom: (value) => RTSPProtocol.values[int.parse(value)],
    saveAs: (value) => value.index.toString(),
  );
  final kRenderingQuality = _SettingsOption(
    def: RenderingQuality.automatic,
    key: 'streaming.rendering_quality',
    loadFrom: (value) => RenderingQuality.values[int.parse(value)],
    saveAs: (value) => value.index.toString(),
  );
  final kVideoFit = _SettingsOption(
    def: UnityVideoFit.contain,
    key: 'streaming.video_fit',
    loadFrom: (value) => UnityVideoFit.values[int.parse(value)],
    saveAs: (value) => value.index.toString(),
  );
  final kRefreshRate = _SettingsOption(
    def: const Duration(minutes: 5),
    key: 'streaming.refresh_rate',
  );
  final kLateStreamBehavior = _SettingsOption(
    def: LateVideoBehavior.automatic,
    key: 'streaming.late_video_behavior',
    loadFrom: (value) => LateVideoBehavior.values[int.parse(value)],
    saveAs: (value) => value.index.toString(),
  );
  final kReloadTimedOutStreams = _SettingsOption(
    def: true,
    key: 'streaming.reload_timed_out_streams',
  );
  final kUseHardwareDecoding = _SettingsOption<bool>(
    def: true,
    key: 'streaming.use_hardware_decoding',
  );

  // Devices Settings
  final kListOfflineDevices = _SettingsOption<bool>(
    def: true,
    key: 'devices.list_offline',
  );

  // Downloads
  final kDownloadOnMobileData = _SettingsOption(
    def: false,
    key: 'downloads.download_on_mobile_data',
  );
  final kChooseLocationEveryTime = _SettingsOption(
    def: false,
    key: 'downloads.choose_location_every_time',
  );
  final kAllowAppCloseWhenDownloading = _SettingsOption(
    def: false,
    key: 'downloads.allow_app_close_when_downloading',
  );
  final kDownloadsDirectory = _SettingsOption(
    def: '',
    getDefault: () async {
      try {
        return (await DownloadsManager.kDefaultDownloadsDirectory).path;
      } catch (e) {
        debugPrint('Error getting default downloads directory: $e');
        return '';
      }
    },
    key: 'downloads.directory',
  );

  // Events
  final kPictureInPicture = _SettingsOption(
    def: false,
    key: 'events.picture_in_picture',
  );
  final kEventsSpeed = _SettingsOption(
    min: 0.25,
    max: 6.0,
    def: 1.0,
    key: 'events.speed',
  );
  final kEventsVolume = _SettingsOption(
    def: 1.0,
    key: 'events.volume',
  );

  // Timeline of Events
  final kShowDifferentColorsForEvents = _SettingsOption(
    def: false,
    key: 'timeline.show_different_colors_for_events',
  );
  final kPauseToBuffer = _SettingsOption(
    def: false,
    key: 'timeline.pause_to_buffer',
  );
  final kTimelineInitialPoint = _SettingsOption(
    def: TimelineInitialPoint.beginning,
    key: 'timeline.initial_point',
    loadFrom: (value) => TimelineInitialPoint.values[int.parse(value)],
    saveAs: (value) => value.index.toString(),
  );

  // Application
  final kThemeMode = _SettingsOption(
    def: ThemeMode.system,
    key: 'application.theme_mode',
    loadFrom: (value) => ThemeMode.values[int.parse(value)],
    saveAs: (value) => value.index.toString(),
  );
  final kLanguageCode = _SettingsOption(
    def: Locale.fromSubtags(languageCode: Intl.getCurrentLocale()),
    key: 'application.language_code',
  );
  final kDateFormat = _SettingsOption(
    def: DateFormat('EEEE, dd MMMM yyyy'),
    key: 'application.date_format',
  );
  final kTimeFormat = _SettingsOption(
    def: DateFormat('hh:mm a'),
    key: 'application.time_format',
  );
  final kConvertTimeToLocalTimezone = _SettingsOption<bool>(
    def: false,
    key: 'application.convert_time_to_local_timezone',
  );

  // Window
  final kLaunchAppOnStartup = _SettingsOption(
    def: false,
    key: 'window.launch_app_on_startup',
  );
  final kMinimizeToTray = _SettingsOption(
    def: false,
    key: 'window.minimize_to_tray',
  );

  // Acessibility
  final kAnimationsEnabled = _SettingsOption<bool>(
    def: true,
    key: 'accessibility.animations_enabled',
  );
  final kHighContrast = _SettingsOption(
    def: false,
    key: 'accessibility.high_contrast',
  );
  final kLargeFont = _SettingsOption(
    def: false,
    key: 'accessibility.large_font',
  );

  // Privacy and Security
  final kAllowDataCollection = _SettingsOption(
    def: true,
    key: 'privacy.allow_data_collection',
  );
  final kAllowCrashReports = _SettingsOption<EnabledPreference>(
    def: EnabledPreference.on,
    key: 'privacy.allow_crash_reports',
    loadFrom: (value) => EnabledPreference.values[int.parse(value)],
    saveAs: (value) => value.index.toString(),
  );

  // Updates
  final kAutoUpdate = _SettingsOption(
    def: true,
    key: 'updates.auto_update',
  );
  final kShowReleaseNotes = _SettingsOption(
    def: true,
    key: 'updates.show_release_notes',
  );

  // Other
  final kDefaultBetaMatrixedZoomEnabled = _SettingsOption(
    def: false,
    key: 'other.matrixed_zoom_enabled',
  );
  final kMatrixSize = _SettingsOption(
    def: MatrixType.t16,
    key: 'other.matrix_size',
    loadFrom: (value) => MatrixType.values[int.parse(value)],
    saveAs: (value) => value.index.toString(),
  );
  final kSoftwareZooming = _SettingsOption<bool>(
    def: Platform.isMacOS || kIsWeb || UpdateManager.isEmbedded ? true : false,
    key: 'other.software_zoom',
    onChanged: (value) {
      for (final player in UnityPlayers.players.values) {
        player
          ..resetCrop()
          ..zoom.softwareZoom = value;
      }
    },
    valueOverrider: Platform.isMacOS || kIsWeb || UpdateManager.isEmbedded
        ? () => true
        : null,
  );
  final kShowDebugInfo = _SettingsOption(
    def: kDebugMode,
    key: 'other.show_debug_info',
  );
  final kShowNetworkUsage = _SettingsOption(
    def: false,
    key: 'other.show_network_usage',
  );

  /// Initializes the [SettingsProvider] instance & fetches state from `async`
  /// `package:hive` method-calls. Called before [runApp].
  static Future<SettingsProvider> ensureInitialized() async {
    instance = SettingsProvider._();
    await instance.initialize();
    debugPrint('SettingsProvider initialized');
    return instance;
  }

  @override
  Future<void> initialize() async {
    final data = await tryReadStorage(() => settings.read());

    await Future.wait([
      kLayoutCyclePeriod.loadData(data),
      kLayoutCycleEnabled.loadData(data),
      kWakelock.loadData(data),
      kNotificationsEnabled.loadData(data),
      kSnoozeNotificationsUntil.loadData(data),
      kNotificationClickBehavior.loadData(data),
      kAutomaticStreaming.loadData(data),
      kStreamOnBackground.loadData(data),
      kConnectAutomaticallyAtStartup.loadData(data),
      kAllowUntrustedCertificates.loadData(data),
      kStreamingType.loadData(data),
      kRTSPProtocol.loadData(data),
      kRenderingQuality.loadData(data),
      kVideoFit.loadData(data),
      kRefreshRate.loadData(data),
      kLateStreamBehavior.loadData(data),
      kReloadTimedOutStreams.loadData(data),
      kUseHardwareDecoding.loadData(data),
      kListOfflineDevices.loadData(data),
      kDownloadOnMobileData.loadData(data),
      kChooseLocationEveryTime.loadData(data),
      kDownloadsDirectory.loadData(data),
      kAllowAppCloseWhenDownloading.loadData(data),
      kPictureInPicture.loadData(data),
      kEventsSpeed.loadData(data),
      kEventsVolume.loadData(data),
      kShowDifferentColorsForEvents.loadData(data),
      kPauseToBuffer.loadData(data),
      kTimelineInitialPoint.loadData(data),
      kThemeMode.loadData(data),
      kLanguageCode.loadData(data),
      kDateFormat.loadData(data),
      kTimeFormat.loadData(data),
      kConvertTimeToLocalTimezone.loadData(data),
      kLaunchAppOnStartup.loadData(data),
      kMinimizeToTray.loadData(data),
      kAnimationsEnabled.loadData(data),
      kHighContrast.loadData(data),
      kLargeFont.loadData(data),
      kAllowDataCollection.loadData(data),
      kAllowCrashReports.loadData(data),
      kAutoUpdate.loadData(data),
      kShowReleaseNotes.loadData(data),
      kDefaultBetaMatrixedZoomEnabled.loadData(data),
      kMatrixSize.loadData(data),
      kSoftwareZooming.loadData(data),
      kShowDebugInfo.loadData(data),
      kShowNetworkUsage.loadData(data),
    ]);

    notifyListeners();
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
        kConnectAutomaticallyAtStartup.key: kConnectAutomaticallyAtStartup
            .saveAs(kConnectAutomaticallyAtStartup.value),
        kAllowUntrustedCertificates.key: kAllowUntrustedCertificates
            .saveAs(kAllowUntrustedCertificates.value),
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
        kListOfflineDevices.key:
            kListOfflineDevices.saveAs(kListOfflineDevices.value),
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
        kDateFormat.key: kDateFormat.saveAs(kDateFormat.value),
        kTimeFormat.key: kTimeFormat.saveAs(kTimeFormat.value),
        kConvertTimeToLocalTimezone.key: kConvertTimeToLocalTimezone
            .saveAs(kConvertTimeToLocalTimezone.value),
        kLaunchAppOnStartup.key:
            kLaunchAppOnStartup.saveAs(kLaunchAppOnStartup.value),
        kMinimizeToTray.key: kMinimizeToTray.saveAs(kMinimizeToTray.value),
        kAnimationsEnabled.key:
            kAnimationsEnabled.saveAs(kAnimationsEnabled.value),
        kHighContrast.key: kHighContrast.saveAs(kHighContrast.value),
        kLargeFont.key: kLargeFont.saveAs(kLargeFont.value),
        kAllowDataCollection.key:
            kAllowDataCollection.saveAs(kAllowDataCollection.value),
        kAllowCrashReports.key:
            kAllowCrashReports.saveAs(kAllowCrashReports.value),
        kAutoUpdate.key: kAutoUpdate.saveAs(kAutoUpdate.value),
        kShowReleaseNotes.key:
            kShowReleaseNotes.saveAs(kShowReleaseNotes.value),
        kDefaultBetaMatrixedZoomEnabled.key: kDefaultBetaMatrixedZoomEnabled
            .saveAs(kDefaultBetaMatrixedZoomEnabled.value),
        kMatrixSize.key: kMatrixSize.saveAs(kMatrixSize.value),
        kSoftwareZooming.key: kSoftwareZooming.saveAs(kSoftwareZooming.value),
        kShowDebugInfo.key: kShowDebugInfo.saveAs(kShowDebugInfo.value),
        kShowNetworkUsage.key:
            kShowNetworkUsage.saveAs(kShowNetworkUsage.value),
      });
    } catch (e) {
      debugPrint('Error saving settings: $e');
    }
    super.save(notifyListeners: notifyListeners);
  }

  void updateProperty(VoidCallback update) {
    update();
    save();
  }

  void toggleCycling() {
    kLayoutCycleEnabled.value = !kLayoutCycleEnabled.value;
    save();
  }

  Future<void> restoreDefaults() async {
    await settings.delete();
    await initialize();
  }

  /// Check if the server certificates passes
  ///
  /// If [kAllowUntrustedCertificates] is enabled, it will return true.
  /// Otherwise, it will return the server's [Server.passedCertificates] value.
  bool checkServerCertificates(Server server) {
    if (kAllowUntrustedCertificates.value) {
      return true;
    }

    return server.passedCertificates;
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

  UnityVideoQuality? get playerQuality {
    return switch (this) {
      RenderingQuality.p4k => UnityVideoQuality.p4k,
      RenderingQuality.p1080 => UnityVideoQuality.p1080,
      RenderingQuality.p720 => UnityVideoQuality.p720,
      RenderingQuality.p480 => UnityVideoQuality.p480,
      RenderingQuality.p360 => UnityVideoQuality.p360,
      RenderingQuality.p240 => UnityVideoQuality.p240,
      RenderingQuality.automatic => null,
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
