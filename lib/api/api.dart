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

import 'package:bluecherry_client/api/api_helpers.dart';
import 'package:bluecherry_client/models/device.dart';
import 'package:bluecherry_client/models/server.dart';
import 'package:bluecherry_client/utils/logging.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:xml2json/xml2json.dart';

export 'events.dart';
export 'ptz.dart';

enum ServerAdditionResponse {
  validated,
  versionMismatch,
  unknown;
}

class API {
  static final API instance = API();

  static final client = http.Client();

  static void initialize() {
    if (kIsWeb) {
      // On Web, a [BrowserClient] is used under the hood, which has the
      // "withCredentials" property. This is cast as dynamic because the
      // [BrowserClient] is not available on the other platforms.
      //
      // This is used to enable the cookies on the requests.
      (client as dynamic).withCredentials = true;
    }
  }

  /// Checks details of a [server] entered by the user.
  /// If the attributes present in [Server] are correct, then the
  /// returned object will have [Server.serverUUID] & [Server.cookie]
  /// present in it otherwise `null`.
  Future<(ServerAdditionResponse response, Server server)>
      checkServerCredentials(
    Server server,
  ) async {
    debugPrint('Checking server credentials for server ${server.id}');
    try {
      final uri = Uri.https(
        '${server.ip}:${server.port}',
        '/ajax/loginapp.php',
        {
          'login': server.login,
          'password': server.password,
          'from_client': '${true}',
        },
      );
      final request = http.MultipartRequest('POST', uri)
        ..fields.addAll({
          'login': server.login,
          'password': server.password,
          'from_client': '${true}',
        })
        ..headers.addAll({
          'Content-Type': 'application/x-www-form-urlencoded',
        });
      final response = await request.send();
      final body = await response.stream.bytesToString();
      debugPrint(
        'checkServerCredentials ${response.statusCode}'
        '\n:....${response.headers}'
        '\n:....$body',
      );

      if (response.statusCode == 200) {
        if (body == 'Route error!') {
          server.online = false;
          return (ServerAdditionResponse.versionMismatch, server);
        }
        final json = await compute(jsonDecode, body);
        return (
          ServerAdditionResponse.validated,
          server.copyWith(
            serverUUID: json['server_uuid'],
            cookie: response.headers['set-cookie'] ??
                response.headers['Set-Cookie'],
            online: true,
          )
        );
      } else {
        debugPrint(body);
        server.online = false;
      }
    } catch (error, stack) {
      handleError(
        error,
        stack,
        'Failed to check server credentials on server $server',
      );

      server.online = false;
    }
    return (ServerAdditionResponse.unknown, server);
  }

  /// Gets [Device] devices present on the [server] after login.
  /// Returns `true` if it is a success or `false` if it failed.
  /// The found [Device] devices are saved in [Server.devices].
  Future<Iterable<Device>?> getDevices(Server server) async {
    if (!server.online) {
      debugPrint('Can not get devices of an offline server: $server');
      return [];
    }

    try {
      assert(server.serverUUID != null && server.hasCookies);
      final response = await client.get(
        Uri.https(
          '${Uri.encodeComponent(server.login)}:${Uri.encodeComponent(server.password)}@${server.ip}:${server.port}',
          '/devices.php',
          {
            'XML': '1',
          },
        ),
        headers: {
          if (server.cookie != null) 'Cookie': server.cookie!,
        },
      );
      // debugPrint(response.body);
      final parser = Xml2Json()..parse(response.body);
      final devicesResult =
          (await compute(jsonDecode, parser.toParker()))['devices']['device'];

      Iterable<Device> devices;
      if (devicesResult is Iterable) {
        // This is reached in the case the server has multiple cameras
        devices = List<Map>.from(devicesResult).map((device) {
          return Device.fromServerJson(device, server);
        });
      } else if (devicesResult is Map) {
        // This is reached in the case the server only has a single camera
        devices = [Device.fromServerJson(devicesResult, server)];
      } else {
        throw UnsupportedError(
          'The client could not parse the response from the server: $devicesResult',
        );
      }

      server.devices
        ..clear()
        ..addAll(devices);
      return devices;
    } catch (error, stack) {
      handleError(error, stack, 'Failed to get devices on server $server');
    }
    return null;
  }

  /// Returns the notification API endpoint.
  ///
  /// Returns the endpoint as [String] if the request was successful, otherwise returns `null`.
  ///
  Future<String?> getNotificationAPIEndpoint(Server server) async {
    try {
      assert(server.serverUUID != null && server.hasCookies);
      final response = await client.get(
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
    } catch (error, stack) {
      handleError(
        error,
        stack,
        'Failed to get notification API endpoint on server $server',
      );
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
      final response = await client.post(
        Uri.parse('${uri!}store-token'),
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
    } catch (error, stack) {
      handleError(
        error,
        stack,
        'Failed to registerNotificationToToken on server $server',
      );
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
      final response = await client.post(
        Uri.parse('${uri!}remove-token'),
        headers: {
          'Cookie': server.cookie!,
          'Content-Type': 'application/json',
        },
        body: jsonEncode(
          {
            'client_id': '${clientID}_flutter',
            'server_id': server.serverUUID,
          },
        ),
      );
      debugPrint(response.statusCode.toString());
      debugPrint(response.body);
      return true;
    } catch (error, stack) {
      handleError(
        error,
        stack,
        'Failed to unregisterNotificationToken on server $server',
      );
      return false;
    }
  }
}
