import 'dart:convert';

import 'package:bluecherry_client/models/device.dart';
import 'package:collection/collection.dart';

/// Describes how the grid should behave in large screens
enum DesktopLayoutType {
  /// If selected, only a single camera can be selected per time
  singleView,

  /// If selected, multiple camers will be shown in the grid
  multipleView,

  /// If selected, only 4 cameras will be show in the grid
  compactView,
}

class Layout {
  final String name;
  final List<Device> devices;
  final DesktopLayoutType layoutType;

  const Layout.raw({
    required this.name,
    required this.devices,
    required this.layoutType,
  });

  const Layout({
    required this.name,
    this.devices = const [],
    this.layoutType = DesktopLayoutType.multipleView,
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
      devices:
          List<Device>.from(map['devices']?.map((x) => Device.fromJson(x))),
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
