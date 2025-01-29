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
import 'package:bluecherry_client/providers/layouts_provider.dart';
import 'package:bluecherry_client/providers/mobile_view_provider.dart';
import 'package:bluecherry_client/utils/constants.dart';
import 'package:bluecherry_client/utils/logging.dart';
import 'package:bluecherry_client/utils/methods.dart';
import 'package:bluecherry_client/utils/storage.dart';
import 'package:bluecherry_client/utils/video_player.dart';
import 'package:flutter/foundation.dart';

class ServersProvider extends UnityProvider {
  ServersProvider._();

  static final ServersProvider _instance = ServersProvider._();
  static ServersProvider get instance => _instance;

  static Future<ServersProvider> ensureInitialized() async {
    await _instance.initialize();
    debugPrint('ServersProvider initialized');
    return _instance;
  }

  bool get hasServers => servers.isNotEmpty;

  List<Server> servers = <Server>[];
  final loadingServers = <String>{};

  bool isServerLoading(Server server) => loadingServers.contains(server.id);

  @override
  Future<void> initialize() async {
    await initializeStorage(kStorageServers);
    refreshDevices(startup: true);
  }

  Future<void> add(Server server) async {
    if (servers.contains(server)) return;

    servers.add(server);
    await save();
    await refreshDevices(ids: [server.id]);

    if (isMobilePlatform) {
      try {
        final notificationToken = await secureStorage.read(
          key: kStorageNotificationToken,
        );
        if (notificationToken != null) {
          await API.instance.registerNotificationToken(
            server,
            notificationToken,
          );
        }
      } catch (exception, stacktrace) {
        debugPrint(exception.toString());
        debugPrint(stacktrace.toString());
      }
    }
  }

  Future<void> remove(Server server) async {
    servers.remove(server);
    await save();

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

      final desktopProvider = LayoutsProvider.instance;
      await desktopProvider.removeDevices(server.devices);
    } catch (exception, stacktrace) {
      debugPrint(exception.toString());
      debugPrint(stacktrace.toString());
    }

    try {
      await API.instance.unregisterNotificationToken(server);
    } catch (exception, stacktrace) {
      debugPrint(exception.toString());
      debugPrint(stacktrace.toString());
    }
  }

  Future<void> update(Server server) async {
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

  Future<List<Server>> refreshDevices({
    bool startup = false,
    Iterable<String>? ids,
  }) async {
    final replaceHolders = <String, Server>{};
    await Future.wait(servers.map((target) async {
      if (ids != null && !ids.contains(target.id)) return;
      if (startup && !target.additionalSettings.connectAutomaticallyAtStartup) {
        target.devices.clear();
        target.online = false;
        return;
      }

      if (!loadingServers.contains(target.id)) {
        loadingServers.add(target.id);
        notifyListeners();
      }

      var (_, server) = await API.instance.checkServerCredentials(target);

      final devices = await API.instance.getDevices(server);
      if (devices != null) {
        debugPrint(devices.length.toString());
        replaceHolders[target.id] = server;
      }

      if (loadingServers.contains(server.id)) {
        loadingServers.remove(server.id);
        notifyListeners();
      }
    }));

    for (final entry in replaceHolders.entries) {
      final server = entry.value;
      final index = servers.indexWhere((s) => s.id == server.id);
      servers[index] = server;
    }

    await save();

    return servers;
  }

  Future<void> disconnectServer(Server server) async {
    final index = servers.indexWhere((s) => s.id == server.id);
    if (index == -1) return;

    final s = servers[index].copyWith(
      devices: [],
      online: false,
    );
    servers[index] = s;

    await save();
  }

  Future<void> reorder(int oldIndex, int newIndex) async {
    try {
      final server = servers.removeAt(oldIndex);
      servers.insert(newIndex, server);
      await save();
    } catch (error, stackTrace) {
      handleError(error, stackTrace, 'Error trying to reorder servers.');
    }
  }

  @override
  Future<void> save({bool notifyListeners = true}) async {
    await write({
      kStorageServers: jsonEncode(
        servers.map((server) => server.toJson()).toList(),
      ),
    });
    super.save(notifyListeners: notifyListeners);
  }

  @override
  Future<void> restore({bool notifyListeners = true}) async {
    final data = await secureStorage.read(key: kStorageServers);
    final serversData = data == null
        ? <Map<String, dynamic>>[]
        : List<Map<String, dynamic>>.from(
            await compute(jsonDecode, data) as List,
          );
    servers = serversData.map<Server>(Server.fromJson).toList();
    super.restore(notifyListeners: notifyListeners);
  }
}
