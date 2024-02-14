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
import 'package:flutter/material.dart';

class EventsProvider extends UnityProvider {
  EventsProvider._();

  static late final EventsProvider instance;
  static Future<EventsProvider> ensureInitialized() async {
    instance = EventsProvider._();
    await instance.initialize();
    return instance;
  }

  @override
  Future<void> initialize() {
    return tryReadStorage(
        () => super.initializeStorage(eventsPlayback, kHiveEventsPlayback));
  }

  /// The list of the device ids that are currently selected
  List<String> selectedIds = [];

  /// Saves current layout/order of [Device]s to cache using `package:hive`.
  /// Pass [notifyListeners] as `false` to prevent redundant redraws.
  @override
  Future<void> save({bool notifyListeners = true}) async {
    try {
      await eventsPlayback.write({
        kHiveEventsPlayback: jsonEncode(selectedIds),
      });
    } catch (e) {
      debugPrint(e.toString());
    }

    super.save(notifyListeners: notifyListeners);
  }

  /// Restores current layout/order of [Device]s from `package:hive` cache.
  @override
  Future<void> restore({bool notifyListeners = true}) async {
    final data = await tryReadStorage(() => eventsPlayback.read());

    selectedIds =
        (jsonDecode(data[kHiveEventsPlayback]) as List).cast<String>();

    super.restore(notifyListeners: notifyListeners);
  }

  Future<void> clear() {
    selectedIds.clear();
    return save();
  }

  bool contains(Device device) {
    return selectedIds.contains(device.uuid);
  }

  Future<void> add(Device device) {
    selectedIds.add(device.uuid);

    return save();
  }

  Future<void> remove(Device device) {
    selectedIds.remove(device.uuid);

    return save();
  }

  void onReorder(int a, int b) {
    final aItem = selectedIds[a];
    final bItem = selectedIds[b];

    selectedIds[a] = bItem;
    selectedIds[b] = aItem;

    save();
  }
}
