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

import 'dart:io';

import 'package:bluecherry_client/api/api.dart';
import 'package:bluecherry_client/models/device.dart';
import 'package:bluecherry_client/models/event.dart';
import 'package:bluecherry_client/providers/downloads_provider.dart';
import 'package:bluecherry_client/providers/home_provider.dart';
import 'package:bluecherry_client/providers/server_provider.dart';
import 'package:bluecherry_client/utils/constants.dart';
import 'package:bluecherry_client/utils/extensions.dart';
import 'package:bluecherry_client/widgets/events_timeline/desktop/timeline.dart';
import 'package:bluecherry_client/widgets/events_timeline/mobile/timeline_device_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

final eventsPlaybackScreenKey = GlobalKey<_EventsPlaybackState>();
const kMaxDevicesOnScreen = 6;

class EventsPlayback extends StatefulWidget {
  EventsPlayback() : super(key: eventsPlaybackScreenKey);

  @override
  State<EventsPlayback> createState() => _EventsPlaybackState();
}

class _EventsPlaybackState extends State<EventsPlayback> {
  Timeline? timeline;
  final focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => fetch());
    focusNode.requestFocus();
  }

  @override
  void dispose() {
    timeline?.dispose();
    super.dispose();
  }

  Map<Device, List<Event>> realDevices = {};
  Map<Device, List<Event>> devices = {}; // filtered

  Set<Device> disabledDevices = {};

  Future<void> fetch([bool fetchFromServer = true]) async {
    setState(() {
      timeline?.dispose();
      timeline = null;
    });
    final home = context.read<HomeProvider>()
      ..loading(UnityLoadingReason.fetchingEventsPlayback);
    var date = DateTime(
      DateTime.now().year,
      DateTime.now().month,
      DateTime.now().day,
    );
    for (final server in ServersProvider.instance.servers) {
      if (!server.online) continue;

      final events = fetchFromServer
          ? ((await API.instance.getEvents(
              await API.instance.checkServerCredentials(server),
            ))
              .where((event) => event.mediaURL != null)
              .toList()
            ..sort((a, b) {
              return a.published.compareTo(b.published);
            }))
          : realDevices.values.expand((e) => e).toList();

      if (events.isEmpty) continue;

      // If there are any events for today, use today as the date
      if (events.any(
        (event) => DateUtils.isSameDay(
          event.published.toUtc(),
          DateTime.now().toUtc(),
        ),
      )) {
        date = DateTime(
          DateTime.now().year,
          DateTime.now().month,
          DateTime.now().day,
        );
      } else {
        // Otherwise, use the most recent date that has events
        final recentDate = (events.toList()
              ..sort((a, b) => b.published.compareTo(a.published)))
            .first
            .published;
        date = DateTime(
          recentDate.year,
          recentDate.month,
          recentDate.day,
        );
      }

      for (final event in events) {
        // If the event is not long enough to be displayed, do not add it
        if (event.duration < const Duration(minutes: 1) ||
            event.mediaURL == null) {
          continue;
        }

        if (!DateUtils.isSameDay(event.published, date) ||
            !DateUtils.isSameDay(event.published.add(event.duration), date)) {
          continue;
        }

        final device = event.server.devices
            .firstWhere((device) => device.id == event.deviceID);

        realDevices[device] ??= [];

        // If there is already an event that conflicts with this one in time, do
        // not add it
        if (realDevices[device]!.any((e) {
          return e.published.isInBetween(
                event.published,
                event.published.add(event.duration),
              ) ||
              e.published.add(e.duration).isInBetween(
                    event.published,
                    event.published.add(event.duration),
                  ) ||
              event.published.isInBetween(
                e.published,
                e.published.add(e.duration),
              ) ||
              event.published.add(event.duration).isInBetween(
                    e.published,
                    e.published.add(e.duration),
                  );
        })) continue;

        realDevices[device] ??= [];
        realDevices[device]!.add(event);

        // If there are more than kMaxDevicesOnScreen devices, do not add any more devices
        if (disabledDevices.contains(device)) {
          if (devices.containsKey(device)) devices.remove(device);
          continue;
        } else if (devices.length == kMaxDevicesOnScreen &&
            !devices.containsKey(device)) {
          disabledDevices.add(device);
          continue;
        }

        devices[device] = realDevices[device]!;
      }
    }

    final parsedTiles = devices.entries
        .where((e) => e.value.isNotEmpty)
        .map((e) => e.buildTimelineTile(context));

    home.notLoading(UnityLoadingReason.fetchingEventsPlayback);

    setState(() {
      timeline = Timeline(
        tiles: parsedTiles.toList(),
        date: date,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Focus(
      autofocus: true,
      focusNode: focusNode,
      onKeyEvent: (node, event) {
        if (timeline == null ||
            !(event is KeyDownEvent || event is KeyRepeatEvent)) {
          return KeyEventResult.ignored;
        }

        debugPrint(event.logicalKey.debugName);
        if (event.logicalKey == LogicalKeyboardKey.space) {
          if (timeline!.isPlaying) {
            timeline!.stop();
          } else {
            timeline!.play();
          }
          return KeyEventResult.handled;
        } else if (event.logicalKey == LogicalKeyboardKey.keyM) {
          if (timeline!.isMuted) {
            timeline!.volume = 1.0;
          } else {
            timeline!.volume = 0.0;
          }
          return KeyEventResult.handled;
        } else if (event.logicalKey == LogicalKeyboardKey.keyR ||
            event.logicalKey == LogicalKeyboardKey.f5) {
          fetch();
          return KeyEventResult.handled;
        } else if (event.logicalKey == LogicalKeyboardKey.arrowRight) {
          timeline!.seekForward();
          return KeyEventResult.handled;
        } else if (event.logicalKey == LogicalKeyboardKey.arrowLeft) {
          timeline!.seekBackward();
          return KeyEventResult.handled;
        }

        return KeyEventResult.ignored;
      },
      child: LayoutBuilder(builder: (context, constraints) {
        final hasDrawer = Scaffold.hasDrawer(context);

        if (hasDrawer || constraints.maxWidth < kMobileBreakpoint.width) {
          if (timeline == null) {
            return SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Stack(children: [
                  if (hasDrawer) const DrawerButton(),
                  const Center(
                    child: CircularProgressIndicator.adaptive(),
                  ),
                ]),
              ),
            );
          }
          return SafeArea(child: TimelineDeviceView(timeline: timeline!));
        }
        return TimelineEventsView(
          // timeline: kDebugMode ? Timeline.fakeTimeline : timeline,
          timeline: timeline,
        );
      }),
    );
  }
}

extension DevicesMapExtension on MapEntry<Device, List<Event>> {
  TimelineTile buildTimelineTile(BuildContext context) {
    final device = key;
    final events = value;
    debugPrint('Loaded ${events.length} events for $device');

    return TimelineTile(
      device: device,
      events: events.map((event) {
        final downloads = context.read<DownloadsManager>();
        final mediaUrl = downloads.isEventDownloaded(event.id)
            ? Uri.file(
                downloads.getDownloadedPathForEvent(event.id),
                windows: Platform.isWindows,
              ).toString()
            : event.mediaURL!.toString();

        return TimelineEvent(
          startTime: event.published,
          duration: event.duration,
          videoUrl: mediaUrl,
          event: event,
        );
      }).toList(),
    );
  }
}
