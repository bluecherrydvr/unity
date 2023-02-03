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
import 'package:bluecherry_client/providers/downloads.dart';
import 'package:bluecherry_client/providers/home_provider.dart';
import 'package:bluecherry_client/providers/server_provider.dart';
import 'package:bluecherry_client/providers/settings_provider.dart';
import 'package:bluecherry_client/utils/extensions.dart';
import 'package:bluecherry_client/utils/methods.dart';
import 'package:bluecherry_client/widgets/desktop_buttons.dart';
import 'package:bluecherry_client/widgets/downloads_manager.dart';
import 'package:bluecherry_client/widgets/error_warning.dart';
import 'package:bluecherry_client/widgets/events/event_player_desktop.dart';
import 'package:bluecherry_client/widgets/misc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:provider/provider.dart';
import 'package:unity_video_player/unity_video_player.dart';

part 'event_player_mobile.dart';
part 'events_screen_desktop.dart';
part 'events_screen_mobile.dart';

typedef EventsData = Map<Server, List<Event>>;

class EventsScreen extends StatefulWidget {
  const EventsScreen({Key? key}) : super(key: key);

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

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => fetch());
  }

  Future<void> fetch() async {
    final home = context.read<HomeProvider>()
      ..loading(UnityLoadingReason.fetchingEventsHistory);
    try {
      for (final server in ServersProvider.instance.servers) {
        try {
          final iterable = await API.instance.getEvents(
            await API.instance.checkServerCredentials(server),
          );
          events[server] = iterable.toList();
          invalid[server] = false;
        } catch (exception, stacktrace) {
          debugPrint(exception.toString());
          debugPrint(stacktrace.toString());
          invalid[server] = true;
        }
      }
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
    return Scaffold(
      appBar: showIf(
        isMobile,
        child: AppBar(
          leading: Scaffold.of(context).hasDrawer
              ? IconButton(
                  icon: const Icon(Icons.menu),
                  splashRadius: 20.0,
                  onPressed: Scaffold.of(context).openDrawer,
                )
              : null,
          title: Text(AppLocalizations.of(context).eventBrowser),
        ),
      ),
      body: () {
        if (ServersProvider.instance.servers.isEmpty) {
          return const NoServerWarning();
        }

        return LayoutBuilder(builder: (context, consts) {
          if (consts.maxWidth >= 800) {
            final servers = context.watch<ServersProvider>();

            return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              SizedBox(
                width: 220,
                child: Material(
                  color: Theme.of(context).appBarTheme.backgroundColor,
                  child: DropdownButtonHideUnderline(
                    child: Column(children: [
                      SubHeader(AppLocalizations.of(context).servers),
                      ...servers.servers.map((server) {
                        return CheckboxListTile(
                          value: allowedServers.contains(server),
                          onChanged: (v) {
                            setState(() {
                              if (v == null || !v) {
                                allowedServers.remove(server);
                              } else {
                                allowedServers.add(server);
                              }
                            });
                          },
                          controlAffinity: ListTileControlAffinity.leading,
                          contentPadding: const EdgeInsetsDirectional.only(
                            start: 8.0,
                            end: 16.0,
                          ),
                          title: Text(
                            server.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontSize: 14.0),
                          ),
                        );
                      }),
                      const Spacer(),
                      // TODO(bdlukaa): THIS IS BLOCKED BY https://github.com/flutter/flutter/pull/115806
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
                      const SizedBox(height: 16.0),
                    ]),
                  ),
                ),
              ),
              const VerticalDivider(width: 1),
              Expanded(
                child: EventsScreenDesktop(
                  events: events,
                  allowedServers: allowedServers,
                  timeFilter: timeFilter,
                  levelFilter: levelFilter,
                ),
              ),
            ]);
          } else {
            return EventsScreenMobile(
              events: events,
              refresh: fetch,
              isFirstTimeLoading: isFirstTimeLoading,
              invalid: invalid,
            );
          }
        });
      }(),
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
