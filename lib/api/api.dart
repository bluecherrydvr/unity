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
import 'package:http/http.dart';
import 'package:flutter/rendering.dart';
import 'package:xml2json/xml2json.dart';

import 'package:bluecherry_client/models/device.dart';
import 'package:bluecherry_client/models/event.dart';
import 'package:bluecherry_client/models/server.dart';
import 'package:bluecherry_client/api/api_helpers.dart';

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
          '${Uri.encodeComponent(server.login)}:${Uri.encodeComponent(server.password)}@${server.ip}:${server.port}',
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
                server,
              ),
            )
            .toList()
            .cast<Device>()
          // cause `online` devies to show on top.
          ..sort((a, b) => a.status ? 0 : 1),
      );
      return true;
    } catch (exception, stacktrace) {
      debugPrint(exception.toString());
      debugPrint(stacktrace.toString());
    }
    return false;
  }

  /// Gets [Event]s present on the [server] after login.
  /// [limit] defines the number of events to be fetched.
  ///
  Future<Iterable<Event>> getEvents(
    Server server, {
    int limit = 50,
  }) async {
    try {
      assert(server.serverUUID != null && server.cookie != null);
      final response = await get(
        Uri.https(
          '${Uri.encodeComponent(server.login)}:${Uri.encodeComponent(server.password)}@${server.ip}:${server.port}',
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
      return jsonDecode(parser.toGData())['feed']['entry']
          .map(
            (e) => Event(
              server,
              int.parse(e['id']['raw']),
              int.parse(e['category']['term'].split('/').first),
              e['title']['\$t'],
              e['published'] == null || e['published']['\$t'] == null
                  ? DateTime.now()
                  : DateTime.parse(e['published']['\$t']),
              e['updated'] == null || e['updated']['\$t'] == null
                  ? DateTime.now()
                  : DateTime.parse(e['updated']['\$t']),
              e['category']['term'],
              int.parse(e['content']['media_id']),
              Duration(
                milliseconds: int.tryParse(e['content']['media_size']) ?? 0,
              ),
              Uri.parse(
                e['content']['\$t'].replaceAll(
                  'https://',
                  'https://${Uri.encodeComponent(server.login)}:${Uri.encodeComponent(server.password)}@',
                ),
              ),
            ),
          )
          .cast<Event>();
    } catch (exception, stacktrace) {
      debugPrint(exception.toString());
      debugPrint(stacktrace.toString());
    }
    return <Event>[];
  }

  /// Returns the notification API endpoint.
  ///
  /// Returns the endpoint as [String] if the request was successful, otherwise returns `null`.
  ///
  Future<String?> getNotificationAPIEndpoint(Server server) async {
    try {
      assert(server.serverUUID != null && server.cookie != null);
      final response = await get(
        Uri.https(
          '${Uri.encodeComponent(server.login)}:${Uri.encodeComponent(server.password)}@${server.ip}:${server.port}',
          '/mobile-app-config.json',
        ),
        headers: {
          'Cookie': server.cookie!,
        },
      );
      final body = jsonDecode(response.body);
      return body['notification_api_endpoint'];
    } catch (exception, stacktrace) {
      debugPrint(exception.toString());
      debugPrint(stacktrace.toString());
    }
    return null;
  }

  /// Registers notification [token] for a [server], so that the notifications can be received with the help of Firebase Messaging.
  /// Returns `true` if it is a success or `false` if it failed.
  ///
  Future<bool> registerNotificationToken(Server server, String token) async {
    try {
      final uri = await getNotificationAPIEndpoint(server);
      final clientID = await APIHelpers.clientUUID;
      assert(uri != null, '[getNotificationAPIEndpoint] returned null.');
      assert(clientID != null, '[clientUUID] returned null.');
      assert(server.serverUUID != null, '[server.serverUUID] is null.');
      final response = await post(
        Uri.parse(uri! + 'store-token'),
        headers: {
          'Cookie': server.cookie!,
          'Content-Type': 'application/json',
        },
        body: jsonEncode(
          {
            'client_id': clientID,
            'server_id': server.serverUUID,
            'token': token,
            'disable_payload_notification': true,
          },
        ),
      );
      debugPrint({
        'client_id': clientID,
        'server_id': server.serverUUID,
        'token': token,
        'disable_payload_notification': true,
      }.toString());
      debugPrint(response.statusCode.toString());
      debugPrint(response.body);
      return true;
    } catch (exception, stacktrace) {
      debugPrint(exception.toString());
      debugPrint(stacktrace.toString());
      return false;
    }
  }

  /// Unregisters notification [token] for a [server], so that the notifications from Firebase Messaging can be stopped.
  /// Returns `true` if it is a success or `false` if it failed.
  ///
  Future<bool> unregisterNotificationToken(Server server) async {
    try {
      final uri = await getNotificationAPIEndpoint(server);
      final clientID = await APIHelpers.clientUUID;
      assert(uri != null, '[getNotificationAPIEndpoint] returned null.');
      assert(clientID != null, '[clientUUID] returned null.');
      assert(server.serverUUID != null, '[server.serverUUID] is null.');
      final response = await post(
        Uri.parse(uri! + 'remove-token'),
        headers: {
          'Cookie': server.cookie!,
          'Content-Type': 'application/json',
        },
        body: jsonEncode(
          {
            'client_id': clientID,
            'server_id': server.serverUUID,
          },
        ),
      );
      debugPrint(response.statusCode.toString());
      debugPrint(response.body);
      return true;
    } catch (exception, stacktrace) {
      debugPrint(exception.toString());
      debugPrint(stacktrace.toString());
      return false;
    }
  }
}
