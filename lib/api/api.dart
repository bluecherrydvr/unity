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

import 'dart:convert';
import 'package:bluecherry_client/models/device.dart';
import 'package:http/http.dart';
import 'package:xml2json/xml2json.dart';

import 'package:bluecherry_client/models/server.dart';

abstract class API {
  /// Checks details of a [server] entered by the user.
  /// If the attributes present in [Server] are correct, then the
  /// returned object will have [Server.serverUUID] & [Server.cookie]
  /// present in it.
  static Future<Server> checkServerCredentials(Server server) async {
    try {
      final uri =
          Uri.https('${server.ip}:${server.port}', '/ajax/loginapp.php');
      final request = MultipartRequest('POST', uri)
        ..fields.addAll({
          'login': server.login,
          'password': server.password,
        });
      final response = await request.send();
      final body = await response.stream.bytesToString();
      print(body);
      print(response.headers);
      final json = jsonDecode(body);
      return server.copyWith(
        serverUUID: json['server_uuid'],
        cookie: response.headers['set-cookie'],
      );
    } catch (exception, stacktrace) {
      print(exception.toString());
      print(stacktrace.toString());
    }
    return server;
  }

  /// Gets [Device] devices present on the [server] after login.
  /// Returns `true` if it is a success or `false` if it failed.
  /// The found [Device] devices are saved in [Server.devices].
  static Future<bool> getDevices(Server server) async {
    try {
      assert(server.serverUUID != null && server.cookie != null);
      final response = await get(
        Uri.https(
          '${server.login}:${Uri.encodeComponent(server.password)}@${server.ip}:${server.port}',
          '/devices.php',
          {
            'XML': '1',
          },
        ),
        headers: {
          'Cookie': server.cookie!,
        },
      );
      final parser = Xml2Json();
      parser.parse(response.body);
      server.devices.clear();
      server.devices.addAll(
        jsonDecode(parser.toParker())['devices']['device']
            .map(
              (e) => Device(
                e['device_name'],
                '/live/${e['id']}',
                e['status'] == 'OK',
                e['horizontal_resolution'],
                e['vertical_resolution'],
              ),
            )
            .cast<Device>(),
      );
      return true;
    } catch (exception, stacktrace) {
      print(exception.toString());
      print(stacktrace.toString());
    }
    return false;
  }
}
