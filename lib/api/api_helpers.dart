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

import 'dart:io';

import 'package:bluecherry_client/api/api.dart';
import 'package:bluecherry_client/models/server.dart';
import 'package:bluecherry_client/providers/server_provider.dart';
import 'package:bluecherry_client/utils/logging.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

/// This file mainly contains helper functions for working with the API.
/// It is not a part of the server's API itself.
///
/// Certain de-serialization, data-conversion or higher-order functions which internally depend on multiple API calls or [File] I/O are present here.
/// These are used by the other actual logic in the code.
///
abstract class APIHelpers {
  /// Returns unique device ID used to identify the app installation.
  static Future<String?> get clientUUID async {
    final instance = DeviceInfoPlugin();
    if (kIsWeb) {
      final web = await instance.webBrowserInfo;
      return web.platform;
    } else if (Platform.isIOS) {
      final ios = await instance.iosInfo;
      return ios.identifierForVendor;
    } else if (Platform.isAndroid) {
      final androidDeviceInfo = await instance.androidInfo;
      return androidDeviceInfo.display;
    } else if (Platform.isWindows) {
      final windowsDeviceInfo = await instance.windowsInfo;
      return windowsDeviceInfo.deviceId;
    } else if (Platform.isLinux) {
      final linuxDeviceInfo = await instance.linuxInfo;
      return linuxDeviceInfo.machineId ?? linuxDeviceInfo.buildId;
    } else if (Platform.isMacOS) {
      final macosDeviceInfo = await instance.macOsInfo;
      return macosDeviceInfo.systemGUID;
    }
    return null;
  }

  /// Used to check whether a notification event is valid.
  ///
  static bool isValidEventType(String? eventType) =>
      ['motion_event', 'device_state'].contains(eventType);

  /// Converts [eventID] into human-readable string.
  /// Used by notification handler.
  static String getEventNameFromID(String eventID) {
    return switch (eventID) {
      'device_state' => 'Device State Event',
      'motion_event' => 'Motion Event',
      _ => 'Event',
    };
  }

  /// Returns the [File] path of the thumbnail downloaded for a [deviceID] from the [server].
  /// Returns `null` & [File] could not be fetched i.e. screenshot does not exist on the server.
  ///
  /// The [attempts] arguments defines how many events should be fetched to test for thumbnail existence.
  /// Default value is set to `50`. In general, very few attempts will find the correct thumbnail out of [Event]s fetched.
  ///
  /// This method is used by the notification handler to download & show the thumbnail in notification body.
  ///
  static Future<String?> getLatestThumbnailForDeviceID(
    Server server,
    String deviceID, {
    int attempts = 50,
  }) async {
    final events = await API.instance.getEvents(
      (await API.instance.checkServerCredentials(server)).$2,
    );
    debugPrint(events.map((e) => e.id).toList().toString());
    Future<String?> getThumbnailForMediaID(int mediaID) async {
      try {
        final uri = Uri.https(
          '${server.login}:${Uri.encodeComponent(server.password)}@${server.ip}:${server.port}',
          '/media/request.php',
          {
            'id': mediaID.toString(),
            'mode': 'screenshot',
          },
        );
        debugPrint(uri.toString());
        final directory = await getExternalStorageDirectory();
        final filePath = '${directory?.path}/$mediaID.png';
        final file = File(filePath);
        debugPrint('file://$filePath');
        if (await file.exists()) {
          return 'file://$filePath';
          // Download the event thumbnail only if it doesn't exist already.
        } else {
          final response = await API.client.get(uri);
          debugPrint(response.statusCode.toString());
          if (response.statusCode ~/ 100 == 2 /* OK */) {
            await file.create(recursive: true);
            await file.writeAsBytes(response.bodyBytes);
            return 'file://$filePath';
          }
        }
      } catch (error, stack) {
        handleError(
          error,
          stack,
          'Failed to get thumbnail for media ID $mediaID',
        );
      }
      return null;
    }

    final list = events.toList()
      ..removeWhere((element) => element.deviceID.toString() != deviceID);
    for (var i = 0; i < list.length; i++) {
      if (list[i].mediaID != null) {
        final thumbnail = await getThumbnailForMediaID(list[i].mediaID!);
        if (thumbnail != null) {
          return thumbnail;
        }
      }
    }
    return null;
  }
}

class DevHttpOverrides extends HttpOverrides {
  /// Skips bad certificate error for servers
  ///
  /// This must be called for every thread.
  ///
  /// See also:
  ///   * <https://github.com/bluecherrydvr/unity/discussions/42>
  ///   * [compute], used to compute data in another thread
  static Future<void> configureCertificates({
    bool? allowUntrustedCertificates,
  }) async {
    ServersProvider.instance = ServersProvider.dump();
    // SettingsProvider.ensureInitialized();
    HttpOverrides.global = DevHttpOverrides()
      ..allowUntrustedCertificates = allowUntrustedCertificates ?? true;
  }

  bool allowUntrustedCertificates = true;

  @override
  HttpClient createHttpClient(SecurityContext? context) {
    return super.createHttpClient(context)
      ..badCertificateCallback = (cert, host, port) {
        debugPrint('==== RECEIVED BAD CERTIFICATE FROM $host');

        final servers = ServersProvider.instance.servers
            .where((server) => server.ip == host);
        for (final server in servers) {
          server.passedCertificates = false;

          for (final device in server.devices) {
            device.server = server;
          }
        }

        return allowUntrustedCertificates;
      };
  }
}
