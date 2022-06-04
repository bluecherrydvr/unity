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
import 'package:http/http.dart';
import 'package:flutter/rendering.dart';
import 'package:xml2json/xml2json.dart';

import 'package:bluecherry_client/models/device.dart';
import 'package:bluecherry_client/models/event.dart';
import 'package:bluecherry_client/models/server.dart';

class API {
  static final API instance = API();

  /// Checks details of a [server] entered by the user.
  /// If the attributes present in [Server] are correct, then the
  /// returned object will have [Server.serverUUID] & [Server.cookie]
  /// present in it otherwise `null`.
  Future<Server> checkServerCredentials(Server server) async {
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
      debugPrint(body.toString());
      debugPrint(response.headers.toString());
      final json = jsonDecode(body);
      return server.copyWith(
        serverUUID: json['server_uuid'],
        cookie: response.headers['set-cookie'],
      );
    } catch (exception, stacktrace) {
      debugPrint(exception.toString());
      debugPrint(stacktrace.toString());
    }
    return server;
  }

  /// Gets [Device] devices present on the [server] after login.
  /// Returns `true` if it is a success or `false` if it failed.
  /// The found [Device] devices are saved in [Server.devices].
  Future<bool> getDevices(Server server) async {
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
                'live/${e['id']}',
                e['status'] == 'OK',
                e['resolutionX'] == null ? null : int.parse(e['resolutionX']),
                e['resolutionX'] == null ? null : int.parse(e['resolutionY']),
              ),
            )
            .cast<Device>(),
      );
      return true;
    } catch (exception, stacktrace) {
      debugPrint(exception.toString());
      debugPrint(stacktrace.toString());
    }
    return false;
  }

  Future<Iterable<Event>> getEvents(
    Server server, {
    int limit = 50,
  }) async {
    try {
      assert(server.serverUUID != null && server.cookie != null);
      final response = await get(
        Uri.https(
          '${server.login}:${Uri.encodeComponent(server.password)}@${server.ip}:${server.port}',
          '/events/',
          {
            'XML': '1',
            'limit': '$limit',
          },
        ),
        headers: {
          'Cookie': server.cookie!,
        },
      );
      final parser = Xml2Json();
      parser.parse(response.body);
      return jsonDecode(parser.toParkerWithAttrs())['feed']['entry']
          .map(
            (e) => Event(
              server,
              int.parse(e['id']['_raw']),
              e['title'],
              DateTime.parse(e['published']),
              DateTime.parse(e['updated']),
              e['category'],
              int.parse(e['content']['_media_id']),
              Duration(milliseconds: int.parse(e['content']['_media_size'])),
              Uri.parse(e['content']['value']),
            ),
          )
          .cast<Event>();
    } catch (exception, stacktrace) {
      debugPrint(exception.toString());
      debugPrint(stacktrace.toString());
    }
    return <Event>[];
  }
}
