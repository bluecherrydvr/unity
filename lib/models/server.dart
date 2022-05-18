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

import 'package:bluecherry_client/models/camera.dart';

/// A [Server] added by a user.
///
class Server {
  final String ip;
  final int port;

  final String username;
  final String password;

  final List<Camera> cameras;

  const Server(
    this.ip,
    this.port,
    this.username,
    this.password,
    this.cameras,
  );

  @override
  String toString() => 'Server($ip, $port, $username, $password, $cameras)';

  @override
  bool operator ==(dynamic other) {
    return other is Server &&
        ip == other.ip &&
        port == other.port &&
        username == other.username &&
        password == other.password;
  }

  @override
  int get hashCode =>
      ip.hashCode ^ port.hashCode ^ username.hashCode ^ password.hashCode;
}
