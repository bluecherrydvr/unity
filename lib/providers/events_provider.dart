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
  final List<Event> filteredEvents;

  factory LoadedEvents() {
    return LoadedEvents.raw(
      events: {},
      invalidResponses: List.empty(growable: true),
      filteredEvents: List.empty(growable: true),
    );
  }

  const LoadedEvents.raw({
    required this.events,
    required this.invalidResponses,
    required this.filteredEvents,
  });
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
    final data = await tryReadStorage(() => desktopView.read());

    super.restore(notifyListeners: notifyListeners);
  }
}

extension EventsScreenProvider on EventsProvider {
  Future<void> loadEvents({
    required DateTime? startTime,
    required DateTime? endTime,
    required EventsMinLevelFilter levelFilter,
  }) async {
    loadedEvents = LoadedEvents();

    // Load the events at the same time
    await Future.wait(ServersProvider.instance.servers.map((server) async {
      if (!server.online || server.devices.isEmpty) return;

      server = await API.instance.checkServerCredentials(server);

      try {
        final allowedDevices = server.devices
            .where((d) => d.status && selectedDevices.contains(d.streamURL));

        // Perform a query for each selected device
        await Future.wait(allowedDevices.map((device) async {
          final iterable = await API.instance.getEvents(
            server,
            startTime: startTime,
            endTime: endTime,
            device: device,
          );

          loadedEvents!.events[server] ??= [];
          loadedEvents!.events[server]!.addAll(iterable);
        }));
      } catch (exception, stacktrace) {
        debugPrint(exception.toString());
        debugPrint(stacktrace.toString());
        loadedEvents!.invalidResponses.add(server);
      }
    }));

    await computeFiltered(levelFilter);
  }

  Future<void> computeFiltered(EventsMinLevelFilter levelFilter) async {
    assert(loadedEvents != null);
    loadedEvents!.filteredEvents.clear();
    loadedEvents!.filteredEvents.addAll(await compute(_updateFiltered, {
      'events': loadedEvents!.events,
      'levelFilter': levelFilter,
      'selectedDevices': selectedDevices,
    }));
  }

  static Iterable<Event> _updateFiltered(Map<String, dynamic> data) {
    final events = data['events'] as EventsData;
    final levelFilter = data['levelFilter'] as EventsMinLevelFilter;
    final selectedDevices = data['selectedDevices'] as Set<String>;

    return events.values.expand((events) sync* {
      for (final event in events) {
        switch (levelFilter) {
          case EventsMinLevelFilter.alarming:
            if (!event.isAlarm) continue;
            break;
          case EventsMinLevelFilter.warning:
            if (event.priority != EventPriority.warning) continue;
            break;
          default:
            break;
        }

        // This is hacky. Maybe find a way to move this logic to [API.getEvents]
        // It'd also be useful to find a way to get the device at Event creation time
        final devices = event.server.devices.where((device) =>
            device.name.toLowerCase() == event.deviceName.toLowerCase());
        if (devices.isNotEmpty) {
          if (!selectedDevices.contains(devices.first.streamURL)) continue;
        }

        yield event;
      }
    });
  }
}
