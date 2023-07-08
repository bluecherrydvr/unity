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
import 'package:bluecherry_client/providers/settings_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:unity_video_player/unity_video_player.dart';

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

/// Helper method to create a video player with required configuration for a [Device].
UnityVideoPlayer getVideoPlayerControllerForDevice(Device device) {
  debugPrint(device.streamURL);
  final controller = UnityVideoPlayer.create(
    quality: SettingsProvider.instance.videoQuality,
    // width: device.resolutionX,
    // height: device.resolutionY,
  )
    ..setDataSource(device.streamURL)
    ..setVolume(0.0)
    ..setSpeed(1.0);

  return controller;
}

/// Wraps [child] in a [Tooltip] if the app meets [condition]
Widget wrapTooltipIf(
  bool condition, {
  required Widget child,
  required String message,
  bool? preferBelow,
}) {
  if (condition) {
    return Tooltip(
      message: message,
      preferBelow: preferBelow,
      child: child,
    );
  }

  return child;
}

/// Wraps [child] in an [Expanded] if the app meets [condition]
Widget wrapExpandedIf(
  bool condition, {
  required Widget child,
}) {
  if (condition) {
    return Expanded(child: child);
  }

  return child;
}

T? showIf<T extends Widget>(bool condition, {required T child}) {
  if (condition) return child;

  return null;
}

/// The current app version
///
/// To update it, update it in the windows installer
Future<String> get appVersion async {
  final installer = await rootBundle.loadString(
    'version.txt',
  );

  return installer
      .split('\n')
      .firstWhere((line) => line.startsWith('#define MyAppVersion'))
      .replaceAll('#define MyAppVersion', '')
      .replaceAll('"', '')
      .trim();
}
