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
// ignore: depend_on_referenced_packages
import 'package:collection/collection.dart';

/// Describes how the grid should behave in large screens
enum DesktopLayoutType {
  /// If selected, only a single camera can be selected per layout
  singleView,

  /// If selected, multiple cameras will be shown in the grid
  multipleView,

  /// If selected, only 4 views will be show in the grid. Each view can have 4
  /// cameras displayed, creating a soft and compact layout view
  compactView,
}

/// A layout is a view that can contain one or more [Device]s.
///
/// See also:
///
///  * [Device], which are displayed inside a Layout
///  * [DesktopLayoutType], which configures the type of the layout
class Layout {
  /// The name of the layout
  final String name;

  /// The devices present in this layout view
  final List<Device> devices;

  /// The type of layout
  final DesktopLayoutType layoutType;

  /// Creates a new layout with the given [name]
  const Layout({
    required this.name,
    this.devices = const [],
    this.layoutType = DesktopLayoutType.multipleView,
  });

  const Layout.raw({
    required this.name,
    required this.devices,
    required this.layoutType,
  });

  @override
  String toString() =>
      'Layout(name: $name, devices: $devices, layoutType: $layoutType)';

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    final listEquals = const DeepCollectionEquality().equals;

    return other is Layout &&
        other.name == name &&
        listEquals(other.devices, devices) &&
        other.layoutType == layoutType;
  }

  @override
  int get hashCode => name.hashCode ^ devices.hashCode ^ layoutType.hashCode;

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'devices': devices.map((x) => x.toJson()).toList(),
      'layoutType': layoutType.index,
    };
  }

  factory Layout.fromMap(Map<String, dynamic> map) {
    return Layout(
      name: map['name'] ?? '',
      devices: List<Device>.from((map['devices'] as List)
          .cast<Map<String, dynamic>>()
          .map(Device.fromJson)),
      layoutType: DesktopLayoutType.values[map['layoutType'] as int],
    );
  }

  String toJson() => json.encode(toMap());

  factory Layout.fromJson(String source) => Layout.fromMap(json.decode(source));

  Layout copyWith({
    String? name,
    List<Device>? devices,
    DesktopLayoutType? layoutType,
  }) {
    return Layout(
      name: name ?? this.name,
      devices: devices ?? this.devices,
      layoutType: layoutType ?? this.layoutType,
    );
  }
}
