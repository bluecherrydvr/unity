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
import 'package:bluecherry_client/providers/mobile_view_provider.dart'
    show getVideoPlayerControllerForDevice;
import 'package:bluecherry_client/utils/constants.dart';
import 'package:bluecherry_client/widgets/video_player.dart';
import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';

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

  List<Device> devices = [];

  /// Instances of video players corresponding to a particular [Device].
  ///
  /// This avoids redundantly creating new video player instance if a [Device]
  /// is already present in the camera grid on the screen or allows to use
  /// existing instance when switching tab (if common camera [Device] tile exists).
  ///
  final Map<Device, BluecherryVideoPlayerController> players = {};

  /// Called by [ensureInitialized].
  Future<void> initialize() async {
    final hive = await Hive.openBox('hive');
    if (!hive.containsKey(kHiveDesktopView)) {
      await _save();
    } else {
      await _restore();
      // Create video player instances for the device tiles already present in the view (restored from cache).
      for (final device in devices) {
        players[device] = getVideoPlayerControllerForDevice(device);
      }
    }
  }

  /// Saves current layout/order of [Device]s to cache using `package:hive`.
  /// Pass [notifyListeners] as `false` to prevent redundant redraws.
  Future<void> _save({bool notifyListeners = true}) async {
    final instance = await Hive.openBox('hive');
    final data = devices.map((device) {
      return {device.uri: device.toJson()};
    }).toList();

    debugPrint(data.toString());
    await instance.put(
      kHiveDesktopView,
      jsonEncode(data),
    );
    if (notifyListeners) {
      this.notifyListeners();
    }
  }

  /// Restores current layout/order of [Device]s from `package:hive` cache.
  Future<void> _restore({bool notifyListeners = true}) async {
    final instance = await Hive.openBox('hive');
    devices = (jsonDecode(instance.get(kHiveDesktopView)!) as List)
        .cast<Map>()
        .map<Device>((item) {
      final realItem = item.entries.first;

      return Device.fromJson((realItem.value as Map).cast<String, dynamic>());
    }).toList();
    if (notifyListeners) {
      this.notifyListeners();
    }
  }

  /// Adds a new camera [device]
  Future<void> add(Device device) {
    // Only create new video player instance, if no other camera tile in the same tab is showing the same camera device.
    if (!devices.contains(device)) {
      debugPrint(device.toString());
      debugPrint(device.streamURL);
      players[device] = getVideoPlayerControllerForDevice(device);
      devices.add(device);
    }
    notifyListeners();
    return _save(notifyListeners: false);
  }

  /// Removes a [Device] tile from the camera grid
  Future<void> remove(Device device) {
    // Only create new video player instance, if no other camera tile in the same tab is showing the same camera device.
    if (devices.contains(device)) {
      debugPrint(device.toString());
      debugPrint(device.streamURL);

      players[device]?.release();
      players[device]?.dispose();

      devices.remove(device);
    }
    notifyListeners();
    return _save(notifyListeners: false);
  }

  /// Moves a device tile from [initial] position to [end] position inside a [tab].
  /// Used for re-ordering camera [DeviceTile]s when dragging.
  Future<void> reorder(int initial, int end) {
    devices.insert(end, devices.removeAt(initial));
    // Prevent redundant latency.
    notifyListeners();
    return _save(notifyListeners: false);
  }
}
