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

import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import 'package:status_bar_control/status_bar_control.dart';

import 'package:unity_video_player/unity_video_player.dart';
import 'package:bluecherry_client/models/device.dart';

/// A helper singleton to set preferred orientation for the app.
class DeviceOrientations {
  /// [DeviceOrientations] singleton instance.
  static final DeviceOrientations instance = DeviceOrientations._();

  /// Private constructor.
  DeviceOrientations._();

  Future<void> set(
    List<DeviceOrientation> orientations,
  ) {
    _stack.add(orientations);
    debugPrint(orientations.toString());
    return SystemChrome.setPreferredOrientations(orientations);
  }

  Future<void> restoreLast() async {
    _stack.removeLast();
    debugPrint(_stack.toString());
    await SystemChrome.setPreferredOrientations(_stack.last);
  }

  /// Maintain a stack of the last set of orientations, to switch back to the most recent one.
  final List<List<DeviceOrientation>> _stack = [];
}

/// Gets the correct [StatusBarStyle].
StatusBarStyle getStatusBarStyleFromBrightness(Brightness brightness) {
  if (Platform.isIOS) {
    return brightness == Brightness.light
        ? StatusBarStyle.DARK_CONTENT
        : StatusBarStyle.LIGHT_CONTENT;
  } else {
    return brightness == Brightness.dark
        ? StatusBarStyle.DARK_CONTENT
        : StatusBarStyle.LIGHT_CONTENT;
  }
}

/// Helper method to create a video player with required configuration for a [Device].
UnityVideoPlayer getVideoPlayerControllerForDevice(
  Device device,
) {
  final controller = UnityVideoPlayer.create();

  controller
    ..setDataSource(
      device.streamURL,
      autoPlay: true,
    )
    ..setVolume(0.0)
    ..setSpeed(1.0);

  return controller;
}
