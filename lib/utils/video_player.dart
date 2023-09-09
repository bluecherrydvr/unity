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

import 'package:bluecherry_client/models/device.dart';
import 'package:flutter/foundation.dart';
import 'package:unity_video_player/unity_video_player.dart';

class UnityPlayers with ChangeNotifier {
  UnityPlayers._();

  static final instance = UnityPlayers._();

  /// Instances of video players corresponding to a particular [Device].
  ///
  /// This avoids redundantly creating new video player instance if a [Device]
  /// is already present in the camera grid on the screen or allows to use
  /// existing instance when switching tab (if common camera [Device] tile exists).
  ///
  static final Map<Device, UnityVideoPlayer> players = {};

  /// Helper method to create a video player with required configuration for a [Device].
  static UnityVideoPlayer forDevice(Device device) {
    debugPrint(device.streamURL);
    final controller = UnityVideoPlayer.create(
      quality: UnityVideoQuality.qualityForResolutionY(device.resolutionY),
    )
      ..setDataSource(device.streamURL)
      ..setVolume(0.0)
      ..setSpeed(1.0);

    return controller;
  }

  /// Release the video player for the given [Device].
  static Future<void> releaseDevice(Device device) async {
    await players[device]?.release();
    await players[device]?.dispose();
    players.remove(device);
  }

  /// Reload the video player for the given [Device].
  static Future<void> reloadDevice(Device device) async {
    await releaseDevice(device);
    players[device] = forDevice(device);
    instance.notifyListeners();
  }

  /// Reload all video players.
  static void reloadAll() {
    for (final device in players.keys) {
      reloadDevice(device);
    }
  }
}
