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
import 'package:bluecherry_client/models/server.dart';
import 'package:bluecherry_client/providers/app_provider_interface.dart';
import 'package:bluecherry_client/utils/constants.dart';
import 'package:bluecherry_client/utils/storage.dart';
import 'package:bluecherry_client/utils/video_player.dart';
import 'package:flutter/foundation.dart';
import 'package:unity_video_player/unity_video_player.dart';

class LayoutsProvider extends UnityProvider {
  LayoutsProvider._();

  static LayoutsProvider? _instance;
  static LayoutsProvider get instance {
    _instance ??= LayoutsProvider._();
    return _instance!;
  }

  static Future<LayoutsProvider> ensureInitialized() async {
    await instance.initialize();
    debugPrint('LayoutsProvider initialized');
    return instance;
  }

  // TODO(bdlukaa): to work better with multiple layouts, an unique list of
  // [Device]s must be created - and each [Layout] will contain only the id
  // of each device. This ensures that the [Device] state is properly updated
  // across all layouts.
  List<Layout> layouts = [
    Layout(name: 'Default', devices: []),
  ];
  int _currentLayout = 0;
  int get currentLayoutIndex => _currentLayout.isNegative ? 0 : _currentLayout;

  Layout get currentLayout => layouts[currentLayoutIndex];

  final collapsedServers = <String>{};
  final lockedLayouts = <Layout>{};

  double? _layoutManagerHeight;
  double? get layoutManagerHeight => _layoutManagerHeight;
  set layoutManagerHeight(double? value) {
    _layoutManagerHeight = value;
    notifyListeners();
    save();
  }

  @override
  Future<void> initialize() async {
    await initializeStorage(kStorageDesktopLayouts);
    await Future.wait(
      currentLayout.devices.map<Future>((device) async {
        UnityPlayers.players[device.uuid] ??= UnityPlayers.forDevice(device);

        if (!kIsWeb &&
            (Platform.isAndroid || Platform.isLinux || Platform.isMacOS)) {
          await Future.delayed(const Duration(milliseconds: 350));
        }
      }),
    );
  }

  @override
  Future<void> save({bool notifyListeners = true}) async {
    await write({
      kStorageDesktopLayouts:
          jsonEncode(layouts.map((layout) => layout.toMap()).toList()),
      kStorageDesktopCurrentLayout: _currentLayout,
      kStorageDesktopCollapsedServers: jsonEncode(collapsedServers.toList()),
      kStorageDesktopLockedLayouts: jsonEncode(
        lockedLayouts.map((l) => l.name).toList(),
      ),
      kStorageDesktopLayoutManagerHeight: layoutManagerHeight,
    });
    super.save(notifyListeners: notifyListeners);
  }

  @override
  Future<void> restore({bool notifyListeners = true}) async {
    final layoutsData = await secureStorage.read(key: kStorageDesktopLayouts);
    if (layoutsData != null) {
      layouts = ((await compute(
                jsonDecode,
                layoutsData,
              ) ??
              []) as List)
          .map<Layout>((item) {
        return Layout.fromMap((item as Map).cast<String, dynamic>());
      }).toList();
    }

    _currentLayout =
        await secureStorage.readInt(key: kStorageDesktopCurrentLayout) ?? 0;

    final collapsedData =
        await secureStorage.read(key: kStorageDesktopCollapsedServers);
    if (collapsedData != null) {
      collapsedServers.addAll(
        ((await compute(jsonDecode, collapsedData) ?? []) as List)
            .cast<String>(),
      );
    }

    final lockedData =
        await secureStorage.read(key: kStorageDesktopLockedLayouts);
    if (lockedData != null) {
      final lockedLayoutsNames =
          ((await compute(jsonDecode, lockedData) ?? []) as List)
              .cast<String>();
      final lockedLayouts = layouts.where((layout) {
        return lockedLayoutsNames.contains(layout.name);
      });
      this.lockedLayouts.addAll(lockedLayouts);
    }
    layoutManagerHeight = await secureStorage.readDouble(
      key: kStorageDesktopLayoutManagerHeight,
    );
    super.restore(notifyListeners: notifyListeners);
  }

  Future<void> add(Device device, [Layout? layout]) async {
    assert(
      !currentLayout.devices.contains(device),
      'The device is already in the layout',
    );
    assert(device.status, 'The device must be online');

    layout ??= currentLayout;

    if (isLayoutLocked(layout)) return;
    if (!layout.devices.contains(device)) {
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
      await save();
    }
  }

  Future<void> _releaseDevice(Device device) async {
    if (!UnityPlayers.players.containsKey(device.uuid)) return;
    if (!layouts
        .any((layout) => layout.devices.any((d) => d.uuid == device.uuid))) {
      await UnityPlayers.releaseDevice(device.uuid);
    }
  }

  Future<void> remove(Device device) async {
    if (isLayoutLocked(currentLayout)) return;
    if (currentLayout.devices.contains(device)) {
      debugPrint('Removed $device');

      currentLayout.devices.remove(device);
      _releaseDevice(device);
    }
    notifyListeners();
    await save();
  }

  Iterable<Device> get allDevices => layouts.expand((layout) => layout.devices);

  Future<void> removeDevices(Iterable<Device> devices) async {
    if (devices.isEmpty) return;
    for (final layout in layouts) {
      if (isLayoutLocked(layout)) return;
      layout.devices.removeWhere(
        (d1) => devices.any((d2) => d1.uri == d2.uri),
      );
    }

    for (final device in devices) {
      _releaseDevice(device);
    }

    notifyListeners();
    await save();
  }

  Future<void> removeDevicesFromCurrentLayout(Iterable<Device> devices) async {
    if (devices.isEmpty) return;
    if (isLayoutLocked(currentLayout)) return;

    currentLayout.devices.removeWhere(
      (d1) => devices.any((d2) => d1.uri == d2.uri),
    );
    for (final device in devices) {
      _releaseDevice(device);
    }

    notifyListeners();
    await save();
  }

  Future<void> reorder(int initial, int end) async {
    if (initial == end) return;
    if (isLayoutLocked(currentLayout)) return;

    currentLayout.devices.insert(end, currentLayout.devices.removeAt(initial));
    notifyListeners();
    await save();
  }

  Future<int> addLayout(Layout layout) async {
    if (!layouts.contains(layout)) {
      debugPrint('Added $layout');
      layouts.add(layout);
    } else {
      debugPrint('$layout already exists');
    }
    notifyListeners();
    await save();
    return layouts.indexOf(layout);
  }

  Future<void> removeLayout(Layout layout) async {
    assert(layouts.length > 1, 'There must be at least one layout left');
    if (layouts.contains(layout)) {
      debugPrint(layout.toString());

      if (currentLayoutIndex == layouts.length - 1) _currentLayout -= 1;
      layouts.remove(layout);

      for (final device in layout.devices) {
        _releaseDevice(device);
      }
    }
    notifyListeners();
    await save();
  }

  Future<void> updateLayout(Layout oldLayout, Layout newLayout) async {
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
    await save();
  }

  Future<void> updateCurrentLayout(int layoutIndex) async {
    _currentLayout = layoutIndex;
    for (final device in currentLayout.devices) {
      UnityPlayers.players[device.uuid] ??= UnityPlayers.forDevice(device);
    }

    notifyListeners();
    await save();
  }

  Layout get nextLayout {
    final next = (_currentLayout + 1) % layouts.length;
    return layouts[next];
  }

  Future<void> switchToNextLayout() async {
    if (layouts.length > 1) {
      await updateCurrentLayout((_currentLayout + 1) % layouts.length);
    }
  }

  Future<void> reorderLayout(int oldIndex, int newIndex) async {
    if (oldIndex == newIndex) return;
    if (newIndex > layouts.length - 1) newIndex = layouts.length - 1;
    if (_currentLayout == oldIndex) {
      _currentLayout = newIndex;
    } else if (_currentLayout == newIndex) {
      _currentLayout = oldIndex;
    }

    layouts.insert(newIndex, layouts.removeAt(oldIndex));
    notifyListeners();
    await save();
  }

  Future<void> clearLayout({Layout? layout}) async {
    layout ??= currentLayout;
    await updateLayout(
      layout,
      layout.copyWith(devices: []),
    );
  }

  Device updateDevice(
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
    save();

    return device;
  }

  Future<void> collapseServer(Server server) async {
    if (!collapsedServers.contains(server.id)) {
      collapsedServers.add(server.id);
      notifyListeners();
      await save();
    }
  }

  Future<void> expandServer(Server server) async {
    if (collapsedServers.contains(server.id)) {
      collapsedServers.remove(server.id);
      notifyListeners();
      await save();
    }
  }

  bool isServerCollapsed(Server server) => collapsedServers.contains(server.id);

  Future<void> lockLayout(Layout layout) async {
    if (!lockedLayouts.contains(layout)) {
      lockedLayouts.add(layout);
      notifyListeners();
      await save();
    }
  }

  Future<void> unlockLayout(Layout layout) async {
    if (lockedLayouts.contains(layout)) {
      lockedLayouts.remove(layout);
      notifyListeners();
      await save();
    }
  }

  Future<void> toggleLayoutLock(Layout layout) async {
    if (isLayoutLocked(layout)) {
      await unlockLayout(layout);
    } else {
      await lockLayout(layout);
    }
  }

  bool isLayoutLocked(Layout layout) => lockedLayouts.contains(layout);
}
