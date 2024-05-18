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

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:bluecherry_client/models/device.dart';
import 'package:bluecherry_client/models/layout.dart';
import 'package:bluecherry_client/providers/app_provider_interface.dart';
import 'package:bluecherry_client/utils/constants.dart';
import 'package:bluecherry_client/utils/storage.dart';
import 'package:bluecherry_client/utils/video_player.dart';
import 'package:flutter/foundation.dart';
import 'package:unity_video_player/unity_video_player.dart';

class DesktopViewProvider extends UnityProvider {
  DesktopViewProvider._();

  static late final DesktopViewProvider instance;
  static Future<DesktopViewProvider> ensureInitialized() async {
    instance = DesktopViewProvider._();
    await instance.initialize();
    debugPrint('DesktopViewProvider initialized');
    return instance;
  }

  // TODO(bdlukaa): to work better with multiple layouts, an unique list of
  // [Device]s must be created - and each [Layout] will contain only the id
  // of each device. This ensures that the [Device] state is properly updated
  // across all layouts.

  List<Layout> layouts = [
    Layout(name: 'Default', devices: List.empty(growable: true)),
  ];
  int _currentLayout = 0;
  int get currentLayoutIndex {
    if (_currentLayout.isNegative) return 0;
    return _currentLayout;
  }

  /// Gets the current selected layout
  Layout get currentLayout => layouts[currentLayoutIndex];

  @override
  Future<void> initialize() async {
    await tryReadStorage(
      () => initializeStorage(desktopView, kStorageDesktopLayouts),
    );
    Future.microtask(() async {
      await Future.wait(
        currentLayout.devices.map<Future>((device) {
          final completer = Completer<UnityVideoPlayer>();
          UnityPlayers.players[device.uuid] ??= UnityPlayers.forDevice(
            device,
            () async {
              if (Platform.isAndroid || Platform.isLinux || Platform.isMacOS) {
                await Future.delayed(const Duration(milliseconds: 350));
              }
              completer.complete(UnityPlayers.players[device.uuid]);
            },
          );
          return completer.future;
        }),
      );
    });
  }

  /// Saves current layout/order of [Device]s to cache using `package:hive`.
  /// Pass [notifyListeners] as `false` to prevent redundant redraws.
  @override
  Future<void> save({bool notifyListeners = true}) async {
    try {
      await desktopView.write({
        kStorageDesktopLayouts:
            jsonEncode(layouts.map((layout) => layout.toMap()).toList()),
        kStorageDesktopCurrentLayout: _currentLayout,
      });
    } catch (error, stackTrace) {
      debugPrint('Failed to save desktop view:\n $error\n$stackTrace');
    }

    super.save(notifyListeners: notifyListeners);
  }

  /// Restores current layout/order of [Device]s from `package:hive` cache.
  @override
  Future<void> restore({bool notifyListeners = true}) async {
    final data = await tryReadStorage(() => desktopView.read());

    layouts = ((await compute(
              jsonDecode,
              data[kStorageDesktopLayouts] as String,
            ) ??
            []) as List)
        .map<Layout>((item) {
      return Layout.fromMap((item as Map).cast<String, dynamic>());
    }).toList();
    _currentLayout = data[kStorageDesktopCurrentLayout] ?? 0;

    super.restore(notifyListeners: notifyListeners);
  }

  /// Adds [device] to the current layout
  Future<void> add(Device device, [Layout? layout]) async {
    assert(
      !currentLayout.devices.contains(device),
      'The device is already in the layout',
    );
    assert(device.status, 'The device must be online');

    layout ??= currentLayout;

    if (!layout.devices.contains(device)) {
      // If it's a single view layout, ensure the player will be disposed
      // properly before adding one
      if (layout.type == DesktopLayoutType.singleView) {
        var previousDevice = layout.devices.firstOrNull;
        if (previousDevice != null) {
          layout.devices.clear();
          await _releaseDevice(device);
        }
      }

      UnityPlayers.players[device.uuid] ??= UnityPlayers.forDevice(device);
      layout.devices.add(device);
      debugPrint('Added $device');

      notifyListeners();
      return save(notifyListeners: false);
    }
    return Future.value();
  }

  /// Releases a device if no layout is using it
  Future<void> _releaseDevice(Device device) async {
    if (!UnityPlayers.players.containsKey(device.uuid)) return;
    if (!layouts
        .any((layout) => layout.devices.any((d) => d.uuid == device.uuid))) {
      await UnityPlayers.releaseDevice(device.uuid);
    }
  }

  /// Removes a [Device] tile from the current layout
  Future<void> remove(Device device) {
    if (currentLayout.devices.contains(device)) {
      debugPrint('Removed $device');

      currentLayout.devices.remove(device);
      _releaseDevice(device);
    }
    notifyListeners();
    return save(notifyListeners: false);
  }

  /// Removes all the [devices] provided
  ///
  /// This is usually used when a server is deleted
  Future<void> removeDevices(Iterable<Device> devices) {
    for (final layout in layouts) {
      layout.devices.removeWhere(
        (d1) => devices.any((d2) => d1.uri == d2.uri),
      );
    }

    for (final device in devices) {
      _releaseDevice(device);
    }

    notifyListeners();
    return save(notifyListeners: false);
  }

  Future<void> removeDevicesFromCurrentLayout(Iterable<Device> devices) {
    currentLayout.devices.removeWhere(
      (d1) => devices.any((d2) => d1.uri == d2.uri),
    );

    for (final device in devices) {
      _releaseDevice(device);
    }

    notifyListeners();
    return save(notifyListeners: false);
  }

  /// Moves a device tile from [initial] position to [end] position inside a [tab].
  /// Used for re-ordering camera [DeviceTile]s when dragging.
  Future<void> reorder(int initial, int end) {
    if (initial == end) return Future.value();

    currentLayout.devices.insert(end, currentLayout.devices.removeAt(initial));
    // Prevent redundant latency.
    notifyListeners();
    return save(notifyListeners: false);
  }

  /// Adds a new layout
  Future<int> addLayout(Layout layout) async {
    if (!layouts.contains(layout)) {
      debugPrint('Added $layout');
      layouts.add(layout);
    } else {
      debugPrint('$layout already exists');
    }
    notifyListeners();
    await save(notifyListeners: false);

    return layouts.indexOf(layout);
  }

  /// Deletes [layout]
  Future<void> removeLayout(Layout layout) {
    assert(layouts.length > 1, 'There must be at least one layout left');

    if (layouts.contains(layout)) {
      debugPrint(layout.toString());

      // if the selected layout is the last, remove one from the index
      // this can be done safely because we already check if there is at least
      // one layout in the list
      if (currentLayoutIndex == layouts.length - 1) _currentLayout -= 1;
      layouts.remove(layout);

      for (final device in layout.devices) {
        _releaseDevice(device);
      }
    }
    notifyListeners();
    return save(notifyListeners: false);
  }

  /// Replaces [oldLayout] with [newLayout]
  Future<void> updateLayout(Layout oldLayout, Layout newLayout) {
    if (layouts.contains(oldLayout)) {
      final layoutIndex = layouts.indexOf(oldLayout);
      layouts
        ..removeAt(layoutIndex)
        ..insert(layoutIndex, newLayout);

      for (final device
          in oldLayout.devices.where((d) => !newLayout.devices.contains(d))) {
        _releaseDevice(device);
      }

      debugPrint('Replaced $oldLayout at $layoutIndex with $newLayout');
    } else {
      debugPrint('Layout $oldLayout not found');
    }

    notifyListeners();
    return save(notifyListeners: false);
  }

  /// Updates the current layout index
  Future<void> updateCurrentLayout(int layoutIndex) {
    _currentLayout = layoutIndex;

    for (final device in currentLayout.devices) {
      // creates the device that don't exist
      UnityPlayers.players[device.uuid] ??= UnityPlayers.forDevice(device);
    }

    notifyListeners();
    return save(notifyListeners: false);
  }

  /// Reorders the layouts
  Future<void> reorderLayout(int oldIndex, int newIndex) {
    if (oldIndex == newIndex) return Future.value();
    if (newIndex > layouts.length - 1) newIndex = layouts.length - 1;

    if (_currentLayout == oldIndex) {
      _currentLayout = newIndex;
    } else if (_currentLayout == newIndex) {
      _currentLayout = oldIndex;
    }

    layouts.insert(newIndex, layouts.removeAt(oldIndex));
    notifyListeners();
    return save(notifyListeners: false);
  }

  /// Updates a device in all the layouts.
  ///
  /// If [reload] is `true`, the device player will be reloaded.
  Future<void> updateDevice(
    Device previousDevice,
    Device device, {
    bool reload = false,
  }) {
    for (final layout in layouts) {
      final index = layout.devices.indexOf(previousDevice);
      if (!index.isNegative) {
        layout.devices[index] = device;
      }
    }

    if (previousDevice.matrixType != device.matrixType) {
      final player = UnityPlayers.players[device.uuid];
      player?.zoom.matrixType = device.matrixType ?? MatrixType.t16;
      player?.zoom.zoomAxis = (-1, -1);
    }

    if (reload) {
      UnityPlayers.reloadDevice(device);
    }

    notifyListeners();
    return save(notifyListeners: false);
  }
}
