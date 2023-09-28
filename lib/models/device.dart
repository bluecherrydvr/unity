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
import 'package:flutter/foundation.dart';

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

  Device.dump({
    this.name = 'device',
    this.id = 0,
    this.status = true,
    this.resolutionX = 640,
    this.resolutionY = 480,
    this.hasPTZ = false,
  }) : server = Server.dump();

  String get uri => 'live/$id';

  factory Device.fromServerJson(Map map, Server server) {
    return Device(
      map['device_name'],
      int.tryParse(map['id']) ?? 0,
      map['status'] == 'OK',
      int.tryParse(map['resolutionX']),
      int.tryParse(map['resolutionY']),
      server,
      hasPTZ: map['ptz_control_protocol'] != null,
    );
  }

  /// Returns the stream URL for this device.
  ///
  /// If the app is running on the web, then HLS is used, otherwise RTSP is used.
  String get streamURL {
    if (kIsWeb) {
      return hslURL;
    } else {
      return rtspURL;
    }
  }

  String get rtspURL {
    return Uri(
      scheme: 'rtsp',
      userInfo: '${Uri.encodeComponent(server.login)}'
          ':'
          '${Uri.encodeComponent(server.password)}',
      host: server.ip,
      port: server.rtspPort,
      path: uri,
    ).toString();
  }

  String get mjpegURL {
    return Uri(
      scheme: 'https',
      userInfo: '${Uri.encodeComponent(server.login)}'
          ':'
          '${Uri.encodeComponent(server.password)}',
      host: server.ip,
      port: server.rtspPort,
      path: 'media/mjpeg.php',
      query: 'id=$id&multipart=true',
    ).toString();
  }

  String get hslURL {
    return Uri(
      scheme: 'https',
      userInfo: '${Uri.encodeComponent(server.login)}'
          ':'
          '${Uri.encodeComponent(server.password)}',
      host: server.ip,
      port: server.port,
      path: 'hls/$id/index.m3u8',
    ).toString();
  }

  /// Returns the full name of this device, including the server name.
  ///
  /// Example: `device (server)`
  String get fullName {
    return '$name (${server.name})';
  }

  @override
  String toString() =>
      'Device($name, $uri, online: $status, ${resolutionX}x$resolutionY, ptz: $hasPTZ)';

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
