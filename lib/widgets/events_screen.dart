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

import 'package:intl/intl.dart';
import 'package:flutter/material.dart';
import 'package:fijkplayer/fijkplayer.dart';
import 'package:fijkplayer_skin/fijkplayer_skin.dart';
import 'package:fijkplayer_skin/schema.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

import 'package:bluecherry_client/providers/server_provider.dart';
import 'package:bluecherry_client/models/server.dart';
import 'package:bluecherry_client/models/event.dart';
import 'package:bluecherry_client/providers/settings_provider.dart';
import 'package:bluecherry_client/api/api.dart';

class EventsScreen extends StatefulWidget {
  const EventsScreen({Key? key}) : super(key: key);

  @override
  State<EventsScreen> createState() => _EventsScreenState();
}

class _EventsScreenState extends State<EventsScreen> {
  bool isFirstTimeLoading = true;
  final Map<Server, List<Event>> events = {};
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
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.menu),
          splashRadius: 20.0,
          onPressed: Scaffold.of(context).openDrawer,
        ),
        title: Text(AppLocalizations.of(context).eventBrowser),
      ),
      body: ServersProvider.instance.servers.isEmpty
          ? Center(
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
            )
          : RefreshIndicator(
              onRefresh: fetch,
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: ServersProvider.instance.servers
                    .map(
                      (e) => ExpansionTile(
                        initiallyExpanded: ServersProvider
                                .instance.servers.length
                                .compareTo(1) ==
                            0,
                        maintainState: true,
                        leading: CircleAvatar(
                          child: Icon(
                            Icons.language,
                            color: Theme.of(context).iconTheme.color,
                          ),
                          backgroundColor: Colors.transparent,
                        ),
                        title: Text(
                          e.name,
                        ),
                        subtitle: e.name != e.ip
                            ? Text(
                                e.ip,
                              )
                            : null,
                        children: isFirstTimeLoading
                            ? <Widget>[
                                const SizedBox(
                                  height: 96.0,
                                  child: Center(
                                    child: CircularProgressIndicator(),
                                  ),
                                )
                              ]
                            : events[e]
                                    ?.map(
                                      (event) => ListTile(
                                        onTap: () {
                                          Navigator.of(context).push(
                                            MaterialPageRoute(
                                              builder: (context) =>
                                                  EventPlayerScreen(
                                                      event: event),
                                            ),
                                          );
                                        },
                                        title: Text(
                                          event.title
                                              .split('device')
                                              .last
                                              .trim()
                                              .split(' ')
                                              .map((e) => e.isEmpty
                                                  ? ''
                                                  : e[0].toUpperCase() +
                                                      e.substring(1))
                                              .join(' '),
                                        ),
                                        isThreeLine: true,
                                        subtitle: Text(
                                          [
                                            event.title
                                                .split('event on')
                                                .first
                                                .trim(),
                                            DateFormat(
                                                  SettingsProvider.instance
                                                      .dateFormat.pattern,
                                                ).format(event.updated) +
                                                ' ' +
                                                DateFormat(
                                                  SettingsProvider.instance
                                                      .timeFormat.pattern,
                                                )
                                                    .format(event.updated)
                                                    .toUpperCase(),
                                          ].join('\n'),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        leading: CircleAvatar(
                                          child: Icon(
                                            Icons.warning,
                                            color: Theme.of(context)
                                                .iconTheme
                                                .color,
                                          ),
                                          backgroundColor: Colors.transparent,
                                        ),
                                      ),
                                    )
                                    .toList() ??
                                [
                                  if (invalid[e] ?? true)
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
                      ),
                    )
                    .toList(),
              ),
            ),
    );
  }
}

class EventPlayerScreen extends StatefulWidget {
  final Event event;
  const EventPlayerScreen({Key? key, required this.event}) : super(key: key);

  @override
  State<EventPlayerScreen> createState() => _EventPlayerScreenState();
}

class _EventPlayerScreenState extends State<EventPlayerScreen> {
  FijkPlayer ijkPlayer = FijkPlayer();

  @override
  void initState() {
    super.initState();
    debugPrint(widget.event.mediaURL.toString());
    ijkPlayer.setDataSource(
      widget.event.mediaURL.toString(),
      autoPlay: true,
    );
  }

  @override
  void dispose() {
    ijkPlayer.release();
    ijkPlayer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.event.title
              .split('device')
              .last
              .trim()
              .split(' ')
              .map(
                (e) => e.isEmpty ? '' : e[0].toUpperCase() + e.substring(1),
              )
              .join(' '),
        ),
      ),
      body: FijkView(
        player: ijkPlayer,
        fit: FijkFit.contain,
        color: Colors.black,
        panelBuilder: (player, data, context, viewSize, texturePos) {
          return CustomFijkPanel(
            player: player,
            viewSize: viewSize,
            texturePos: texturePos,
            curActiveIdx: 0,
            curTabIdx: 0,
            videoFormat: VideoSourceFormat(video: [VideoSourceFormatVideo()]),
            showConfig: _ShowConfig(),
          );
        },
      ),
    );
  }
}

class _ShowConfig extends ShowConfigAbs {
  @override
  bool nextBtn = false;
  @override
  bool speedBtn = false;
  @override
  bool drawerBtn = false;
  @override
  bool lockBtn = false;
  @override
  bool topBar = false;
  @override
  bool autoNext = false;
  @override
  bool bottomPro = false;
  @override
  bool stateAuto = false;
  @override
  bool isAutoPlay = false;
}
