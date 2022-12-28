import 'dart:convert';

import 'package:bluecherry_client/models/device.dart';
import 'package:bluecherry_client/providers/settings_provider.dart';
import 'package:bluecherry_client/widgets/misc.dart';

import 'package:unity_multi_window/unity_multi_window.dart';
import 'package:flutter/material.dart';
import 'package:window_manager/window_manager.dart';

const kInitialWindowSize = Size(900, 645);

/// Configures the current window
Future<void> configureWindow() async {
  await WindowManager.instance.ensureInitialized();
  windowManager.waitUntilReadyToShow().then((_) async {
    await windowManager.setTitleBarStyle(
      TitleBarStyle.hidden,
      windowButtonVisibility: false,
    );
    await windowManager.setSize(kInitialWindowSize);
    await windowManager.setMinimumSize(const Size(900, 600));
    await windowManager.center();
    await windowManager.setSkipTaskbar(false);
    await windowManager.show();
  });
}

/// Configures the current window
Future<void> configureCameraWindow() async {
  await WindowManager.instance.ensureInitialized();
  windowManager.waitUntilReadyToShow().then((_) async {
    await windowManager.setTitleBarStyle(
      TitleBarStyle.hidden,
      windowButtonVisibility: false,
    );
    await windowManager.setSize(const Size(900, 600));
    await windowManager.setMinimumSize(const Size(900, 600));
    await windowManager.center(animate: true);
    // await windowManager.maximize();
    await windowManager.setSkipTaskbar(false);
    await windowManager.show();
  });
}

extension DeviceWindowExtension on Device {
  /// Opens this device in a new window
  void openInANewWindow() async {
    assert(isDesktop, 'Can not open a new window in a non-desktop environment');

    debugPrint('Opening a new window');
    final window = await MultiWindow.run([
      json.encode(toJson()),
      '${SettingsProvider.instance.themeMode.index}',
    ]);

    debugPrint('Opened window with id ${window.windowId}');
  }
}
