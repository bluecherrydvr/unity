// ignore_for_file: overridden_fields

/*
 * This file is a part of Bluecherry Client (https://https://github.com/bluecherrydvr/bluecherry_client).
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
import 'package:fijkplayer/fijkplayer.dart';
import 'package:fijkplayer_skin/fijkplayer_skin.dart';
import 'package:fijkplayer_skin/schema.dart';
import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';

import 'package:bluecherry_client/providers/server_provider.dart';
import 'package:bluecherry_client/models/server.dart';
import 'package:bluecherry_client/models/event.dart';

class EventsScreen extends StatefulWidget {
  const EventsScreen({Key? key}) : super(key: key);

  @override
  State<EventsScreen> createState() => _EventsScreenState();
}

class _EventsScreenState extends State<EventsScreen> {
  bool isFirstTimeLoading = true;
  final Map<Server, Iterable<Event>> events = {};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await fetch();
      setState(() {
        isFirstTimeLoading = false;
      });
    });
  }

  Future<void> fetch() async {
    for (final server in ServersProvider.instance.servers) {
      try {
        events[server] = await API.instance.getEvents(
          await API.instance.checkServerCredentials(server),
        );
      } catch (exception, stacktrace) {
        debugPrint(exception.toString());
        debugPrint(stacktrace.toString());
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('event_browser'.tr()),
      ),
      body: RefreshIndicator(
        onRefresh: fetch,
        child: ListView(
          children: ServersProvider.instance.servers
              .map(
                (e) => ExpansionTile(
                  initiallyExpanded:
                      ServersProvider.instance.servers.length.compareTo(1) == 0,
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
                      : events[e]!
                          .map(
                            (event) => ListTile(
                              onTap: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        EventPlayerScreen(event: event),
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
                                        : e[0].toUpperCase() + e.substring(1))
                                    .join(' '),
                              ),
                              subtitle: Text(
                                [
                                  event.title.split('event on').first.trim(),
                                  DateFormat.yMMMEd('en_US')
                                      .add_jms()
                                      .format(event.updated),
                                ].join(' • '),
                              ),
                              leading: CircleAvatar(
                                child: Icon(
                                  Icons.warning,
                                  color: Theme.of(context).iconTheme.color,
                                ),
                                backgroundColor: Colors.transparent,
                              ),
                            ),
                          )
                          .toList(),
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
