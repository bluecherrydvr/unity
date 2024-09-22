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

import 'package:bluecherry_client/models/device.dart';
import 'package:bluecherry_client/models/event.dart';
import 'package:bluecherry_client/providers/events_provider.dart';
import 'package:bluecherry_client/providers/settings_provider.dart';
import 'package:bluecherry_client/utils/date.dart';
import 'package:bluecherry_client/utils/extensions.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:unity_video_player/unity_video_player.dart';

final secondsInADay = const Duration(days: 1).inSeconds;

/// The initial point of the timeline.
enum TimelineInitialPoint {
  /// The timeline will start at the beginning of the day (00:00:00).
  beginning,

  /// The timeline will start at the first event of the day, if any. Otherwise,
  /// it will start at the [beginning] of the day.
  firstEvent,

  /// The timeline will start at an hour ago from the current time.
  hourAgo,
}

class TimelineTile {
  final Device device;
  late final List<TimelineEvent> _events;

  late final UnityVideoPlayer videoController;

  TimelineTile({
    required this.device,
    required List<TimelineEvent> events,
  }) {
    _events = events;
    videoController = UnityVideoPlayer.create(
      quality: UnityVideoQuality.p480,
      enableCache: true,
      title: device.fullName,
      softwareZoom: SettingsProvider.instance.kSoftwareZooming.value,
      matrixType: SettingsProvider.instance.kMatrixSize.value,
    );
    videoController.setMultipleDataSource(
      _events.map((event) => event.videoUrl),
      autoPlay: false,
    );
  }

  List<TimelineEvent> get events {
    final eventsProvider = EventsProvider.instance;
    return _events.where((event) {
      var typeFilterPasses = false;

      final eventFilter = eventsProvider.eventTypeFilter;
      if (eventFilter == -1) {
        typeFilterPasses = true;
      } else {
        typeFilterPasses = eventFilter == event.event.type.index;
      }

      // TODO(bdlukaa): Add selected device filter

      return typeFilterPasses;
    }).toList();
  }

  /// Returns the current event in the tile.
  ///
  /// If there are more than one event that happened at the same time, the
  /// continuous event will have preference. If there is no continuous event,
  /// the first event will be returned.
  ///
  /// If there are no events playing, `null` will be returned.
  Event? currentEvent(DateTime currentDate) {
    final playingEvents = events.where((event) => event.isPlaying(currentDate));
    if (playingEvents.isEmpty) return null;
    if (playingEvents.length == 1) return playingEvents.first.event;

    final continuousEvent = playingEvents
        .firstWhereOrNull((event) => event.event.type == EventType.continuous);
    if (continuousEvent != null) return continuousEvent.event;

    return playingEvents.first.event;
  }
}

class TimelineEvent {
  /// The duration of the event
  final Duration duration;

  /// When the event started
  final DateTime startTime;

  final String videoUrl;

  final Event event;

  TimelineEvent({
    required this.duration,
    required DateTime startTime,
    required this.event,
    this.videoUrl =
        'https://user-images.githubusercontent.com/28951144/229373695-22f88f13-d18f-4288-9bf1-c3e078d83722.mp4',
  }) : startTime = startTime.toLocal();

  static List<TimelineEvent> get fakeData {
    return [
      TimelineEvent(
        duration: const Duration(minutes: 1),
        startTime: DateTime.now()
            .add(
              Duration(
                  hours: Random().nextInt(4), minutes: Random().nextInt(60)),
            )
            .toUtc(),
        event: Event.dump(),
      ),
      TimelineEvent(
        duration: const Duration(hours: 1),
        startTime: DateTime.now()
            .add(Duration(hours: Random().nextInt(4) + 5))
            .toUtc(),
        event: Event.dump(),
      ),
      TimelineEvent(
        duration: const Duration(minutes: 1),
        startTime: DateTime.now()
            .add(Duration(hours: Random().nextInt(4) + 9))
            .toUtc(),
        event: Event.dump(),
      ),
      TimelineEvent(
        duration: const Duration(minutes: 1),
        startTime: DateTime.now()
            .add(
              Duration(
                hours: Random().nextInt(4) + 13,
                minutes: Random().nextInt(60),
              ),
            )
            .toUtc(),
        event: Event.dump(),
      ),
      TimelineEvent(
        duration: const Duration(minutes: 1),
        startTime: DateTime.now()
            .add(Duration(
              hours: Random().nextInt(4) + 14,
              minutes: Random().nextInt(60),
            ))
            .toUtc(),
        event: Event.dump(),
      ),
      TimelineEvent(
        duration: const Duration(minutes: 1),
        startTime: DateTime.now()
            .add(Duration(
              hours: Random().nextInt(4) + 20,
              minutes: Random().nextInt(60),
            ))
            .toUtc(),
        event: Event.dump(),
      ),
    ];
  }

  DateTime get endTime => startTime.add(duration);

  bool isPlaying(DateTime currentDate) {
    return currentDate.toUtc().isInBetween(startTime.toUtc(), endTime.toUtc());
  }

  /// The position of the video at the [currentDate]
  Duration position(DateTime currentDate) {
    return currentDate.toUtc().difference(startTime.toUtc());
  }
}

/// A timeline of events
///
/// Events are played as they happened in time. The timeline is limited to a
/// single day, so events are from hour 0 to 23.
class Timeline extends ChangeNotifier {
  /// Each tile of the timeline
  final List<TimelineTile> tiles = [];

  /// All the events must have happened in the same day
  late final DateTime date;

  Timeline({
    required List<TimelineTile> tiles,
    required DateTime date,
    Duration initialPosition = Duration.zero,
  }) {
    this.date = DateTime(date.year, date.month, date.day).toLocal();
    currentPosition = initialPosition;

    add(tiles.where((tile) => tile.events.isNotEmpty));

    for (final tile in this.tiles) {
      tile.videoController
        // ..onBufferUpdate.listen((_) => _eventCallback(tile))
        ..onDurationUpdate.listen((_) => _eventCallback(tile))
        ..onPlayingStateUpdate.listen((_) => _eventCallback(tile))
        ..onCurrentPosUpdate.listen((_) => _eventCallback(tile, notify: false));
    }

    zoomController.addListener(notifyListeners);
  }

  Timeline.dump()
      : this(
          tiles: [
            TimelineTile(
              device: Device.dump(id: 0, name: 'device1'),
              events: TimelineEvent.fakeData,
            ),
            TimelineTile(
              device: Device.dump(id: 1, name: 'device2'),
              events: TimelineEvent.fakeData,
            ),
            TimelineTile(
              device: Device.dump(id: 2, name: 'device3'),
              events: TimelineEvent.fakeData,
            ),
            TimelineTile(
              device: Device.dump(id: 3, name: 'device4'),
              events: TimelineEvent.fakeData,
            ),
          ],
          date: DateTime.now(),
        );

  void _eventCallback(TimelineTile tile, {bool notify = true}) {
    if (tile.videoController.duration <= Duration.zero) return;

    // final index = tiles.indexOf(tile);

    // final bufferFactor = tile.videoController.currentBuffer.inMilliseconds /
    //     tile.videoController.duration.inMilliseconds;

    // // This only applies if the video is not buffered
    // if (bufferFactor < 1.0) {
    //   if (tile.videoController.currentBuffer <
    //       tile.videoController.currentPos) {
    //     debugPrint('should pause $index for buffering');
    //     pausedToBuffer.add(index);
    //     stop();
    //   } else if (pausedToBuffer.contains(index)) {
    //     debugPrint('should play $index from buffering');
    //     pausedToBuffer.remove(index);

    //     if (pausedToBuffer.isEmpty) play();
    //   }
    // } else if (pausedToBuffer.contains(index)) {
    //   debugPrint('should play $index from buffering');
    //   pausedToBuffer.remove(index);

    //   if (pausedToBuffer.isEmpty) play();
    // }
    if (notify) notifyListeners();
  }

  Timeline.placeholder() : date = DateTime(2023);

  static Timeline get fakeTimeline {
    return Timeline(
      date: DateTime(2023),
      tiles: [
        TimelineTile(
          device: Device.dump(name: 'device1'),
          events: TimelineEvent.fakeData,
        ),
        TimelineTile(
          device: Device.dump(name: 'device2'),
          events: TimelineEvent.fakeData,
        ),
        TimelineTile(
          device: Device.dump(name: 'device3'),
          events: TimelineEvent.fakeData,
        ),
        TimelineTile(
          device: Device.dump(name: 'device4'),
          events: TimelineEvent.fakeData,
        ),
      ],
    );
  }

  List<TimelineEvent> get allEvents =>
      tiles.expand((tile) => tile.events).toList();

  void add(Iterable<TimelineTile> tiles) {
    // assert(tiles.every((tile) {
    //   return tile.events.every((event) {
    //     return DateUtils.isSameDay(
    //       event.startTime.toLocal(),
    //       date.toLocal(),
    //     );
    //   });
    // }), 'All events must have happened in the same day');
    this.tiles.addAll(tiles.where((tile) {
      // add the events in the same day
      return tile.events.any((event) {
        return DateUtils.isSameDay(
          event.startTime.toLocal(),
          date.toLocal(),
        );
      });
    }));
    // assert(
    //   this.tiles.length <= kMaxDevicesOnScreen,
    //   'There must be at most $kMaxDevicesOnScreen devices on screen',
    // );
    notifyListeners();
  }

  void removeTile(TimelineTile tile) {
    tiles.remove(tile);
    notifyListeners();
  }

  void forEachEvent(
      void Function(TimelineTile tile, TimelineEvent event) callback) {
    for (var tile in tiles) {
      for (var event in tile.events) {
        callback(tile, event);
      }
    }
  }

  /// The current position of the timeline
  var currentPosition = const Duration();
  Duration get endPosition => const Duration(days: 1);

  DateTime get currentDate => date.add(currentPosition);

  void seekTo(Duration position) {
    currentPosition = position;
    notifyListeners();

    forEachEvent((tile, event) async {
      if (!event.isPlaying(currentDate)) return;
      final eventIndex = tile.events.indexOf(event);
      await tile.videoController.jumpToIndex(eventIndex);

      final position = event.position(currentDate);
      tile.videoController.seekTo(position);
      if (!isPlaying) tile.videoController.pause();

      debugPrint('Seeking ${tile.device} to $position');
    });
  }

  /// Seeks forward by [duration]
  void seekForward([Duration duration = const Duration(seconds: 15)]) =>
      seekTo(currentPosition + duration);

  /// Seeks backward by [duration]
  void seekBackward([Duration duration = const Duration(seconds: 15)]) =>
      seekTo(currentPosition - duration);

  void stepForward() => seekTo(currentPosition + period);
  void stepBackward() => seekTo(currentPosition - period);

  void seekToEvent(TimelineEvent event) {
    final tile = tiles.firstWhereOrNull((tile) => tile.events.contains(event));
    if (tile == null) {
      debugPrint('Event ${event.event.id} not found in any tile');
      return;
    }
    final eventIndex = tile.events.indexOf(event);
    tile.videoController.jumpToIndex(eventIndex);

    final position = event.position(currentDate);
    tile.videoController.seekTo(position);
    if (!isPlaying) tile.videoController.pause();

    updateScrollPosition();

    debugPrint('Seeking ${tile.device} to $position');
  }

  TimelineEvent? seekToPreviousEvent() {
    final events = allEvents.sortedBy((e) => e.startTime);

    // There can be more than one event that is playing at the same time (e.g.
    // continuous and motion events). We need to get the last one, the top one
    // in the list. It is usually the motion event, since they are shorter.
    // This way, the user will be able to traverse the events in the correct
    // order.
    final currentEvent = events.lastWhereOrNull(
      (e) => e.isPlaying(currentDate),
    );
    final previousEvent = events.lastWhereOrNull(
      (e) => e.startTime.isBefore(currentEvent?.startTime ?? currentDate),
    );

    if (previousEvent != null) {
      currentPosition = previousEvent.startTime.difference(date);
      seekToEvent(previousEvent);
    }
    return previousEvent;
  }

  TimelineEvent? seekToNextEvent() {
    final nextEvent = allEvents
        .sortedBy((e) => e.startTime)
        .firstWhereOrNull((e) => e.startTime.isAfter(currentDate));

    if (nextEvent != null) {
      currentPosition = nextEvent.startTime.difference(date);
      seekToEvent(nextEvent);
    }
    return nextEvent;
  }

  double _volume = 1.0;
  bool get isMuted => volume == 0;
  double get volume => _volume;
  set volume(double value) {
    if (value < 0.0 || value > 1.0) return;

    _volume = value;
    notifyListeners();

    for (final tile in tiles) {
      tile.videoController.setVolume(volume);
    }
  }

  double _speed = SettingsProvider.instance.kEventsSpeed.value;
  double get speed => _speed;
  set speed(double value) {
    _speed = value.clamp(
      SettingsProvider.instance.kEventsSpeed.min!,
      SettingsProvider.instance.kEventsSpeed.max!,
    );
    stop();
    notifyListeners();

    for (final tile in tiles) {
      tile.videoController.setSpeed(speed);
    }

    play();
  }

  Duration get period => Duration(milliseconds: 1000 ~/ _speed);

  final indicatorKey = GlobalKey(debugLabel: 'Indicator key');
  final zoomController = ScrollController(
    debugLabel: 'Zoom Indicator Controller',
  );
  void scrollTo(double to, [double? max]) {
    final position =
        zoomController.hasClients ? zoomController.positions.last : null;
    zoomController.jumpTo(clampDouble(
      to,
      0.0,
      max ?? position?.maxScrollExtent ?? 0.0,
    ));
  }

  double _zoom = 1.0;
  double get zoom => _zoom;
  set zoom(double value) {
    value = _zoom = clampDouble(value, 1.0, maxZoom);
    updateScrollPosition();
    notifyListeners();
  }

  void updateScrollPosition() {
    if (_zoom == 1.0) {
      scrollTo(0.0);
    } else if (_zoom > 1.0) {
      final position =
          zoomController.hasClients ? zoomController.positions.last : null;
      if (position == null) return;
      final visibilityFactor = position.viewportDimension / 6.0;
      final zoomedWidth = position.viewportDimension * zoom;
      final secondWidth = zoomedWidth / secondsInADay;
      final to = currentPosition.inSeconds * secondWidth;

      if (to < position.viewportDimension) {
        // If the current position is at the beggining of the viewport, jump
        // to 0.0
        scrollTo(0.0);
      } else if (zoomedWidth - (visibilityFactor * zoom) < to) {
        // If the current position is at the end of the viewport, jump to the
        // beggining of the end of the viewport
        // scrollTo(zoomedWidth);
        scrollTo(zoomedWidth - position.viewportDimension, zoomedWidth);
      } else {
        // Otherwise, jump to the current position minus the visibility factor,
        // to ensure that the current position is visible at a viable position
        scrollTo(to - visibilityFactor);
      }
    }
  }

  static const maxZoom = 100.0;

  Timer? timer;
  bool get isPlaying => timer != null && timer!.isActive;

  /// The indexes of the tiles that are paused to buffer
  Set<int> pausedToBuffer = {};
  void stop() {
    if (timer == null) return;

    timer?.cancel();
    timer = null;

    forEachEvent((tile, event) {
      tile.videoController.pause();

      if (event.isPlaying(currentDate)) {
        tile.videoController.seekTo(event.position(currentDate));
      }
    });

    for (final tile in tiles) {
      tile.videoController.pause();
    }
    notifyListeners();
  }

  void play([TimelineEvent? event]) {
    debugPrint('Playing timeline with $period');
    timer?.cancel();
    timer ??= Timer.periodic(period, (timer) {
      if (event == null) {
        currentPosition += period;

        if (SettingsProvider.instance.kAutomaticallySkipEmptyPeriods.value) {
          final isPlaying = allEvents.any((e) => e.isPlaying(currentDate));
          if (!isPlaying) {
            final nextEvent = seekToNextEvent();
            if (nextEvent == null) {
              stop();
              return;
            }
          }
        }

        notifyListeners();
      }

      forEachEvent((tile, e) {
        if (!tile.events.any((e) => e.isPlaying(currentDate))) {
          tile.videoController.pause();
          return;
        }
        if (!e.isPlaying(currentDate)) return;

        final position = e.position(currentDate);
        if (tile.videoController.isPlaying) {
          // if the video is late by a lot of seconds, seek to the current position
          final isLate = position - tile.videoController.currentPos >
              const Duration(milliseconds: 3000);
          if (isLate) {
            tile.videoController.seekTo(position);
            debugPrint('Device is late. Seeking ${tile.device} to $position');
          }
          return;
        }

        if ((event != null && event == e) || e.isPlaying(currentDate)) {
          if (event == null) {
            tile.videoController.seekTo(position);
            debugPrint('-- Seeking ${tile.device} to $position');
          }
          if (!tile.videoController.isPlaying) {
            tile.videoController.start();
            debugPrint('Playing ${tile.device}');
          }
        } else {
          tile.videoController.pause();
          debugPrint('Pausing ${tile.device}');
        }
      });
    });
    notifyListeners();
  }

  @override
  void dispose() {
    stop();
    for (final tile in tiles) {
      tile.videoController.dispose();
    }
    zoomController.dispose();
    super.dispose();
  }

  void notify() => notifyListeners();
}
