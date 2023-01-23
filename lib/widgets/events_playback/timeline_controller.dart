import 'dart:async';

import 'package:auto_size_text/auto_size_text.dart';
import 'package:bluecherry_client/models/event.dart';
import 'package:bluecherry_client/providers/home_provider.dart';
import 'package:bluecherry_client/providers/server_provider.dart';
import 'package:bluecherry_client/utils/extensions.dart';
import 'package:bluecherry_client/widgets/events_playback/events_playback.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:unity_video_player/unity_video_player.dart';

const kDeviceNameWidth = 140.0;
const kTimelineViewHeight = 190.0;
const kTimelineTileHeight = 24.0;

/// The width of a millisecond
const kPeriodWidth = 0.01;
const kGapDuration = Duration(seconds: 6);
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

  /// Returns a list with useful data
  ///
  /// * 0 - List<TimelineItem>
  /// * 1 - Duration
  /// * 2 - Oldest [Event]
  /// * 3 - Newest [Event]
  static List calculateTimeline(List data) {
    final allEvents = data[0] as Iterable<Event>;

    final oldestEvent = allEvents.oldest;
    final newestEvent = allEvents.newest;

    final oldest = oldestEvent.published;
    final newest = newestEvent.published;

    final timelineEvents = <TimelineItem>[];
    var currentDateTime = oldest;
    TimelineItem? currentItem;

    while (!currentDateTime.hasForDate(newest)) {
      void increment() =>
          currentDateTime = currentDateTime.add(const Duration(minutes: 1));

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
          final start = timelineEvents.isEmpty
              ? currentDateTime
              : timelineEvents.last.end;
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
            timelineEvents.add(currentItem);
            // currentDateTime = timelineEvents.last.end;
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
            timelineEvents.add(currentItem);
            // currentDateTime = timelineEvents.last.end;
            currentItem = null;
          } else {
            increment();
          }
        }
      }
    }

    final duration = timelineEvents.map((item) {
      if (item is TimelineValue) {
        return item.duration;
      } else if (item is TimelineGap) {
        return kGapDuration;
      } else {
        throw UnsupportedError('${item.runtimeType} is not supported');
      }
    }).reduce((a, b) => a + b);

    return [
      timelineEvents,
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

  List<TimelineTile> tiles = [];
  Event? oldest;
  Event? newest;

  /// The duration of all events summed
  Duration duration = Duration.zero;
  List<TimelineItem> timelineEvents = [];

  Timer? timer;
  void startTimer() {
    // do not initialize it twice, otherwise it may cause inconsistency
    if (timer != null) return;

    const interval = Duration(milliseconds: 100);
    timer = Timer.periodic(interval, (timer) {
      if (oldest == null) return;

      void add(Duration duration, {bool isGap = false}) {
        _position = _position + duration;
        currentDate = oldest!.published.add(_position);
        if (isGap) {
          _thumbPosition = _thumbPosition + kGapDuration;
        } else {
          _thumbPosition = _thumbPosition + duration;
        }
      }

      bool check(TimelineItem e) {
        if (e is TimelineGap) {
          return currentDate.isInBetween(e.start, e.end);
        } else if (e is TimelineValue) {
          return e.events.hasForDate(currentDate);
        } else {
          throw UnsupportedError('${e.runtimeType} is not supported');
        }
      }

      // Usually, if no events were found, it probably means there is a gap between
      // events in a single [TimelineItem]. >>should<< be normal
      final itemForDate = timelineEvents.any(check)
          ? timelineEvents.firstWhere(check)
          : currentItem;

      if (itemForDate is TimelineGap) {
        add(itemForDate.duration, isGap: true);
      } else if (itemForDate is TimelineValue) {
        add(interval);
      }

      if (currentItem != itemForDate) {
        currentItem = itemForDate;
        notifyListeners();
      }
      positionNotifier.notifyListeners();
    });
  }

  /// The position of the current item, considering the gaps
  Duration _position = Duration.zero;

  /// The position of the thumb, considering gaps with the duration of [kGapDuration]
  Duration _thumbPosition = Duration.zero;

  DateTime currentDate = DateTime(0);
  final positionNotifier = ChangeNotifier();

  double progress = 0.0;
  TimelineItem? currentItem;

  double speed = 1;

  TimelineController();

  /// Whether this controller is initialized
  ///
  /// See also:
  ///
  /// * [initialize], which initializes the timeline view
  bool get initialized {
    return timelineEvents.isNotEmpty;
  }

  /// [events] all the events split by device
  ///
  /// [allEvents] all events in the history
  Future<void> initialize(
    EventsData events,
    List<Event> allEvents,
  ) async {
    HomeProvider.instance
        .loading(UnityLoadingReason.fetchingEventsPlaybackPeriods);
    await _clear();
    notifyListeners();

    positionNotifier.notifyListeners();

    for (final event in events.entries) {
      final id = event.key;
      final events = event.value;
      final item = TimelineTile(
        deviceId: id,
        events: events,
        player: UnityVideoPlayer.create(),
      );
      item.player.onPlayingStateUpdate.listen((playing) {
        if (playing) {
          play();
        } else {
          pause();
        }
        notifyListeners();
      });
      item.player.setMultipleDataSource(
        // we can ensure the url is not null because we filter for alarms above
        item.events.where((event) => event.mediaURL != null).map((event) {
          return event.mediaURL!.toString();
        }).toList(),
        autoPlay: false,
      );
      tiles.add(item);
    }

    final result = await compute(TimelineItem.calculateTimeline, [allEvents]);
    timelineEvents = result[0] as List<TimelineItem>;

    duration = result[1] as Duration;

    oldest = result[2] as Event;
    newest = result[2] as Event;

    currentDate = oldest!.published;

    HomeProvider.instance.notLoading(
      UnityLoadingReason.fetchingEventsPlaybackPeriods,
    );

    startTimer();
    notifyListeners();
  }

  /// Starts all players
  Future<void> play() async {
    startTimer();
    await Future.wait(tiles.map((i) => i.player.start()));

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
    // controller?.stop();

    notifyListeners();
  }

  @protected
  Future<void> _clear() async {
    for (final item in tiles) {
      await item.player.release();
      item.player.dispose();
    }

    tiles.clear();
    timelineEvents.clear();

    _thumbPosition = Duration.zero;
    _position = Duration.zero;
  }

  @override
  Future<void> dispose() async {
    super.dispose();
    _clear();
    timer?.cancel();
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
    final maxHeight = timelineController.tiles.length * kTimelineTileHeight;

    final servers = context.watch<ServersProvider>().servers;

    return SizedBox(
      height: maxHeight,
      child: Row(children: [
        Column(
            children: timelineController.tiles.map((i) {
          final device = servers.findDevice(i.deviceId)!;
          final server = servers.firstWhere((s) => s.ip == device.server.ip);

          return SizedBox(
            height: kTimelineTileHeight,
            width: kDeviceNameWidth,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              child: AutoSizeText(
                '${server.name}/${device.name}',
                maxLines: 1,
                overflow: TextOverflow.fade,
                maxFontSize: 12.0,
              ),
            ),
          );
        }).toList()),
        const VerticalDivider(width: 2.0),
        Expanded(
          child: Stack(children: [
            Positioned.fill(
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
                          children: timelineController.timelineEvents.map((i) {
                        if (i is TimelineGap) {
                          return Container(
                            width: kGapWidth,
                            height: kTimelineTileHeight,
                            padding: const EdgeInsets.symmetric(horizontal: 5),
                            alignment: Alignment.center,
                            color: Colors.grey.shade400,
                            child: AutoSizeText(
                              i.duration.humanReadableCompact(context, true),
                              maxLines: 1,
                              minFontSize: 8.0,
                              maxFontSize: 10.0,
                              textAlign: TextAlign.center,
                              style: const TextStyle(color: Colors.black),
                            ),
                          );
                        } else if (i is TimelineValue) {
                          return SizedBox(
                            height: kTimelineTileHeight,
                            width: i.duration.inMilliseconds * kPeriodWidth,
                            child: () {
                              final events =
                                  tile.events.inBetween(i.start, i.end);

                              if (events.isEmpty) {
                                // return const Text('-');
                                return const SizedBox.shrink();
                              }

                              Widget buildForEvent(
                                Event? event,
                                Duration duration,
                              ) {
                                return Tooltip(
                                  message:
                                      duration.humanReadableCompact(context),
                                  preferBelow: false,
                                  verticalOffset: 14.0,
                                  child: Container(
                                    height: kTimelineTileHeight,
                                    width:
                                        duration.inMilliseconds * kPeriodWidth,
                                    color: event == null
                                        ? null
                                        : event.isAlarm
                                            ? Colors.amber
                                            : Colors.green,
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 4,
                                    ),
                                  ),
                                );
                              }

                              var widgets = <Widget>[];

                              Event? previous;
                              for (final event in events) {
                                if (previous == null) {
                                  previous = event;
                                  final duration = event.mediaDuration ??
                                      event.updated.difference(event.published);

                                  widgets.add(buildForEvent(event, duration));
                                } else {
                                  final previousEnd = previous.published.add(
                                    previous.mediaDuration ??
                                        (previous.updated
                                            .difference(previous.published)),
                                  );
                                  final difference =
                                      previousEnd.difference(event.published);

                                  widgets.add(buildForEvent(null, difference));

                                  final duration = event.mediaDuration ??
                                      event.updated.difference(event.published);
                                  widgets.add(buildForEvent(event, duration));
                                }
                              }

                              return Row(children: widgets);
                            }(),
                          );
                        } else {
                          throw UnsupportedError('Unsupported');
                        }
                      }).toList()),
                    );
                  }).toList(),
                ),
              ),
            ),
            if (timelineController.initialized)
              RepaintBoundary(
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

                    return Padding(
                      padding: EdgeInsets.only(left: x),
                      child: child!,
                    );
                  },
                  child: IgnorePointer(
                    child: Container(
                      height: kTimelineViewHeight,
                      width: 4.0,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                ),
              ),
          ]),
        ),
      ]),
    );
  }
}
