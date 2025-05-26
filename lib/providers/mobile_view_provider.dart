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
import 'package:bluecherry_client/providers/app_provider_interface.dart';
import 'package:bluecherry_client/utils/constants.dart';
import 'package:bluecherry_client/utils/storage.dart';
import 'package:bluecherry_client/utils/video_player.dart';
import 'package:flutter/foundation.dart';

class MobileViewProvider extends UnityProvider {
  MobileViewProvider._();

  static late final MobileViewProvider instance;
  static Future<MobileViewProvider> ensureInitialized() async {
    instance = MobileViewProvider._();
    await instance.initialize();
    debugPrint('MobileViewProvider initialized');
    return instance;
  }

  /// Keeps camera [Device]s order/layout to show inside the [SmallDeviceGrid] in the order user last saved them.
  ///
  /// ```dart
  /// {
  ///    1 : [Device(...)],
  ///    2 : [Device(...), Device(...)],
  ///    4 : [Device(...), Device(...), Device(...), Device(...)]
  ///    6 : [Device(...), Device(...), Device(...), Device(...), Device(...), Device(...), Device(...), Device(...), Device(...)]
  /// }
  /// ```
  Map<int, List<Device?>> devices = {
    1: List<Device?>.generate(1, (index) => null, growable: false),
    2: List<Device?>.generate(2, (index) => null, growable: false),
    4: List<Device?>.generate(4, (index) => null, growable: false),
    6: List<Device?>.generate(6, (index) => null, growable: false),
  };

  /// This map keeps the `bool`s to indicate whether the hover details of a [Device] is shown or not.
  /// The positioning corresponds to the [devices].
  /// This is important because camera [Device] tiles lose state upon reorder.
  Map<int, List<bool>> hoverStates = {
    1: List<bool>.generate(1, (index) => false, growable: false),
    2: List<bool>.generate(2, (index) => false, growable: false),
    4: List<bool>.generate(4, (index) => false, growable: false),
    6: List<bool>.generate(6, (index) => false, growable: false),
  };

  /// Current [tab].
  /// `4` corresponds to `2x2`, `2` corresponds to `2x1` & `1` corresponds to `1x1`.
  int tab = 1;

  /// Layout for [current] [tab].
  List<Device?> get current => devices[tab]!;

  @override
  Future<void> initialize() async {
    await initializeStorage(kStorageMobileView);
    UnityPlayers.initializeDevices(current.whereType<Device>().toList());
  }

  /// Moves a device tile from [initial] position to [end] position inside a [tab].
  /// Used for re-ordering camera [DeviceTile]s when dragging.
  Future<void> reorder(int tab, int initial, int end) {
    devices[tab]!.insert(end, devices[tab]!.removeAt(initial));
    hoverStates[tab]!.insert(end, hoverStates[tab]!.removeAt(initial));
    // Prevent redundant latency.
    notifyListeners();
    return save(notifyListeners: false);
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
    UnityPlayers.initializeDevices(items.whereType<Device>().toList());
    // Remove & dispose the video player instances that will not be used in this new tab.
    UnityPlayers.players.removeWhere((deviceUUID, player) {
      final result = items.contains(Device.fromUUID(deviceUUID));
      if (!result) {
        player.dispose();
      }
      return !result;
    });
    tab = value;
    notifyListeners();
    return save(notifyListeners: false);
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
      UnityPlayers.players[device?.uuid]?.dispose();
      UnityPlayers.players.remove(device?.uuid);
    }
    // Remove.
    devices[tab]![index] = null;
    notifyListeners();
    return save(notifyListeners: false);
  }

  /// Adds a new camera [device] tile in a [tab], at specified index.
  Future<void> add(int tab, int index, Device device) {
    // Only create new video player instance, if no other camera tile in the same tab is showing the same camera device.
    if (!devices[tab]!.contains(device)) {
      debugPrint('Added $device');
      UnityPlayers.players[device.uuid] ??= UnityPlayers.forDevice(device);
    }
    devices[tab]![index] = device;
    notifyListeners();
    return save(notifyListeners: false);
  }

  /// Replaces a [Device] tile from the camera grid, at specified [tab] [index] with passed [device].
  Future<void> replace(int tab, int index, Device device) async {
    final current = devices[tab]![index];
    final count = devices[tab]!.where((element) => element == current).length;
    // Only dispose if it was the only instance available.
    // If some other tile exists showing same camera device, then don't dispose the video player controller.
    if (count == 1) {
      UnityPlayers.players[current?.uuid]?.dispose();
      UnityPlayers.players.remove(current?.uuid);
    }
    if (!devices[tab]!.contains(device)) {
      debugPrint('Replaced $device');
      UnityPlayers.players[device.uuid] ??= UnityPlayers.forDevice(device);
    }
    // Save the new [device] at the position.
    devices[tab]![index] = device;
    notifyListeners();
    return save(notifyListeners: false);
  }

  /// Reloads a camera [Device] tile from the camera grid, at specified [tab] [index].
  /// e.g. in response to a network error etc.
  Future<void> reload(int tab, int index) async {
    final device = devices[tab]![index]!;
    await UnityPlayers.reloadDevice(device);
    notifyListeners();
  }

  Future<void> removeDevice(Device device) async {
    // Find the tab & index of the device to remove.
    final entries =
        devices.entries.where((e) => e.value.contains(device)).toList();
    if (entries.isEmpty) {
      debugPrint('Device not found in any tab.');
      return;
    }
    for (final entry in entries) {
      final tab = entry.key;
      final index = entry.value.indexOf(device);
      if (index != -1) {
        await remove(tab, index);
      }
    }
  }

  /// Saves current layout/order of [Device]s to cache using `package:hive`.
  /// Pass [notifyListeners] as `false` to prevent redundant redraws.
  @override
  Future<void> save({bool notifyListeners = true}) async {
    final data = devices.map<String, List<Map<String, dynamic>?>>(
      (key, value) => MapEntry(
        key.toString(),
        value.map<Map<String, dynamic>?>((e) => e?.toJson()).toList(),
      ),
    );

    await write({
      kStorageMobileView: jsonEncode(data),
      kStorageMobileViewTab: tab,
    });

    super.save(notifyListeners: notifyListeners);
  }

  /// Restores current layout/order of [Device]s from `package:hive` cache.
  @override
  Future<void> restore({bool notifyListeners = true}) async {
    final data = await secureStorage.read(key: kStorageMobileView);
    if (data != null) {
      devices =
          ((await compute(jsonDecode, data)) as Map)
              .map(
                (key, value) => MapEntry<int, List<Device?>>(
                  int.parse(key),
                  (value as Iterable)
                      .map<Device?>(
                        (e) => e == null ? null : Device.fromJson(e),
                      )
                      .toList(),
                ),
              )
              .cast<int, List<Device?>>();
    }

    // This is just for migration. Old clients do not have the "6" layout in their
    // devices, so we add it here
    if (!devices.containsKey(6)) {
      devices.addAll({
        6: [null, null, null, null, null, null],
      });
    }

    tab = await secureStorage.readInt(key: kStorageMobileViewTab) ?? 1;
    super.restore(notifyListeners: notifyListeners);
  }
}
