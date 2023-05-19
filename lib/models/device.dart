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

import 'package:bluecherry_client/models/server.dart';

/// A [Device] present on a server.
class Device {
  /// Name of the device.
  final String name;

  /// [Uri] to the RTSP stream associated with the device.
  final int id;

  /// `true` [status] indicates that device device is working correctly or is `Online`.
  final bool status;

  /// Horizontal resolution of the device device.
  final int? resolutionX;

  /// Vertical resolution of the device device.
  final int? resolutionY;

  /// Whether this device has a PTZ protocol
  final bool hasPTZ;

  /// Reference to the [Server], to which this camera [Device] belongs.
  Server server;

  /// Creates a device.
  Device(
    this.name,
    this.id,
    this.status,
    this.resolutionX,
    this.resolutionY,
    this.server, {
    this.hasPTZ = false,
  });

  String get uri => 'live/$id';

  factory Device.fromServerJson(Map map, Server server) {
    return Device(
      map['device_name'],
      int.tryParse(map['id']) ?? 0,
      map['status'] == 'OK',
      map['resolutionX'] == null ? null : int.parse(map['resolutionX']),
      map['resolutionX'] == null ? null : int.parse(map['resolutionY']),
      server,
      hasPTZ: map['ptz_control_protocol'] != null,
    );
  }

  String get streamURL {
    // if (server.passedCertificates) {
    //   return hslURL;
    // } else {
    return rtspURL;
    // }
  }

  String get rtspURL {
    return ''
        'rtsp://'
        '${server.login}:${server.password}@${server.ip}:${server.rtspPort}'
        '/$uri';
  }

  String get mjpegURL {
    return 'https://${server.login}:${server.password}@${server.ip}:${server.port}/media/mjpeg.php?id=$id&multipart=true';
  }

  String get hslURL {
    return 'https://${server.login}:${server.password}@${server.ip}:${server.port}/hls/$id/index.m3u8';
  }

  /// Server name / Device name
  String get fullName {
    return '${server.name} / $name';
  }

  @override
  String toString() =>
      'Device($name, $uri, $status, $resolutionX, $resolutionY)';

  @override
  bool operator ==(dynamic other) {
    return other is Device &&
        name == other.name &&
        uri == other.uri &&
        resolutionX == other.resolutionX &&
        resolutionY == other.resolutionY &&
        hasPTZ == other.hasPTZ;
  }

  @override
  int get hashCode =>
      name.hashCode ^
      uri.hashCode ^
      status.hashCode ^
      resolutionX.hashCode ^
      resolutionY.hashCode ^
      hasPTZ.hashCode;

  Device copyWith({
    String? name,
    int? id,
    bool? status,
    int? resolutionX,
    int? resolutionY,
    Server? server,
    bool? hasPTZ,
  }) =>
      Device(
        name ?? this.name,
        id ?? this.id,
        status ?? this.status,
        resolutionX ?? this.resolutionX,
        resolutionY ?? this.resolutionY,
        server ?? this.server,
        hasPTZ: hasPTZ ?? this.hasPTZ,
      );

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'id': id,
      'status': status,
      'resolutionX': resolutionX,
      'resolutionY': resolutionY,
      'server': server.toJson(devices: false),
      'hasPTZ': hasPTZ,
    };
  }

  factory Device.fromJson(Map<String, dynamic> json) {
    return Device(
      json['name'],
      int.tryParse(json['id']?.toString() ??
              json['uri']?.toString().replaceAll('live/', '') ??
              '') ??
          0,
      json['status'],
      json['resolutionX'],
      json['resolutionY'],
      Server.fromJson(json['server'] as Map<String, dynamic>),
      hasPTZ: json['hasPTZ'] ?? false,
    );
  }
}
