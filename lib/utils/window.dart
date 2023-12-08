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

import 'dart:convert';
import 'dart:io';

import 'package:bluecherry_client/models/device.dart';
import 'package:bluecherry_client/models/layout.dart';
import 'package:bluecherry_client/providers/settings_provider.dart';
import 'package:bluecherry_client/utils/methods.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:unity_multi_window/unity_multi_window.dart';
import 'package:window_manager/window_manager.dart';

/// The initial size of the window
const kInitialWindowSize = Size(1066, 645);

/// Configures the current window
Future<void> configureWindow() async {
  await WindowManager.instance.ensureInitialized();
  windowManager.waitUntilReadyToShow(
    const WindowOptions(
      minimumSize: kDebugMode ? Size(100, 100) : kInitialWindowSize,
      skipTaskbar: false,
      titleBarStyle: TitleBarStyle.hidden,
      windowButtonVisibility: true,
    ),
    () async {
      await windowManager.show();
    },
  );
}

/// Configures the camera sub window
///
/// See also:
///
///  * [SingleCameraWindow]
Future<void> configureWindowTitle(String title) async {
  await WindowManager.instance.ensureInitialized();
  await windowManager.setTitle(title);
}

enum MultiWindowType { device, layout }

extension DeviceWindowExtension on Device {
  /// Opens this device in a new window
  Future<void> openInANewWindow() async {
    assert(
      isDesktopPlatform,
      'Can not open a new window in a non-desktop environment',
    );

    debugPrint('Opening a new window');
    final window = await MultiWindow.run([
      '${MultiWindowType.device.index}',
      json.encode(toJson()),
      '${SettingsProvider.instance.themeMode.index}',
    ]);

    debugPrint('Opened window with id ${window.windowId}');
  }
}

extension LayoutWindowExtension on Layout {
  Future<void> openInANewWindow() async {
    assert(
      isDesktopPlatform,
      'Can not open a new window in a non-desktop environment',
    );

    debugPrint('Opening a new window');
    final window = await MultiWindow.run([
      '${MultiWindowType.layout.index}',
      json.encode(toMap()),
      '${SettingsProvider.instance.themeMode.index}',
    ]);

    debugPrint('Opened window with id ${window.windowId}');
  }
}

/// Launches the file explorer at the given path
void launchFileExplorer(String path) {
  assert(isDesktopPlatform);

  if (Platform.isWindows) {
    Process.run('explorer', [path]);
  } else if (Platform.isLinux) {
    Process.run('xdg-open', [path]);
  } else if (Platform.isMacOS) {
    Process.run('open', [path]);
  } else {
    throw UnsupportedError(
      '${Platform.operatingSystem} is not a supported platform',
    );
  }
}
