// ignore_for_file: overridden_fields

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
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:provider/provider.dart';
import 'package:unity_video_player/unity_video_player.dart';

part 'event_player_mobile.dart';
part 'events_screen_desktop.dart';
part 'events_screen_mobile.dart';

typedef EventsData = Map<Server, List<Event>>;

class EventsScreen extends StatefulWidget {
  const EventsScreen({super.key});

  @override
  State<EventsScreen> createState() => _EventsScreenState();
}

class _EventsScreenState extends State<EventsScreen> {
  EventsTimeFilter timeFilter = EventsTimeFilter.last24Hours;
  EventsMinLevelFilter levelFilter = EventsMinLevelFilter.any;
  List<Server> allowedServers = [...ServersProvider.instance.servers];

  bool isFirstTimeLoading = true;
  final EventsData events = {};
  Map<Server, bool> invalid = {};

  /// The devices that can't be displayed in the list
  List<String> disabledDevices = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => fetch());
  }

  Future<void> fetch() async {
    final home = context.read<HomeProvider>()
      ..loading(UnityLoadingReason.fetchingEventsHistory);
    try {
      // Load the events at the same time
      await Future.wait(ServersProvider.instance.servers.map((server) async {
        try {
          final iterable = await API.instance.getEvents(
            await API.instance.checkServerCredentials(server),
          );
          if (mounted) {
            setState(() {
              events[server] = iterable.toList();
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
    home.notLoading(UnityLoadingReason.fetchingEventsHistory);
    if (mounted) {
      setState(() {
        isFirstTimeLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasDrawer = Scaffold.hasDrawer(context);
    final loc = AppLocalizations.of(context);

    if (ServersProvider.instance.servers.isEmpty) {
      return const NoServerWarning();
    }

    final now = DateTime.now();
    final hourRange = {
      EventsTimeFilter.last12Hours: 12,
      EventsTimeFilter.last24Hours: 24,
      EventsTimeFilter.last6Hours: 6,
      EventsTimeFilter.lastHour: 1,
      EventsTimeFilter.any: -1,
    }[timeFilter]!;

    final events = this.events.values.expand((events) sync* {
      for (final event in events) {
        // allow events from the allowed servers
        if (!allowedServers.any((element) => event.server.ip == element.ip)) {
          continue;
        }

        // allow events within the time range
        if (timeFilter != EventsTimeFilter.any) {
          if (now.difference(event.published).inHours > hourRange) {
            continue;
          }
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
    }).toList();

    return LayoutBuilder(builder: (context, consts) {
      if (hasDrawer || consts.maxWidth < kMobileBreakpoint.width) {
        return Column(children: [
          AppBar(
            leading: MaybeUnityDrawerButton(context),
            title: Text(loc.eventBrowser),
            actions: [
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
              events: events,
              loadedServers: this.events.keys,
              refresh: fetch,
              // isFirstTimeLoading: isFirstTimeLoading,
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
            child: DropdownButtonHideUnderline(
              child: Column(children: [
                SubHeader(
                  loc.servers,
                  height: 40.0,
                ),
                Expanded(
                  child: SingleChildScrollView(
                    child: buildTreeView(context, setState: setState),
                  ),
                ),
                const SubHeader('Time filter', height: 24.0),
                DropdownButton<EventsTimeFilter>(
                  isExpanded: true,
                  value: timeFilter,
                  items: const [
                    DropdownMenuItem(
                      value: EventsTimeFilter.any,
                      child: Text('Any'),
                    ),
                    DropdownMenuItem(
                      value: EventsTimeFilter.lastHour,
                      child: Text('Last hour'),
                    ),
                    DropdownMenuItem(
                      value: EventsTimeFilter.last6Hours,
                      child: Text('Last 6 hours'),
                    ),
                    DropdownMenuItem(
                      value: EventsTimeFilter.last12Hours,
                      child: Text('Last 12 hours'),
                    ),
                    DropdownMenuItem(
                      value: EventsTimeFilter.last24Hours,
                      child: Text('Last 24 hours'),
                    ),
                    // DropdownMenuItem(
                    //   child: Text('Select time range'),
                    //   value: EventsTimeFilter.custom,
                    // ),
                  ],
                  onChanged: (v) => setState(
                    () => timeFilter = v ?? timeFilter,
                  ),
                ),
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
                const SizedBox(height: 16.0),
              ]),
            ),
          ),
        ),
        const VerticalDivider(width: 1),
        Expanded(child: EventsScreenDesktop(events: events)),
      ]);
    });
  }

  Widget buildTreeView(
    BuildContext context, {
    double checkboxScale = 0.8,
    double gapCheckboxText = 0.0,
    required void Function(VoidCallback fn) setState,
  }) {
    final theme = Theme.of(context);
    final servers = context.watch<ServersProvider>();

    Widget buildCheckbox({
      required Server server,
      required bool? value,
      required ValueChanged<bool?> onChanged,
      required bool isError,
    }) {
      return Transform.scale(
        scale: checkboxScale,
        child: Checkbox(
          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
          visualDensity: const VisualDensity(
            horizontal: -4,
            vertical: -4,
          ),
          splashRadius: 0.0,
          tristate: true,
          value: value,
          isError: isError,
          onChanged: onChanged,
        ),
      );
    }

    return TreeView(
      indent: 56,
      iconSize: 18.0,
      nodes: servers.servers.map((server) {
        final isTriState = disabledDevices
            .any((d) => server.devices.any((device) => device.rtspURL == d));
        final isOffline = !server.online;

        return TreeNode(
          content: Row(children: [
            buildCheckbox(
              server: server,
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
            ),
            SizedBox(width: gapCheckboxText),
            Expanded(
              child: Text(
                server.name,
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
                softWrap: false,
              ),
            ),
            Text(
              '${server.devices.length}',
              style: theme.textTheme.labelSmall,
            ),
            const SizedBox(width: 10.0),
          ]),
          children: () {
            if (isOffline) {
              return <TreeNode>[];
            } else {
              return server.devices.sorted().map((device) {
                final enabled = isOffline || !allowedServers.contains(server)
                    ? false
                    : !disabledDevices.contains(device.rtspURL);
                return TreeNode(
                  content: Row(children: [
                    IgnorePointer(
                      ignoring: !device.status,
                      child: buildCheckbox(
                        server: server,
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
                      ),
                    ),
                    SizedBox(width: gapCheckboxText),
                    Text(
                      device.name,
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                      softWrap: false,
                    ),
                  ]),
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
      builder: (context) {
        final theme = Theme.of(context);
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
                Center(
                  child: Container(
                    width: 50,
                    height: 6.0,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(100),
                      color: theme.dividerColor,
                    ),
                    margin: const EdgeInsets.symmetric(
                      horizontal: 10.0,
                      vertical: 12.0,
                    ),
                  ),
                ),
                const SubHeader('Time filter'),
                DropdownButton<EventsTimeFilter>(
                  isExpanded: true,
                  value: timeFilter,
                  items: const [
                    DropdownMenuItem(
                      value: EventsTimeFilter.any,
                      child: Text('Any'),
                    ),
                    DropdownMenuItem(
                      value: EventsTimeFilter.lastHour,
                      child: Text('Last hour'),
                    ),
                    DropdownMenuItem(
                      value: EventsTimeFilter.last6Hours,
                      child: Text('Last 6 hours'),
                    ),
                    DropdownMenuItem(
                      value: EventsTimeFilter.last12Hours,
                      child: Text('Last 12 hours'),
                    ),
                    DropdownMenuItem(
                      value: EventsTimeFilter.last24Hours,
                      child: Text('Last 24 hours'),
                    ),
                    // DropdownMenuItem(
                    //   child: Text('Select time range'),
                    //   value: EventsTimeFilter.custom,
                    // ),
                  ],
                  onChanged: (v) => setState(
                    () => timeFilter = v ?? timeFilter,
                  ),
                ),
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

enum EventsTimeFilter {
  lastHour,
  last6Hours,
  last12Hours,
  last24Hours,
  any,
}

enum EventsMinLevelFilter {
  any,
  info,
  warning,
  alarming,
  critical,
}
