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

import 'dart:async';

import 'package:bluecherry_client/models/device.dart';
import 'package:bluecherry_client/providers/settings_provider.dart';
import 'package:bluecherry_client/utils/logging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:unity_video_player/unity_video_player.dart';

class UnityPlayers with ChangeNotifier {
  UnityPlayers._() {
    createTimer();
  }

  static final instance = UnityPlayers._();

  /// Instances of video players corresponding to a particular [Device].
  ///
  /// This avoids redundantly creating new video player instance if a [Device]
  /// is already present in the camera grid on the screen or allows to use
  /// existing instance when switching tab (if common camera [Device] tile exists).
  static final players = <String, UnityVideoPlayer>{};

  /// Devices that should be reloaded at every [reloadTime] interval.
  static final _reloadable = <String>[];

  static Timer? _reloadTimer;
  static void createTimer() {
    UnityPlayers._reloadTimer?.cancel();
    UnityPlayers._reloadTimer = null;
    if (SettingsProvider.instance.kRefreshRate.value > Duration.zero) {
      UnityPlayers._reloadTimer = Timer.periodic(
        SettingsProvider.instance.kRefreshRate.value,
        (_) => reloadDevices(),
      );
    }
  }

  /// Reloads all devices that are marked as reloadable.
  static Future<void> reloadDevices() async {
    debugPrint('Reloading devices $_reloadable');
    for (final player
        in players.entries.where((entry) => _reloadable.contains(entry.key))) {
      // reload each device at once
      await reloadDevice(Device.fromUUID(player.key)!);
    }
  }

  /// Whether the given [Device] is reloadable.
  static bool isReloadable(String deviceUUID) =>
      _reloadable.contains(deviceUUID);

  /// Helper method to create a video player with required configuration for a [Device].
  static UnityVideoPlayer forDevice(
    Device device, [
    VoidCallback? onSetSource,
  ]) {
    final settings = SettingsProvider.instance;
    late UnityVideoPlayer controller;

    Future<void> setSource() async {
      if (device.url != null) {
        debugPrint('Initializing ${device.url}');
        await controller.setDataSource(device.url!);
      } else {
        var streamingType = device.preferredStreamingType ??
            device.server.additionalSettings.preferredStreamingType ??
            settings.kStreamingType.value;
        if (kIsWeb && streamingType == StreamingType.rtsp) {
          streamingType = StreamingType.hls;
        }
        final (String source, Future<String> fallback) =
            switch (streamingType) {
          StreamingType.rtsp => (device.rtspURL, device.getHLSUrl()),
          StreamingType.hls => (
              await device.getHLSUrl(),
              Future.value(device.rtspURL)
            ),
          StreamingType.mjpeg => (device.mjpegURL, Future.value(device.hlsURL)),
        };
        debugPrint('Initializing $source');
        controller.fallbackUrl = fallback;
        await controller.setDataSource(source);

        _reloadable.add(source);
      }
      onSetSource?.call();
    }

    controller = UnityVideoPlayer.create(
      quality: switch (device.server.additionalSettings.renderingQuality ??
          settings.kRenderingQuality.value) {
        RenderingQuality.p4k => UnityVideoQuality.p4k,
        RenderingQuality.p1080 => UnityVideoQuality.p1080,
        RenderingQuality.p720 => UnityVideoQuality.p720,
        RenderingQuality.p480 => UnityVideoQuality.p480,
        RenderingQuality.p360 => UnityVideoQuality.p360,
        RenderingQuality.p240 => UnityVideoQuality.p240,
        RenderingQuality.automatic => null,
      },
      onReload: setSource,
      title: device.fullName,
    )
      ..setVolume(0.0)
      ..setSpeed(1.0);

    setSource();

    controller.onError.listen((event) {
      writeLogToFile(
        'An error ocurred when playing a video (${controller.dataSource}): $event\n',
      );
    });

    return controller;
  }

  /// Release the video player for the given [Device].
  static Future<void> releaseDevice(String deviceUUID) async {
    debugPrint('Releasing device $deviceUUID. ${players[deviceUUID]}');
    _reloadable.remove(deviceUUID);
    await players[deviceUUID]?.dispose();
    players.remove(deviceUUID);
  }

  /// Reload the video player for the given [Device].
  static Future<void> reloadDevice(Device device) async {
    await releaseDevice(device.uuid);
    players[device.uuid] = forDevice(device);
    instance.notifyListeners();
  }

  /// Reload all video players.
  ///
  /// [onlyIfTimedOut], if true, the device will only be reloaded if it's timed out
  static void reloadAll({bool onlyIfTimedOut = false}) {
    for (final entry in players.entries) {
      final player = entry.value;
      if (onlyIfTimedOut) {
        if (!player.isImageOld) continue;
      }
      final deviceUUID = entry.key;
      final device = Device.fromUUID(deviceUUID);
      if (device != null) reloadDevice(device);
    }
  }

  /// Opens a fullscreen video player for the given [Device].
  ///
  /// If there is not a video player instance for the given [Device], it will
  /// be created and released when the fullscreen player is closed.
  static Future<void> openFullscreen(
    BuildContext context,
    Device device, {
    bool ptzEnabled = false,
  }) async {
    var player = UnityPlayers.players[device.uuid];
    final isLocalController = player == null;
    if (isLocalController) player = UnityPlayers.forDevice(device);

    await Navigator.of(context).pushNamed(
      '/fullscreen',
      arguments: {
        'device': device,
        'player': player,
        'ptzEnabled': ptzEnabled,
      },
    );
    if (isLocalController) await player.dispose();
  }

  @override
  void dispose() {
    _reloadTimer?.cancel();
    super.dispose();
  }
}
