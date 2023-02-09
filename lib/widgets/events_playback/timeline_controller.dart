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

import 'package:auto_size_text/auto_size_text.dart';
import 'package:bluecherry_client/models/event.dart';
import 'package:bluecherry_client/providers/events_playback_provider.dart';
import 'package:bluecherry_client/providers/home_provider.dart';
import 'package:bluecherry_client/providers/server_provider.dart';
import 'package:bluecherry_client/utils/extensions.dart';
import 'package:bluecherry_client/utils/theme.dart';
import 'package:bluecherry_client/widgets/events_playback/events_playback.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import 'package:unity_video_player/unity_video_player.dart';

const kDeviceNameWidth = 140.0;
const kTimelineViewHeight = 190.0;
const kTimelineTileHeight = 24.0;

const kTimelineThumbWidth = 10.0;
const kTimelineThumbOverflowPadding = 20.0;

/// The width of a millisecond
const kGapDuration = Duration(seconds: 5);

class TimelineTile {
  final String deviceId;
  final List<Event> events;
  final UnityVideoPlayer player;

  const TimelineTile({
    required this.deviceId,
    required this.events,
    required this.player,
  });
}

extension TimelineTileExtension on List<TimelineTile> {
  /// Get the correspondent tile for the given events
  ///
  /// Returns null if there is no correspondent tile
  TimelineTile? forEvent(Event event) {
    if (any((tile) => tile.events.contains(event))) {
      final tile = firstWhere((tile) => tile.events.contains(event));
      return tile;
    }

    return null;
  }
}

abstract class TimelineItem {
  final DateTime start;
  final DateTime end;

  final Duration duration;

  const TimelineItem(this.start, this.end, this.duration);

  /// Checks if the item [e] is in between the span of the given [date]
  ///
  /// See also:
  ///
  ///  * [DateTime.isInBetween]
  bool checkForDate(DateTime date) {
    if (this is TimelineGap) {
      return date.isInBetween(start, end);
    } else if (this is TimelineValue) {
      return (this as TimelineValue).events.hasForDate(date);
    } else {
      throw UnsupportedError('$runtimeType is not supported');
    }
  }

  /// Returns a list with useful data
  ///
  /// * 0 - List<TimelineItem>
  /// * 1 - Duration
  /// * 2 - Oldest [Event]
  /// * 3 - Newest [Event]
  static List calculateTimeline(List data) {
    final allEvents = (data[0] as Iterable<Event>).where(
      (e) => e.duration > Duration.zero,
    );

    if (allEvents.isEmpty) return [];

    final oldestEvent = allEvents.oldest;
    final newestEvent = allEvents.newest;

    final oldest = oldestEvent.published;
    final newest = newestEvent.published;

    final items = <TimelineItem>[];
    var currentDateTime = oldest;
    TimelineItem? currentItem;

    // The interval time is the duration of the shortest event
    final intervalTime = () {
      final eventsDuration = allEvents.map((e) => e.duration).toList()
        ..sort((a, b) => a.compareTo(b));
      return eventsDuration.first;
    }();

    debugPrint(
      'Generating timeline with ${allEvents.length}, '
      'and with an interval time of $intervalTime',
    );

    void increment() => currentDateTime = currentDateTime.add(intervalTime);

    /// A loop that runs until the newest event date has been reached
    ///
    /// [currentItem] means current item for the current date time.
    ///
    /// If null, we create a new timeline item:
    ///   * If there is events for the current date time, a [TimelineValue] is
    ///     created
    ///   * Otherwise, a [TimelineGap] is created
    ///
    /// If not null, we check for the current date time and update the current
    /// item accordingly:
    ///   * If it's a gap but there is an event for the current date time, the
    ///     gap is ended
    ///   * If it's a value but there is no longer any event in the current time
    ///     span, the value is ended
    while (!currentDateTime.hasForDate(newest)) {
      if (currentItem == null) {
        final forDate = allEvents.forDateList(currentDateTime);
        if (forDate.isNotEmpty) {
          final start = forDate.oldest.published;
          currentItem = TimelineValue(
            start: start,
            end: currentDateTime,
            duration: Duration.zero,
            events: forDate,
          );
          // currentDateTime = start;
          increment();
        } else {
          final start = items.isEmpty ? currentDateTime : items.last.end;
          currentItem = TimelineGap(
            start: start,
            gapDuration: Duration.zero,
            end: currentDateTime,
          );
          // currentDateTime = start;
          increment();
        }
      } else {
        if (allEvents.hasForDate(currentDateTime)) {
          // ends the gap
          if (currentItem is TimelineGap) {
            final event = allEvents.forDateList(currentDateTime).oldest;
            currentItem = TimelineGap(
              start: currentItem.start,
              end: event.published,
              gapDuration: event.published.difference(currentItem.start),
            );
            items.add(currentItem);
            // currentDateTime = items.last.end;
            currentItem = null;
          } else {
            increment();
          }
        } else {
          // ends a timeline value
          if (currentItem is TimelineValue) {
            final events = allEvents
                .inBetween(currentItem.start, currentDateTime)
                .toList();

            var duration = Duration.zero;
            Event? previous;
            for (final event in events) {
              if (previous == null) {
                previous = event;
                final eventDuration = event.duration;

                duration = duration + eventDuration;
              } else {
                // the gap between the two events
                final previousEnd = previous.published.add(previous.duration);
                final difference = previousEnd.difference(event.published);
                duration = duration + difference;

                final eventDuration = event.duration;
                duration = duration + eventDuration;
              }
            }

            currentItem = TimelineValue(
              start: currentItem.start,
              end: currentItem.start.add(duration),
              duration: duration,
              events: events,
            );
            items.add(currentItem);
            // currentDateTime = items.last.end;
            currentItem = null;
          } else {
            increment();
          }
        }
      }
    }

    final duration = items.map((item) {
      if (item is TimelineValue) {
        return item.duration;
      } else if (item is TimelineGap) {
        return kGapDuration;
      } else {
        throw UnsupportedError('${item.runtimeType} is not supported');
      }
    }).reduce((a, b) => a + b);

    return [
      items,
      duration,
      oldestEvent,
      newestEvent,
    ];
  }
}

class TimelineValue extends TimelineItem {
  final Iterable<Event> events;

  const TimelineValue({
    required this.events,
    required DateTime start,
    required DateTime end,
    required Duration duration,
  }) : super(start, end, duration);

  @override
  String toString() {
    return 'TimelineValue(events: $events, start: $start, end: $end, duration: $duration)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is TimelineValue &&
        other.events.length == events.length &&
        other.start == start &&
        other.end == end &&
        other.duration == duration;
  }

  @override
  int get hashCode {
    return events.hashCode ^ start.hashCode ^ end.hashCode ^ duration.hashCode;
  }
}

class TimelineGap extends TimelineItem {
  const TimelineGap({
    required DateTime start,
    required DateTime end,
    required Duration gapDuration,
  }) : super(start, end, gapDuration);

  @override
  String toString() =>
      'TimelineGap(gapDuration: $duration, start: $start, end: $end)';

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is TimelineGap &&
        other.duration == duration &&
        other.start == start &&
        other.end == end;
  }

  @override
  int get hashCode => duration.hashCode ^ start.hashCode ^ end.hashCode;
}

/// Controls the state of a [TimelineView].
///
/// Before using, make sure the controller is initialize by caling [initialize].
/// If tried to use without being initialized, an error is thrown.
///
/// This controller ensures all the timeline items are in sync with each other.
/// It also manages the gaps between [TimelineValue]s and skip them properly
///
/// While in a gap, the upcoming video is precached for a smooth transition.
///
/// Use [setDate] for seeking. It requires the initial item position and its
/// precision. It is responsible for seeking the tile player as well.
///
/// See also:
///
///   * [kGapDuration], which is the duration of a skipped gap
class TimelineController extends ChangeNotifier {
  /// Controls the timeline view scrolling
  final scrollController = ScrollController();

  /// The horizontal extent of the timeline
  double get timelineExtent {
    if (!scrollController.hasClients ||
        !scrollController.position.hasViewportDimension) {
      return 0.0;
    }
    return scrollController.position.viewportDimension;
  }

  double get periodWidth {
    final timelineDuration = items
        .map((e) {
          if (e is TimelineGap) return gapDuration;

          return e.duration;
        })
        .reduce((a, b) => a + b)
        .inMilliseconds;

    return timelineExtent / timelineDuration * zoom;
  }

  /// The duration of a gap in the timeline
  ///
  /// This should not be used to calculate the current item. Instead, this should
  /// only be used to calculate the width and position of the timeline thumb
  Duration get gapDuration {
    if (zoom < maxZoom / 2) return Duration.zero;

    return kGapDuration;
  }

  double get gapWidth {
    if (zoom < maxZoom / 2) return 0.0;

    return gapDuration.inMilliseconds * periodWidth;
  }

  /// All the tiles of the timeline. Usually represents the devices in a server
  List<TimelineTile> tiles = [];

  /// The oldest event of the timeline
  Event? oldest;

  /// The newest event of the timeline
  Event? newest;

  /// The duration of the entire timeline
  Duration duration = Duration.zero;

  /// The position of the current item, considering the gaps
  late final positionNotifier = ChangeNotifier();

  /// The thumb position is calculated in the following way:
  ///
  ///   We account all the previous items and their respective duration, and
  ///   position the thumb accordingly. For a precise match, [thumbPrecision] is
  ///   used. It is updated by the current player (if any) or the ticker.
  ///
  ///   [thumbPrecision] is reset every time the current item changes
  Duration thumbPrecision = Duration.zero;
  Duration get thumbPosition {
    return _thumbPosition(currentDate, thumbPrecision);
    // if (currentItem == null) return Duration.zero;

    // final previousItems = items.where((i) => i.end.isBefore(currentDate));

    // var pos = previousItems.fold(
    //   Duration.zero,
    //   (duration, item) {
    //     if (item is TimelineGap) return duration + gapDuration;

    //     return duration + item.duration;
    //   },
    // );
    // // if (item is TimelineGap) pos = pos + precision;

    // final precision =
    //     thumbPrecision > currentItem!.duration ? Duration.zero : thumbPrecision;

    // return pos + precision;
  }

  Duration _thumbPosition(DateTime forDate, Duration precision) {
    final item = itemForDate(forDate);
    if (item == null) return Duration.zero;

    final previousItems = items.where((i) => i.end.isBefore(forDate));

    var pos = previousItems.fold(
      Duration.zero,
      (duration, item) {
        if (item is TimelineGap) return duration + gapDuration;

        return duration + item.duration;
      },
    );

    final thumbPrecision =
        precision > item.duration ? Duration.zero : precision;

    return pos + thumbPrecision;
  }

  /// This makes animating with gap possible
  ///
  /// When it reaches [kGapDuration], we move to the next item. While the gap is
  /// running, we precache the next items
  Duration currentGapDuration = Duration.zero;

  /// The current date of the timeline, in real time
  ///
  /// The initial date is the date of start of the oldest event
  DateTime currentDate = DateTime(0);

  /// The current item span of the timeline
  @protected
  TimelineItem? _currentItem;
  TimelineItem? get currentItem => _currentItem;

  /// Sets the current item and resets the player for the given tile
  ///
  /// When the item is updated, it's found necessary to reset the player position
  /// for a smooth experience. It's more noticable in a multiple tile situation
  set currentItem(TimelineItem? item) {
    debugPrint(
      'Changing item '
      '${currentItem.runtimeType} (${currentItem?.start}) '
      'to ${item.runtimeType} (${item?.start})',
    );

    if (currentItem is TimelineValue) {
      final tile = tiles.forEvent((currentItem as TimelineValue).events.first);
      if (tile != null) {
        tile.player.reset();
      }
    }
    _currentItem = item;
  }

  double _speed = 1;
  double get speed => _speed;
  set speed(double speed) {
    for (final tile in tiles) {
      tile.player.setSpeed(speed);
    }

    _speed = speed;
    notifyListeners();
  }

  double _volume = 1;
  double get volume => _volume;
  set volume(double volume) {
    for (final tile in tiles) {
      tile.player.setVolume(volume);
    }

    _muted = false;
    _volume = volume;
    notifyListeners();
  }

  bool _muted = false;
  bool get isMuted => _muted;
  void mute() {
    _muted = true;
    for (final tile in tiles) {
      tile.player.setVolume(0);
    }

    notifyListeners();
  }

  void unmute() {
    _muted = false;
    for (final tile in tiles) {
      tile.player.setVolume(volume);
    }
    notifyListeners();
  }

  /// Zoom represents the expansion of the timeline
  ///
  /// 1.0 is the smaller state. It is also the initial state. On this state, all
  /// [items] will fit within the timeline.
  ///
  /// 2.0 is the max value. On this state, all items can be easily viewed and
  /// differentiated to the human eye
  double _zoom = 1.0;
  double get zoom => _zoom;
  set zoom(double zoom) {
    _zoom = zoom;
    notifyListeners();
    ensureThumbVisible();
  }

  static const double minZoom = 1.0;
  static const double maxZoom = 18.0;

  /// All the events in the timeline
  ///
  /// See also:
  ///
  ///  * [TimelineValue], an item that can play media
  ///  * [TimelineGap], an item that doesn't have any media during a timespan
  List<TimelineItem> items = [];

  /// Usually, if no events were found, it probably means there is a gap between
  /// events in a single [TimelineItem]. >>should<< be normal.
  ///
  /// This usually doesn't happen because, when creating the timeline (See TimelineItem.calculateTimeline),
  /// the span used is the duration of the smallest event. If it happens, something
  /// may have gone wrong. Yet, this is not going to break the timeline, since
  /// the next event is going to be played after the next gap
  TimelineItem? itemForDate(DateTime date) {
    return items.any((e) => e.checkForDate(date))
        ? items.firstWhere((e) => e.checkForDate(date))
        : currentItem;
  }

  /// A ticker that runs every interval
  Timer? timer;
  void startTimer(BuildContext context) {
    // do not initialize it twice, otherwise it may cause inconsistency
    if (timer != null && timer!.isActive) return;
    if (oldest == null || newest == null) return;

    final home = context.read<HomeProvider>();
    const interval = Duration(milliseconds: 25);

    void reset() {
      currentDate = oldest!.published;
      currentItem = null;
      thumbPrecision = Duration.zero;

      for (final tile in tiles) {
        tile.player.reset();
      }
      positionNotifier.notifyListeners();
    }

    /// Whether this is past the end
    bool has() {
      return items.any((e) => currentDate.isInBetween(e.start, e.end));
    }

    if (!has()) {
      timer?.cancel();
      reset();
    }

    timer = Timer.periodic(interval, (timer) async {
      if (!has()) {
        timer.cancel();
        reset();

        return;
      }

      /// Usually, if no events were found, it probably means there is a gap between
      /// events in a single [TimelineItem]. >>should<< be normal.
      ///
      /// This usually doesn't happen because, when creating the timeline (See TimelineItem.calculateTimeline),
      /// the span used is the duration of the smallest event. If it happens, something
      /// may have gone wrong. Yet, this is not going to break the timeline, since
      /// the next event is going to be played after the next gap
      final itemForDate = items.any((i) => i.checkForDate(currentDate))
          ? items.firstWhere((i) => i.checkForDate(currentDate))
          : currentItem;

      /// When the item changes, we ensure to change it and update the ticker
      if (currentItem != itemForDate) {
        currentItem = itemForDate;
        thumbPrecision = Duration.zero;
        notifyListeners();
        positionNotifier.notifyListeners();
      }

      /// If the current item is a gap, we add it according to the (current ticker duration * speed)
      /// When it reaches the max gap duration (kGapDuration), it preloads the next item.
      if (currentItem is TimelineGap) {
        addGap(currentItem!.duration, interval * speed);

        final nextDate = currentDate.add(currentItem!.duration);

        /// We check for the next event and assign its media source, if necessary
        if (items.any((e) => e is TimelineValue && e.checkForDate(nextDate))) {
          final next = items
              .whereType<TimelineValue>()
              .firstWhere((value) => value.checkForDate(nextDate));

          for (final event in next.events) {
            final tile = tiles.forEvent(event);
            if (tile == null) continue;

            final mediaUrl = event.mediaURL?.toString();

            if (!event.isAlarm &&
                mediaUrl != null &&
                tile.player.dataSource != mediaUrl) {
              debugPrint('PRELOADING $mediaUrl');
              tile.player.setDataSource(
                mediaUrl,
                autoPlay: false,
              );
            }
          }
        }
      } else if (currentItem is TimelineValue) {
        /// If all the events in the timeline are alarms, we add it according to
        /// the (current ticker duration * speed)
        ///
        /// Otherwise, the duration that is added is the *difference* between the
        /// last added position and the current position
        ///
        /// Check the listener for [onCurrentPosUpdate] in [initialize] for more
        /// info on how this is done
        if ((currentItem! as TimelineValue).events.hasForDate(currentDate)) {
          final allEvents =
              (currentItem! as TimelineValue).events.forDateList(currentDate);
          if (allEvents.where((event) => event.isAlarm).length ==
              allEvents.length) {
            final precision = interval * speed;
            currentDate = currentDate.add(precision);
            thumbPrecision = thumbPrecision + precision;
            positionNotifier.notifyListeners();
          }
        }
      }

      if (currentItem is TimelineValue) {
        final events = (currentItem as TimelineValue).events;

        /// Ensure the current event is playing
        if (events.hasForDate(currentDate)) {
          for (final event in events.forDateList(currentDate)) {
            if (event.mediaURL == null) continue;

            final tile = tiles.forEvent(event);
            if (tile == null) continue;

            if (tile.player.dataSource == event.mediaURL!.toString()) {
              if (!tile.player.isPlaying) {
                await tile.player.start();
              }
            } else {
              home.loading(UnityLoadingReason.timelineEventLoading);
              await tile.player.setDataSource(
                event.mediaURL!.toString(),
              );
              home.notLoading(UnityLoadingReason.timelineEventLoading);
              notifyListeners();
            }
          }
        }
      }
    });
  }

  /// Sets the timeline at the provided [date]
  ///
  /// [precision] determines the precision of the pointer
  void setDate(DateTime date, Duration precision) {
    final item = itemForDate(date);

    if (item == null) {
      throw ArgumentError(
        '$date is not a valid timespan of the current timeline',
      );
    }

    // If it's the current item, we seek for the precision
    if (currentItem == item && item is TimelineValue) {
      debugPrint('Item for date $date is already the current item');
      for (final event in item.events) {
        final tile = tiles.forEvent(event);
        if (tile == null) continue;

        final mediaUrl = event.mediaURL?.toString();

        if (!event.isAlarm &&
            mediaUrl != null &&
            tile.player.dataSource == mediaUrl) {
          debugPrint('SEEKING $mediaUrl TO $precision');
          tile.player.seekTo(precision);
        }
      }
      return;
    }

    currentItem = item;
    currentDate = item.start.add(precision);
    if (item is TimelineGap) {
      currentGapDuration = precision;
      thumbPrecision = precision;

      // this avoids reseting the thumbPrecision, since it's reset when the item
      // is changed
      currentItem = item;

      debugPrint('seeking gap to $precision');
    } else if (item is TimelineValue) {
      thumbPrecision = Duration.zero;
    } else {
      throw UnsupportedError(
        '${currentItem.runtimeType} is not a supported item',
      );
    }

    notifyListeners();
    positionNotifier.notifyListeners();

    debugPrint(
      '(${item.runtimeType})'
      ' $date = i${item.start}'
      ' precision $precision',
    );
  }

  void setVideoPosition(Duration precision) {
    assert(currentItem != null);
    assert(currentItem is TimelineValue);

    final desiredDate = currentItem!.start.add(precision);

    if (currentDate.isBefore(desiredDate)) {
      currentDate = desiredDate;
      // notifyListeners();
    }
    thumbPrecision = precision;

    _updateThumbPosition();
    positionNotifier.notifyListeners();
  }

  /// If the gap duration has ended, it [add]s into the current position
  ///
  /// Otherwise, it adds [position] to the current thumb position
  void addGap(Duration gapDuration, Duration position) {
    assert(currentItem is TimelineGap);

    if (currentGapDuration >= kGapDuration) {
      currentGapDuration = thumbPrecision = Duration.zero;
      currentDate = currentItem!.start.add(gapDuration + position);
    } else {
      thumbPrecision = thumbPrecision + position;
      currentGapDuration = currentGapDuration + position;
    }
    positionNotifier.notifyListeners();
    _updateThumbPosition();
  }

  /// Checks for the current scroll position of the timeline. If the thumb is
  /// reaching the end of the timeline, scroll to ensure the thumb is visible
  void _updateThumbPosition() {
    if (scrollController.hasClients) {
      final thumbX =
          thumbPosition.inMilliseconds * periodWidth - scrollController.offset;

      final to = scrollController.offset + kTimelineThumbOverflowPadding / 2;

      if (thumbX > timelineExtent) {
        scrollController.jumpTo(to);
      } else if (thumbX > timelineExtent - kTimelineThumbOverflowPadding) {
        scrollController.animateTo(
          to,
          duration: const Duration(milliseconds: 200),
          curve: Curves.linear,
        );
      }
    }
  }

  /// Makes the thumb visible in the start-ish of the timeline
  ///
  /// It jumps to the start of the [currentItem]. If the thumb is overflown,
  /// we ensure it is visible by calling [_updateThumbPosition]
  void ensureThumbVisible() {
    if (currentItem == null) return;

    scrollController.jumpTo(
      _thumbPosition(
            currentItem!.start,
            Duration.zero,
          ).inMilliseconds *
          periodWidth,
    );

    // avoid any overflow
    _updateThumbPosition();
  }

  /// Whether this controller is initialized
  ///
  /// See also:
  ///
  /// * [initialize], which initializes the timeline view
  bool get initialized {
    return items.isNotEmpty;
  }

  /// [events] all the events split by device
  ///
  /// [allEvents] all events in the history
  Future<void> initialize(
    BuildContext context,
    EventsData events,
    List<Event> allEvents,
  ) async {
    HomeProvider.instance
        .loading(UnityLoadingReason.fetchingEventsPlaybackPeriods);
    await _clear();
    notifyListeners();

    positionNotifier.notifyListeners();

    // ignore: use_build_context_synchronously
    if (!context.mounted || allEvents.isEmpty) {
      HomeProvider.instance.notLoading(
        UnityLoadingReason.fetchingEventsPlaybackPeriods,
      );
      return;
    }

    /// Only generate tiles for the devices that are selected
    final selectedIds = context.read<EventsProvider>().selectedIds;
    for (final event
        in events.entries.where((e) => selectedIds.contains(e.key))) {
      final id = event.key;
      final events = event.value;
      final item = TimelineTile(
        deviceId: id,
        events: events,
        player: UnityVideoPlayer.create(),
      );
      item.player
        ..setSpeed(speed)
        ..setVolume(volume)
        ..onCurrentPosUpdate.listen((pos) {
          if (item.events.hasForDate(currentDate)) {
            setVideoPosition(pos);
            debugPrint('pos $pos');
          }
        })
        ..onPlayingStateUpdate.listen((playing) {
          if (playing && isPaused) {
            pause();
          }
          notifyListeners();
        })
        ..onBufferStateUpdate.listen((buffering) {
          /// If the current item is paused to buffer, we show the loading indicator
          /// and pause the current timeline
          if (buffering) {
            context
                .read<HomeProvider>()
                .loading(UnityLoadingReason.timelineEventLoading);
            // pause();
          } else {
            context
                .read<HomeProvider>()
                .notLoading(UnityLoadingReason.timelineEventLoading);
            // play(context);
          }
        });
      tiles.add(item);
    }

    final result = await compute(TimelineItem.calculateTimeline, [allEvents]);
    items = result[0] as List<TimelineItem>;
    duration = result[1] as Duration;
    oldest = result[2] as Event;
    newest = result[3] as Event;

    currentDate = oldest!.published;

    HomeProvider.instance.notLoading(
      UnityLoadingReason.fetchingEventsPlaybackPeriods,
    );

    if (context.mounted) startTimer(context);
    notifyListeners();
  }

  /// Starts all players
  Future<void> play(BuildContext context) async {
    startTimer(context);
    notifyListeners();
  }

  /// Checks if the current player state is paused
  ///
  /// If a single player is paused, all players will be paused.
  bool get isPaused {
    return timer == null || !timer!.isActive;
  }

  /// Pauses all players
  Future<void> pause() async {
    timer?.cancel();
    await Future.wait(tiles.map((i) => i.player.pause()));

    notifyListeners();
  }

  @protected
  Future<void> _clear() async {
    timer?.cancel();

    for (final item in tiles) {
      item.player.release();
      item.player.dispose();
    }
    tiles.clear();
    items.clear();

    thumbPrecision = Duration.zero;
    currentDate = DateTime(0);
  }

  @override
  Future<void> dispose() async {
    super.dispose();
    _clear();
    positionNotifier.dispose();
    scrollController.dispose();
  }
}

class TimelineView extends StatelessWidget {
  final TimelineController timelineController;

  const TimelineView({
    Key? key,
    required this.timelineController,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    debugPrint('${timelineController.periodWidth}');
    final servers = context.watch<ServersProvider>().servers;

    final maxHeight = kTimelineTileHeight *
        // at least the height of 4
        timelineController.tiles.length.clamp(
          4,
          double.infinity,
        );

    final theme = Theme.of(context).extension<TimelineTheme>()!;
    return Stack(children: [
      Positioned.fill(
        child: SingleChildScrollView(
          child: SizedBox(
            height: maxHeight,
            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: timelineController.tiles.map((i) {
                  final device = servers.findDevice(i.deviceId)!;
                  final server =
                      servers.firstWhere((s) => s.devices.contains(device));
                  return Tooltip(
                    message: '${server.name}/${device.name}',
                    preferBelow: false,
                    verticalOffset: 12.0,
                    child: Container(
                      height: kTimelineTileHeight,
                      width: kDeviceNameWidth,
                      padding: const EdgeInsets.symmetric(horizontal: 8.0),
                      child: Row(children: [
                        Flexible(
                          flex: 2,
                          child: AutoSizeText(
                            server.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            maxFontSize: 12.0,
                          ),
                        ),
                        Expanded(
                          flex: 3,
                          child: AutoSizeText(
                            '/${device.name}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            maxFontSize: 12.0,
                          ),
                        ),
                      ]),
                    ),
                  );
                }).toList(),
              ),
              const VerticalDivider(width: 2.0),
              Expanded(
                child: SingleChildScrollView(
                  controller: timelineController.scrollController,
                  scrollDirection: Axis.horizontal,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: timelineController.tiles.map((tile) {
                      return Container(
                        height: kTimelineTileHeight,
                        decoration: const BoxDecoration(
                          border: Border(bottom: BorderSide()),
                        ),
                        child: Row(
                            children: timelineController.items.map((i) {
                          if (i is TimelineGap) {
                            return _TimelineItemGestures(
                              controller: timelineController,
                              width: timelineController.gapWidth,
                              item: i,
                              child: Container(
                                height: kTimelineTileHeight,
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 5),
                                alignment: Alignment.center,
                                color: theme.gapColor,
                                child: AutoSizeText(
                                  i.duration.humanReadableCompact(context),
                                  maxLines: 1,
                                  minFontSize: 8.0,
                                  maxFontSize: 10.0,
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(color: Colors.black),
                                ),
                              ),
                            );
                          } else if (i is TimelineValue) {
                            final events =
                                tile.events.inBetween(i.start, i.end);

                            final width = i.duration.inMilliseconds *
                                timelineController.periodWidth;

                            if (events.isEmpty) {
                              return SizedBox(width: width);
                            }
                            return _TimelineItemGestures(
                              controller: timelineController,
                              width: width,
                              item: i,
                              child: SizedBox(
                                height: kTimelineTileHeight,
                                child: () {
                                  Widget buildForEvent(
                                    Event? event,
                                    Duration duration,
                                  ) {
                                    return Container(
                                      height: kTimelineTileHeight,
                                      width: duration.inMilliseconds *
                                          timelineController.periodWidth,
                                      color: event == null
                                          ? null
                                          : event.isAlarm
                                              ? theme.alarmColor
                                              : theme.eventColor,
                                      alignment: Alignment.center,
                                      // child: AutoSizeText(
                                      //   duration.humanReadableCompact(context),
                                      //   maxLines: 1,
                                      //   maxFontSize: 12,
                                      //   minFontSize: 8,
                                      //   textAlign: TextAlign.center,
                                      // ),
                                    );
                                  }

                                  var widgets = <Widget>[];

                                  Event? previous;
                                  for (final event in events) {
                                    if (previous == null) {
                                      previous = event;
                                      final duration = event.duration;

                                      widgets
                                          .add(buildForEvent(event, duration));
                                    } else {
                                      final previousEnd = previous.published
                                          .add(previous.duration);
                                      final difference = previousEnd
                                          .difference(event.published);

                                      widgets
                                          .add(buildForEvent(null, difference));

                                      final duration = event.duration;
                                      widgets
                                          .add(buildForEvent(event, duration));
                                    }
                                  }

                                  return Row(children: widgets);
                                }(),
                              ),
                            );
                          } else {
                            throw UnsupportedError(
                              '${i.runtimeType} is not a supported type',
                            );
                          }
                        }).toList()),
                      );
                    }).toList(),
                  ),
                ),
              ),
            ]),
          ),
        ),
      ),
      if (timelineController.initialized) ...[
        Positioned.fill(
          left: kDeviceNameWidth,
          child: RepaintBoundary(
            child: AnimatedBuilder(
              animation: Listenable.merge([
                timelineController.scrollController,
                timelineController.positionNotifier,
              ]),
              builder: (context, child) {
                final scrollOffset =
                    timelineController.scrollController.hasClients
                        ? timelineController.scrollController.offset
                        : 0.0;
                final x = timelineController.thumbPosition.inMilliseconds *
                        timelineController.periodWidth -
                    scrollOffset;

                if (x.isNegative) {
                  return const SizedBox(
                    height: kTimelineViewHeight,
                  );
                }

                return Stack(clipBehavior: Clip.none, children: [
                  Positioned(
                    top: 0.0,
                    bottom: 0.0,
                    left: x - 3,
                    width: kTimelineThumbWidth,
                    child: child!,
                  ),
                  Positioned(
                    left: x - 10,
                    width: kTimelineThumbWidth,
                    top: 0.0,
                    bottom: -10.0,
                    child: Align(
                      alignment: Alignment.bottomCenter,
                      child: Icon(
                        Icons.arrow_drop_up,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                  ),
                ]);
              },
              child: IgnorePointer(
                child: SizedBox(
                  width: kTimelineThumbWidth,
                  child: Center(
                    child: Container(
                      width: 2.5,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    ]);
  }
}

class _TimelineItemGestures extends StatefulWidget {
  final TimelineController controller;
  final TimelineItem item;
  final double width;
  final Widget child;

  const _TimelineItemGestures({
    Key? key,
    required this.controller,
    required this.item,
    required this.width,
    required this.child,
  }) : super(key: key);

  static const kPopupWidth = 60.0;

  @override
  State<_TimelineItemGestures> createState() => _TimelineItemGesturesState();
}

class _TimelineItemGesturesState extends State<_TimelineItemGestures> {
  Offset? localPosition;
  DateTime? date;

  /// Used by [MouseRegion.onExit] to pause/play the timeline according to the initial value
  bool _initiallyPaused = false;

  @override
  Widget build(BuildContext context) {
    if (widget.width == 0.0) return const SizedBox.shrink();
    final previous =
        widget.controller.items.where((e) => e.end.isBefore(widget.item.start));

    final theme = Theme.of(context).extension<TimelineTheme>()!;

    return MouseRegion(
      onEnter: (d) {
        _initiallyPaused = widget.controller.isPaused;
        widget.controller.pause();
      },
      onHover: (d) {
        final ms = d.localPosition.dx / widget.controller.periodWidth;
        final duration = Duration(milliseconds: ms.toInt());

        DateTime? date;
        if (previous.isEmpty) {
          date = widget.item.start.add(duration);
        } else if (widget.item is TimelineValue) {
          date = widget.item.start.add(duration);
        } else if (widget.item is TimelineGap) {
          date = widget.item.start.add(widget.item.duration);
        }

        setState(() {
          localPosition = d.localPosition;
          this.date = date;
        });

        if (date != null) widget.controller.setDate(date, duration);
      },
      onExit: (d) {
        if (!_initiallyPaused) widget.controller.play(context);
        setState(() => localPosition = date = null);
      },
      child: IgnorePointer(
        child: SizedBox(
          width: widget.width,
          child: Stack(clipBehavior: Clip.none, children: [
            widget.child,
            if (localPosition != null && date != null)
              PositionedDirectional(
                start: localPosition!.dx - _TimelineItemGestures.kPopupWidth,
                child: Container(
                  height: kTimelineTileHeight,
                  width: _TimelineItemGestures.kPopupWidth,
                  color: theme.seekPopupColor,
                  padding: const EdgeInsets.symmetric(horizontal: 8.0),
                  margin: const EdgeInsets.only(bottom: 2.5),
                  alignment: Alignment.center,
                  child: AutoSizeText(
                    DateFormat.Hms().format(date!),
                    maxLines: 1,
                    minFontSize: 8.0,
                  ),
                ),
              ),
          ]),
        ),
      ),
    );
  }
}
