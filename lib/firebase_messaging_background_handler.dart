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

import 'package:bluecherry_client/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:status_bar_control/status_bar_control.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import 'package:bluecherry_client/api/api.dart';
import 'package:bluecherry_client/firebase_options.dart';
import 'package:bluecherry_client/providers/mobile_view_provider.dart';
import 'package:bluecherry_client/providers/server_provider.dart';
import 'package:bluecherry_client/utils/constants.dart';
import 'package:bluecherry_client/models/device.dart';
import 'package:bluecherry_client/widgets/device_tile.dart';

const channel = AndroidNotificationChannel(
  'com.bluecherrydvr',
  'Bluecherry Client',
  importance: Importance.high,
  playSound: true,
  showBadge: true,
  enableLights: true,
);

final flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

/// Callbacks received from the [FirebaseMessaging] instance.
Future<void> _firebaseMessagingHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  debugPrint(message.toMap().toString());
  // try {
  // final notification = FlutterLocalNotificationsPlugin();
  // const initializationSettings = InitializationSettings(
  //   android: AndroidInitializationSettings('@drawable/ic_stat_linked_camera'),
  //   iOS: IOSInitializationSettings(),
  // );
  // await notification
  //     .resolvePlatformSpecificImplementation<
  //         AndroidFlutterLocalNotificationsPlugin>()
  //     ?.createNotificationChannel(channel);
  // notification.initialize(
  //   initializationSettings,
  //   onSelectNotification: (payload) {},
  // );
  // notification.show(
  //   Random().nextInt((pow(2, 31)) ~/ 1 - 1),
  //   message.notification?.title ?? '',
  //   message.notification?.body ?? '',
  //   NotificationDetails(
  //     android: AndroidNotificationDetails(
  //       channel.id,
  //       channel.name,
  //       icon: 'drawable/ic_stat_linked_camera',
  //     ),
  //   ),
  // );
  // } catch (exception, stacktrace) {
  //   debugPrint(exception.toString());
  //   debugPrint(stacktrace.toString());
  // }
}

String? mutex;

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
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      debugPrint(message.toMap().toString());
      // try {
      //   flutterLocalNotificationsPlugin.show(
      //     Random().nextInt((pow(2, 31)) ~/ 1 - 1),
      //     message.notification?.title ?? '',
      //     message.notification?.body ?? '',
      //     NotificationDetails(
      //       android: AndroidNotificationDetails(
      //         channel.id,
      //         channel.name,
      //         icon: 'drawable/ic_stat_linked_camera',
      //       ),
      //     ),
      //   );
      // } catch (exception, stacktrace) {
      //   debugPrint(exception.toString());
      //   debugPrint(stacktrace.toString());
      // }
    });
    await FirebaseMessaging.instance.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );
    await flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);
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
    FirebaseMessaging.onMessageOpenedApp.listen((message) async {
      final eventType = message.data['eventType'];
      final serverUUID = message.data['serverId'];
      final id = message.data['deviceId'];
      final name = message.data['deviceName'];
      final uri = 'live/$id';
      // Return if same device is already playing.
      if (mutex == id || eventType != 'motion_event') {
        return;
      }
      final server = ServersProvider.instance.servers
          .firstWhere((server) => server.serverUUID == serverUUID);
      final device = Device(name, uri, true, 0, 0, server);
      final player =
          MobileViewProvider.instance.getVideoPlayerController(device);
      SystemChrome.setPreferredOrientations([
        DeviceOrientation.landscapeLeft,
        DeviceOrientation.landscapeRight,
      ]);
      StatusBarControl.setHidden(true);
      if (mutex == null) {
        mutex = id;
        await navigatorKey.currentState?.push(
          MaterialPageRoute(
            builder: (context) => DeviceFullscreenViewer(
              device: device,
              ijkPlayer: player,
            ),
          ),
        );
      } else {
        mutex = id;
        await navigatorKey.currentState?.pushReplacement(
          MaterialPageRoute(
            builder: (context) => DeviceFullscreenViewer(
              device: device,
              ijkPlayer: player,
            ),
          ),
        );
      }
      SystemChrome.setPreferredOrientations(DeviceOrientation.values);
      StatusBarControl.setHidden(false);
      await player.release();
      await player.release();
      mutex = null;
    });
    FirebaseMessaging.instance.getInitialMessage().then((message) async {
      if (message != null) {
        final eventType = message.data['eventType'];
        final serverUUID = message.data['serverId'];
        final id = message.data['deviceId'];
        final name = message.data['deviceName'];
        final uri = 'live/$id';
        // Return if same device is already playing.
        if (mutex == id || eventType != 'motion_event') {
          return;
        }
        final server = ServersProvider.instance.servers
            .firstWhere((server) => server.serverUUID == serverUUID);
        final device = Device(name, uri, true, 0, 0, server);
        final player =
            MobileViewProvider.instance.getVideoPlayerController(device);
        SystemChrome.setPreferredOrientations([
          DeviceOrientation.landscapeLeft,
          DeviceOrientation.landscapeRight,
        ]);
        StatusBarControl.setHidden(true);
        if (mutex == null) {
          mutex = id;
          await navigatorKey.currentState?.push(
            MaterialPageRoute(
              builder: (context) => DeviceFullscreenViewer(
                device: device,
                ijkPlayer: player,
              ),
            ),
          );
        } else {
          mutex = id;
          await navigatorKey.currentState?.pushReplacement(
            MaterialPageRoute(
              builder: (context) => DeviceFullscreenViewer(
                device: device,
                ijkPlayer: player,
              ),
            ),
          );
        }
        SystemChrome.setPreferredOrientations(DeviceOrientation.values);
        StatusBarControl.setHidden(false);
        await player.release();
        await player.release();
        mutex = null;
      }
    });
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
