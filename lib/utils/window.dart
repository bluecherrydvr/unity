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
import 'package:bluecherry_client/providers/update_provider.dart';
import 'package:bluecherry_client/utils/methods.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:launch_at_startup/launch_at_startup.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:provider/provider.dart';
// import 'package:tray_manager/tray_manager.dart';
import 'package:unity_multi_window/unity_multi_window.dart';
import 'package:window_manager/window_manager.dart';

/// The initial size of the window
const kInitialWindowSize = Size(1066, 645);

bool get canConfigureWindow {
  if (isDesktopPlatform) {
    if (Platform.isLinux &&
        UpdateManager.linuxEnvironment == LinuxPlatform.embedded) {
      return false;
    }
    return true;
  }
  return false;
}

/// Configures the current window
Future<void> configureWindow() async {
  if (canConfigureWindow) {
    final settings = SettingsProvider.instance;
    await WindowManager.instance.ensureInitialized();
    await windowManager.waitUntilReadyToShow(
      WindowOptions(
        minimumSize: kDebugMode ? Size(100, 100) : kInitialWindowSize,
        skipTaskbar: false,
        titleBarStyle: TitleBarStyle.hidden,
        windowButtonVisibility: true,
        fullScreen: settings.kFullscreen.value,
      ),
      () async {
        if (kDebugMode && !settings.kFullscreen.value) {
          await windowManager.setSize(kInitialWindowSize);
        }
        await windowManager.show();
      },
    );
  }
}

/// Configures the camera sub window
///
/// See also:
///
///  * [SingleCameraWindow]
Future<void> configureWindowTitle(String title) async {
  if (canConfigureWindow) {
    await WindowManager.instance.ensureInitialized();
    await windowManager.setTitle(title);
  }
}

enum MultiWindowType { device, layout }

bool get canOpenNewWindow {
  return isDesktopPlatform && !isEmbedded;
}

bool isSubWindow = false;
ResultWindow get subWindow {
  assert(isSubWindow);
  return ResultWindow(pid);
}

/// Perform a window close operation.
///
/// If the window is a sub window, it will be forcefully closed.
///
/// If the window is the main window, it will be minimized to the tray if the
/// setting is enabled, otherwise it will be closed.
Future<void> performWindowClose(BuildContext context) async {
  if (isSubWindow) {
    subWindow.close();
  } else {
    final settings = context.read<SettingsProvider>();
    if (settings.kMinimizeToTray.value) {
      return windowManager.hide();
    } else {
      return windowManager.close();
    }
  }
}

extension DeviceWindowExtension on Device {
  /// Opens this device in a new window
  Future<void> openInANewWindow() async {
    assert(
      isDesktopPlatform,
      'Can not open a new window in a non-desktop environment',
    );

    assert(!isEmbedded, 'Can not open a new window in an embedded environment');

    debugPrint('Opening a new window');
    final window = await MultiWindow.run([
      '${MultiWindowType.device.index}',
      '${SettingsProvider.instance.kThemeMode.value.index}',
      json.encode(toJson()),
    ]);

    debugPrint('Opened window with id ${window.windowId}');
  }
}

extension LayoutWindowExtension on Layout {
  static (MultiWindowType, ThemeMode, Map<String, dynamic>) fromArgs(
    List<String> args,
  ) {
    if (args.first == 'sub_window') {
      args = args.sublist(1);
    }
    final type = MultiWindowType.values[int.parse(args[0])];
    final themeMode = ThemeMode.values[int.parse(args[1])];
    final map = json.decode(args[2]);
    return (type, themeMode, map);
  }

  Future<void> openInANewWindow() async {
    assert(
      isDesktopPlatform,
      'Can not open a new window in a non-desktop environment',
    );

    assert(!isEmbedded, 'Can not open a new window in an embedded environment');

    debugPrint('Opening a new window');
    final window = await MultiWindow.run([
      '${MultiWindowType.layout.index}',
      '${SettingsProvider.instance.kThemeMode.value.index}',
      json.encode(toMap()),
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

/// It is only possible to launch at startup on Desktop Systems.
///
/// MacOS is still lacking configuration at this time, so we are not supporting
/// it for now.
bool get canLaunchAtStartup => isDesktopPlatform && !Platform.isMacOS;

Future<void> setupLaunchAtStartup() async {
  assert(isDesktopPlatform);
  final packageInfo = await PackageInfo.fromPlatform();

  launchAtStartup.setup(
    appName: packageInfo.appName,
    appPath: Platform.resolvedExecutable,
    // Set packageName parameter to support MSIX.
    // This is required to check if the app is running in MSIX container.
    // We do not support MSIX for now.
    // packageName: 'dev.leanflutter.examples.launchatstartupexample',
  );
}

// System tray is temporarily disabled due to issues with the `tray_manager`
// plugin. It will be re-enabled once the issues are resolved.
// bool get canUseSystemTray => isDesktopPlatform && !Platform.isLinux;
bool get canUseSystemTray => false;

Future<void> setupSystemTray() async {
  assert(canUseSystemTray);

  // await trayManager.destroy();
  // await trayManager.setIcon(
  //   Platform.isWindows ? 'assets/images/icon.ico' : 'assets/images/icon.png',
  // );
  // final menu = Menu(items: [
  //   MenuItem(key: 'screens', label: 'Layouts'),
  //   MenuItem(key: 'timeline_of_events', label: 'Timeline of Events'),
  //   MenuItem(key: 'events_browser', label: 'Events Browser'),
  //   MenuItem(key: 'downloads', label: 'Downloads'),
  //   MenuItem(key: 'settings', label: 'Settings'),
  //   MenuItem.separator(),
  //   MenuItem(key: 'quit', label: 'Quit bluecherry'),
  // ]);

  // await trayManager.setContextMenu(menu);
  // await trayManager.setTitle('Bluecherry');
  // await trayManager.setToolTip('Bluecherry Client');

  // trayManager.addListener(UnityTrayListener());
}

// class UnityTrayListener with TrayListener {
//   @override
//   void onTrayIconMouseDown() {
//     debugPrint('Tray icon mouse down');
//     windowManager.show();
//   }

//   @override
//   void onTrayIconRightMouseDown() {
//     debugPrint('Tray icon right mouse down');
//     // trayManager.popUpContextMenu();
//   }

//   @override
//   void onTrayIconRightMouseUp() {
//     debugPrint('Tray icon right mouse up');
//   }

//   @override
//   void onTrayMenuItemClick(MenuItem menuItem) {
//     switch (menuItem.key) {
//       case 'screens':
//         HomeProvider.instance.setTab(UnityTab.deviceGrid);
//         break;
//       case 'timeline_of_events':
//         HomeProvider.instance.setTab(UnityTab.eventsTimeline);
//         break;
//       case 'events_browser':
//         HomeProvider.instance.setTab(UnityTab.eventsHistory);
//         break;
//       case 'downloads':
//         HomeProvider.instance.setTab(UnityTab.downloads);
//         break;
//       case 'settings':
//         HomeProvider.instance.setTab(UnityTab.settings);
//         break;
//       case 'quit':
//         windowManager.close();
//         break;
//     }
//   }
// }
