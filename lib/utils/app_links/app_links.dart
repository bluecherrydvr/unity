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

import 'package:args/args.dart';
import 'package:bluecherry_client/models/device.dart';
import 'package:bluecherry_client/models/layout.dart';
import 'package:bluecherry_client/providers/desktop_view_provider.dart';
import 'package:bluecherry_client/providers/server_provider.dart';
import 'package:bluecherry_client/providers/settings_provider.dart';
import 'package:bluecherry_client/utils/extensions.dart';
import 'package:flutter/material.dart';

export 'app_links_stub.dart' if (dart.library.ffi) 'app_links_real.dart';

Future<void> handleArgs(
  List<String> args, {
  required Future<void> Function() onSplashScreen,
  required void Function(Layout layout, ThemeMode theme) onLayoutScreen,
  required void Function(Device device, ThemeMode theme) onDeviceScreen,
  required VoidCallback onRunApp,
}) async {
  final settings = SettingsProvider.instance;

  var parser = ArgParser()
    ..addFlag(
      'fullscreen',
      abbr: 'f',
      help: 'Open the app in fullscreen mode',
      defaultsTo: settings.kFullscreen.value,
    )
    ..addFlag(
      'immersive',
      abbr: 'i',
      help:
          'Open the app in immersive mode. This is only applied if fullscreen '
          'mode is enabled',
      defaultsTo: settings.isImmersiveMode,
    )
    ..addFlag(
      'kiosk',
      abbr: 'k',
      help: 'Only allow users to access the Layouts View',
    )
    ..addFlag(
      'wakelock',
      abbr: 'w',
      help: 'Keep the screen on while the app is running. Already enabled when '
          'kiosk mode is active',
      defaultsTo: settings.kWakelock.value,
    )
    ..addFlag(
      'cycle',
      abbr: 'c',
      help: 'Cycle through the cameras in the layout',
      defaultsTo: settings.kLayoutCycleEnabled.value,
    )
    ..addOption(
      'layout',
      abbr: 'l',
      help: 'Open the app in a specific layout',
      valueHelp: 'layout name',
    )
    ..addOption(
      'layout-index',
      abbr: 'x',
      help: 'Open the app in a specific layout by index',
      valueHelp: '0',
    )
    ..addOption(
      'theme',
      allowed: ['light', 'dark', 'system'],
      help: 'Set the theme of the app',
      valueHelp: 'light',
      allowedHelp: {
        'light': 'Light theme',
        'dark': 'Dark theme',
        'system': 'Defaults to the system theme',
      },
      defaultsTo: settings.kThemeMode.value.name,
    )

    // Multi window
    ..addOption(
      'camera',
      help: 'Open the app the specified camera id. The server is mandatory',
    )
    ..addOption(
      'server',
      help: 'Open the app the specified server name. This must be a valid '
          'server name If camera is specified, this is mandatory.',
      valueHelp: 'Market',
    );

  final results = parser.parse(args);
  debugPrint('Opening app with ${results.arguments}');

  if (results.wasParsed('fullscreen')) {
    final isFullscreen = results.flag('fullscreen');
    settings.kFullscreen.value = isFullscreen;
  }
  if (results.wasParsed('immersive')) {
    final isImmersive = results.flag('immersive');
    settings.kImmersiveMode.value = isImmersive;
  }
  // if (results.wasParsed('kiosk')) {
  //   final isKiosk = results.flag('kiosk');
  // }
  if (results.wasParsed('wakelock')) {
    final isWakeLock = results.flag('wakelock');
    settings.kWakelock.value = isWakeLock;
  }
  if (results.wasParsed('cycle')) {
    final cycle = results.flag('cycle');
    settings.kLayoutCycleEnabled.value = cycle;
  }

  await onSplashScreen();

  final theme = () {
    final themeResult = results.option('theme');
    if (themeResult == null) return settings.kThemeMode.value;
    switch (themeResult) {
      case 'light':
        return ThemeMode.light;
      case 'dark':
        return ThemeMode.dark;
      case 'system':
        return ThemeMode.system;
    }
  }()!;

  final layout = results.option('layout');
  final layoutIndex = () {
    final layoutIndexResult = results.option('layout-index');
    if (layoutIndexResult == null) return null;
    return int.tryParse(layoutIndexResult);
  }();

  if (layout != null && layoutIndex != null) {
    throw ArgumentError('Only one of layout or layout-index can be provided');
  } else if (layoutIndex != null && layoutIndex < 0) {
    throw ArgumentError('layout-index must be a positive number');
  }

  if (layout != null) {
    await DesktopViewProvider.ensureInitialized();
    final view = DesktopViewProvider.instance;
    final layoutResult = view.layouts.firstWhereOrNull(
      (element) => element.name == layout,
    );
    if (layoutResult == null) {
      throw ArgumentError('Layout $layout not found');
    }
    return onLayoutScreen(layoutResult, theme);
  }

  final camera = results.option('camera');
  final server = results.option('server');

  if (camera != null && server == null) {
    throw ArgumentError('Server is mandatory when camera is provided');
  } else if (camera == null && server != null) {
    throw ArgumentError('Camera is mandatory when server is provided');
  }

  if (camera != null && server != null) {
    final serverResult = ServersProvider.instance.servers.firstWhereOrNull((s) {
      return s.name == server;
    });
    if (serverResult == null) {
      throw ArgumentError('Server $server not found');
    } else {
      final deviceResult = serverResult.devices.firstWhereOrNull((d) {
        return d.id.toString() == camera;
      });
      if (deviceResult == null) {
        throw ArgumentError('Camera $camera not found');
      }
      return onDeviceScreen(deviceResult, theme);
    }
  }

  return onRunApp();
}
