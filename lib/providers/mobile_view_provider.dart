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
import 'package:bluecherry_client/utils/constants.dart';
import 'package:bluecherry_client/utils/methods.dart';
import 'package:bluecherry_client/utils/storage.dart';
import 'package:flutter/foundation.dart';
import 'package:unity_video_player/unity_video_player.dart';

/// This class manages & saves (caching) the current camera [Device] layout/order for the [DeviceGrid] on mobile.
///
/// **The idea is to:**
///
/// - Have same video player instance (and multiple viewports) for a same device. See [players].
/// - Effectively manage the layout of the [DeviceGrid] on mobile. See [devices].
/// - Prevent redundant re-initialization of video players when switching tabs (if common a [Device] is present across tabs or same camera is added twice).
///
class MobileViewProvider extends ChangeNotifier {
  /// `late` initialized [MobileViewProvider] instance.
  static late final MobileViewProvider instance;

  /// Initializes the [MobileViewProvider] instance & fetches state from `async`
  /// `package:hive` method-calls. Called before [runApp].
  static Future<MobileViewProvider> ensureInitialized() async {
    instance = MobileViewProvider();
    await instance.initialize();
    return instance;
  }

  /// Keeps camera [Device]s order/layout to show inside the [MobileDeviceGrid] in the order user last saved them.
  ///
  /// ```dart
  /// {
  ///    1 : [Device(...)],
  ///    2 : [Device(...), Device(...)],
  ///    4 : [Device(...), Device(...), Device(...), Device(...)]
  ///    9 : [Device(...), Device(...), Device(...), Device(...), Device(...), Device(...), Device(...), Device(...), Device(...)]
  /// }
  /// ```
  Map<int, List<Device?>> devices = {
    1: <Device?>[null],
    2: <Device?>[null, null],
    4: <Device?>[null, null, null, null],
    9: <Device?>[null, null, null, null, null, null, null, null, null],
  };

  /// This map keeps the `bool`s to indicate whether the hover details of a [Device] is shown or not.
  /// The positioning corresponds to the [devices].
  /// This is important because camera [Device] tiles lose state upon reorder.
  Map<int, List<bool>> hoverStates = {
    1: <bool>[false],
    2: <bool>[false, false],
    4: <bool>[false, false, false, false],
    9: <bool>[false, false, false, false, false, false, false, false, false],
  };

  /// Instances of video players corresponding to a particular [Device].
  ///
  /// This avoids redundantly creating new video player instance if a [Device]
  /// is already present in the camera grid on the screen or allows to use
  /// existing instance when switching tab (if common camera [Device] tile exists).
  ///
  final Map<Device, UnityVideoPlayer> players = {};

  /// Current [tab].
  /// `4` corresponds to `2x2`, `2` corresponds to `2x1` & `1` corresponds to `1x1`.
  int tab = 1;

  /// Layout for [current] [tab].
  List<Device?> get current => devices[tab]!;

  /// Called by [ensureInitialized].
  Future<void> initialize() async {
    final data = await mobileView.read() as Map;
    if (!data.containsKey(kHiveMobileView)) {
      await _save();
    } else {
      await _restore();
      // Create video player instances for the device tiles already present in the view (restored from cache).
      for (final device in current) {
        if (device != null) {
          players[device] = getVideoPlayerControllerForDevice(device);
        }
      }
    }
  }

  /// Moves a device tile from [initial] position to [end] position inside a [tab].
  /// Used for re-ordering camera [DeviceTile]s when dragging.
  Future<void> reorder(int tab, int initial, int end) {
    devices[tab]!.insert(end, devices[tab]!.removeAt(initial));
    hoverStates[tab]!.insert(end, hoverStates[tab]!.removeAt(initial));
    // Prevent redundant latency.
    notifyListeners();
    return _save(notifyListeners: false);
  }

  /// Sets [current] mobile view tab.
  Future<void> setTab(int value) async {
    // Prevent redundant calls.
    if (value == tab) {
      return;
    }
    // [Device]s present in the new tab.
    final items = devices[value]!;
    // Find the non-common i.e. new device tiles in this tab & create a new video player for them.
    for (final device in items) {
      if (!players.keys.contains(device) && device != null) {
        players[device] = getVideoPlayerControllerForDevice(device);
      }
    }
    // Remove & dispose the video player instances that will not be used in this new tab.
    players.removeWhere((key, value) {
      final result = items.contains(key);
      if (!result) {
        value
          ..release()
          ..dispose();
      }
      return !result;
    });
    tab = value;
    notifyListeners();
    return _save(notifyListeners: false);
  }

  /// Removes a [Device] tile from the camera grid, at specified [tab] [index].
  Future<void> remove(int tab, int index) {
    final device = devices[tab]![index];
    var count = 0;
    for (final element in devices[tab]!) {
      if (element == device) count++;
    }
    debugPrint(devices[tab]!.toString());
    debugPrint(count.toString());
    // Only dispose if it was the only instance available.
    // If some other tile exists showing same camera device, then don't dispose the video player controller.
    if (count == 1) {
      players[device]?.release();
      players[device]?.dispose();
      players.remove(device);
    }
    // Remove.
    devices[tab]![index] = null;
    notifyListeners();
    return _save(notifyListeners: false);
  }

  /// Adds a new camera [device] tile in a [tab], at specified index.
  Future<void> add(int tab, int index, Device device) {
    // Only create new video player instance, if no other camera tile in the same tab is showing the same camera device.
    if (!devices[tab]!.contains(device)) {
      debugPrint(device.toString());
      debugPrint(device.streamURL);
      players[device] = getVideoPlayerControllerForDevice(device);
    }
    devices[tab]![index] = device;
    notifyListeners();
    return _save(notifyListeners: false);
  }

  /// Replaces a [Device] tile from the camera grid, at specified [tab] [index] with passed [device].
  Future<void> replace(int tab, int index, Device device) async {
    final current = devices[tab]![index];
    var count = 0;
    for (final element in devices[tab]!) {
      if (element == current) count++;
    }
    // Only dispose if it was the only instance available.
    // If some other tile exists showing same camera device, then don't dispose the video player controller.
    if (count == 1) {
      await players[current]?.release();
      players[current]?.dispose();
      players.remove(current);
    }
    if (!devices[tab]!.contains(device)) {
      debugPrint(device.toString());
      debugPrint(device.streamURL);
      players[device] = getVideoPlayerControllerForDevice(device);
    }
    // Save the new [device] at the position.
    devices[tab]![index] = device;
    notifyListeners();
    return _save(notifyListeners: false);
  }

  /// Reloads a camera [Device] tile from the camera grid, at specified [tab] [index].
  /// e.g. in response to a network error etc.
  Future<void> reload(int tab, int index) async {
    final device = devices[tab]![index]!;
    await players[device]?.reset();
    await players[device]?.setDataSource(device.streamURL);
    await players[device]?.setVolume(0.0);
    await players[device]?.setSpeed(1.0);
    notifyListeners();
    return _save(notifyListeners: false);
  }

  /// Saves current layout/order of [Device]s to cache using `package:hive`.
  /// Pass [notifyListeners] as `false` to prevent redundant redraws.
  Future<void> _save({bool notifyListeners = true}) async {
    final data = devices.map(
      (key, value) => MapEntry(
        key.toString(),
        value.map((e) => e?.toJson()).toList().cast<Map<String, dynamic>?>(),
      ),
    );
    debugPrint(data.toString());
    await mobileView.write({
      kHiveMobileView: jsonEncode(data),
      kHiveMobileViewTab: tab,
    });

    if (notifyListeners) {
      this.notifyListeners();
    }
  }

  /// Restores current layout/order of [Device]s from `package:hive` cache.
  Future<void> _restore({bool notifyListeners = true}) async {
    final data = await mobileView.read() as Map;
    devices =
        ((await compute(jsonDecode, data[kHiveMobileView] as String)) as Map)
            .map(
              (key, value) => MapEntry<int, List<Device?>>(
                int.parse(key),
                value
                    .map((e) => e == null ? null : Device.fromJson(e))
                    .toList()
                    .cast<Device?>(),
              ),
            )
            .cast<int, List<Device?>>();

    tab = data[kHiveMobileViewTab]!;
    if (notifyListeners) {
      this.notifyListeners();
    }
  }

  @override
  // ignore: must_call_super
  void dispose() {}
}
