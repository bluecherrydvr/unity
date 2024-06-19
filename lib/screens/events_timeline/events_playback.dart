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

import 'package:bluecherry_client/models/device.dart';
import 'package:bluecherry_client/models/event.dart';
import 'package:bluecherry_client/providers/downloads_provider.dart';
import 'package:bluecherry_client/providers/events_provider.dart';
import 'package:bluecherry_client/providers/settings_provider.dart';
import 'package:bluecherry_client/screens/events_browser/events_screen.dart';
import 'package:bluecherry_client/screens/events_timeline/desktop/timeline.dart';
import 'package:bluecherry_client/screens/events_timeline/desktop/timeline_sidebar.dart';
import 'package:bluecherry_client/screens/events_timeline/mobile/timeline_device_view.dart';
import 'package:bluecherry_client/utils/date.dart';
import 'package:bluecherry_client/utils/methods.dart';
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

class _EventsPlaybackState extends EventsScreenState<EventsPlayback> {
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
    focusNode.dispose();
    super.dispose();
  }

  DateTime date = DateTime(
    DateTimeExtension.now().year,
    DateTimeExtension.now().month,
    DateTimeExtension.now().day,
  ).toLocal();

  bool hasEverFetched = false;

  @override
  Future<void> fetch() async {
    if (!context.mounted) return;
    final eventsProvider = context.read<EventsProvider>();
    final settings = context.read<SettingsProvider>();
    setState(() {
      hasEverFetched = true;
      date = date.toLocal();
      eventsProvider
        ..startDate = DateTime(date.year, date.month, date.day).toLocal()
        ..endDate =
            DateTime(date.year, date.month, date.day, 23, 59, 59).toLocal();
      timeline?.dispose();
      timeline = null;
    });
    await super.fetch();

    final devices = <Device, List<Event>>{};

    for (final event in eventsProvider.loadedEvents!.filteredEvents) {
      if (event.isAlarm || event.mediaURL == null) continue;

      if (!DateUtils.isSameDay(event.published, date) ||
          !DateUtils.isSameDay(event.published.add(event.duration), date)) {
        continue;
      }

      final device = event.server.devices.firstWhere(
        (d) => d.id == event.deviceID,
        orElse: () => Device.dump(
          name: event.deviceName,
          id: event.deviceID,
        ),
      );
      devices[device] ??= [];

      if (devices[device]!.any((e) {
        return e.published.isInBetween(event.published, event.updated,
                allowSameMoment: true) ||
            e.updated.isInBetween(event.published, event.updated,
                allowSameMoment: true) ||
            event.published
                .isInBetween(e.published, e.updated, allowSameMoment: true) ||
            event.updated
                .isInBetween(e.published, e.updated, allowSameMoment: true);
      })) continue;

      devices[device]!.add(event);
    }

    final parsedTiles =
        devices.entries.map((e) => e.buildTimelineTile(context)).toList();

    if (mounted) {
      setState(() {
        timeline = Timeline(
          tiles: parsedTiles,
          date: date,
          initialPosition: switch (settings.kTimelineInitialPoint.value) {
            TimelineInitialPoint.beginning => Duration.zero,
            TimelineInitialPoint.firstEvent => () {
                final firstEvent = parsedTiles
                    .map((e) {
                      final earliestEvent = e.events.reduce(
                          (a, b) => a.startTime.isBefore(b.startTime) ? a : b);
                      return earliestEvent;
                    })
                    .reduce((a, b) => a.startTime.isBefore(b.startTime) ? a : b)
                    .startTime;
                return Duration(
                  hours: firstEvent.hour,
                  minutes: firstEvent.minute,
                  seconds: firstEvent.second,
                );
              }(),
            TimelineInitialPoint.hourAgo => Duration(
                hours: DateTimeExtension.now().hour - 1,
              ),
          },
        );
      });
    }
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
        } else if (event.logicalKey == LogicalKeyboardKey.f5) {
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

        if (hasDrawer ||
            // special case: the width is less than the mobile breakpoint
            constraints.maxWidth < 630.0 /* kMobileBreakpoint.width */) {
          if (!hasEverFetched) {
            WidgetsBinding.instance.addPostFrameCallback((_) => fetch());
          }
          if (timeline == null) {
            return SafeArea(
              child: Padding(
                padding: const EdgeInsetsDirectional.all(8.0),
                child: Stack(children: [
                  if (hasDrawer) const DrawerButton(),
                  const Center(child: CircularProgressIndicator.adaptive()),
                ]),
              ),
            );
          }
          return SafeArea(
            child: TimelineDeviceView(
              timeline: timeline!,
              onDateChanged: (date) {
                this.date = date;
                fetch();
              },
            ),
          );
        }
        return SafeArea(
          child: TimelineEventsView(
            // timeline: kDebugMode ? Timeline.fakeTimeline : timeline,
            timeline: timeline,
            sidebar: TimelineSidebar(
              date: date,
              onDateChanged: (date) => setState(() => this.date = date),
              onFetch: fetch,
            ),
            onFetch: fetch,
          ),
        );
      }),
    );
  }
}

extension DevicesMapExtension on MapEntry<Device, Iterable<Event>> {
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
                windows: isDesktopPlatform && Platform.isWindows,
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
