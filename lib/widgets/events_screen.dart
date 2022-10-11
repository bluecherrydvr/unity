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
import 'dart:math';
import 'package:intl/intl.dart';
import 'package:flutter/material.dart';
import 'package:fijkplayer/fijkplayer.dart';
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
      body: InteractiveViewer(
        minScale: 1.0,
        maxScale: 4.0,
        child: FijkView(
          player: ijkPlayer,
          fit: FijkFit.contain,
          color: Colors.black,
          panelBuilder: (player, data, context, size, rect) => VideoViewport(
            context: context,
            player: player,
            size: size,
            rect: rect,
          ),
        ),
      ),
    );
  }
}

class VideoViewport extends StatefulWidget {
  final FijkPlayer player;
  final BuildContext context;
  final Size size;
  final Rect rect;

  const VideoViewport({
    Key? key,
    required this.player,
    required this.context,
    required this.size,
    required this.rect,
  }) : super(key: key);

  @override
  _VideoViewportState createState() => _VideoViewportState();
}

class _VideoViewportState extends State<VideoViewport> {
  FijkPlayer get player => widget.player;
  FijkState state = FijkState.asyncPreparing;
  Duration position = Duration.zero;
  bool visible = true;
  Timer timer = Timer(Duration.zero, () {});

  @override
  void initState() {
    super.initState();
    // Set class attributes to match the current [FijkPlayer]'s state.
    state = widget.player.state;
    position = widget.player.currentPos;
    widget.player.addListener(listener);
    widget.player.onCurrentPosUpdate.listen(currentPosListener);
    widget.player.onBufferStateUpdate.listen(bufferStateListener);
    timer = Timer(const Duration(seconds: 5), () {
      if (mounted) {
        setState(() {
          visible = false;
        });
      }
    });
  }

  void listener() {
    if (mounted) {
      setState(() {
        state = player.state;
      });
    }
  }

  void currentPosListener(Duration event) {
    if (mounted) {
      setState(() {
        position = event;
        // Deal with the [seekTo] condition inside the [Slider] [Widget] callback.
        if (state == FijkState.idle) {
          state = FijkState.started;
        }
      });
    }
  }

  void bufferStateListener(bool event) {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    Rect rect = Rect.fromLTRB(
        max(0.0, widget.rect.left),
        max(0.0, widget.rect.top),
        min(widget.size.width, widget.rect.right),
        min(widget.size.height, widget.rect.bottom));
    return Positioned.fromRect(
      rect: rect,
      child: Material(
        color: Colors.transparent,
        child: SafeArea(
          child: Stack(
            children: [
              Positioned.fill(
                child: GestureDetector(
                  onTap: () {
                    if (!visible) {
                      setState(() {
                        visible = true;
                      });
                      if (timer.isActive) timer.cancel();
                      timer = Timer(const Duration(seconds: 5), () {
                        setState(() {
                          visible = false;
                        });
                      });
                    } else {
                      setState(() {
                        visible = false;
                      });
                    }
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 400),
                    decoration: BoxDecoration(
                      gradient: visible
                          ? const LinearGradient(
                              stops: [
                                1.0,
                                0.8,
                                0.0,
                                0.8,
                                1.0,
                              ],
                              colors: [
                                Colors.black38,
                                Colors.transparent,
                                Colors.transparent,
                                Colors.transparent,
                                Colors.black38,
                              ],
                            )
                          : null,
                    ),
                  ),
                ),
              ),
              if (visible ||
                  player.isBuffering ||
                  state == FijkState.asyncPreparing) ...[
                Positioned(
                  top: 0.0,
                  bottom: 0.0,
                  left: 0.0,
                  right: 0.0,
                  child: state == FijkState.error
                      ? Center(
                          child: Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                const Icon(
                                  Icons.warning,
                                  color: Colors.white70,
                                  size: 32.0,
                                ),
                                const SizedBox(height: 8.0),
                                Text(
                                  player.value.exception.message!.toUpperCase(),
                                  style: const TextStyle(
                                    color: Colors.white70,
                                    fontSize: 12.0,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        )
                      : player.isBuffering || state == FijkState.asyncPreparing
                          ? const Center(
                              child: CircularProgressIndicator(
                                color: Colors.white,
                              ),
                            )
                          : GestureDetector(
                              child: Icon(
                                state == FijkState.started
                                    ? Icons.pause
                                    : Icons.play_arrow,
                                color: Colors.white,
                                shadows: const <Shadow>[
                                  BoxShadow(
                                      color: Colors.black54,
                                      blurRadius: 15.0,
                                      offset: Offset(0.0, 0.75)),
                                ],
                                size: 56.0,
                              ),
                              onTap: () {
                                state == FijkState.started
                                    ? widget.player.pause()
                                    : widget.player.start();
                              },
                            ),
                ),
                if (player.value.duration != Duration.zero)
                  Positioned(
                    bottom: 0.0,
                    left: 0.0,
                    right: 0.0,
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        const SizedBox(width: 16.0),
                        Container(
                          alignment: Alignment.centerRight,
                          height: 36.0,
                          child: Text(
                            player.currentPos.label,
                            style: Theme.of(context)
                                .textTheme
                                .headline4
                                ?.copyWith(color: Colors.white),
                          ),
                        ),
                        const SizedBox(width: 8.0),
                        Expanded(
                          child: SliderTheme(
                            data: SliderThemeData(
                              overlayShape: const RoundSliderOverlayShape(
                                  overlayRadius: 12.0),
                              overlayColor: Theme.of(context)
                                  .primaryColor
                                  .withOpacity(0.4),
                              thumbColor: Theme.of(context).primaryColor,
                              activeTrackColor: Theme.of(context).primaryColor,
                              inactiveTrackColor: Theme.of(context)
                                  .primaryColor
                                  .withOpacity(0.5),
                              trackHeight: 2.0,
                              thumbShape: const RoundSliderThumbShape(
                                enabledThumbRadius: 6.0,
                              ),
                            ),
                            child: Transform.translate(
                              offset: const Offset(0, 0.8),
                              child: Slider(
                                value: position.inMilliseconds.toDouble(),
                                min: 0.0,
                                max: player.value.duration.inMilliseconds
                                    .toDouble(),
                                onChanged: (value) async {
                                  setState(() {
                                    state = FijkState.idle;
                                  });
                                  position =
                                      Duration(milliseconds: value.toInt());
                                  await player.seekTo(value.toInt());
                                  await player.start();
                                },
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8.0),
                        Container(
                          alignment: Alignment.centerLeft,
                          height: 36.0,
                          child: Text(
                            player.value.duration.label,
                            style: Theme.of(context)
                                .textTheme
                                .headline4
                                ?.copyWith(color: Colors.white),
                          ),
                        ),
                        const SizedBox(width: 8.0),
                        IconButton(
                          padding: EdgeInsets.zero,
                          icon: Icon(
                            widget.player.value.fullScreen
                                ? Icons.fullscreen_exit
                                : Icons.fullscreen,
                            color: Colors.white,
                          ),
                          onPressed: () {
                            widget.player.value.fullScreen
                                ? player.exitFullScreen()
                                : player.enterFullScreen();
                          },
                        ),
                        const SizedBox(width: 8.0),
                      ],
                    ),
                  ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    player.removeListener(listener);

    super.dispose();
  }
}

extension DurationExtension on Duration {
  /// Return [Duration] as typical formatted string.
  String get label {
    if (this > const Duration(days: 1)) {
      final days = inDays.toString().padLeft(3, '0');
      final hours = (inHours - (inDays * 24)).toString().padLeft(2, '0');
      final minutes = (inMinutes - (inHours * 60)).toString().padLeft(2, '0');
      final seconds = (inSeconds - (inMinutes * 60)).toString().padLeft(2, '0');
      return '$days:$hours:$minutes:$seconds';
    } else if (this > const Duration(hours: 1)) {
      final hours = inHours.toString().padLeft(2, '0');
      final minutes = (inMinutes - (inHours * 60)).toString().padLeft(2, '0');
      final seconds = (inSeconds - (inMinutes * 60)).toString().padLeft(2, '0');
      return '$hours:$minutes:$seconds';
    } else {
      final minutes = inMinutes.toString().padLeft(2, '0');
      final seconds = (inSeconds - (inMinutes * 60)).toString().padLeft(2, '0');
      return '$minutes:$seconds';
    }
  }
}
