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
import 'package:bluecherry_client/models/event.dart';
import 'package:bluecherry_client/models/server.dart';
import 'package:bluecherry_client/providers/app_provider_interface.dart';
import 'package:bluecherry_client/providers/server_provider.dart';
import 'package:bluecherry_client/screens/events_browser/filter.dart';
import 'package:bluecherry_client/utils/constants.dart';
import 'package:bluecherry_client/utils/extensions.dart';
import 'package:bluecherry_client/utils/logging.dart' as logging;
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

  /// Returns `true` if the events can be fetched.
  bool get canFetch =>
      selectedDevices.isNotEmpty &&
      (loadedEvents == null || loadedEvents!.events.isEmpty);

  DateTime? _startDate;
  DateTime? get startDate => _startDate;
  set startDate(DateTime? value) {
    _startDate = value;
    notifyListeners();
  }

  DateTime? _endDate;
  DateTime? get endDate => _endDate;
  set endDate(DateTime? value) {
    _endDate = value;
    notifyListeners();
  }

  bool get isDateSet => _startDate != null && _endDate != null;

  /// Returns the oldest date of the selected devices.
  DateTime? get oldestDate {
    final devices = ServersProvider.instance.servers
        .expand((server) => server.devices)
        .where((device) => selectedDevices.contains(device.streamURL));
    if (devices.isEmpty) return null;

    DateTime? oldest;
    for (final device in devices) {
      final deviceOldest = device.oldestRecording;
      if (deviceOldest == null) continue;

      if (oldest == null || deviceOldest.isBefore(oldest)) {
        oldest = deviceOldest;
      }
    }
    return oldest;
  }

  EventsMinLevelFilter _levelFilter = EventsMinLevelFilter.any;
  EventsMinLevelFilter get levelFilter => _levelFilter;
  set levelFilter(EventsMinLevelFilter value) {
    _levelFilter = value;
    notifyListeners();
  }

  int _eventTypeFilter = -1;
  int get eventTypeFilter => _eventTypeFilter;
  set eventTypeFilter(int value) {
    _eventTypeFilter = value;
    notifyListeners();
  }

  LoadedEvents? loadedEvents;

  @override
  Future<void> initialize() async {
    await initializeStorage(kStorageEvents);
  }

  @override
  Future<void> save({bool notifyListeners = true}) async {
    await write({'selectedDevices': jsonEncode(selectedDevices.toList())});

    super.save(notifyListeners: notifyListeners);
  }

  @override
  Future<void> restore({bool notifyListeners = true}) async {
    final data = await secureStorage.read(key: 'selectedDevices');
    if (data != null) {
      selectedDevices = Set<String>.from(jsonDecode(data) as List);
    }
    selectedDevices.removeWhere((device) {
      final server = ServersProvider.instance.servers.firstWhereOrNull(
        (server) => server.devices.any((d) => d.streamURL == device),
      );
      return server == null ||
          !server.devices.any((d) {
            if (d.streamURL == device) {
              return d.status;
            } else {
              return false;
            }
          });
    });

    super.restore(notifyListeners: notifyListeners);
  }

  void _notify() => notifyListeners();
}

extension EventsScreenProvider on EventsProvider {
  Future<void> loadEvents({DateTime? startDate, DateTime? endDate}) async {
    loadedEvents = LoadedEvents();
    _notify();

    startDate ??= this.startDate;
    endDate ??= this.endDate;

    // Load the events at the same time
    await Future.wait(
      ServersProvider.instance.servers.map((server) async {
        if (!server.online || server.devices.isEmpty) return;

        (_, server) = await API.instance.checkServerCredentials(server);

        try {
          final allowedDevices = server.devices.where(
            (d) => d.status && selectedDevices.contains(d.streamURL),
          );

          // Perform a query for each selected device
          await Future.wait(
            allowedDevices.map((device) async {
              final iterable =
                  (await API.instance.getEvents(
                      server,
                      startTime: startDate,
                      endTime: endDate,
                      device: device,
                    )).toList()
                    ..removeWhere((event) {
                      switch (levelFilter) {
                        case EventsMinLevelFilter.alarming:
                          if (event.isAlarm) return true;
                          break;
                        case EventsMinLevelFilter.warning:
                          if (event.priority == EventPriority.warning) {
                            return true;
                          }
                          break;
                        default:
                          break;
                      }
                      return false;
                    })
                    ..removeWhere((event) {
                      if (!isDateSet) return false;

                      final isToRemove =
                          event.published.toUtc().isBefore(
                            startDate!.toUtc(),
                          ) ||
                          event.updated.toUtc().isAfter(endDate!.toUtc());

                      if (isToRemove) {
                        logging.writeLogToFile(
                          'Removing future event ${event.id} '
                          'from ${event.server.name}/${event.deviceID}: '
                          '{raw: ${event.publishedRaw}, parsed: ${event.published}}.',
                          print: true,
                        );
                      }
                      return isToRemove;
                    })
                    ..sort((a, b) => a.published.compareTo(b.published));

              loadedEvents!.events[server] ??= [];
              loadedEvents!.events[server]!.addAll(iterable);

              if (iterable.isNotEmpty) {
                logging.writeLogToFile(
                  'First event: ${iterable.first}',
                  print: true,
                );
                logging.writeLogToFile(
                  'Last event: ${iterable.last}',
                  print: true,
                );
              }
              _notify();
            }),
          );
        } catch (error, stack) {
          logging.handleError(error, stack, 'Error loading events for $server');
          loadedEvents!.invalidResponses.add(server);
        }
      }),
    );
  }
}
