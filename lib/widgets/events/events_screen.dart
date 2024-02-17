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

import 'dart:async';
import 'dart:io';

import 'package:bluecherry_client/api/api.dart';
import 'package:bluecherry_client/models/event.dart';
import 'package:bluecherry_client/models/server.dart';
import 'package:bluecherry_client/providers/downloads_provider.dart';
import 'package:bluecherry_client/providers/home_provider.dart';
import 'package:bluecherry_client/providers/server_provider.dart';
import 'package:bluecherry_client/providers/settings_provider.dart';
import 'package:bluecherry_client/screens/downloads/indicators.dart';
import 'package:bluecherry_client/utils/constants.dart';
import 'package:bluecherry_client/utils/extensions.dart';
import 'package:bluecherry_client/utils/methods.dart';
import 'package:bluecherry_client/utils/widgets/squared_icon_button.dart';
import 'package:bluecherry_client/widgets/collapsable_sidebar.dart';
import 'package:bluecherry_client/widgets/desktop_buttons.dart';
import 'package:bluecherry_client/widgets/error_warning.dart';
import 'package:bluecherry_client/widgets/events/event_player_desktop.dart';
import 'package:bluecherry_client/widgets/events/filter.dart';
import 'package:bluecherry_client/widgets/misc.dart';
import 'package:bluecherry_client/widgets/search.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:unity_video_player/unity_video_player.dart';

part 'event_player_mobile.dart';
part 'events_screen_desktop.dart';
part 'events_screen_mobile.dart';

typedef EventsData = Map<Server, Iterable<Event>>;

final eventsScreenKey = GlobalKey<EventsScreenState>();

class EventsScreen extends StatefulWidget {
  const EventsScreen({required super.key});

  @override
  State<EventsScreen> createState() => EventsScreenState<EventsScreen>();
}

class EventsScreenState<T extends StatefulWidget> extends State<T> {
  DateTime? startTime, endTime;
  EventsMinLevelFilter levelFilter = EventsMinLevelFilter.any;

  final EventsData events = {};
  Map<Server, bool> invalid = {};

  List<Event> filteredEvents = [];

  /// The devices that can't be displayed in the list.
  ///
  /// The rtsp url is used to identify the device.
  Set<String> disabledDevices = {
    for (final server in ServersProvider.instance.servers)
      ...server.devices.map((d) => d.streamURL)
  };

  /// Fetches the events from the servers.
  Future<void> fetch() async {
    events.clear();
    filteredEvents = [];
    final home = context.read<HomeProvider>()
      ..loading(UnityLoadingReason.fetchingEventsHistory);
    // Load the events at the same time
    await Future.wait(ServersProvider.instance.servers.map((server) async {
      if (!server.online || server.devices.isEmpty) return;

      server = await API.instance.checkServerCredentials(server);

      try {
        final allowedDevices = server.devices
            .where((d) => d.status && !disabledDevices.contains(d.streamURL));

        // Perform a query for each selected device
        await Future.wait(allowedDevices.map((device) async {
          final iterable = await API.instance.getEvents(
            server,
            startTime: startTime,
            endTime: endTime,
            device: device,
          );
          if (mounted) {
            super.setState(() {
              events[server] ??= [];
              events[server] = [...events[server]!, ...iterable];
              invalid[server] = false;
            });
          }
        }));
      } catch (exception, stacktrace) {
        debugPrint(exception.toString());
        debugPrint(stacktrace.toString());
        invalid[server] = true;
      }
    }));

    await computeFiltered();

    home.notLoading(UnityLoadingReason.fetchingEventsHistory);
  }

  Future<void> computeFiltered() async {
    filteredEvents = (await compute(_updateFiltered, {
      'events': events,
      'levelFilter': levelFilter,
      'disabledDevices': disabledDevices,
    }))
        .toList();
  }

  static Iterable<Event> _updateFiltered(Map<String, dynamic> data) {
    final events = data['events'] as EventsData;
    final levelFilter = data['levelFilter'] as EventsMinLevelFilter;
    final disabledDevices = data['disabledDevices'] as Set<String>;

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
          if (disabledDevices.contains(devices.first.streamURL)) continue;
        }

        yield event;
      }
    });
  }

  /// We override setState because we need to update the filtered events
  @override
  void setState(VoidCallback fn) {
    super.setState(fn);
    // computes the events based on the filter, then update the screen
    computeFiltered().then((_) {
      if (mounted) super.setState(() {});
    });
  }

  bool searchVisible = false;
  final searchController = TextEditingController();
  final searchFocusNode = FocusNode();
  String searchQuery = '';

  @override
  Widget build(BuildContext context) {
    if (ServersProvider.instance.servers.isEmpty) {
      return const NoServerWarning();
    }

    final hasDrawer = Scaffold.hasDrawer(context);
    final loc = AppLocalizations.of(context);
    final isLoading = HomeProvider.instance.isLoadingFor(
      UnityLoadingReason.fetchingEventsHistory,
    );

    return LayoutBuilder(builder: (context, consts) {
      if (hasDrawer || consts.maxWidth < kMobileBreakpoint.width) {
        return EventsScreenMobile(
          events: filteredEvents,
          loadedServers: events.keys,
          refresh: fetch,
          invalid: invalid,
          showFilter: () => showMobileFilter(context),
        );
      }

      return Material(
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          ConstrainedBox(
            constraints: kSidebarConstraints,
            child: SafeArea(
              child: DropdownButtonHideUnderline(
                child: Column(children: [
                  SubHeader(
                    loc.servers,
                    height: 38.0,
                    trailing: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Padding(
                          padding: const EdgeInsetsDirectional.only(end: 6.0),
                          child: SearchToggleButton(
                            searchVisible: searchVisible,
                            onPressed: () {
                              setState(() => searchVisible = !searchVisible);
                              if (searchVisible) {
                                searchFocusNode.requestFocus();
                              }
                            },
                          ),
                        ),
                        Text(
                          '${ServersProvider.instance.servers.length}',
                        ),
                      ],
                    ),
                  ),
                  ToggleSearchBar(
                    searchVisible: searchVisible,
                    searchController: searchController,
                    searchFocusNode: searchFocusNode,
                    onSearchChanged: (query) {
                      super.setState(() => searchQuery = query);
                    },
                  ),
                  Expanded(
                    child: SingleChildScrollView(
                      child: EventsDevicesPicker(
                        events: events,
                        disabledDevices: disabledDevices,
                        onDisabledDeviceAdded: (device) =>
                            setState(() => disabledDevices.add(device)),
                        onDisabledDeviceRemoved: (device) =>
                            setState(() => disabledDevices.remove(device)),
                        searchQuery: searchQuery,
                      ),
                    ),
                  ),
                  SubHeader(loc.timeFilter, height: 24.0),
                  buildTimeFilterTile(),
                  // const SubHeader('Minimum level', height: 24.0),
                  // DropdownButton<EventsMinLevelFilter>(
                  //   isExpanded: true,
                  //   value: levelFilter,
                  //   items: EventsMinLevelFilter.values.map((level) {
                  //     return DropdownMenuItem(
                  //       value: level,
                  //       child: Text(level.name.uppercaseFirst()),
                  //     );
                  //   }).toList(),
                  //   onChanged: (v) => setState(
                  //     () => levelFilter = v ?? levelFilter,
                  //   ),
                  // ),
                  const SizedBox(height: 8.0),
                  FilledButton(
                    onPressed: isLoading ? null : fetch,
                    child: Text(loc.filter),
                  ),
                  const SizedBox(height: 12.0),
                ]),
              ),
            ),
          ),
          Expanded(
            child: Card(
              margin: EdgeInsets.zero,
              shape: const RoundedRectangleBorder(
                borderRadius: BorderRadiusDirectional.only(
                  topStart: Radius.circular(12.0),
                ),
              ),
              child: EventsScreenDesktop(events: filteredEvents),
            ),
          ),
        ]),
      );
    });
  }

  Widget buildTimeFilterTile({VoidCallback? onSelect}) {
    return Builder(builder: (context) {
      final loc = AppLocalizations.of(context);
      return ListTile(
        title: Text(() {
          final formatter = DateFormat.MEd();
          if (startTime == null || endTime == null) {
            return loc.today;
          } else if (DateUtils.isSameDay(startTime, endTime)) {
            return formatter.format(startTime!);
          } else {
            return loc.fromToDate(
              formatter.format(startTime!),
              formatter.format(endTime!),
            );
          }
        }()),
        onTap: () async {
          final range = await showDateRangePicker(
            context: context,
            firstDate: DateTime(1970),
            lastDate: DateTime.now(),
            initialEntryMode: DatePickerEntryMode.calendarOnly,
            initialDateRange: startTime == null || endTime == null
                ? null
                : DateTimeRange(start: startTime!, end: endTime!),
          );
          if (range != null) {
            setState(() {
              startTime = range.start;
              endTime = range.end;
            });
            onSelect?.call();
          }
        },
      );
    });
  }

  Future<void> showMobileFilter(BuildContext context) async {
    /// This is used to update the screen when the bottom sheet is closed.
    var hasChanged = false;

    await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) {
        return DraggableScrollableSheet(
          expand: false,
          maxChildSize: 0.85,
          initialChildSize: 0.85,
          builder: (context, controller) {
            return PrimaryScrollController(
              controller: controller,
              child: MobileFilterSheet(
                events: events,
                disabledDevices: disabledDevices,
                onDisabledDeviceAdded: (device) {
                  setState(() => disabledDevices.add(device));
                  hasChanged = true;
                },
                onDisabledDeviceRemoved: (device) {
                  setState(() => disabledDevices.remove(device));
                  hasChanged = true;
                },
                levelFilter: levelFilter,
                onLevelFilterChanged: (filter) {
                  setState(() => levelFilter = filter);
                  hasChanged = true;
                },
                timeFilterTile: buildTimeFilterTile(onSelect: () {
                  hasChanged = true;
                }),
              ),
            );
          },
        );
      },
    );

    if (hasChanged) fetch();
  }
}
