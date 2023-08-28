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
import 'dart:io';

import 'package:bluecherry_client/models/device.dart';
import 'package:bluecherry_client/models/server.dart';
import 'package:bluecherry_client/utils/methods.dart';
import 'package:collection/collection.dart';
import 'package:file_picker/file_picker.dart';
import 'package:xml/xml.dart';

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
  final DesktopLayoutType type;

  /// Creates a new layout with the given [name]
  const Layout({
    required this.name,
    this.devices = const [],
    this.type = DesktopLayoutType.multipleView,
  });

  const Layout.raw({
    required this.name,
    required this.devices,
    required this.type,
  });

  @override
  String toString() => 'Layout(name: $name, devices: $devices, type: $type)';

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    final listEquals = const DeepCollectionEquality().equals;

    return other is Layout &&
        other.name == name &&
        listEquals(other.devices, devices) &&
        other.type == type;
  }

  @override
  int get hashCode => name.hashCode ^ devices.hashCode ^ type.hashCode;

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'devices': devices.map((x) => x.toJson()).toList(),
      'layoutType': type.index,
    };
  }

  factory Layout.fromMap(Map<String, dynamic> map) {
    return Layout(
      name: map['name'] ?? '',
      devices: List<Device>.from((map['devices'] as List)
          .cast<Map<String, dynamic>>()
          .map(Device.fromJson)),
      type: DesktopLayoutType.values[map['layoutType'] as int],
    );
  }

  String toJson() => json.encode(toMap());

  factory Layout.fromJson(String source) => Layout.fromMap(json.decode(source));

  Layout copyWith({
    String? name,
    List<Device>? devices,
    DesktopLayoutType? type,
  }) {
    return Layout(
      name: name ?? this.name,
      devices: devices ?? this.devices,
      type: type ?? this.type,
    );
  }

  /// Exports the layout to an XML file
  String toXml() {
    final builder = XmlBuilder()..processing('xml', 'version="1.0"');
    builder.element('layout', nest: () {
      builder
        ..element('name', nest: () => builder.text(name))
        ..element('type', nest: () => builder.text(type.name))
        ..element('devices', nest: () {
          for (final device in devices) {
            builder.element('device', nest: () {
              builder
                ..element('id', nest: () => builder.text(device.id))
                ..element('name', nest: () => builder.text(device.name))
                ..element('server', nest: () => builder.text(device.server.ip))
                ..element(
                  'server_port',
                  nest: () => builder.text(device.server.port),
                );
            });
          }
        });
    });
    final document = builder.buildDocument();
    return document.toXmlString(pretty: true);
  }

  /// Saves the layout to a file, which can be imported later
  Future<void> export({required String dialogTitle}) async {
    if (isDesktopPlatform) {
      final outputFile = await FilePicker.platform.saveFile(
        allowedExtensions: ['xml'],
        type: FileType.custom,
        lockParentWindow: true,
        dialogTitle: dialogTitle,
        fileName: 'Layout-${name.replaceAll(' ', '_')}.xml',
      );
      if (outputFile != null) {
        final file = File(outputFile);
        if (!await file.exists()) await file.create();
        await file.writeAsString(toXml());
      }
    }
  }

  static Layout fromXML(String xml, {required String fallbackName}) {
    final document = XmlDocument.parse(xml);
    final layout = document.getElement('layout');
    if (layout == null) throw ArgumentError('Invalid layout file');
    final name = layout.getElement('name')?.innerText ?? fallbackName;
    final type = layout.getElement('type')?.innerText;
    final devices = () sync* {
      for (final deviceElement
          in layout.getElement('devices')!.findElements('device')) {
        final id = deviceElement.getElement('id')?.innerText;
        if (id == null) {
          throw ArgumentError('Invalid layout file: device id not found');
        } else if (int.tryParse(id) == null) {
          throw ArgumentError('Invalid layout file: device id not valid');
        }
        final name = deviceElement.getElement('name')?.innerText;
        final server = deviceElement.getElement('server')?.innerText;
        final serverPort = deviceElement.getElement('server_port')?.innerText;
        if (server == null) {
          throw ArgumentError('Invalid layout file: device server not found');
        }
        if (serverPort == null) {
          throw ArgumentError('Invalid layout file: server port not found');
        } else if (int.tryParse(serverPort) == null) {
          throw ArgumentError('Invalid layout file: server port not valid');
        }

        yield Device(
          name ?? '',
          int.parse(id),
          true,
          640,
          480,
          Server(
            server,
            server,
            int.parse(serverPort),
            '',
            '',
            [],
          ),
        );
      }
    }();

    return Layout(
      name: name,
      type: DesktopLayoutType.values.firstWhereOrNull((t) => t.name == type) ??
          DesktopLayoutType.singleView,
      devices: devices.toList(),
    );
  }
}
