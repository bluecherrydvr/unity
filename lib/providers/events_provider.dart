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

import 'package:bluecherry_client/api/api.dart';
import 'package:bluecherry_client/models/event.dart';
import 'package:bluecherry_client/models/server.dart';
import 'package:bluecherry_client/providers/app_provider_interface.dart';
import 'package:bluecherry_client/providers/server_provider.dart';
import 'package:bluecherry_client/screens/events_browser/filter.dart';
import 'package:bluecherry_client/utils/constants.dart';
import 'package:bluecherry_client/utils/storage.dart';
import 'package:flutter/foundation.dart';

typedef EventsData = Map<Server, List<Event>>;

class LoadedEvents {
  final EventsData events;
  final List<Server> invalidResponses;

  factory LoadedEvents() {
    return LoadedEvents.raw(
      events: {},
      invalidResponses: List.empty(growable: true),
    );
  }

  const LoadedEvents.raw({
    required this.events,
    required this.invalidResponses,
  });

  List<Event> get filteredEvents => events.values.expand((e) => e).toList();
}

class EventsProvider extends UnityProvider {
  EventsProvider._();

  static late final EventsProvider instance;
  static Future<EventsProvider> ensureInitialized() async {
    instance = EventsProvider._();
    await instance.initialize();
    debugPrint('EventsProvider initialized');
    return instance;
  }

  Set<String> selectedDevices = {};
  void toggleDevice(String device) {
    if (selectedDevices.contains(device)) {
      selectedDevices.remove(device);
    } else {
      selectedDevices.add(device);
    }
    save();
  }

  void selectDevices(Iterable<String> devices) {
    selectedDevices.addAll(devices);
    notifyListeners();
  }

  void unselectDevices(Iterable<String> devices) {
    selectedDevices.removeAll(devices);
    notifyListeners();
  }

  DateTime? startTime, endTime;
  EventsMinLevelFilter _levelFilter = EventsMinLevelFilter.any;
  EventsMinLevelFilter get levelFilter => _levelFilter;
  set levelFilter(EventsMinLevelFilter value) {
    _levelFilter = value;
    notifyListeners();
  }

  LoadedEvents? loadedEvents;

  @override
  Future<void> initialize() async {
    await tryReadStorage(() => initializeStorage(events, kStorageEvents));
  }

  @override
  Future<void> save({bool notifyListeners = true}) async {
    try {
      await events.write({});
    } catch (error, stackTrace) {
      debugPrint('Failed to save desktop view:\n $error\n$stackTrace');
    }

    super.save(notifyListeners: notifyListeners);
  }

  @override
  Future<void> restore({bool notifyListeners = true}) async {
    // final data = await tryReadStorage(() => desktopView.read());

    super.restore(notifyListeners: notifyListeners);
  }

  void _notify() => notifyListeners();
}

extension EventsScreenProvider on EventsProvider {
  Future<void> loadEvents() async {
    loadedEvents = LoadedEvents();
    _notify();

    // Load the events at the same time
    await Future.wait(ServersProvider.instance.servers.map((server) async {
      if (!server.online || server.devices.isEmpty) return;

      server = await API.instance.checkServerCredentials(server);

      try {
        final allowedDevices = server.devices
            .where((d) => d.status && selectedDevices.contains(d.streamURL));

        // Perform a query for each selected device
        await Future.wait(allowedDevices.map((device) async {
          final iterable = (await API.instance.getEvents(
            server,
            startTime: startTime,
            endTime: endTime,
            device: device,
          ))
              .toList()
            ..removeWhere((event) {
              switch (levelFilter) {
                case EventsMinLevelFilter.alarming:
                  if (event.isAlarm) return true;
                  break;
                case EventsMinLevelFilter.warning:
                  if (event.priority == EventPriority.warning) return true;
                  break;
                default:
                  break;
              }
              return false;
            });

          loadedEvents!.events[server] ??= [];
          loadedEvents!.events[server]!.addAll(iterable);
          _notify();
        }));
      } catch (exception, stacktrace) {
        debugPrint(exception.toString());
        debugPrint(stacktrace.toString());
        loadedEvents!.invalidResponses.add(server);
      }
    }));
  }
}
