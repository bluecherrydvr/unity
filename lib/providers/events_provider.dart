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
    save();
  }

  void unselectDevices(Iterable<String> devices) {
    selectedDevices.removeAll(devices);
    save();
  }

  DateTime? _startDate;
  DateTime get startDate =>
      _startDate ?? DateTime.timestamp().subtract(const Duration(hours: 24));
  set startDate(DateTime? value) {
    _startDate = value;
    notifyListeners();
  }

  DateTime? _endDate;
  DateTime get endDate => _endDate ?? DateTime.timestamp();
  set endDate(DateTime? value) {
    _endDate = value;
    notifyListeners();
  }

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
      await events.write({
        kStorageEvents: kStorageEvents,
        'selectedDevices': selectedDevices.toList(),
      });
    } catch (error, stackTrace) {
      debugPrint('Failed to save events:\n $error\n$stackTrace');
    }

    super.save(notifyListeners: notifyListeners);
  }

  @override
  Future<void> restore({bool notifyListeners = true}) async {
    final data = await tryReadStorage(() => events.read());

    selectedDevices =
        List<String>.from(data['selectedDevices'] as List).toSet();

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

      (_, server) = await API.instance.checkServerCredentials(server);

      try {
        final allowedDevices = server.devices
            .where((d) => d.status && selectedDevices.contains(d.streamURL));

        // Perform a query for each selected device
        await Future.wait(allowedDevices.map((device) async {
          final iterable = (await API.instance.getEvents(
            server,
            startTime: startDate,
            endTime: endDate,
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
