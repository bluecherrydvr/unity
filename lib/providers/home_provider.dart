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
import 'package:bluecherry_client/utils/methods.dart';
import 'package:bluecherry_client/widgets/misc.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:status_bar_control/status_bar_control.dart';

enum UnityTab {
  deviceGrid,
  directCameraScreen,
  eventsScreen,
  addServer,
  downloads,
  settings,
}

class HomeProvider extends ChangeNotifier {
  int tab = ServersProvider.instance.serverAdded
      ? UnityTab.deviceGrid.index
      : UnityTab.addServer.index;

  Future<void> setTab(int tab, BuildContext context) async {
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

  Future<void> refreshDeviceOrientation(BuildContext context) async {
    if (isMobile) {
      final theme = Theme.of(context);
      final home = context.read<HomeProvider>();
      final tab = home.tab;

      if (tab == UnityTab.deviceGrid.index) {
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
      } else if (tab == UnityTab.addServer.index) {
        // Use portrait orientation in "Add Server" tab.
        // See #14.
        await StatusBarControl.setHidden(false);
        await StatusBarControl.setStyle(
          getStatusBarStyleFromBrightness(theme.brightness),
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
        DeviceOrientations.instance.set(
          DeviceOrientation.values,
        );
      }
    }
  }
}
