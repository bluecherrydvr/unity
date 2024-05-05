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
import 'package:bluecherry_client/providers/server_provider.dart';
import 'package:bluecherry_client/providers/settings_provider.dart';
import 'package:bluecherry_client/providers/update_provider.dart';
import 'package:bluecherry_client/utils/methods.dart';
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

class HomeProvider extends ChangeNotifier {
  static final _instance = HomeProvider();
  static HomeProvider get instance => _instance;

  UnityTab tab = ServersProvider.instance.hasServers
      ? UnityTab.deviceGrid
      : UnityTab.addServer;

  List<UnityLoadingReason> loadReasons = [];

  Future<void> setTab(UnityTab tab, BuildContext context) async {
    if (tab == this.tab) return;

    this.tab = tab;

    if (tab != UnityTab.downloads) {
      initiallyExpandedDownloadEventId = null;
    }

    if (tab != UnityTab.addServer) {
      automaticallyGoToAddServersScreen = false;
    }

    refreshDeviceOrientation(context);
    updateWakelock(context);
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
