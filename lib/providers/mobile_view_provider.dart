/*
 * This file is a part of Bluecherry Client (https://https://github.com/bluecherrydvr/bluecherry_client).
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

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:bluecherry_client/models/device.dart';
import 'package:bluecherry_client/utils/constants.dart';

/// This [Provider] saves/provides the current camera [Device] layout/order for the [DeviceGrid] on mobile.
class MobileViewProvider extends ChangeNotifier {
  /// `late` initialized [MobileViewProvider] instance.
  static late final MobileViewProvider instance;

  /// Initializes the [MobileViewProvider] instance & fetches state from `async`
  /// `package:shared_preferences` method-calls. Called before [runApp].
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
  /// }
  /// ```
  Map<int, List<Device?>> devices = {
    1: <Device?>[null],
    2: <Device?>[null, null],
    4: <Device?>[null, null, null, null],
  };

  /// Current [tab].
  /// 4 corresponds to 2x2, 2 corresponds to 2x1 & 1 corresponds to 1x1.
  int tab = 4;

  /// Layout for [current] [tab].
  List<Device?> get current => devices[tab]!;

  /// Called by [ensureInitialized].
  Future<void> initialize() async {
    final sharedPreferences = await SharedPreferences.getInstance();
    if (!sharedPreferences.containsKey(kSharedPreferencesMobileView)) {
      await _save();
    } else {
      await _restore();
    }
  }

  /// Edits a particular device tile in a particular [DeviceGrid] tab.
  Future<void> edit(
    int tab,
    int index,
    Device? device,
  ) {
    devices[tab]![index] = device;
    return _save();
  }

  /// Moves a device tile from [initial] position to [end] position inside a [tab].
  /// Used for re-ordering camera [DeviceTile]s when dragging.
  Future<void> move(int tab, int initial, int end) {
    devices[tab]!.insert(end, devices[tab]!.removeAt(initial));
    // Prevent redundant latency.
    notifyListeners();
    return _save(notifyListeners: false);
  }

  /// Removes a camera [Device] from the layout & updates cache.
  Future<void> remove(int tab, int index) {
    devices[tab]![index] = null;
    notifyListeners();
    return _save(notifyListeners: false);
  }

  /// Replaces the existing camera [Device] with [device] in the layout & updates cache.
  Future<void> replace(int tab, int index, Device? device) {
    devices[tab]![index] = device;
    notifyListeners();
    return _save(notifyListeners: false);
  }

  /// Sets [current] mobile view tab.
  Future<void> setTab(int value) async {
    tab = value;
    return _save();
  }

  /// Saves current layout/order of [Device]s to cache using `package:shared_preferences`.
  /// Pass [notifyListeners] as `false` to prevent redundant redraws.
  Future<void> _save({bool notifyListeners = true}) async {
    final instance = await SharedPreferences.getInstance();
    await instance.setString(
      kSharedPreferencesMobileView,
      jsonEncode(
        devices.map(
          (key, value) => MapEntry(
            key.toString(),
            value.map((e) => e?.toJson()).toList(),
          ),
        ),
      ),
    );
    await instance.setInt(
      kSharedPreferencesMobileViewTab,
      tab,
    );
    if (notifyListeners) {
      this.notifyListeners();
    }
  }

  /// Restores current layout/order of [Device]s from `package:shared_preferences` cache.
  Future<void> _restore() async {
    final instance = await SharedPreferences.getInstance();
    devices = jsonDecode(instance.getString(kSharedPreferencesMobileView)!)
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
    tab = instance.getInt(kSharedPreferencesMobileViewTab)!;
    notifyListeners();
  }

  @override
  // ignore: must_call_super
  void dispose() {}
}
