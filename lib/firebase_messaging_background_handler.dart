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

import 'dart:io';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:http/http.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:awesome_notifications/awesome_notifications.dart';

import 'package:bluecherry_client/api/api.dart';
import 'package:bluecherry_client/firebase_options.dart';
import 'package:bluecherry_client/providers/server_provider.dart';
import 'package:bluecherry_client/utils/constants.dart';
import 'package:bluecherry_client/utils/methods.dart';

import 'package:bluecherry_client/main.dart';

// final eventType = message.data['eventType'];
// final serverUUID = message.data['serverId'];
// final id = message.data['deviceId'];
// final name = message.data['deviceName'];
// final uri = 'live/$id';
// // Return if same device is already playing.
// if (mutex == id || eventType != 'motion_event') {
//   return;
// }
// final server = ServersProvider.instance.servers
//     .firstWhere((server) => server.serverUUID == serverUUID);
// final device = Device(name, uri, true, 0, 0, server);
// final player =
//     MobileViewProvider.instance.getVideoPlayerController(device);
// SystemChrome.setPreferredOrientations([
//   DeviceOrientation.landscapeLeft,
//   DeviceOrientation.landscapeRight,
// ]);
// StatusBarControl.setHidden(true);
// if (mutex == null) {
//   mutex = id;
//   await navigatorKey.currentState?.push(
//     MaterialPageRoute(
//       builder: (context) => DeviceFullscreenViewer(
//         device: device,
//         ijkPlayer: player,
//       ),
//     ),
//   );
// } else {
//   mutex = id;
//   await navigatorKey.currentState?.pushReplacement(
//     MaterialPageRoute(
//       builder: (context) => DeviceFullscreenViewer(
//         device: device,
//         ijkPlayer: player,
//       ),
//     ),
//   );
// }
// SystemChrome.setPreferredOrientations(DeviceOrientation.values);
// StatusBarControl.setHidden(false);
// await player.release();
// await player.release();
// mutex = null;

/// Callbacks received from the [FirebaseMessaging] instance.
Future<void> _firebaseMessagingHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  HttpOverrides.global = DevHttpOverrides();
  await EasyLocalization.ensureInitialized();
  await ServersProvider.ensureInitialized();
  debugPrint(message.toMap().toString());
  try {
    await AwesomeNotifications().initialize(
      'resource://drawable/ic_stat_linked_camera',
      [
        NotificationChannel(
          channelKey: 'com.bluecherrydvr',
          channelName: 'Bluecherry DVR',
          channelDescription: 'Bluecherry DVR Notifications',
          ledColor: Colors.white,
        )
      ],
      debug: true,
    );
    final eventType = message.data['eventType'];
    final name = message.data['deviceName'];
    final serverUUID = message.data['serverId'];
    if (!['motion_event', 'device_state'].contains(eventType)) {
      return;
    }
    final key = Random().nextInt(pow(2, 8) ~/ 1 - 1);
    AwesomeNotifications().createNotification(
      content: NotificationContent(
        id: key,
        color: const Color.fromRGBO(92, 107, 192, 1),
        channelKey: 'com.bluecherrydvr',
        title: getEventNameFromID(eventType),
        body: name,
        displayOnBackground: true,
        displayOnForeground: true,
        payload: message.data
            .map<String, String>(
              (key, value) => MapEntry(
                key,
                value.toString(),
              ),
            )
            .cast(),
      ),
      actionButtons: [
        NotificationActionButton(
          label: '15 minutes',
          key: 'snooze_15',
        ),
        NotificationActionButton(
          label: '30 minutes',
          key: 'snooze_30',
        ),
        NotificationActionButton(
          label: '1 hour',
          key: 'snooze_60',
        ),
      ],
    );
    try {
      final server = ServersProvider.instance.servers
          .firstWhere((server) => server.serverUUID == serverUUID);
      final events = await API.instance.getEvents(
        await API.instance.checkServerCredentials(server),
        limit: 10,
      );
      final event = events.firstWhere(
        (event) {
          debugPrint(
              '${event.title.split('device').last.trim().toLowerCase()} == ${name.toLowerCase()}');
          return event.title.split('device').last.trim().toLowerCase() ==
              name.toLowerCase();
        },
      );
      final thumbnail =
          'https://admin:bluecherry@7007cams.bluecherry.app:7001/media/request.php?id=128690&mode=screenshot';
      if (thumbnail != null) {
        final path = await _downloadAndSaveFile(thumbnail);
        debugPrint(path);
        await AwesomeNotifications().dismiss(key);
        await AwesomeNotifications().createNotification(
          content: NotificationContent(
            id: key,
            color: const Color.fromRGBO(92, 107, 192, 1),
            channelKey: 'com.bluecherrydvr',
            bigPicture: path,
            title: getEventNameFromID(eventType),
            body: name,
            displayOnBackground: true,
            displayOnForeground: true,
            payload: message.data
                .map<String, String>(
                  (key, value) => MapEntry(
                    key,
                    value.toString(),
                  ),
                )
                .cast(),
            notificationLayout: NotificationLayout.BigPicture,
          ),
          actionButtons: [
            NotificationActionButton(
              label: '15 minutes',
              key: 'snooze_15',
            ),
            NotificationActionButton(
              label: '30 minutes',
              key: 'snooze_30',
            ),
            NotificationActionButton(
              label: '1 hour',
              key: 'snooze_60',
            ),
          ],
        );
      }
    } catch (exception, stacktrace) {
      debugPrint(exception.toString());
      debugPrint(stacktrace.toString());
    }
  } catch (exception, stacktrace) {
    debugPrint(exception.toString());
    debugPrint(stacktrace.toString());
  }
}

Future<void> _backgroundActionStreamReceiver(ReceivedAction action) async {
  debugPrint(action.toString());
}

Future<String> _downloadAndSaveFile(String url) async {
  final directory = await getExternalStorageDirectory();
  final filePath = '${directory?.path}/${Random().nextInt(1 << 32)}.png';
  final response = await get(Uri.parse(url));
  final file = File(filePath);
  await file.create(recursive: true);
  await file.writeAsBytes(response.bodyBytes);
  debugPrint('file://$filePath');
  return 'file://$filePath';
}

/// Initialize & handle Firebase core & messaging plugins.
///
/// Saves entry point of application from getting unnecessarily cluttered.
///
abstract class FirebaseConfiguration {
  static Future<void> ensureInitialized() async {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingHandler);
    FirebaseMessaging.onMessage.listen((RemoteMessage message) async {
      debugPrint(message.toMap().toString());
      try {
        final eventType = message.data['eventType'];
        final name = message.data['deviceName'];
        final serverUUID = message.data['serverId'];
        if (!['motion_event', 'device_state'].contains(eventType)) {
          return;
        }
        final key = Random().nextInt(pow(2, 8) ~/ 1 - 1);
        AwesomeNotifications().createNotification(
          content: NotificationContent(
            id: key,
            color: const Color.fromRGBO(92, 107, 192, 1),
            channelKey: 'com.bluecherrydvr',
            title: getEventNameFromID(eventType),
            body: name,
            displayOnBackground: true,
            displayOnForeground: true,
            payload: message.data
                .map<String, String>(
                  (key, value) => MapEntry(
                    key,
                    value.toString(),
                  ),
                )
                .cast(),
          ),
          actionButtons: [
            NotificationActionButton(
              label: '15 minutes',
              key: 'snooze_15',
            ),
            NotificationActionButton(
              label: '30 minutes',
              key: 'snooze_30',
            ),
            NotificationActionButton(
              label: '1 hour',
              key: 'snooze_60',
            ),
          ],
        );
        try {
          final server = ServersProvider.instance.servers
              .firstWhere((server) => server.serverUUID == serverUUID);
          final events = await API.instance.getEvents(
            await API.instance.checkServerCredentials(server),
            limit: 10,
          );
          final event = events.firstWhere(
            (event) {
              debugPrint(
                  '${event.title.split('device').last.trim().toLowerCase()} == ${name.toLowerCase()}');
              return event.title.split('device').last.trim().toLowerCase() ==
                  name.toLowerCase();
            },
          );
          final thumbnail =
              'https://admin:bluecherry@7007cams.bluecherry.app:7001/media/request.php?id=128690&mode=screenshot';
          if (thumbnail != null) {
            final path = await _downloadAndSaveFile(thumbnail);
            debugPrint(path);
            await AwesomeNotifications().dismiss(key);
            await AwesomeNotifications().createNotification(
              content: NotificationContent(
                id: key,
                color: const Color.fromRGBO(92, 107, 192, 1),
                channelKey: 'com.bluecherrydvr',
                bigPicture: path,
                title: getEventNameFromID(eventType),
                body: name,
                displayOnBackground: true,
                displayOnForeground: true,
                payload: message.data
                    .map<String, String>(
                      (key, value) => MapEntry(
                        key,
                        value.toString(),
                      ),
                    )
                    .cast(),
                notificationLayout: NotificationLayout.BigPicture,
              ),
              actionButtons: [
                NotificationActionButton(
                  label: '15 minutes',
                  key: 'snooze_15',
                ),
                NotificationActionButton(
                  label: '30 minutes',
                  key: 'snooze_30',
                ),
                NotificationActionButton(
                  label: '1 hour',
                  key: 'snooze_60',
                ),
              ],
            );
          }
        } catch (exception, stacktrace) {
          debugPrint(exception.toString());
          debugPrint(stacktrace.toString());
        }
      } catch (exception, stacktrace) {
        debugPrint(exception.toString());
        debugPrint(stacktrace.toString());
      }
    });
    await FirebaseMessaging.instance.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );
    await AwesomeNotifications().initialize(
      'resource://drawable/ic_stat_linked_camera',
      [
        NotificationChannel(
          channelKey: 'com.bluecherrydvr',
          channelName: 'Bluecherry DVR',
          channelDescription: 'Bluecherry DVR Notifications',
          ledColor: Colors.white,
        )
      ],
      backgroundClickAction: _backgroundActionStreamReceiver,
      debug: true,
    );
    AwesomeNotifications().isNotificationAllowed().then((isAllowed) {
      if (!isAllowed) {
        AwesomeNotifications().requestPermissionToSendNotifications();
      }
    });
    AwesomeNotifications().actionStream.listen((action) {
      debugPrint(action.toString());
    });
    await FirebaseMessaging.instance
        .setForegroundNotificationPresentationOptions(
      alert: true,
      badge: true,
      sound: true,
    );
    FirebaseMessaging.instance.onTokenRefresh.listen(
      (token) async {
        debugPrint('[FirebaseMessaging.instance.onTokenRefresh]: $token');
        final instance = await SharedPreferences.getInstance();
        await instance.setString(
          kSharedPreferencesNotificationToken,
          token,
        );
        for (final server in ServersProvider.instance.servers) {
          API.instance.registerNotificationToken(
            await API.instance.checkServerCredentials(server),
            token,
          );
        }
      },
    );
    // Sometimes [FirebaseMessaging.instance.onTokenRefresh] is not getting invoked.
    // Having this as a fallback.
    FirebaseMessaging.instance.getToken().then((token) async {
      debugPrint('[FirebaseMessaging.instance.getToken]: $token');
      if (token != null) {
        final instance = await SharedPreferences.getInstance();
        // Do not proceed, if token is already saved.
        if (instance.getString(kSharedPreferencesNotificationToken) == token) {
          return;
        }
        await instance.setString(
          kSharedPreferencesNotificationToken,
          token,
        );
        for (final server in ServersProvider.instance.servers) {
          API.instance.registerNotificationToken(
            await API.instance.checkServerCredentials(server),
            token,
          );
        }
      }
    });
  }
}
