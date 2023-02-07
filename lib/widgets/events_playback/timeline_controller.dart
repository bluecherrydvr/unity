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
const kPeriodWidth = 0.008;
const kGapDuration = Duration(seconds: 5);
final kGapWidth = kGapDuration.inMilliseconds * kPeriodWidth;

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
    final allEvents = data[0] as Iterable<Event>;

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
      final eventsDuration = allEvents
          .map((e) => e.mediaDuration ?? e.updated.difference(e.published))
          .toList()
        ..sort((a, b) => a.compareTo(b));
      return eventsDuration.first;
    }();

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
      void increment() => currentDateTime = currentDateTime.add(intervalTime);

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
                final eventDuration = event.mediaDuration ??
                    event.updated.difference(event.published);

                duration = duration + eventDuration;
              } else {
                // the gap between the two events
                final previousEnd = previous.published.add(
                  previous.mediaDuration ??
                      (previous.updated.difference(previous.published)),
                );
                final difference = previousEnd.difference(event.published);
                duration = duration + difference;

                final eventDuration = event.mediaDuration ??
                    event.updated.difference(event.published);
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
        other.events == events &&
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

class TimelineController extends ChangeNotifier {
  final scrollController = ScrollController();

  /// All the tiles of the timeline. Usually represents the devices in a server
  List<TimelineTile> tiles = [];

  /// The oldest event of the timeline
  Event? oldest;

  /// The newest event of the timeline
  Event? newest;

  /// The duration of the entire timeline
  Duration duration = Duration.zero;

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

    if (currentItem == item) {
      debugPrint('Item for date $date is already the current item');
      return;
    }

    final previousItems = items.where((i) => i.end.isBefore(date));

    /// The position of the timeline of the current date
    ///
    /// This takes account the whole time span
    final position = () {
      if (previousItems.isEmpty) return date.difference(item.start);

      // duration of the timeline until the previous events
      final dur = previousItems.map((e) => e.duration).reduce((a, b) => a + b);
      return dur + precision;
    }();

    var thumbPosition = () {
      var pos = previousItems.fold(
        Duration.zero,
        (duration, item) {
          if (item is TimelineGap) return duration + kGapDuration;

          return duration + item.duration;
        },
      );
      // if (item is! TimelineGap) pos = pos + precision;

      return pos;
    }();

    _position = position;
    _thumbPosition = thumbPosition;
    add(Duration.zero, isGap: true); // updates the screen

    debugPrint(
      '(${item.runtimeType})'
      ' $date = i${item.start}'
      ' pos $position thumb $thumbPosition',
    );
  }

  /// Adds a [duration] to the current position
  void add(Duration duration, {bool isGap = false}) {
    _position = _position + duration;
    currentDate = oldest!.published.add(_position);
    if (!isGap) _thumbPosition = _thumbPosition + duration;
    _updateThumbPosition();
  }

  /// If the gap duration has ended, it [add]s into the current position
  ///
  /// Otherwise, it adds [position] to the current thumb position
  void addGap(Duration gapDuration, Duration position) {
    if (currentGapDuration >= kGapDuration) {
      add(gapDuration, isGap: true);
      currentGapDuration = Duration.zero;
    } else {
      _thumbPosition = _thumbPosition + position;
      currentGapDuration = currentGapDuration + position;
      _updateThumbPosition();
    }
  }

  /// Checks for the current scroll position of the timeline. If the thumb is
  /// reaching the end of the timeline, scroll to ensure the thumb is visible
  void _updateThumbPosition() {
    // if (scrollController.hasClients) {
    //   final thumbX = _thumbPosition.inMilliseconds * kPeriodWidth -
    //       scrollController.offset;

    //   final to = scrollController.offset + kTimelineThumbOverflowPadding / 2;

    //   if (thumbX > scrollController.position.viewportDimension) {
    //     scrollController.jumpTo(to);
    //   } else if (thumbX >
    //       scrollController.position.viewportDimension -
    //           kTimelineThumbOverflowPadding) {
    //     scrollController.animateTo(
    //       to,
    //       duration: const Duration(milliseconds: 200),
    //       curve: Curves.linear,
    //     );
    //   }
    // }
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
      _position = Duration.zero;
      _thumbPosition = Duration.zero;

      for (final tile in tiles) {
        tile.player.reset();
      }
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

      /// If the current item is a gap, we add it according to the (current ticker duration * speed)
      /// When it reaches the max gap duration (kGapDuration), it preloads the next item.
      if (itemForDate is TimelineGap) {
        // if (currentItem is! TimelineGap) {
        // if it's the first tick of the timeline gap, we retrack the timeline
        // to show it at the correct position
        // currentDate = itemForDate.start;
        // }
        addGap(itemForDate.duration, interval * speed);

        // for (final tile in tiles) {
        //   // tile.player.set
        // }

        final nextDate = currentDate.add(itemForDate.duration);

        /// We check for the next event and assign its media source, if necessary
        if (items.any((e) => e is TimelineValue && e.checkForDate(nextDate))) {
          final next = items.firstWhere(
            (e) => e is TimelineValue && e.checkForDate(nextDate),
          ) as TimelineValue;

          for (final event in next.events) {
            final tile =
                tiles.firstWhere((tile) => tile.events.contains(event));

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
      } else if (itemForDate is TimelineValue) {
        /// If all the events in the timeline are alarms, we add it according to
        /// the (current ticker duration * speed)
        ///
        /// Otherwise, the duration that is added is the *difference* between the
        /// last added position and the current position
        ///
        /// Check the listener for [onCurrentPosUpdate] in [initialize] for more
        /// info on how this is done
        if (itemForDate.events.hasForDate(currentDate)) {
          final allEvents = itemForDate.events.forDateList(currentDate);
          if (allEvents.where((event) => event.isAlarm).length ==
              allEvents.length) {
            add(interval * speed);
          }
        } else {
          notifyListeners();
        }
      }

      /// When the item changes, we ensure to change it and update the ticker
      if (currentItem != itemForDate) {
        currentItem = itemForDate;
        notifyListeners();
      }

      if (currentItem is TimelineValue) {
        final events = (currentItem as TimelineValue).events;

        /// Ensure the current event is playing
        if (events.hasForDate(currentDate)) {
          for (final event in events.forDateList(currentDate)) {
            if (event.mediaURL == null) continue;

            if (tiles.any((tile) => tile.events.contains(event))) {
              final tile =
                  tiles.firstWhere((tile) => tile.events.contains(event));
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
      }

      positionNotifier.notifyListeners();
    });
  }

  /// The position of the current item, considering the gaps
  Duration _position = Duration.zero;
  late final positionNotifier = ValueNotifier<Duration>(_position);

  /// The position of the thumb, considering gaps with the duration of [kGapDuration]
  Duration _thumbPosition = Duration.zero;

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
  TimelineItem? currentItem;

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
      var previousPos = Duration.zero;
      item.player
        ..setSpeed(speed)
        ..setVolume(volume)
        ..onCurrentPosUpdate.listen((pos) {
          /// When the current position changes, we add it to the timeline position
          ///
          /// The amount of duration added is the difference between the previous
          /// position and the current position
          if (pos < previousPos) previousPos = pos;

          final has = item.events.hasForDate(currentDate);
          if (has) {
            add(pos - previousPos);
            debugPrint('$pos - $previousPos - ${pos - previousPos}');

            previousPos = pos;
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

    _thumbPosition = Duration.zero;
    _position = Duration.zero;
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
    final servers = context.watch<ServersProvider>().servers;

    final maxHeight = kTimelineTileHeight *
        // at least the height of 4
        timelineController.tiles.length.clamp(
          4,
          double.infinity,
        );
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
                              width: kGapWidth,
                              item: i,
                              child: Container(
                                height: kTimelineTileHeight,
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 5),
                                alignment: Alignment.center,
                                color: Colors.grey.shade400,
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

                            if (events.isEmpty) {
                              return const SizedBox.shrink();
                            }
                            return _TimelineItemGestures(
                              controller: timelineController,
                              width: i.duration.inMilliseconds * kPeriodWidth,
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
                                          kPeriodWidth,
                                      color: event == null
                                          ? null
                                          : event.isAlarm
                                              ? Colors.amber
                                              : Colors.green,
                                      alignment: Alignment.center,
                                      child: AutoSizeText(
                                        duration.humanReadableCompact(context),
                                        maxLines: 1,
                                        maxFontSize: 12,
                                        minFontSize: 8,
                                        textAlign: TextAlign.center,
                                      ),
                                    );
                                  }

                                  var widgets = <Widget>[];

                                  Event? previous;
                                  for (final event in events) {
                                    if (previous == null) {
                                      previous = event;
                                      final duration = event.mediaDuration ??
                                          event.updated
                                              .difference(event.published);

                                      widgets
                                          .add(buildForEvent(event, duration));
                                    } else {
                                      final previousEnd =
                                          previous.published.add(
                                        previous.mediaDuration ??
                                            (previous.updated.difference(
                                                previous.published)),
                                      );
                                      final difference = previousEnd
                                          .difference(event.published);

                                      widgets
                                          .add(buildForEvent(null, difference));

                                      final duration = event.mediaDuration ??
                                          event.updated
                                              .difference(event.published);
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
                final x = timelineController._thumbPosition.inMilliseconds *
                        kPeriodWidth -
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

  static const kPopupWidth = 160.0;

  @override
  State<_TimelineItemGestures> createState() => _TimelineItemGesturesState();
}

class _TimelineItemGesturesState extends State<_TimelineItemGestures> {
  Offset? localPosition;
  DateTime? date;

  @override
  Widget build(BuildContext context) {
    // final realDuration = () {
    //   if (widget.item is TimelineValue) {
    //     return widget.item.duration;
    //   } else if (widget.item is TimelineGap) {
    //     return kGapDuration;
    //   } else {
    //     throw UnsupportedError(
    //         '${widget.item.runtimeType} is not a supported type');
    //   }
    // }();

    final previous =
        widget.controller.items.where((e) => e.end.isBefore(widget.item.start));

    return MouseRegion(
      onEnter: (d) {
        widget.controller.pause();
      },
      onHover: (d) {
        final ms = d.localPosition.dx / kPeriodWidth;
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
        widget.controller.play(context);
        setState(() {
          localPosition = null;
          date = null;
        });
      },
      child: IgnorePointer(
        child: SizedBox(
          width: widget.width,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              widget.child,
              if (localPosition != null && date != null)
                PositionedDirectional(
                  start: localPosition!.dx - _TimelineItemGestures.kPopupWidth,
                  child: IgnorePointer(
                    child: Container(
                      height: kTimelineTileHeight,
                      width: _TimelineItemGestures.kPopupWidth,
                      color: Colors.grey,
                      padding: const EdgeInsets.symmetric(horizontal: 8.0),
                      margin: const EdgeInsets.only(bottom: 2.5),
                      alignment: Alignment.center,
                      child: AutoSizeText(
                        '${DateFormat.Hms().format(date!)} - ${DateFormat.Hms().format(widget.item.start)}',
                        maxLines: 1,
                        minFontSize: 8.0,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
