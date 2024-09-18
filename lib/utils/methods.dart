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
import 'package:bluecherry_client/main.dart' show navigatorKey;
import 'package:bluecherry_client/providers/update_provider.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// A helper singleton to set preferred orientation for the app.
class DeviceOrientations {
  /// [DeviceOrientations] singleton instance.
  static final DeviceOrientations instance = DeviceOrientations._();

  /// Private constructor.
  DeviceOrientations._();

  /// Maintain a stack of the last set of orientations, to switch back to the
  /// most recent one.
  final List<List<DeviceOrientation>> _stack = [];

  Future<void> set(List<DeviceOrientation> orientations) {
    _stack.add(orientations);
    debugPrint(orientations.toString());
    return SystemChrome.setPreferredOrientations(orientations);
  }

  Future<void> restoreLast() async {
    _stack.removeLast();
    debugPrint(_stack.toString());
    await SystemChrome.setPreferredOrientations(_stack.last);
  }
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

/// Wraps [child] in an [Expanded] if [condition] is true.
Widget wrapExpandedIf(
  bool condition, {
  required Widget child,
}) {
  if (condition) {
    return Expanded(child: child);
  }

  return child;
}

/// Returns true if the app is running on a desktop platform. This is useful
/// for determining whether to show desktop-specific UI elements.
///
/// This does not check if the runtime is native or web. Use [isDesktopPlatform]
/// for that instead.
bool get isDesktop {
  return [
    TargetPlatform.windows,
    TargetPlatform.linux,
    TargetPlatform.macOS,
  ].contains(defaultTargetPlatform);
}

/// Returns true if the app is running on a desktop platform. This is useful
/// to execute code that should only run on desktop platforms.
bool get isDesktopPlatform {
  if (kIsWeb) return false;
  return Platform.isWindows || Platform.isMacOS || Platform.isLinux;
}

/// Returns true if the app is running on a mobile platform. This is useful
/// for determining whether to show mobile-specific UI elements.
///
/// This does not check if the runtime is native or web. Use [isMobilePlatform]
/// for that instead.
bool get isMobile {
  return [
    TargetPlatform.android,
    TargetPlatform.iOS,
    TargetPlatform.fuchsia,
  ].contains(defaultTargetPlatform);
}

/// Returns true if the app is running on a mobile platform. This is useful
/// to execute code that should only run on mobile platforms.
bool get isMobilePlatform {
  if (kIsWeb) return false;
  return Platform.isAndroid || Platform.isIOS;
}

/// Whether the current platform is iOS or macOS.
bool get isCupertino {
  final cupertinoPlatforms = [TargetPlatform.iOS, TargetPlatform.macOS];
  final navigatorContext = navigatorKey.currentContext;
  if (navigatorContext != null) {
    final theme = Theme.of(navigatorContext);
    return cupertinoPlatforms.contains(theme.platform);
  }

  return cupertinoPlatforms.contains(defaultTargetPlatform);
}

bool get isEmbedded {
  if (kIsWeb) return false;

  if (Platform.isLinux) {
    return UpdateManager.linuxEnvironment == LinuxPlatform.embedded;
  }
  return false;
}

/// Determines the amount of events that can be loaded at once.
///
/// The calculation is based on the current connectivity status. If the device
/// is connected to a WiFi network, then it returns 400, otherwise it returns
/// 200.
Future<int> get eventsLimit async {
  final connectivityResult = UpdateManager.isEmbedded
      ? ConnectivityResult.wifi
      : await Connectivity().checkConnectivity();

  switch (connectivityResult) {
    case ConnectivityResult.wifi:
    case ConnectivityResult.ethernet:
    case ConnectivityResult.vpn:
      return 400;
    default:
      return 200;
  }
}
