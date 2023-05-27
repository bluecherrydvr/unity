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

import 'package:bluecherry_client/api/api.dart';
import 'package:bluecherry_client/models/server.dart';
import 'package:bluecherry_client/providers/desktop_view_provider.dart';
import 'package:bluecherry_client/providers/mobile_view_provider.dart';
import 'package:bluecherry_client/utils/constants.dart';
import 'package:bluecherry_client/utils/storage.dart';
import 'package:bluecherry_client/widgets/misc.dart';
import 'package:flutter/foundation.dart';

/// This class manages & saves (caching) the currently added [Server]s by the user.
///
class ServersProvider extends ChangeNotifier {
  /// `late` initialized [ServersProvider] instance.
  static late final ServersProvider instance;

  /// Initializes the [ServersProvider] instance & fetches state from `async`
  /// `package:hive` method-calls. Called before [runApp].
  static Future<ServersProvider> ensureInitialized() async {
    try {
      instance = ServersProvider();
      await instance.initialize();
    } catch (exception, stacktrace) {
      debugPrint(exception.toString());
      debugPrint(stacktrace.toString());
    }
    return instance;
  }

  bool get serverAdded => servers.isNotEmpty;

  List<Server> servers = <Server>[];

  /// The list of servers that are being loaded
  List<String> loadingServer = <String>[];

  bool isServerLoading(Server server) => loadingServer.contains(server.id);

  /// Called by [ensureInitialized].
  Future<void> initialize() async {
    final data = await serversStorage.read() as Map;
    if (!data.containsKey(kHiveServers)) {
      await _save();
    } else {
      await _restore();
    }

    refreshDevices();
  }

  /// Adds a new [Server] to the cache.
  /// Also registers the Firebase Messaging token for the server, to receive the notifications.
  Future<void> add(Server server) async {
    // Prevent duplicates.
    if (servers.contains(server)) {
      return;
    }
    servers.add(server);
    await _save();
    refreshDevices();

    if (isMobile) {
      // Register notification token.
      try {
        final data = await serversStorage.read() as Map;
        final notificationToken = data[kHiveNotificationToken];
        assert(notificationToken != null, '[kHiveNotificationToken] is null.');
        await API.instance
            .registerNotificationToken(server, notificationToken!);
      } catch (exception, stacktrace) {
        debugPrint(exception.toString());
        debugPrint(stacktrace.toString());
      }
    }
  }

  /// Removes a [Server] from the cache.
  /// Also un-registers the Firebase Messaging token for the server, to stop receiving the notifications.
  Future<void> remove(Server server) async {
    servers.remove(server);
    await _save();

    // Remove the device camera tiles showing devices from this server.
    try {
      final provider = MobileViewProvider.instance;
      final view = {...provider.devices};
      for (final tab in view.keys) {
        final devices = view[tab]!;
        for (var i = 0; i < devices.length; i++) {
          final device = devices[i];
          if (device?.server == server) {
            await provider.remove(tab, i);
          }
        }
      }

      final desktopProvider = DesktopViewProvider.instance;
      await desktopProvider.removeDevices(server.devices);
    } catch (exception, stacktrace) {
      debugPrint(exception.toString());
      debugPrint(stacktrace.toString());
    }
    // Unregister notification token.
    try {
      await API.instance.unregisterNotificationToken(server);
    } catch (exception, stacktrace) {
      debugPrint(exception.toString());
      debugPrint(stacktrace.toString());
    }
  }

  /// Updates the given [server] in the cache.
  Future<void> update(Server server) async {
    // If not found, add it
    if (!servers.any((s) => s.ip == server.ip && s.port == server.port)) {
      return add(server);
    }

    final s =
        servers.firstWhere((s) => s.ip == server.ip && s.port == server.port);
    final serverIndex = servers.indexOf(s);

    servers[serverIndex] = server;

    await _save();
  }

  /// If [ids] is provided, only the provided ids will be refreshed
  Future<List<Server>> refreshDevices([List<String>? ids]) async {
    await Future.wait(servers.map((server) async {
      if (ids != null && !ids.contains(server.id)) return;

      if (!loadingServer.contains(server.id)) {
        loadingServer.add(server.id);
        notifyListeners();
      }

      API.instance.checkServerCredentials(server).then((server) {
        API.instance.getDevices(server).then((devices) {
          if (devices != null) {
            server.devices
              ..clear()
              ..addAll(devices);
          }

          if (loadingServer.contains(server.id)) {
            loadingServer.remove(server.id);
            notifyListeners();
          }
        });
      });
    }));
    await _save();

    return servers;
  }

  /// Save currently added [Server]s to `package:hive` cache.
  Future<void> _save() async {
    await serversStorage.write({
      kHiveServers: servers.map((e) => e.toJson()).toList(),
    });
    notifyListeners();
  }

  /// Restore currently added [Server]s from `package:hive` cache.
  Future<void> _restore() async {
    final data = await serversStorage.read() as Map;

    final serversData = data[kHiveServers] is String
        ? await compute(jsonDecode, data[kHiveServers] as String)
        : data[kHiveServers] as List;
    servers = serversData
        .cast<Map<String, dynamic>>()
        .map(Server.fromJson)
        .toList()
        .cast<Server>();
    notifyListeners();
  }

  @override
  // ignore: must_call_super
  void dispose() {}
}
