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
import 'package:provider/provider.dart';

import 'package:unity_video_player/unity_video_player.dart';

const kDeviceNameWidth = 140.0;
const kTimelineViewHeight = 190.0;
const kTimelineTileHeight = 24.0;

const kTimelineThumbWidth = 2.5;
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

    // The interval time is the duration of the shortest event
    final intervalTime = () {
      final eventsDuration = allEvents
          .map((e) => e.mediaDuration ?? e.updated.difference(e.published))
          .toList()
        ..sort((a, b) => a.compareTo(b));
      return eventsDuration.first;
    }();

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

  void add(Duration duration, {bool isGap = false}) {
    _position = _position + duration;
    currentDate = oldest!.published.add(_position);
    if (!isGap) _thumbPosition = _thumbPosition + duration;
    _updateThumbPosition();
  }

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

  void _updateThumbPosition() {
    if (scrollController.hasClients) {
      final thumbX = _thumbPosition.inMilliseconds * kPeriodWidth -
          scrollController.offset;

      if (thumbX >
          scrollController.position.viewportDimension -
              kTimelineThumbOverflowPadding) {
        scrollController.jumpTo(
          scrollController.offset + kTimelineThumbOverflowPadding / 2,
        );
      }
    }
  }

  double? _placeholderSeekX;
  void seek(double x) {
    final viewport = scrollController.position.viewportDimension;

    if (x > viewport) return;

    final pos = scrollController.offset + x;

    final fullDuration = timelineEvents.map((e) {
      if (e is TimelineGap) return kGapDuration;

      return e.duration;
    }).reduce((a, b) => a + b);

    debugPrint('$fullDuration $pos');
  }

  /// A ticker that runs every [interval]
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
      return timelineEvents.any((e) => currentDate.isInBetween(e.start, e.end));
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

      bool checkForDate(TimelineItem e, DateTime date) {
        if (e is TimelineGap) {
          return date.isInBetween(e.start, e.end);
        } else if (e is TimelineValue) {
          return e.events.hasForDate(date);
        } else {
          throw UnsupportedError('${e.runtimeType} is not supported');
        }
      }

      /// Usually, if no events were found, it probably means there is a gap between
      /// events in a single [TimelineItem]. >>should<< be normal.
      final itemForDate =
          timelineEvents.any((e) => checkForDate(e, currentDate))
              ? timelineEvents.firstWhere((e) => checkForDate(e, currentDate))
              : currentItem;

      /// If the current item is a gap, we add it according to the (current ticker duration * speed)
      /// When it reaches the max gap duration (kGapDuration), it preloads the next item.
      if (itemForDate is TimelineGap) {
        addGap(itemForDate.duration, interval * speed);

        final nextDate = currentDate.add(itemForDate.duration);

        if (timelineEvents.any(
          (e) => e is TimelineValue && checkForDate(e, nextDate),
        )) {
          final next = timelineEvents.firstWhere(
            (e) => e is TimelineValue && checkForDate(e, nextDate),
          ) as TimelineValue;

          for (final event in next.events) {
            final tile =
                tiles.firstWhere((tile) => tile.events.contains(event));

            final mediaUrl = event.mediaURL!.toString();

            if (!event.isAlarm && tile.player.dataSource != mediaUrl) {
              tile.player.setDataSource(
                mediaUrl,
                autoPlay: false,
              );
            }
          }
        }
      } else if (itemForDate is TimelineValue) {
        /// If the event is an alarm, we add it according to the (current ticker duration * speed)
        ///
        /// Otherwise, the duration that is added is the *difference* between the
        /// last added position and the current position
        ///
        /// Check the listener for [onCurrentPosUpdate] in [initialize] for more
        /// info on how this is done
        if (itemForDate.events.hasForDate(currentDate)) {
          final event = itemForDate.events.forDate(currentDate);
          if (event.isAlarm) add(interval * speed);
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

        if (events.hasForDate(currentDate)) {
          final event = events.forDate(currentDate);
          if (tiles.any((tile) => tile.events.contains(event))) {
            final tile =
                tiles.firstWhere((tile) => tile.events.contains(event));
            if (event.mediaURL != null) {
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
  final positionNotifier = ChangeNotifier();

  /// The position of the thumb, considering gaps with the duration of [kGapDuration]
  Duration _thumbPosition = Duration.zero;

  /// This makes animating with gap possible
  ///
  /// When it reaches [kGapDuration], we move to the next item. While the gap is
  /// running, we precache the next items
  Duration currentGapDuration = Duration.zero;
  DateTime currentDate = DateTime(0);
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

    _volume = volume;
    notifyListeners();
  }

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
    if (!context.mounted) return;

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
          if (buffering) {
            context
                .read<HomeProvider>()
                .loading(UnityLoadingReason.timelineEventLoading);
          } else {
            context
                .read<HomeProvider>()
                .notLoading(UnityLoadingReason.timelineEventLoading);
          }
        });
      tiles.add(item);
    }

    final result = await compute(TimelineItem.calculateTimeline, [allEvents]);
    timelineEvents = result[0] as List<TimelineItem>;

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
    // if (currentItem is TimelineValue) {
    //   // await (currentItem as TimelineValue).;
    //   if (tiles.any((tile) => tile.events.hasForDate(currentDate))) {
    //     final tile =
    //         tiles.firstWhere((tile) => tile.events.hasForDate(currentDate));
    //     tile.player.start();
    //   }
    // }

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

class TimelineView extends StatefulWidget {
  final TimelineController timelineController;

  const TimelineView({
    Key? key,
    required this.timelineController,
  }) : super(key: key);

  @override
  State<TimelineView> createState() => _TimelineViewState();
}

class _TimelineViewState extends State<TimelineView> {
  @override
  Widget build(BuildContext context) {
    final maxHeight =
        widget.timelineController.tiles.length * kTimelineTileHeight;

    final servers = context.watch<ServersProvider>().servers;

    return SizedBox(
      height: maxHeight,
      child: Row(children: [
        Column(
            children: widget.timelineController.tiles.map((i) {
          final device = servers.findDevice(i.deviceId)!;
          // final server = servers.firstWhere((s) => s.ip == device.server.ip);

          // device.fullName

          return SizedBox(
            height: kTimelineTileHeight,
            width: kDeviceNameWidth,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              child: AutoSizeText(
                device.fullName,
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
                controller: widget.timelineController.scrollController,
                scrollDirection: Axis.horizontal,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: widget.timelineController.tiles.map((tile) {
                    return Container(
                      height: kTimelineTileHeight,
                      decoration: const BoxDecoration(
                        border: Border(bottom: BorderSide()),
                      ),
                      child: Row(
                          children:
                              widget.timelineController.timelineEvents.map((i) {
                        if (i is TimelineGap) {
                          return Container(
                            width: kGapWidth,
                            height: kTimelineTileHeight,
                            padding: const EdgeInsets.symmetric(horizontal: 5),
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
                          );
                        } else if (i is TimelineValue) {
                          return SizedBox(
                            height: kTimelineTileHeight,
                            width: i.duration.inMilliseconds * kPeriodWidth,
                            child: () {
                              final events =
                                  tile.events.inBetween(i.start, i.end);

                              if (events.isEmpty) {
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
                                  verticalOffset: -12.0,
                                  decoration: const BoxDecoration(),
                                  child: Container(
                                    height: kTimelineTileHeight,
                                    width:
                                        duration.inMilliseconds * kPeriodWidth,
                                    color: event == null
                                        ? null
                                        : event.isAlarm
                                            ? Colors.amber
                                            : Colors.green,
                                    // padding: const EdgeInsets.symmetric(
                                    //   horizontal: 4,
                                    // ),
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
            if (widget.timelineController.initialized)
              RepaintBoundary(
                child: AnimatedBuilder(
                  animation: Listenable.merge([
                    widget.timelineController.scrollController,
                    widget.timelineController.positionNotifier,
                  ]),
                  builder: (context, child) {
                    final scrollOffset =
                        widget.timelineController.scrollController.hasClients
                            ? widget.timelineController.scrollController.offset
                            : 0.0;
                    final x = widget.timelineController._thumbPosition
                                .inMilliseconds *
                            kPeriodWidth -
                        scrollOffset;

                    if (x.isNegative) {
                      return const SizedBox(
                        height: kTimelineViewHeight,
                      );
                    }

                    return Padding(
                      padding: EdgeInsets.only(
                        left: widget.timelineController._placeholderSeekX ?? x,
                      ),
                      child: child!,
                    );
                  },
                  child: GestureDetector(
                    // onHorizontalDragUpdate: (d) {
                    //   setState(
                    //     () => widget.timelineController._placeholderSeekX =
                    //         d.localPosition.dx,
                    //   );
                    // },
                    // onHorizontalDragEnd: (d) {
                    //   widget.timelineController.seek(
                    //     widget.timelineController._placeholderSeekX!,
                    //   );
                    //   setState(
                    //     () =>
                    //         widget.timelineController._placeholderSeekX = null,
                    //   );
                    // },
                    child: Container(
                      height: kTimelineViewHeight,
                      width: kTimelineThumbWidth,
                      margin: const EdgeInsetsDirectional.only(end: 2.5),
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
