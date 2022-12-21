import 'dart:convert';

import 'package:bluecherry_client/models/device.dart';
import 'package:bluecherry_client/utils/constants.dart';
import 'package:bluecherry_client/widgets/misc.dart';

import 'package:desktop_multi_window/desktop_multi_window.dart';
import 'package:flutter/services.dart';
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
    await windowManager.show();
    await windowManager.setSkipTaskbar(false);
  });
}

extension DeviceWindowExtension on Device {
  /// Opens this device in a new window
  void openInANewWindow() async {
    assert(isDesktop, 'Can not open a new window in a non-desktop environment');
    final window = await DesktopMultiWindow.createWindow(json.encode({
      'window_id': uuid.v4(),
      'device': toJson(),
    }));
    window
      ..setFrame(const Offset(0, 0) & kInitialWindowSize)
      ..center()
      ..setTitle(fullName)
      ..show();
  }
}
