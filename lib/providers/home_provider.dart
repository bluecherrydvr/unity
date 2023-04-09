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

import 'package:bluecherry_client/providers/server_provider.dart';
import 'package:bluecherry_client/providers/settings_provider.dart';
import 'package:bluecherry_client/utils/methods.dart';
import 'package:bluecherry_client/widgets/misc.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:status_bar_control/status_bar_control.dart';

enum UnityTab {
  deviceGrid,
  eventsPlayback,
  directCameraScreen,
  eventsScreen,
  addServer,
  downloads,
  settings,
}

enum UnityLoadingReason {
  /// Fetching the events in the [EventsPlayback] screen
  fetchingEventsPlayback,

  /// Fetching the periods in [EventsPlayback] screen.
  ///
  /// It is a heavy computational task, so it's useful to warn the user something
  /// is going on
  fetchingEventsPlaybackPeriods,

  /// Fetching the events in the [EventsScreen] screen
  fetchingEventsHistory,

  /// Downloading an event media
  downloadEvent,

  /// Whether a timeline event is loading
  timelineEventLoading,
}

class HomeProvider extends ChangeNotifier {
  static late HomeProvider _instance;

  HomeProvider() {
    _instance = this;
  }

  static HomeProvider get instance => _instance;

  int tab = ServersProvider.instance.serverAdded
      ? UnityTab.deviceGrid.index
      : UnityTab.addServer.index;

  List<UnityLoadingReason> loadReasons = [];

  Future<void> setTab(int tab, BuildContext context) async {
    if (tab.isNegative) return;
    this.tab = tab;

    if (tab != UnityTab.downloads.index) {
      initiallyExpandedDownloadEventId = null;
    }

    notifyListeners();
    refreshDeviceOrientation(context);
  }

  int? initiallyExpandedDownloadEventId;
  void toDownloads(int eventId, BuildContext context) {
    initiallyExpandedDownloadEventId = eventId;

    setTab(UnityTab.downloads.index, context);
  }

  static Future<void> setDefaultStatusBarStyle() async {
    if (isMobile) {
      // Restore the navigation bar & status bar styling.
      SystemChrome.setSystemUIOverlayStyle(
        const SystemUiOverlayStyle(
          systemNavigationBarColor: Colors.black,
          systemNavigationBarDividerColor: Colors.black,
          systemNavigationBarIconBrightness: Brightness.dark,
        ),
      );
      StatusBarControl.setStyle(
        getStatusBarStyleFromBrightness(
          SettingsProvider.instance.themeMode == ThemeMode.light
              ? Brightness.dark
              : Brightness.light,
        ),
      );
    }
  }

  Future<void> refreshDeviceOrientation(BuildContext context) async {
    if (isMobile) {
      final theme = Theme.of(context);
      final home = context.read<HomeProvider>();
      final tab = home.tab;

      /// On device grid or in eventsPlayback, use landscape
      if ([
        UnityTab.deviceGrid.index,
        UnityTab.eventsPlayback.index,
      ].contains(tab)) {
        await StatusBarControl.setHidden(true);
        await StatusBarControl.setStyle(
          getStatusBarStyleFromBrightness(theme.brightness),
        );
        DeviceOrientations.instance.set(
          [
            DeviceOrientation.landscapeLeft,
            DeviceOrientation.landscapeRight,
          ],
        );
      } else if ([UnityTab.addServer.index].contains(tab)) {
        // Use portrait orientation in "Add Server" tab.
        // See #14.
        await StatusBarControl.setHidden(false);
        await StatusBarControl.setStyle(
          // getStatusBarStyleFromBrightness(theme.brightness),
          StatusBarStyle.LIGHT_CONTENT,
        );
        DeviceOrientations.instance.set(
          [
            DeviceOrientation.portraitUp,
            DeviceOrientation.portraitDown,
          ],
        );
      } else {
        await StatusBarControl.setHidden(false);
        await StatusBarControl.setStyle(
          getStatusBarStyleFromBrightness(theme.brightness),
        );
        DeviceOrientations.instance.set(DeviceOrientation.values);
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
}
