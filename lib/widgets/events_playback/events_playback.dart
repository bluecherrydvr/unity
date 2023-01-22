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
import 'package:bluecherry_client/providers/events_playback_provider.dart';
import 'package:bluecherry_client/providers/home_provider.dart';
import 'package:bluecherry_client/providers/server_provider.dart';
import 'package:bluecherry_client/utils/extensions.dart';
import 'package:bluecherry_client/widgets/events_playback/events_playback_desktop.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class FilterData {
  final List<String>? devices;

  final DateTime fromLimit;
  final DateTime toLimit;

  final DateTime from;
  final DateTime to;

  const FilterData({
    required this.devices,
    required this.fromLimit,
    required this.toLimit,
    required this.from,
    required this.to,
  });

  FilterData copyWith({
    List<String>? devices,
    DateTime? fromLimit,
    DateTime? toLimit,
    DateTime? from,
    DateTime? to,
  }) {
    return FilterData(
      devices: devices ?? this.devices,
      fromLimit: fromLimit ?? this.fromLimit,
      toLimit: toLimit ?? this.toLimit,
      from: from ?? this.from,
      to: to ?? this.to,
    );
  }
}

// Device Id : Events for device
typedef EventsData = Map<String, List<Event>>;

class EventsPlayback extends StatefulWidget {
  const EventsPlayback({Key? key}) : super(key: key);

  @override
  State<EventsPlayback> createState() => _EventsPlaybackState();
}

class _EventsPlaybackState extends State<EventsPlayback> {
  bool isFirstTimeLoading = true;
  EventsData eventsForDevice = {};

  FilterData? filterData;
  EventsData filteredData = {};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => fetch());
  }

  Future<void> fetch() async {
    final home = context.read<HomeProvider>()
      ..loading(UnityLoadingReason.fetchingEventsPlayback);

    try {
      for (final server in ServersProvider.instance.servers) {
        try {
          final events = await API.instance.getEvents(
            await API.instance.checkServerCredentials(server),
          );

          for (final event in events) {
            if (!server.devices.any((d) => d.name == event.deviceName)
                //  || event.isAlarm
                ) {
              continue;
            }

            final device =
                server.devices.firstWhere((d) => d.name == event.deviceName);
            final id = EventsProvider.idForDevice(device);

            if (eventsForDevice.containsKey(id)) {
              eventsForDevice[id]!.add(event);
            } else {
              eventsForDevice[id] = [event];
            }
          }
        } catch (exception, stacktrace) {
          debugPrint(exception.toString());
          debugPrint(stacktrace.toString());
        }
      }
    } catch (exception, stacktrace) {
      debugPrint(exception.toString());
      debugPrint(stacktrace.toString());
    }

    final allEvents = eventsForDevice.values.reduce((a, b) => a + b);
    final from = allEvents.oldest;
    final to = allEvents.newest;
    filterData = FilterData(
      devices: null,
      from: from.published,
      fromLimit: from.published,
      to: to.published,
      toLimit: to.published,
    );

    updateFilteredData();

    home.notLoading(UnityLoadingReason.fetchingEventsPlayback);

    if (mounted) {
      setState(() {
        isFirstTimeLoading = false;
      });
    }
  }

  void updateFilteredData() {
    filteredData = Map.fromEntries(
      eventsForDevice.entries.where((entry) {
        if (filterData == null) return true;

        if (filterData!.devices != null &&
            !filterData!.devices!.contains(entry.key)) {
          return false;
        }

        return true;
      }).map((e) {
        if (filterData == null) return e;

        final events = e.value.where((event) {
          return filterData!.from.isBefore(event.published) &&
              filterData!.to.isAfter(event.published);
          // &&
          // !event.isAlarm;
        }).toList();

        return MapEntry(e.key, events);
      }),
    );
  }

  @override
  Widget build(BuildContext context) {
    final home = context.watch<HomeProvider>();

    return EventsPlaybackDesktop(
      events: filteredData,
      filter: filterData,
      onFilter: (filter) {
        home.loading(UnityLoadingReason.fetchingEventsPlayback);

        updateFilteredData();
        setState(() => filterData = filter);

        home.notLoading(UnityLoadingReason.fetchingEventsPlayback);
      },
    );
  }
}
