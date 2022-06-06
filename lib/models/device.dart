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

import 'package:bluecherry_client/models/server.dart';

/// A [Device] present on a server.
class Device {
  /// Name of the device device.
  final String name;

  /// [Uri] to the RTSP stream associated with the device.
  final String uri;

  /// `true` [status] indicates that device device is working correctly or is `Online`.
  final bool status;

  /// Horizontal resolution of the device device.
  final int? resolutionX;

  /// Vertical resolution of the device device.
  final int? resolutionY;

  /// Reference to the [Server], to which this camera [Device] belongs.
  final Server server;

  const Device(
    this.name,
    this.uri,
    this.status,
    this.resolutionX,
    this.resolutionY,
    this.server,
  );

  String streamURL(Server server) =>
      'rtsp://${server.login}:${server.password}@${server.ip}:${server.rtspPort}/$uri';

  @override
  String toString() =>
      'Device($name, $uri, $status, $resolutionX, $resolutionY)';

  @override
  bool operator ==(dynamic other) {
    return other is Device &&
        name == other.name &&
        uri == other.uri &&
        resolutionX == other.resolutionX &&
        resolutionY == other.resolutionY;
  }

  @override
  int get hashCode =>
      name.hashCode ^
      uri.hashCode ^
      status.hashCode ^
      resolutionX.hashCode ^
      resolutionY.hashCode;

  Device copyWith({
    String? name,
    String? uri,
    bool? status,
    int? resolutionX,
    int? resolutionY,
    Server? server,
  }) =>
      Device(
        name ?? this.name,
        uri ?? this.uri,
        status ?? this.status,
        resolutionX ?? this.resolutionX,
        resolutionY ?? this.resolutionY,
        server ?? this.server,
      );

  Map<String, dynamic> toJson() => {
        'name': name,
        'uri': uri,
        'status': status,
        'resolutionX': resolutionX,
        'resolutionY': resolutionY,
        'server': server.toJson(),
      };

  factory Device.fromJson(Map<String, dynamic> json) => Device(
        json['name'],
        json['uri'],
        json['status'],
        json['resolutionX'],
        json['resolutionY'],
        Server.fromJson(json['server']),
      );
}
