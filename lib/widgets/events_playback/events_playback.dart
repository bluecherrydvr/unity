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
import 'package:bluecherry_client/widgets/error_warning.dart';
import 'package:bluecherry_client/widgets/events_playback/events_playback_desktop.dart';
import 'package:bluecherry_client/widgets/events_playback/events_playback_mobile.dart';
import 'package:bluecherry_client/widgets/events_playback/timeline_controller.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

class FilterData {
  final List<String>? devices;

  final DateTime fromLimit;
  final DateTime toLimit;

  final DateTime from;
  final DateTime to;

  final bool allowAlarms;

  const FilterData({
    required this.devices,
    required this.fromLimit,
    required this.toLimit,
    required this.from,
    required this.to,
    required this.allowAlarms,
  });

  factory FilterData.standard({
    required List<String>? devices,
    required DateTime fromLimit,
    required DateTime toLimit,
  }) {
    final now = DateTime.now();
    final desiredFrom = now.subtract(const Duration(days: 1));

    return FilterData(
      allowAlarms: false,
      from: desiredFrom.isBefore(fromLimit) ? fromLimit : desiredFrom,
      to: now,
      fromLimit: fromLimit,
      toLimit: toLimit,
      devices: devices,
    );
  }

  FilterData copyWith({
    List<String>? devices,
    DateTime? fromLimit,
    DateTime? toLimit,
    DateTime? from,
    DateTime? to,
    bool? allowAlarms,
  }) {
    return FilterData(
      devices: devices ?? this.devices,
      fromLimit: fromLimit ?? this.fromLimit,
      toLimit: toLimit ?? this.toLimit,
      from: from ?? this.from,
      to: to ?? this.to,
      allowAlarms: allowAlarms ?? this.allowAlarms,
    );
  }

  @override
  String toString() {
    return 'FilterData(devices: $devices, fromLimit: $fromLimit, toLimit: $toLimit, from: $from, to: $to, allowAlarms: $allowAlarms)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is FilterData &&
        listEquals(other.devices, devices) &&
        other.fromLimit == fromLimit &&
        other.toLimit == toLimit &&
        other.from == from &&
        other.to == to &&
        other.allowAlarms == allowAlarms;
  }

  @override
  int get hashCode {
    return devices.hashCode ^
        fromLimit.hashCode ^
        toLimit.hashCode ^
        from.hashCode ^
        to.hashCode ^
        allowAlarms.hashCode;
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
      await Future.wait(ServersProvider.instance.servers.map((server) async {
        for (final server in ServersProvider.instance.servers) {
          try {
            final events = await API.instance.getEvents(
              await API.instance.checkServerCredentials(server),
            );

            for (final event in events) {
              if (!server.devices.any((d) => d.name == event.deviceName) ||
                  event.duration == Duration.zero) {
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
      }));
    } catch (exception, stacktrace) {
      debugPrint(exception.toString());
      debugPrint(stacktrace.toString());
    }

    if (eventsForDevice.isNotEmpty) {
      final allEvents = eventsForDevice.values.reduce((a, b) => a + b);
      final from = allEvents.oldest;
      final to = allEvents.newest;
      filterData = FilterData.standard(
        devices: null,
        fromLimit: from.published,
        toLimit: to.published,
      );

      await updateFilteredData();
    }

    home.notLoading(UnityLoadingReason.fetchingEventsPlayback);

    if (mounted) {
      setState(() {
        isFirstTimeLoading = false;
      });
    }
  }

  Future<void> updateFilteredData() async {
    filteredData = await compute(_filterData, [
      eventsForDevice,
      filterData,
    ]);
  }

  static EventsData _filterData(List data) {
    final eventsForDevice = data[0] as EventsData;
    final filterData = data[1] as FilterData?;

    return Map.fromEntries(
      eventsForDevice.entries.where((entry) {
        if (filterData == null) return true;

        if (filterData.devices != null &&
            !filterData.devices!.contains(entry.key)) {
          return false;
        }

        return true;
      }).map((e) {
        if (filterData == null) return e;

        final events = e.value.where((event) {
          final passDate = filterData.from.isBefore(event.published) &&
              filterData.to.isAfter(event.published);

          final passAlarm = filterData.allowAlarms ? true : !event.isAlarm;

          return passDate && passAlarm;
        }).toList();

        return MapEntry(e.key, events);
      }).where((e) => e.value.isNotEmpty),
    );
  }

  @override
  Widget build(BuildContext context) {
    final servers = context.watch<ServersProvider>();
    if (servers.servers.isEmpty) {
      return const NoServerWarning();
    }

    final home = context.watch<HomeProvider>();

    Future<void> onFilter(FilterData filter) async {
      home.loading(UnityLoadingReason.fetchingEventsPlayback);

      filterData = filter;
      await updateFilteredData();
      setState(() {});

      home.notLoading(UnityLoadingReason.fetchingEventsPlayback);
    }

    return LayoutBuilder(builder: (context, constraints) {
      if (constraints.maxWidth >= 800) {
        return EventsPlaybackDesktop(
          events: filteredData,
          filter: filterData,
          onFilter: onFilter,
        );
      } else {
        return EventsPlaybackMobile(
          events: filteredData,
          filter: filterData,
          onFilter: onFilter,
        );
      }
    });
  }
}

abstract class EventsPlaybackWidget extends StatefulWidget {
  final EventsData events;
  final FilterData? filter;
  final FutureValueChanged<FilterData> onFilter;

  const EventsPlaybackWidget({
    super.key,
    required this.events,
    required this.filter,
    required this.onFilter,
  });
}

abstract class EventsPlaybackState extends State<EventsPlaybackWidget> {
  late final timelineController = TimelineController();
  final focusNode = FocusNode();

  @override
  void didUpdateWidget(covariant EventsPlaybackWidget oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.filter != widget.filter) {
      initialize();
    }
  }

  void initialize() {
    final selectedIds = context.read<EventsProvider>().selectedIds;

    final realEvents = ({...widget.events}
      ..removeWhere((key, value) => !selectedIds.contains(key)));

    final allEvents = realEvents.isEmpty
        ? <Event>[]
        : realEvents.values.reduce((value, element) => value + element);

    timelineController.initialize(context, realEvents, allEvents);
  }

  @override
  void dispose() {
    timelineController.dispose();
    focusNode.dispose();
    super.dispose();
  }

  Widget buildChild(BuildContext context);

  @override
  Widget build(BuildContext context) {
    return KeyboardListener(
      focusNode: focusNode,
      autofocus: true,
      onKeyEvent: (event) {
        if (event is KeyDownEvent) {
          if (event.logicalKey == LogicalKeyboardKey.space) {
            if (timelineController.isPaused) {
              timelineController.play(context);
            } else {
              timelineController.pause();
            }
          } else if (event.logicalKey == LogicalKeyboardKey.keyM) {
            if (timelineController.isMuted) {
              timelineController.unmute();
            } else {
              timelineController.mute();
            }
          }
        }
      },
      child: ListenableBuilder(
        listenable: timelineController,
        builder: (context, child) => buildChild(context),
      ),
    );
  }

  Future<void> showFilter(BuildContext context) async {
    final initiallyPaused = timelineController.isPaused;
    timelineController.pause();

    var localFilter = widget.filter;
    await showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(builder: (context, setState) {
          return FilterDialog(
            filter: localFilter,
            onFilter: (filter) async => setState(() => localFilter = filter),
          );
        });
      },
    );
    if (widget.filter != localFilter && localFilter != null) {
      widget.onFilter(localFilter!);
    }

    // ignore: use_build_context_synchronously
    if (!initiallyPaused) timelineController.play(context);
  }
}
