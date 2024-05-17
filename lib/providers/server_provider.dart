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
import 'package:bluecherry_client/providers/app_provider_interface.dart';
import 'package:bluecherry_client/providers/desktop_view_provider.dart';
import 'package:bluecherry_client/providers/mobile_view_provider.dart';
import 'package:bluecherry_client/utils/constants.dart';
import 'package:bluecherry_client/utils/methods.dart';
import 'package:bluecherry_client/utils/storage.dart';
import 'package:bluecherry_client/utils/video_player.dart';
import 'package:flutter/foundation.dart';

class ServersProvider extends UnityProvider {
  ServersProvider._();
  ServersProvider.dump();

  static late ServersProvider instance;
  static Future<ServersProvider> ensureInitialized() async {
    instance = ServersProvider._();
    await instance.initialize();
    debugPrint('ServersProvider initialized');
    return instance;
  }

  /// Whether any server is added.
  bool get hasServers => servers.isNotEmpty;

  List<Server> servers = <Server>[];

  /// The list of servers that are being loaded
  List<String> loadingServer = <String>[];

  bool isServerLoading(Server server) => loadingServer.contains(server.id);

  /// Called by [ensureInitialized].
  @override
  Future<void> initialize() async {
    await tryReadStorage(
        () => super.initializeStorage(serversStorage, kStorageServers));
    refreshDevices(startup: true);
  }

  /// Adds a new [Server] to the cache.
  /// Also registers the Firebase Messaging token for the server, to receive the notifications.
  Future<void> add(Server server) async {
    if (servers.contains(server)) return;

    servers.add(server);
    await save();
    await refreshDevices(ids: [server.id]);

    if (isMobilePlatform) {
      // Register notification token.
      try {
        final data = await tryReadStorage(() => serversStorage.read());
        final notificationToken = data[kStorageNotificationToken];
        assert(
            notificationToken != null, '[kStorageNotificationToken] is null.');
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
    await save();

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

    final s = servers.firstWhere(
      (s) => s.ip == server.ip && s.port == server.port,
      orElse: () => server,
    );
    final serverIndex = servers.indexOf(s);

    for (final device in server.devices) {
      device.server = server;
      if (UnityPlayers.players.keys.contains(device.uuid)) {
        UnityPlayers.reloadDevice(device);
      }
    }

    servers[serverIndex] = server;

    await save();
    UnityPlayers.reloadAll();
  }

  /// If [ids] is provided, only the provided ids will be refreshed
  Future<List<Server>> refreshDevices({
    bool startup = false,
    Iterable<String>? ids,
  }) async {
    await Future.wait(servers.map((server) async {
      if (ids != null && !ids.contains(server.id)) return;
      if (startup && !server.additionalSettings.connectAutomaticallyAtStartup) {
        return;
      }

      if (!loadingServer.contains(server.id)) {
        loadingServer.add(server.id);
        notifyListeners();
      }

      (_, server) = await API.instance.checkServerCredentials(server);
      final devices = await API.instance.getDevices(server);
      if (devices != null) {
        server.devices
          ..clear()
          ..addAll(devices);
      }

      if (loadingServer.contains(server.id)) {
        loadingServer.remove(server.id);
        notifyListeners();
      }
    }));
    await save();

    return servers;
  }

  /// Save currently added [Server]s to `package:hive` cache.
  @override
  Future<void> save({bool notifyListeners = true}) async {
    try {
      await serversStorage.write({
        kStorageServers: servers.map((e) => e.toJson()).toList(),
      });
    } catch (e) {
      debugPrint(e.toString());
    }
    super.save(notifyListeners: notifyListeners);
  }

  /// Restore currently added [Server]s from `package:hive` cache.
  @override
  Future<void> restore({bool notifyListeners = true}) async {
    final data = await tryReadStorage(() => serversStorage.read());

    final serversData = List<Map<String, dynamic>>.from(
      data[kStorageServers] is String
          ? (await compute(jsonDecode, data[kStorageServers] as String) as List)
          : data[kStorageServers] as List,
    );
    servers = serversData.map<Server>(Server.fromJson).toList();
    super.restore(notifyListeners: notifyListeners);
  }

  @override
  // ignore: must_call_super
  void dispose() {}
}
