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
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';

class EventsProvider extends ChangeNotifier {
  EventsProvider._();

  /// `late` initialized [EventsProvider] instance.
  static late final EventsProvider instance;

  /// Initializes the [EventsProvider] instance & fetches state from `async`
  /// `package:hive` method-calls. Called before [runApp].
  static Future<EventsProvider> ensureInitialized() async {
    instance = EventsProvider._();
    await instance.initialize();
    return instance;
  }

  /// Called by [ensureInitialized].
  Future<void> initialize() async {
    final hive = await Hive.openBox('hive');
    if (!hive.containsKey(kHiveEventsPlayback)) {
      await _save();
    } else {
      await _restore();
    }
  }

  /// The list of the device ids that are currently selected
  List<String> selectedIds = [];

  /// Saves current layout/order of [Device]s to cache using `package:hive`.
  /// Pass [notifyListeners] as `false` to prevent redundant redraws.
  Future<void> _save({bool notifyListeners = true}) async {
    final instance = await Hive.openBox('hive');

    await instance.put(
      kHiveEventsPlayback,
      jsonEncode(selectedIds),
    );

    if (notifyListeners) {
      this.notifyListeners();
    }
  }

  /// Restores current layout/order of [Device]s from `package:hive` cache.
  Future<void> _restore({bool notifyListeners = true}) async {
    final instance = await Hive.openBox('hive');

    selectedIds =
        (jsonDecode(instance.get(kHiveEventsPlayback)) as List).cast<String>();

    if (notifyListeners) {
      this.notifyListeners();
    }
  }

  static String idForDevice(Device device) {
    return '${device.server.ip}:${device.server.port}/${device.name}';
  }

  Future<void> clear() {
    selectedIds.clear();
    return _save();
  }

  bool contains(Device device) {
    return selectedIds.contains(idForDevice(device));
  }

  Future<void> add(Device device) {
    selectedIds.add(idForDevice(device));

    return _save();
  }

  Future<void> remove(Device device) {
    selectedIds.remove(idForDevice(device));

    return _save();
  }

  void onReorder(int a, int b) {
    final aItem = selectedIds[a];
    final bItem = selectedIds[b];

    selectedIds[a] = bItem;
    selectedIds[b] = aItem;

    _save();
  }
}
