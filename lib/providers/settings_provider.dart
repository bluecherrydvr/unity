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

import 'package:bluecherry_client/models/server.dart';
import 'package:bluecherry_client/providers/app_provider_interface.dart';
import 'package:bluecherry_client/providers/downloads_provider.dart';
import 'package:bluecherry_client/screens/events_timeline/desktop/timeline.dart';
import 'package:bluecherry_client/screens/settings/shared/options_chooser_tile.dart';
import 'package:bluecherry_client/utils/logging.dart';
import 'package:bluecherry_client/utils/methods.dart';
import 'package:bluecherry_client/utils/security.dart';
import 'package:bluecherry_client/utils/storage.dart';
import 'package:bluecherry_client/utils/video_player.dart';
import 'package:bluecherry_client/utils/window.dart';
import 'package:bluecherry_client/widgets/hover_button.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:intl/intl.dart';
import 'package:launch_at_startup/launch_at_startup.dart';
import 'package:unity_video_player/unity_video_player.dart';
import 'package:window_manager/window_manager.dart';

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

enum DisplayOn {
  always,
  onHover,
  never;

  String locale(BuildContext context) {
    final loc = AppLocalizations.of(context);
    return switch (this) {
      DisplayOn.always => loc.always,
      DisplayOn.onHover => loc.onHover,
      DisplayOn.never => loc.never,
    };
  }

  static Iterable<Option<DisplayOn>> options(BuildContext context) {
    return values.map<Option<DisplayOn>>((value) {
      return Option(
        value: value,
        text: value.locale(context),
      );
    });
  }

  T build<T>(T child, T never, Set<ButtonStates> states) {
    if (this == DisplayOn.never) {
      return never;
    } else if (this == DisplayOn.always) {
      return child;
    } else if (this == DisplayOn.onHover) {
      if (states.isHovering) return child;
      return never;
    } else {
      throw UnimplementedError('DisplayOn $this not implemented');
    }
  }
}

class _SettingsOption<T> {
  final String key;
  final T def;
  final Future<T> Function()? getDefault;

  late final String Function(dynamic value) saveAs;
  late final T Function(String value) loadFrom;
  final Future<bool?> Function(T)? onChanged;
  final T Function(dynamic value)? valueOverrider;

  late T _value;

  T get value => valueOverrider?.call(_value) ?? _value;
  set value(T newValue) {
    SettingsProvider.instance.updateProperty(() async {
      final allow = (await onChanged?.call(newValue)) ?? true;
      if (allow) _value = newValue;
    });
  }

  T call() {
    return value;
  }

  final T? min;
  final T? max;

  Future<T> get defaultValue {
    if (getDefault == null) return Future.value(def);
    try {
      return getDefault!();
    } catch (error, stack) {
      handleError(error, stack, 'Failed to get default value for $key');
      return Future.value(def);
    }
  }

  _SettingsOption? dependOn;

  _SettingsOption({
    required this.key,
    required this.def,
    this.getDefault,
    String Function(dynamic value)? saveAs,
    T Function(String value)? loadFrom,
    this.min,
    this.max,
    this.onChanged,
    this.valueOverrider,
    this.dependOn,
  }) {
    Future.microtask(() async {
      _value = await defaultValue;
    });

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

  Future<void> loadData() async {
    await dependOn?.loadData();
    try {
      var serializedData = await secureStorage.read(key: key);
      if (getDefault != null) serializedData ??= saveAs(await defaultValue);
      serializedData ??= defAsString;
      _value = loadFrom(serializedData);
    } catch (error, stackTrace) {
      handleError(
        error,
        stackTrace,
        'Error loading data for $key. Fallback to default value',
      );
      _value = await defaultValue;
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
  final kLayoutCyclePeriod = _SettingsOption<Duration>(
    def: const Duration(seconds: 5),
    key: 'general.cycle_period',
  );
  final kLayoutCycleEnabled = _SettingsOption<bool>(
    def: true,
    key: 'general.cycle_enabled',
  );
  final kWakelock = _SettingsOption<bool>(
    def: true,
    key: 'general.wakelock',
  );

  // Notifications
  final kNotificationsEnabled = _SettingsOption<bool>(
    def: true,
    key: 'notifications.enabled',
  );
  final kSnoozeNotificationsUntil = _SettingsOption<DateTime>(
    def: DateTime.utc(1969, 7, 20, 20, 18, 04),
    key: 'notifications.snooze_until',
  );
  final kNotificationClickBehavior = _SettingsOption<NotificationClickBehavior>(
    def: NotificationClickBehavior.showEventsScreen,
    key: 'notifications.click_behavior',
    loadFrom: (value) => NotificationClickBehavior.values[int.parse(value)],
    saveAs: (value) => value.index.toString(),
  );

  // Data usage
  final kAutomaticStreaming = _SettingsOption<NetworkUsage>(
    def: NetworkUsage.wifiOnly,
    key: 'data_usage.automatic_streaming',
    loadFrom: (value) => NetworkUsage.values[int.parse(value)],
    saveAs: (value) => value.index.toString(),
  );
  final kStreamOnBackground = _SettingsOption<NetworkUsage>(
    def: NetworkUsage.wifiOnly,
    key: 'data_usage.stream_on_background',
    loadFrom: (value) => NetworkUsage.values[int.parse(value)],
    saveAs: (value) => value.index.toString(),
  );

  // Server settings
  final kConnectAutomaticallyAtStartup = _SettingsOption<bool>(
    def: true,
    key: 'server.connect_automatically_at_startup',
  );
  final kAllowUntrustedCertificates = _SettingsOption<bool>(
    def: true,
    key: 'server.allow_untrusted_certificates',
  );

  // Streaming settings
  final kStreamingType = _SettingsOption<StreamingType>(
    def: kIsWeb ? StreamingType.hls : StreamingType.rtsp,
    key: 'streaming.type',
    loadFrom: (value) => StreamingType.values[int.parse(value)],
    saveAs: (value) => value.index.toString(),
  );
  final kRTSPProtocol = _SettingsOption<RTSPProtocol>(
    def: RTSPProtocol.tcp,
    key: 'streaming.rtsp_protocol',
    loadFrom: (value) => RTSPProtocol.values[int.parse(value)],
    saveAs: (value) => value.index.toString(),
  );
  final kRenderingQuality = _SettingsOption<RenderingQuality>(
    def: RenderingQuality.automatic,
    key: 'streaming.rendering_quality',
    loadFrom: (value) => RenderingQuality.values[int.parse(value)],
    saveAs: (value) => value.index.toString(),
  );
  final kVideoFit = _SettingsOption<UnityVideoFit>(
    def: UnityVideoFit.contain,
    key: 'streaming.video_fit',
    loadFrom: (value) => UnityVideoFit.values[int.parse(value)],
    saveAs: (value) => value.index.toString(),
  );
  final kRefreshRate = _SettingsOption<Duration>(
    def: const Duration(minutes: 5),
    key: 'streaming.refresh_rate',
  );
  final kLateStreamBehavior = _SettingsOption<LateVideoBehavior>(
    def: LateVideoBehavior.automatic,
    key: 'streaming.late_video_behavior',
    loadFrom: (value) => LateVideoBehavior.values[int.parse(value)],
    saveAs: (value) => value.index.toString(),
  );
  final kReloadTimedOutStreams = _SettingsOption<bool>(
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
  final kInitialDevicesVolume = _SettingsOption<double>(
    min: 0.0,
    max: 1.0,
    def: 0.0,
    key: 'devices.volume',
  );
  final kShowCameraNameOn = _SettingsOption<DisplayOn>(
    def: DisplayOn.always,
    key: 'devices.show_camera_name_on',
    loadFrom: (value) => DisplayOn.values[int.parse(value)],
    saveAs: (value) => value.index.toString(),
  );
  final kShowServerNameOn = _SettingsOption<DisplayOn>(
    def: DisplayOn.onHover,
    key: 'devices.show_server_name_on',
    loadFrom: (value) => DisplayOn.values[int.parse(value)],
    saveAs: (value) => value.index.toString(),
  );
  final kShowVideoStatusLabelOn = _SettingsOption<DisplayOn>(
    def: DisplayOn.always,
    key: 'devices.show_video_status_label_on',
    loadFrom: (value) => DisplayOn.values[int.parse(value)],
    saveAs: (value) => value.index.toString(),
  );

  // Downloads
  final kDownloadOnMobileData = _SettingsOption<bool>(
    def: false,
    key: 'downloads.download_on_mobile_data',
  );
  final kChooseLocationEveryTime = _SettingsOption<bool>(
    def: false,
    key: 'downloads.choose_location_every_time',
  );
  final kAllowAppCloseWhenDownloading = _SettingsOption<bool>(
    def: false,
    key: 'downloads.allow_app_close_when_downloading',
  );
  final kDownloadsDirectory = _SettingsOption<String>(
    def: '',
    getDefault: () async {
      try {
        return (await DownloadsManager.kDefaultDownloadsDirectory)?.path ?? '';
      } catch (e) {
        return '';
      }
    },
    key: 'downloads.directory',
  );

  // Events
  final kPictureInPicture = _SettingsOption<bool>(
    def: false,
    key: 'events.picture_in_picture',
  );
  final kEventsSpeed = _SettingsOption<double>(
    min: 0.25,
    max: 6.0,
    def: 1.0,
    key: 'events.speed',
  );
  final kEventsVolume = _SettingsOption<double>(
    def: 1.0,
    key: 'events.volume',
  );

  // Timeline of Events
  final kShowDifferentColorsForEvents = _SettingsOption<bool>(
    def: false,
    key: 'timeline.show_different_colors_for_events',
  );
  final kPauseToBuffer = _SettingsOption<bool>(
    def: false,
    key: 'timeline.pause_to_buffer',
  );
  final kTimelineInitialPoint = _SettingsOption<TimelineInitialPoint>(
    def: TimelineInitialPoint.beginning,
    key: 'timeline.initial_point',
    loadFrom: (value) => TimelineInitialPoint.values[int.parse(value)],
    saveAs: (value) => value.index.toString(),
  );
  final kAutomaticallySkipEmptyPeriods = _SettingsOption<bool>(
    def: false,
    key: 'timeline.automatically_skip_empty_periods',
  );

  // Application
  final kThemeMode = _SettingsOption<ThemeMode>(
    def: ThemeMode.system,
    key: 'application.theme_mode',
    loadFrom: (value) => ThemeMode.values[int.parse(value)],
    saveAs: (value) => value.index.toString(),
  );
  final kLanguageCode = _SettingsOption<Locale>(
    def: Locale.fromSubtags(languageCode: Intl.getCurrentLocale()),
    key: 'application.language_code',
  );

  late final kDateFormat = _SettingsOption<DateFormat>(
    def: DateFormat('EEEE, dd MMMM yyyy'),
    key: 'application.date_format',
    dependOn: kLanguageCode,
    getDefault: () async {
      return DateFormat(
        'EEEE, dd MMMM yyyy',
        kLanguageCode.value.toLanguageTag(),
      );
    },
    valueOverrider: (value) {
      return DateFormat(value.pattern, kLanguageCode.value.toLanguageTag());
    },
  );

  static const availableTimeFormats = ['HH:mm', 'hh:mm a'];
  late final kTimeFormat = _SettingsOption<DateFormat>(
    def: DateFormat('hh:mm a'),
    getDefault: () async {
      return DateFormat(
        'hh:mm a',
        kLanguageCode.value.toLanguageTag(),
      );
    },
    key: 'application.time_format',
    dependOn: kLanguageCode,
    valueOverrider: (value) {
      return DateFormat(value.pattern, kLanguageCode.value.toLanguageTag());
    },
  );

  /// The extended time format adds the second to the time format.
  DateFormat get extendedTimeFormat {
    return switch (kTimeFormat.value.pattern!) {
      'HH:mm' => DateFormat('HH:mm:ss', kLanguageCode.value.toLanguageTag()),
      'hh:mm a' => DateFormat(
          'hh:mm:ss a',
          kLanguageCode.value.toLanguageTag(),
        ),
      _ => DateFormat(
          kTimeFormat.value.pattern,
          kLanguageCode.value.toLanguageTag(),
        ),
    };
  }

  // TODO(bdlukaa): Remove this migration in future releases
  var _hasMigratedTimezone = false;
  late final kConvertTimeToLocalTimezone = _SettingsOption<bool>(
    def: true,
    key: 'application.convert_time_to_local_timezone',
    loadFrom: (value) {
      if (!_hasMigratedTimezone) {
        _hasMigratedTimezone = true;
        return true;
      }
      return bool.tryParse(value) ?? true;
    },
  );

  // Window
  final kLaunchAppOnStartup = _SettingsOption<bool>(
    def: false,
    key: 'window.launch_app_on_startup',
    getDefault: !canLaunchAtStartup
        ? null
        : () async {
            try {
              return await launchAtStartup.isEnabled();
            } catch (_) {
              return false;
            }
          },
    onChanged: (value) async {
      if (kIsWeb || !canLaunchAtStartup) return false;

      if (value) {
        await launchAtStartup.enable();
      } else {
        await launchAtStartup.disable();
      }
      return true;
    },
  );
  final kFullscreen = _SettingsOption<bool>(
    def: false,
    key: 'window.fullscreen',
    getDefault: () async {
      if (!isDesktopPlatform) return false;
      try {
        return windowManager.isFullScreen();
      } catch (error) {
        return false;
      }
    },
    onChanged: (value) async {
      if (!isDesktopPlatform) return false;
      try {
        await WindowManager.instance.ensureInitialized();
        await windowManager.setFullScreen(value);
        return true;
      } catch (error) {
        return false;
      }
    },
  );
  final kImmersiveMode = _SettingsOption<bool>(
    def: false,
    key: 'window.immersive_mode',
    onChanged: (value) async {
      if (isMobilePlatform) {
        if (value) {
          await SystemChrome.setEnabledSystemUIMode(
            SystemUiMode.immersive,
            overlays: [],
          );
        } else {
          await SystemChrome.setEnabledSystemUIMode(
            SystemUiMode.manual,
            overlays: SystemUiOverlay.values,
          );
        }
      }
      return true;
    },
  );
  final kMinimizeToTray = _SettingsOption<bool>(
    def: false,
    key: 'window.minimize_to_tray',
  );

  // Acessibility
  final kAnimationsEnabled = _SettingsOption<bool>(
    def: true,
    key: 'accessibility.animations_enabled',
  );
  final kHighContrast = _SettingsOption<bool>(
    def: false,
    key: 'accessibility.high_contrast',
  );
  final kLargeFont = _SettingsOption<bool>(
    def: false,
    key: 'accessibility.large_font',
  );

  // Privacy and Security
  final kAllowDataCollection = _SettingsOption<bool>(
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
  final kAutoUpdate = _SettingsOption<bool>(
    def: true,
    key: 'updates.auto_update',
  );
  final kShowReleaseNotes = _SettingsOption<bool>(
    def: true,
    key: 'updates.show_release_notes',
  );

  // Other
  final kMatrixedZoomEnabled = _SettingsOption<bool>(
    def: false,
    key: 'other.matrixed_zoom_enabled',
  );
  final kMatrixSize = _SettingsOption<MatrixType>(
    def: MatrixType.t16,
    key: 'other.matrix_size',
    loadFrom: (value) => MatrixType.values[int.parse(value)],
    saveAs: (value) => value.index.toString(),
  );
  static bool get isHardwareZoomSupported {
    return UnityVideoPlayerInterface.instance.supportsHardwareZoom;
  }

  final kSoftwareZooming = _SettingsOption<bool>(
    def: isHardwareZoomSupported ? true : false,
    key: 'other.software_zoom',
    onChanged: (value) async {
      for (final player in UnityPlayers.players.values) {
        player
          ..resetCrop()
          ..zoom.softwareZoom = value;
      }
      return true;
    },
    valueOverrider: isHardwareZoomSupported ? (_) => true : null,
  );
  final kEventsMatrixedZoom = _SettingsOption<bool>(
    def: true,
    key: 'other.zoom_matrixed_zoom_enabled',
  );
  final kShowDebugInfo = _SettingsOption<bool>(
    def: kDebugMode,
    key: 'other.show_debug_info',
    onChanged: (value) async {
      if (value) {
        final canEnable = await UnityAuth.ask();
        return canEnable;
      }
      return true;
    },
  );
  final kShowNetworkUsage = _SettingsOption<bool>(
    def: false,
    key: 'other.show_network_usage',
  );

  /// The list of all settings.
  late final List<_SettingsOption> _allSettings = [
    kLayoutCyclePeriod,
    kLayoutCycleEnabled,
    kWakelock,
    kNotificationsEnabled,
    kSnoozeNotificationsUntil,
    kNotificationClickBehavior,
    kAutomaticStreaming,
    kStreamOnBackground,
    kConnectAutomaticallyAtStartup,
    kAllowUntrustedCertificates,
    kStreamingType,
    kRTSPProtocol,
    kRenderingQuality,
    kVideoFit,
    kRefreshRate,
    kLateStreamBehavior,
    kReloadTimedOutStreams,
    kUseHardwareDecoding,
    kListOfflineDevices,
    kInitialDevicesVolume,
    kShowCameraNameOn,
    kShowServerNameOn,
    kShowVideoStatusLabelOn,
    kDownloadOnMobileData,
    kChooseLocationEveryTime,
    kAllowAppCloseWhenDownloading,
    kDownloadsDirectory,
    kPictureInPicture,
    kEventsSpeed,
    kEventsVolume,
    kShowDifferentColorsForEvents,
    kPauseToBuffer,
    kTimelineInitialPoint,
    kAutomaticallySkipEmptyPeriods,
    kThemeMode,
    kLanguageCode,
    kDateFormat,
    kTimeFormat,
    kConvertTimeToLocalTimezone,
    kLaunchAppOnStartup,
    kFullscreen,
    kImmersiveMode,
    kMinimizeToTray,
    kAnimationsEnabled,
    kHighContrast,
    kLargeFont,
    kAllowDataCollection,
    kAllowCrashReports,
    kAutoUpdate,
    kShowReleaseNotes,
    kMatrixedZoomEnabled,
    kMatrixSize,
    kSoftwareZooming,
    kEventsMatrixedZoom,
    kShowDebugInfo,
    kShowNetworkUsage,
  ];

  int _settingsIndex = 0;
  int get settingsIndex => _settingsIndex;
  set settingsIndex(int value) {
    _settingsIndex = value;
    notifyListeners();
  }

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
    try {
      await initializeStorage('settings');
    } catch (error, stackTrace) {
      handleError(
        error,
        stackTrace,
        'Error initializing settings storage. Fallback to memory',
      );
    }

    _hasMigratedTimezone =
        await secureStorage.readBool(key: 'hasMigratedTimezone') ?? false;

    await Future.wait(_allSettings.map((setting) => setting.loadData()));

    notifyListeners();
  }

  @override
  Future<void> save({bool notifyListeners = true}) async {
    await write(<String, dynamic>{
      for (final setting in _allSettings)
        ...() {
          try {
            return <String, String>{setting.key: setting.saveAs(setting.value)};
          } catch (error, stackTrace) {
            handleError(
              error,
              stackTrace,
              'Error saving setting ${setting.key}',
            );
          }
          return <String, String>{};
        }(),
      'hasMigratedTimezone': _hasMigratedTimezone.toString(),
    });

    super.save(notifyListeners: notifyListeners);
  }

  Future<void> updateProperty(Future Function() update) async {
    await update();
    save();
  }

  void toggleCycling() {
    kLayoutCycleEnabled.value = !kLayoutCycleEnabled.value;
    save();
  }

  Future<void> restoreDefaults() async {
    final canRestoreDefaults = await UnityAuth.ask();

    if (canRestoreDefaults) {
      for (final setting in _allSettings) {
        setting._value = await setting.defaultValue;
        await save();
      }
      await initialize();
    }
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

  bool get isImmersiveMode {
    return kFullscreen.value && kImmersiveMode.value;
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
