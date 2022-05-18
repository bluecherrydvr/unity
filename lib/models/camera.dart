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

/// A [Camera] present on a server.
class Camera {
  /// Name of the camera device.
  final String name;

  /// [Uri] to the RTSP stream associated with the device.
  final String uri;

  const Camera(
    this.name,
    this.uri,
  );

  String streamURL(Server server) =>
      'rtsp://${server.username}:${server.password}@${server.ip}:${server.port}/$uri';

  @override
  String toString() => 'Camera($name, $uri)';

  @override
  bool operator ==(dynamic other) {
    return other is Camera && name == other.name && uri == other.uri;
  }

  @override
  int get hashCode => name.hashCode ^ uri.hashCode;
}
