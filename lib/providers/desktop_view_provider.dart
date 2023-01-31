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

import 'package:bluecherry_client/models/device.dart';
import 'package:bluecherry_client/models/layout.dart';
import 'package:bluecherry_client/utils/constants.dart';
import 'package:bluecherry_client/utils/methods.dart';
import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:unity_video_player/unity_video_player.dart';

class DesktopViewProvider extends ChangeNotifier {
  /// `late` initialized [DesktopViewProvider] instance.
  static late final DesktopViewProvider instance;

  /// Initializes the [DesktopViewProvider] instance & fetches state from `async`
  /// `package:hive` method-calls. Called before [runApp].
  static Future<DesktopViewProvider> ensureInitialized() async {
    instance = DesktopViewProvider();
    await instance.initialize();
    return instance;
  }

  List<Layout> layouts = [
    const Layout(name: 'Default'),
  ];
  int _currentLayout = 0;
  int get currentLayoutIndex {
    if (_currentLayout.isNegative) return 0;

    return _currentLayout;
  }

  Layout get currentLayout => layouts[_currentLayout];

  /// Whether the layouts are rotating in a cycle
  bool cycling = false;

  /// Instances of video players corresponding to a particular [Device].
  ///
  /// This avoids redundantly creating new video player instance if a [Device]
  /// is already present in the camera grid on the screen or allows to use
  /// existing instance when switching tab (if common camera [Device] tile exists).
  ///
  final Map<Device, UnityVideoPlayer> players = {};

  /// Called by [ensureInitialized].
  Future<void> initialize() async {
    final hive = await Hive.openBox('hive');
    if (!hive.containsKey(kHiveDesktopLayouts)) {
      await _save();
    } else {
      await _restore();
      // Create video player instances for the device tiles already present in the view (restored from cache).
      for (final device in currentLayout.devices) {
        players[device] = getVideoPlayerControllerForDevice(device);
      }
    }
  }

  /// Saves current layout/order of [Device]s to cache using `package:hive`.
  /// Pass [notifyListeners] as `false` to prevent redundant redraws.
  Future<void> _save({bool notifyListeners = true}) async {
    final instance = await Hive.openBox('hive');

    await instance.put(
      kHiveDesktopLayouts,
      jsonEncode(layouts.map((layout) => layout.toMap()).toList()),
    );
    await instance.put(kHiveDesktopCurrentLayout, _currentLayout);
    await instance.put(kHiveDesktopCycling, cycling);

    if (notifyListeners) {
      this.notifyListeners();
    }
  }

  /// Restores current layout/order of [Device]s from `package:hive` cache.
  Future<void> _restore({bool notifyListeners = true}) async {
    final instance = await Hive.openBox('hive');

    layouts = ((await compute(
              jsonDecode,
              instance.get(kHiveDesktopLayouts) as String,
            ) ??
            []) as List)
        .cast<Map>()
        .map<Layout>((item) {
      return Layout.fromMap(item.cast<String, dynamic>());
    }).toList();
    _currentLayout = instance.get(kHiveDesktopCurrentLayout) ?? 0;

    cycling = instance.get(kHiveDesktopCycling) ?? false;

    if (notifyListeners) {
      this.notifyListeners();
    }
  }

  /// Adds a new camera [device]
  Future<void> add(Device device) {
    // Only create new video player instance, if no other camera tile in the
    // same tab is showing the same camera device.
    if (!currentLayout.devices.contains(device)) {
      // If it's a single view layout, ensure the player will be disposed
      // properly before adding one
      if (currentLayout.layoutType == DesktopLayoutType.singleView) {
        for (final device in currentLayout.devices) {
          if (!players.containsKey(device)) continue;
          players[device]!
            ..release()
            ..dispose();
        }
        currentLayout.devices.clear();
      }

      debugPrint(device.toString());
      debugPrint(device.streamURL);

      players[device] = getVideoPlayerControllerForDevice(device);
      currentLayout.devices.add(device);
    }
    notifyListeners();
    return _save(notifyListeners: false);
  }

  /// Removes a [Device] tile from the camera grid
  Future<void> remove(Device device) {
    // Only create new video player instance, if no other camera tile in the same tab is showing the same camera device.
    if (currentLayout.devices.contains(device)) {
      debugPrint(device.toString());
      debugPrint(device.streamURL);

      players[device]?.release();
      players[device]?.dispose();

      currentLayout.devices.remove(device);
    }
    notifyListeners();
    return _save(notifyListeners: false);
  }

  /// Moves a device tile from [initial] position to [end] position inside a [tab].
  /// Used for re-ordering camera [DeviceTile]s when dragging.
  Future<void> reorder(int initial, int end) {
    currentLayout.devices.insert(end, currentLayout.devices.removeAt(initial));
    // Prevent redundant latency.
    notifyListeners();
    return _save(notifyListeners: false);
  }

  /// Reloads a camera [Device] tile from the camera grid, at specified [tab] [index].
  /// e.g. in response to a network error etc.
  Future<void> reload(Device device) async {
    await players[device]?.reset();
    await players[device]?.setDataSource(
      device.streamURL,
    );
    await players[device]?.setVolume(0.0);
    await players[device]?.setSpeed(1.0);
    notifyListeners();
    return _save(notifyListeners: false);
  }

  /// Adds a new layout
  Future<void> addLayout(Layout layout) {
    if (!layouts.contains(layout)) {
      debugPrint(layout.toString());
      layouts.add(layout);
    }
    notifyListeners();
    return _save(notifyListeners: false);
  }

  /// Deletes [layout]
  Future<void> removeLayout(Layout layout) {
    assert(layouts.length > 1, 'There must be at least one layout');

    if (layouts.contains(layout)) {
      debugPrint(layout.toString());

      // if the selected layout is the last, remove one from the index
      // this can be done safely because we already check if there is at least
      // one layout in the list
      if (currentLayoutIndex == layouts.length - 1) _currentLayout -= 1;
      layouts.remove(layout);
    }
    notifyListeners();
    return _save(notifyListeners: false);
  }

  /// Replaces [oldLayout] with [newLayout]
  Future<void> updateLayout(Layout oldLayout, Layout newLayout) {
    if (layouts.contains(oldLayout)) {
      debugPrint(newLayout.toString());

      layouts.insert(layouts.indexOf(oldLayout), newLayout);

      debugPrint(oldLayout.toString());
      debugPrint(newLayout.toString());
    }

    notifyListeners();
    return _save(notifyListeners: false);
  }

  /// Updates the current layout index
  Future<void> updateCurrentLayout(int layoutIndex) {
    _currentLayout = layoutIndex;

    for (final device in currentLayout.devices) {
      if (!players.containsKey(device)) {
        players[device] = getVideoPlayerControllerForDevice(device);
      }
    }

    notifyListeners();
    return _save(notifyListeners: false);
  }

  /// Toggles cycling
  Future<void> toggleCycling() {
    cycling = !cycling;

    notifyListeners();
    return _save(notifyListeners: false);
  }
}
