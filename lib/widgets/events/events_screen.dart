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
import 'package:bluecherry_client/utils/extensions.dart';
import 'package:bluecherry_client/widgets/misc.dart';
import 'package:bluecherry_client/widgets/video_player.dart';
import 'package:intl/intl.dart';
import 'package:flutter/material.dart';
import 'package:fijkplayer/fijkplayer.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

import 'package:bluecherry_client/providers/server_provider.dart';
import 'package:bluecherry_client/models/server.dart';
import 'package:bluecherry_client/models/event.dart';
import 'package:bluecherry_client/providers/settings_provider.dart';
import 'package:bluecherry_client/api/api.dart';

part 'event_player.dart';
part 'events_screen_desktop.dart';

typedef EventsData = Map<Server, List<Event>>;

class EventsScreen extends StatefulWidget {
  const EventsScreen({Key? key}) : super(key: key);

  @override
  State<EventsScreen> createState() => _EventsScreenState();
}

class _EventsScreenState extends State<EventsScreen> {
  bool isFirstTimeLoading = true;
  final EventsData events = {};
  Map<Server, bool> invalid = {};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await fetch();
    });
  }

  Future<void> fetch() async {
    try {
      for (final server in ServersProvider.instance.servers) {
        try {
          final iterable = await API.instance.getEvents(
            await API.instance.checkServerCredentials(server),
          );
          events[server] = iterable.toList().cast<Event>();
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
    if (mounted) {
      setState(() {
        isFirstTimeLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: isDesktop
          ? null
          : AppBar(
              leading: Scaffold.of(context).hasDrawer
                  ? IconButton(
                      icon: const Icon(Icons.menu),
                      splashRadius: 20.0,
                      onPressed: Scaffold.of(context).openDrawer,
                    )
                  : null,
              title: Text(AppLocalizations.of(context).eventBrowser),
            ),
      body: () {
        if (ServersProvider.instance.servers.isEmpty) {
          return Center(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.dns,
                  size: 72.0,
                  color: Theme.of(context).iconTheme.color?.withOpacity(0.8),
                ),
                const SizedBox(height: 8.0),
                Text(
                  AppLocalizations.of(context).noServersAdded,
                  style: Theme.of(context)
                      .textTheme
                      .headline5
                      ?.copyWith(fontSize: 16.0),
                ),
              ],
            ),
          );
        }

        return LayoutBuilder(builder: (context, consts) {
          if (consts.maxWidth >= 800) {
            return EventsScreenDesktop(events: events);
          } else {
            return RefreshIndicator(
              onRefresh: fetch,
              child: ListView.builder(
                physics: const AlwaysScrollableScrollPhysics(),
                itemCount: ServersProvider.instance.servers.length,
                itemBuilder: (context, index) {
                  final server = ServersProvider.instance.servers[index];
                  return ExpansionTile(
                    initiallyExpanded:
                        ServersProvider.instance.servers.length.compareTo(1) ==
                            0,
                    maintainState: true,
                    leading: CircleAvatar(
                      child: Icon(
                        Icons.language,
                        color: Theme.of(context).iconTheme.color,
                      ),
                      backgroundColor: Colors.transparent,
                    ),
                    title: Row(children: [
                      Expanded(child: Text(server.name)),
                      if (isDesktop)
                        IconButton(
                          onPressed: fetch,
                          tooltip: 'Refresh',
                          icon: const Icon(Icons.refresh),
                        ),
                    ]),
                    subtitle: server.name != server.ip ? Text(server.ip) : null,
                    children: isFirstTimeLoading
                        ? <Widget>[
                            const SizedBox(
                              height: 96.0,
                              child: Center(
                                child: CircularProgressIndicator(),
                              ),
                            )
                          ]
                        : events[server]?.map((event) {
                              return ListTile(
                                contentPadding:
                                    const EdgeInsetsDirectional.only(
                                  start: 64.0,
                                  end: 16.0,
                                ),
                                onTap: () async {
                                  await Navigator.of(context).pushNamed(
                                    '/events',
                                    arguments: event,
                                  );
                                },
                                title: Text(event.deviceName),
                                isThreeLine: true,
                                subtitle: Text(
                                  [
                                    event.title.split('event on').first.trim(),
                                    DateFormat(
                                          SettingsProvider
                                              .instance.dateFormat.pattern,
                                        ).format(event.updated) +
                                        ' ' +
                                        DateFormat(
                                          SettingsProvider
                                              .instance.timeFormat.pattern,
                                        ).format(event.updated).toUpperCase(),
                                  ].join('\n'),
                                  overflow: TextOverflow.ellipsis,
                                ),
                                leading: CircleAvatar(
                                  child: Icon(
                                    Icons.warning,
                                    color: Colors.amber.shade300,
                                  ),
                                  backgroundColor: Colors.transparent,
                                ),
                              );
                            }).toList() ??
                            [
                              if (invalid[server] ?? true)
                                SizedBox(
                                  height: 72.0,
                                  child: Center(
                                    child: Text(
                                      AppLocalizations.of(context)
                                          .invalidResponse,
                                      style: Theme.of(context)
                                          .textTheme
                                          .headline5
                                          ?.copyWith(fontSize: 16.0),
                                    ),
                                  ),
                                )
                              else
                                SizedBox(
                                  height: 72.0,
                                  child: Center(
                                    child: Text(
                                      AppLocalizations.of(context)
                                          .noEventsFound,
                                      style: Theme.of(context)
                                          .textTheme
                                          .headline5
                                          ?.copyWith(fontSize: 16.0),
                                    ),
                                  ),
                                ),
                            ],
                  );
                },
              ),
            );
          }
        });
      }(),
    );
  }
}
