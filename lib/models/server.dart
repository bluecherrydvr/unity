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

import 'package:bluecherry_client/models/device.dart';

/// A [Server] added by a user.
///
class Server {
  final String ip;
  final int port;
  final int rtspPort;

  final String login;
  final String password;

  final List<Device> devices;

  final String? serverUUID;
  final String? cookie;

  const Server(
    this.ip,
    this.port,
    this.login,
    this.password,
    this.devices, {
    this.rtspPort = 7002,
    this.serverUUID,
    this.cookie,
  });

  @override
  String toString() => 'Server($ip, $port, $login, $password, $devices)';

  @override
  bool operator ==(dynamic other) {
    return other is Server &&
        ip == other.ip &&
        port == other.port &&
        login == other.login &&
        password == other.password &&
        rtspPort == other.rtspPort;
  }

  @override
  int get hashCode =>
      ip.hashCode ^
      port.hashCode ^
      login.hashCode ^
      password.hashCode ^
      rtspPort.hashCode;

  Server copyWith({
    String? ip,
    int? port,
    int? rtspPort,
    String? login,
    String? password,
    List<Device>? devices,
    String? serverUUID,
    String? cookie,
  }) {
    return Server(
      ip ?? this.ip,
      port ?? this.port,
      login ?? this.login,
      password ?? this.password,
      devices ?? this.devices,
      rtspPort: rtspPort ?? this.rtspPort,
      serverUUID: serverUUID ?? this.serverUUID,
      cookie: cookie ?? this.cookie,
    );
  }
}
