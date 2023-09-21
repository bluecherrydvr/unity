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
import 'package:bluecherry_client/utils/constants.dart';
import 'package:bluecherry_client/utils/extensions.dart';
import 'package:bluecherry_client/utils/methods.dart';
import 'package:bluecherry_client/utils/tree_view/tree_view.dart';
import 'package:bluecherry_client/widgets/desktop_buttons.dart';
import 'package:bluecherry_client/widgets/downloads_manager.dart';
import 'package:bluecherry_client/widgets/error_warning.dart';
import 'package:bluecherry_client/widgets/events/event_player_desktop.dart';
import 'package:bluecherry_client/widgets/misc.dart';
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

final eventsScreenKey = GlobalKey<_EventsScreenState>();

class EventsScreen extends StatefulWidget {
  const EventsScreen({required super.key});

  @override
  State<EventsScreen> createState() => _EventsScreenState();
}

class _EventsScreenState extends State<EventsScreen> {
  DateTime? startTime, endTime;
  EventsMinLevelFilter levelFilter = EventsMinLevelFilter.any;
  List<Server> allowedServers = [...ServersProvider.instance.servers];

  final EventsData events = {};
  Map<Server, bool> invalid = {};

  Iterable<Event> filteredEvents = [];

  /// The devices that can't be displayed in the list.
  ///
  /// The rtsp url is used to identify the device.
  List<String> disabledDevices = [
    for (final server in ServersProvider.instance.servers)
      ...server.devices.map((d) => d.rtspURL)
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => fetch());
  }

  Future<void> fetch() async {
    events.clear();
    filteredEvents = [];
    final home = context.read<HomeProvider>()
      ..loading(UnityLoadingReason.fetchingEventsHistory);
    try {
      // Load the events at the same time
      await Future.wait(ServersProvider.instance.servers.map((server) async {
        if (!server.online || !allowedServers.contains(server)) return;

        try {
          final allowedDevices = server.devices
              .where((d) => d.status && !disabledDevices.contains(d.rtspURL));
          final iterable = await API.instance.getEvents(
            await API.instance.checkServerCredentials(server),
            startTime: startTime,
            endTime: endTime,
            device: allowedDevices.length == 1 ? allowedDevices.first : null,
          );
          if (mounted) {
            super.setState(() {
              events[server] = iterable;
              invalid[server] = false;
            });
          }
        } catch (exception, stacktrace) {
          debugPrint(exception.toString());
          debugPrint(stacktrace.toString());
          invalid[server] = true;
        }
      }));
    } catch (exception, stacktrace) {
      debugPrint(exception.toString());
      debugPrint(stacktrace.toString());
    }

    await computeFiltered();

    home.notLoading(UnityLoadingReason.fetchingEventsHistory);
  }

  Future<void> computeFiltered() async {
    filteredEvents = await compute(_updateFiltered, {
      'events': events,
      'allowedServers': allowedServers,
      'levelFilter': levelFilter,
      'disabledDevices': disabledDevices,
    });
  }

  static Iterable<Event> _updateFiltered(Map<String, dynamic> data) {
    final events = data['events'] as EventsData;
    final allowedServers = data['allowedServers'] as List<Server>;
    final levelFilter = data['levelFilter'] as EventsMinLevelFilter;
    final disabledDevices = data['disabledDevices'] as List<String>;

    return events.values.expand((events) sync* {
      for (final event in events) {
        // allow events from the allowed servers
        if (!allowedServers.any((element) => event.server.ip == element.ip)) {
          continue;
        }

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
          if (disabledDevices.contains(devices.first.rtspURL)) continue;
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
    final home = context.read<HomeProvider>()
      ..loading(UnityLoadingReason.fetchingEventsHistory);
    computeFiltered().then((_) {
      if (mounted) super.setState(() {});
      home.notLoading(UnityLoadingReason.fetchingEventsHistory);
    });
  }

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
        return Column(children: [
          AppBar(
            leading: MaybeUnityDrawerButton(context),
            title: Text(loc.eventBrowser),
            actions: [
              IconButton(
                onPressed: () {
                  eventsScreenKey.currentState?.fetch();
                },
                icon: const Icon(Icons.refresh),
                iconSize: 20.0,
                tooltip: loc.refresh,
              ),
              Padding(
                padding: const EdgeInsetsDirectional.only(end: 15.0),
                child: IconButton(
                  icon: const Icon(Icons.filter_list),
                  tooltip: loc.filter,
                  onPressed: () => showMobileFilter(context),
                ),
              ),
            ],
          ),
          Expanded(
            child: EventsScreenMobile(
              events: filteredEvents,
              loadedServers: events.keys,
              refresh: fetch,
              invalid: invalid,
            ),
          ),
        ]);
      }

      return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        SizedBox(
          width: 220,
          child: Card(
            margin: EdgeInsets.zero,
            shape: const RoundedRectangleBorder(),
            child: SafeArea(
              child: DropdownButtonHideUnderline(
                child: Column(children: [
                  SubHeader(
                    loc.servers,
                    height: 38.0,
                    trailing:
                        Text('${ServersProvider.instance.servers.length}'),
                  ),
                  Expanded(
                    child: SingleChildScrollView(
                      child: buildTreeView(context, setState: setState),
                    ),
                  ),
                  SubHeader(loc.timeFilter, height: 24.0),
                  buildTimeFilterTile(),
                  const SubHeader('Minimum level', height: 24.0),
                  DropdownButton<EventsMinLevelFilter>(
                    isExpanded: true,
                    value: levelFilter,
                    items: EventsMinLevelFilter.values.map((level) {
                      return DropdownMenuItem(
                        value: level,
                        child: Text(level.name.uppercaseFirst()),
                      );
                    }).toList(),
                    onChanged: (v) => setState(
                      () => levelFilter = v ?? levelFilter,
                    ),
                  ),
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
        ),
        const VerticalDivider(width: 1),
        Expanded(child: EventsScreenDesktop(events: filteredEvents)),
      ]);
    });
  }

  Widget buildTimeFilterTile() {
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
          );
          if (range != null) {
            startTime = range.start;
            endTime = range.end;
          }
        },
      );
    });
  }

  Widget buildTreeView(
    BuildContext context, {
    double checkboxScale = 0.8,
    double gapCheckboxText = 0.0,
    required void Function(VoidCallback fn) setState,
  }) {
    final servers = context.watch<ServersProvider>();

    return TreeView(
      indent: 56,
      iconSize: 18.0,
      nodes: servers.servers.map((server) {
        final isTriState = disabledDevices
            .any((d) => server.devices.any((device) => device.rtspURL == d));
        final isOffline = !server.online;
        final serverEvents = events[server];

        return TreeNode(
          content: buildCheckbox(
            value: !allowedServers.contains(server) || isOffline
                ? false
                : isTriState
                    ? null
                    : true,
            isError: isOffline,
            onChanged: (v) {
              setState(() {
                if (isTriState) {
                  disabledDevices.removeWhere((d) =>
                      server.devices.any((device) => device.rtspURL == d));
                } else if (v == null || !v) {
                  allowedServers.remove(server);
                } else {
                  allowedServers.add(server);
                }
              });
            },
            checkboxScale: checkboxScale,
            text: server.name,
            secondaryText: isOffline ? null : '${server.devices.length}',
            gapCheckboxText: gapCheckboxText,
            textFit: FlexFit.tight,
          ),
          children: () {
            if (isOffline) {
              return <TreeNode>[];
            } else {
              return server.devices.sorted().map((device) {
                final enabled = isOffline || !allowedServers.contains(server)
                    ? false
                    : !disabledDevices.contains(device.rtspURL);
                final eventsForDevice =
                    serverEvents?.where((event) => event.deviceID == device.id);
                return TreeNode(
                  content: IgnorePointer(
                    ignoring: !device.status,
                    child: buildCheckbox(
                      value: device.status ? enabled : false,
                      isError: !device.status,
                      onChanged: (v) {
                        if (!device.status) return;

                        setState(() {
                          if (enabled) {
                            disabledDevices.add(device.rtspURL);
                          } else {
                            disabledDevices.remove(device.rtspURL);
                          }
                        });
                      },
                      checkboxScale: checkboxScale,
                      text: device.name,
                      secondaryText: eventsForDevice != null && device.status
                          ? ' (${eventsForDevice.length})'
                          : null,
                      gapCheckboxText: gapCheckboxText,
                    ),
                  ),
                );
              }).toList();
            }
          }(),
        );
      }).toList(),
    );
  }

  Future<void> showMobileFilter(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) {
        final loc = AppLocalizations.of(context);

        return DraggableScrollableSheet(
          expand: false,
          maxChildSize: 0.8,
          initialChildSize: 0.7,
          builder: (context, controller) {
            return StatefulBuilder(builder: (context, localSetState) {
              /// This updates the screen in the back and the bottom sheet.
              /// This is used to avoid the creation of a new StatefulWidget
              void setState(VoidCallback fn) {
                this.setState(fn);
                localSetState(fn);
              }

              return ListView(controller: controller, children: [
                SubHeader(loc.timeFilter),
                buildTimeFilterTile(),
                const SubHeader('Minimum level'),
                DropdownButton<EventsMinLevelFilter>(
                  isExpanded: true,
                  value: levelFilter,
                  items: EventsMinLevelFilter.values.map((level) {
                    return DropdownMenuItem(
                      value: level,
                      child: Text(level.name.uppercaseFirst()),
                    );
                  }).toList(),
                  onChanged: (v) => setState(
                    () => levelFilter = v ?? levelFilter,
                  ),
                ),
                SubHeader(loc.servers),
                buildTreeView(
                  context,
                  gapCheckboxText: 10.0,
                  checkboxScale: 1.15,
                  setState: setState,
                ),
              ]);
            });
          },
        );
      },
    );
  }
}

enum EventsMinLevelFilter {
  any,
  info,
  warning,
  alarming,
  critical,
}
