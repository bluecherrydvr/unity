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
import 'package:bluecherry_client/screens/events_timeline/desktop/timeline_view.dart';
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
  Future<void> fetch({DateTime? startDate, DateTime? endDate}) async {
    if (!context.mounted) return;
    final eventsProvider = context.read<EventsProvider>();
    final settings = context.read<SettingsProvider>();
    setState(() {
      hasEverFetched = true;
      date = date.toLocal();
      startDate = DateTime(date.year, date.month, date.day).toLocal();
      endDate = DateTime(date.year, date.month, date.day, 23, 59, 59).toLocal();
      timeline?.dispose();
      timeline = null;
    });

    // if (kDebugMode && true) {
    //   setState(() => timeline = Timeline.dump());
    //   return;
    // }

    await super.fetch(
      startDate: startDate,
      endDate: endDate,
    );

    final devices = <Device, List<Event>>{};

    final events = eventsProvider.loadedEvents!.filteredEvents
      ..sort((a, b) {
        // Sort the events in a way that the continuous events are displayed first
        // Ideally, in the Timeline, the motion events should be displayed on
        // top of the continuous events. We need to sort the continuous events
        // so that the continuous events don't get on top of the motion events.
        final aIsContinuous = a.type == EventType.continuous;
        final bIsContinuous = b.type == EventType.continuous;
        if (aIsContinuous && !bIsContinuous) return -1;
        if (!aIsContinuous && bIsContinuous) return 1;
        return 0;
      });
    for (final event in events) {
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

      // This ensures that events that happened at the same time are not
      // displayed on the same device.
      //
      // if (devices[device]!.any((e) {
      //   return e.published.isInBetween(event.published, event.updated,
      //           allowSameMoment: true) ||
      //       e.updated.isInBetween(event.published, event.updated,
      //           allowSameMoment: true) ||
      //       event.published
      //           .isInBetween(e.published, e.updated, allowSameMoment: true) ||
      //       event.updated
      //           .isInBetween(e.published, e.updated, allowSameMoment: true);
      // })) continue;

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

        debugPrint(
          '${event.logicalKey}${event.logicalKey.debugName}'
          ' - '
          '${event.physicalKey}${event.physicalKey.debugName}',
        );

        switch (event.logicalKey) {
          case LogicalKeyboardKey.arrowRight:
            timeline!.seekForward();
            return KeyEventResult.handled;
          case LogicalKeyboardKey.arrowLeft:
            timeline!.seekBackward();
            return KeyEventResult.handled;
          case LogicalKeyboardKey.space:
          case LogicalKeyboardKey.mediaPlayPause:
            if (timeline!.isPlaying) {
              timeline!.stop();
            } else {
              timeline!.play();
            }
            return KeyEventResult.handled;
          case LogicalKeyboardKey.mediaPlay:
          case LogicalKeyboardKey.play:
            if (!timeline!.isPlaying) {
              timeline!.play();
              return KeyEventResult.handled;
            }
            return KeyEventResult.ignored;
          case LogicalKeyboardKey.mediaPause:
          case LogicalKeyboardKey.pause:
          case LogicalKeyboardKey.mediaStop:
            if (timeline!.isPlaying) {
              timeline!.stop();
              return KeyEventResult.handled;
            }
            return KeyEventResult.ignored;
          case LogicalKeyboardKey.f5:
            fetch();
            return KeyEventResult.handled;
          case LogicalKeyboardKey.mediaSkipForward:
          case LogicalKeyboardKey.mediaTrackNext:
            timeline!.seekToNextEvent();
            return KeyEventResult.handled;
          case LogicalKeyboardKey.mediaSkipBackward:
          case LogicalKeyboardKey.mediaTrackPrevious:
            timeline!.seekToPreviousEvent();
            return KeyEventResult.handled;
          case LogicalKeyboardKey.mediaStepForward:
            timeline!.stepForward();
            return KeyEventResult.handled;
          case LogicalKeyboardKey.mediaStepBackward:
            timeline!.stepBackward();
            return KeyEventResult.handled;
          case LogicalKeyboardKey.home:
          case LogicalKeyboardKey.numpad0:
          case LogicalKeyboardKey.digit0:
            timeline!.seekTo(Duration.zero);
            return KeyEventResult.handled;
          case LogicalKeyboardKey.end:
            timeline!.seekTo(timeline!.endPosition);
            return KeyEventResult.handled;
          case LogicalKeyboardKey.keyM:
            if (timeline!.isMuted) {
              timeline!.volume = 1.0;
            } else {
              timeline!.volume = 0.0;
            }
            return KeyEventResult.handled;
          case LogicalKeyboardKey.arrowUp:
            timeline!.volume += 0.1;
            return KeyEventResult.handled;
          case LogicalKeyboardKey.arrowDown:
            timeline!.volume -= 0.1;
            return KeyEventResult.handled;

          case LogicalKeyboardKey.numpad1:
          case LogicalKeyboardKey.digit1:
            timeline!.seekTo(timeline!.endPosition * 0.1);
            return KeyEventResult.handled;
          case LogicalKeyboardKey.numpad2:
          case LogicalKeyboardKey.digit2:
            timeline!.seekTo(timeline!.endPosition * 0.2);
            return KeyEventResult.handled;
          case LogicalKeyboardKey.numpad3:
          case LogicalKeyboardKey.digit3:
            timeline!.seekTo(timeline!.endPosition * 0.3);
            return KeyEventResult.handled;
          case LogicalKeyboardKey.numpad4:
          case LogicalKeyboardKey.digit4:
            timeline!.seekTo(timeline!.endPosition * 0.4);
            return KeyEventResult.handled;
          case LogicalKeyboardKey.numpad5:
          case LogicalKeyboardKey.digit5:
            timeline!.seekTo(timeline!.endPosition * 0.5);
            return KeyEventResult.handled;
          case LogicalKeyboardKey.numpad6:
          case LogicalKeyboardKey.digit6:
            timeline!.seekTo(timeline!.endPosition * 0.6);
            return KeyEventResult.handled;
          case LogicalKeyboardKey.numpad7:
          case LogicalKeyboardKey.digit7:
            timeline!.seekTo(timeline!.endPosition * 0.7);
            return KeyEventResult.handled;
          case LogicalKeyboardKey.numpad8:
          case LogicalKeyboardKey.digit8:
            timeline!.seekTo(timeline!.endPosition * 0.8);
            return KeyEventResult.handled;
          case LogicalKeyboardKey.numpad9:
          case LogicalKeyboardKey.digit9:
            timeline!.seekTo(timeline!.endPosition * 0.9);
            return KeyEventResult.handled;

          default:
            return KeyEventResult.ignored;
        }
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
