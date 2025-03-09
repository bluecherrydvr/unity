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

import 'package:bluecherry_client/main.dart';
import 'package:bluecherry_client/providers/layouts_provider.dart';
import 'package:bluecherry_client/providers/server_provider.dart';
import 'package:bluecherry_client/providers/settings_provider.dart';
import 'package:bluecherry_client/providers/update_provider.dart';
import 'package:bluecherry_client/utils/constants.dart';
import 'package:bluecherry_client/utils/methods.dart';
import 'package:bluecherry_client/utils/video_player.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:provider/provider.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

enum UnityTab {
  /// Initial app tab.
  ///
  /// On mobile, a grid of devices. On Desktop, options about layouts and devices.
  deviceGrid,

  /// Camera screen.
  ///
  /// Display a camera stream directly in fullscreen.
  directCameraScreen,

  /// Events History tab.
  ///
  /// Display the servers' events in a list.
  eventsHistory,

  /// Events Timeline tab.
  ///
  /// Display the events in a day timeline.
  eventsTimeline,

  /// Add server tab.
  addServer,

  /// Downloads tab.
  downloads,

  /// Settings tab.
  settings;

  String locale(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final layout = context.watch<LayoutsProvider>().currentLayout;

    var title = switch (this) {
      UnityTab.deviceGrid => loc.screens(layout.name),
      UnityTab.directCameraScreen => loc.directCamera,
      UnityTab.eventsHistory => loc.eventBrowser,
      UnityTab.eventsTimeline => loc.eventsTimeline,
      UnityTab.addServer => loc.addServer,
      UnityTab.downloads => loc.downloads,
      UnityTab.settings => loc.settings,
    };

    if (kIsWeb) {
      title = 'Bluecherry • $title';
    }
    return title;
  }
}

enum UnityLoadingReason {
  /// Fetching the events in the [EventsPlayback] screen
  fetchingEventsPlayback,

  /// Fetching the events in the [EventsScreen] screen
  fetchingEventsHistory,

  /// Downloading an event media
  downloadEvent;

  String locale(BuildContext context) {
    final loc = AppLocalizations.of(context);

    return switch (this) {
      UnityLoadingReason.downloadEvent => loc.taskDownloadingEvent,
      UnityLoadingReason.fetchingEventsHistory => loc.taskFetchingEvent,
      UnityLoadingReason.fetchingEventsPlayback =>
        loc.taskFetchingEventsPlayback,
    };
  }
}

class NavigatorData {
  /// The tab that this navigator data represents.
  final UnityTab tab;
  final IconData icon;
  final IconData selectedIcon;
  final String text;

  const NavigatorData({
    required this.tab,
    required this.icon,
    required this.selectedIcon,
    required this.text,
  });

  static List<NavigatorData> of(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final screenSize = MediaQuery.sizeOf(context);
    final layout = context.read<LayoutsProvider>().currentLayout;

    return [
      NavigatorData(
        tab: UnityTab.deviceGrid,
        icon: Icons.window_outlined,
        selectedIcon: Icons.window,
        text: loc.screens(layout.name),
      ),
      NavigatorData(
        tab: UnityTab.eventsTimeline,
        icon: Icons.subscriptions_outlined,
        selectedIcon: Icons.subscriptions,
        text: loc.eventsTimeline,
      ),
      if (screenSize.width <= kMobileBreakpoint.width ||
          Scaffold.hasDrawer(context))
        NavigatorData(
          tab: UnityTab.directCameraScreen,
          icon: Icons.videocam_outlined,
          selectedIcon: Icons.videocam,
          text: loc.directCamera,
        ),
      NavigatorData(
        tab: UnityTab.eventsHistory,
        icon: Icons.featured_play_list_outlined,
        selectedIcon: Icons.featured_play_list,
        text: loc.eventBrowser,
      ),
      NavigatorData(
        tab: UnityTab.addServer,
        icon: Icons.dns_outlined,
        selectedIcon: Icons.dns,
        text: loc.addServer,
      ),
      if (!kIsWeb)
        NavigatorData(
          tab: UnityTab.downloads,
          icon: Icons.download_outlined,
          selectedIcon: Icons.download,
          text: loc.downloads,
        ),
      NavigatorData(
        tab: UnityTab.settings,
        icon: Icons.settings_outlined,
        selectedIcon: Icons.settings,
        text: loc.settings,
      ),
    ];
  }
}

class HomeProvider extends ChangeNotifier {
  static final _instance = HomeProvider();
  static HomeProvider get instance => _instance;

  UnityTab tab =
      ServersProvider.instance.hasServers
          ? UnityTab.deviceGrid
          : UnityTab.addServer;

  List<UnityLoadingReason> loadReasons = [];

  /// Stores the volume of each device.
  ///
  /// These are filled when the user leaves the Devices tab and cleared when
  /// they come back.
  Map<String, double> volumes = {};

  Future<void> setTab(UnityTab tab, [BuildContext? context]) async {
    if (tab == this.tab) return;

    final currentTab = this.tab;
    final nextTab = tab;

    this.tab = tab;

    if (nextTab != UnityTab.downloads) initiallyExpandedDownloadEventId = null;

    if (nextTab != UnityTab.addServer) {
      automaticallyGoToAddServersScreen = false;
    }

    if (currentTab == UnityTab.deviceGrid) {
      // If we're moving out of the device grid tab, we should not be able to
      // hear the live feed anymore.

      final devices = LayoutsProvider.instance.allDevices;
      final players =
          UnityPlayers.players.entries
              .where(
                (entry) => devices.any((device) => device.uuid == entry.key),
              )
              .toList();

      for (final player in players) {
        volumes[player.key] = player.value.volume;
        player.value.setVolume(0.0);
      }
    } else if (nextTab == UnityTab.deviceGrid) {
      // When the user comes back to the device grid, we should restore the
      // volume of the devices.

      for (final entry in volumes.entries) {
        final player = UnityPlayers.players[entry.key];
        if (player != null) player.setVolume(entry.value);
      }

      volumes.clear();
    }

    if (context != null) {
      refreshDeviceOrientation(context);
      updateWakelock(context);
    }
    notifyListeners();
  }

  bool automaticallyGoToAddServersScreen = false;

  int? initiallyExpandedDownloadEventId;
  void toDownloads(int eventId, BuildContext context) {
    initiallyExpandedDownloadEventId = eventId;

    setTab(UnityTab.downloads, context);
  }

  static Future<void> setDefaultStatusBarStyle({bool? isLight}) async {
    if (isMobile) {
      isLight ??= () {
        final context = navigatorKey.currentContext;
        if (context == null) return false;

        return MediaQuery.platformBrightnessOf(context) == Brightness.light;
      }();
      // Restore the navigation bar & status bar styling.
      SystemChrome.setSystemUIOverlayStyle(
        isLight ? SystemUiOverlayStyle.dark : SystemUiOverlayStyle.light,
      );
    }
  }

  Future<void> refreshDeviceOrientation(BuildContext context) async {
    if (isMobile) {
      if (Navigator.of(context).canPop()) return;

      final home = context.read<HomeProvider>();
      final tab = home.tab;

      switch (tab) {
        case UnityTab.deviceGrid:
          setDefaultStatusBarStyle();
          DeviceOrientations.instance.set([
            DeviceOrientation.landscapeLeft,
            DeviceOrientation.landscapeRight,
          ]);
          break;
        default:
          setDefaultStatusBarStyle();
          // The empty list causes the application to defer to the operating system default.
          // [SystemChrome.setPreferredOrientations]
          DeviceOrientations.instance.set([]);
          break;
      }
    }
  }

  void updateWakelock(BuildContext context) {
    if (UpdateManager.isEmbedded) {
      // we can not access wakelock from the pi
      return;
    }
    final settings = context.read<SettingsProvider>();

    if (!settings.kWakelock.value) {
      WakelockPlus.disable();
    } else {
      switch (tab) {
        case UnityTab.deviceGrid:
        case UnityTab.eventsTimeline:
          WakelockPlus.enable();
          break;
        default:
          WakelockPlus.disable();
          break;
      }
    }
  }

  /// Whether something in the app is loading
  bool get isLoading => loadReasons.isNotEmpty;
  void loading(UnityLoadingReason reason, {bool notify = true}) {
    loadReasons.add(reason);

    if (notify) notifyListeners();
  }

  void notLoading(UnityLoadingReason reason, {bool notify = true}) {
    loadReasons.remove(reason);

    if (notify) notifyListeners();
  }

  bool isLoadingFor(UnityLoadingReason reason) => loadReasons.contains(reason);
}
