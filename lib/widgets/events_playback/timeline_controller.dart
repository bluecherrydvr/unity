import 'dart:async';

import 'package:auto_size_text/auto_size_text.dart';
import 'package:bluecherry_client/models/event.dart';
import 'package:bluecherry_client/providers/home_provider.dart';
import 'package:bluecherry_client/providers/server_provider.dart';
import 'package:bluecherry_client/utils/extensions.dart';
import 'package:bluecherry_client/widgets/events_playback/events_playback.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:provider/provider.dart';
import 'package:unity_video_player/unity_video_player.dart';

const kDeviceNameWidth = 140.0;
const kTimelineViewHeight = 190.0;
const kTimelineTileHeight = 24.0;

const kPeriodWidth = 2.0;
const kGapWidth = 84.0;
const kGapDuration = Duration(seconds: 6);

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
  const TimelineItem();

  static List<TimelineItem> findGaps(List data) {
    final oldest = data[0] as DateTime;
    final newest = data[1] as DateTime;
    final allEvents = data[2] as Iterable<Event>;

    final gaps = <TimelineItem>[];
    var currentDateTime = oldest;
    TimelineItem? currentItem;

    while (!currentDateTime.hasForDate(newest)) {
      currentDateTime = currentDateTime.add(const Duration(seconds: 1));

      if (currentItem == null) {
        if (!allEvents.hasForDate(currentDateTime)) {
          currentItem = TimelineGap(
            start: currentDateTime,
            gapDuration: Duration.zero,
            end: currentDateTime,
          );
        } else {
          final forDate = allEvents.forDateList(currentDateTime);
          currentItem = TimelineValue(
            start: forDate.oldest.published,
            end: currentDateTime,
            duration: Duration.zero,
            events: forDate,
          );
        }
      } else {
        if (allEvents.hasForDate(currentDateTime)) {
          // ends the gap
          if (currentItem is TimelineGap) {
            currentItem = TimelineGap(
              start: currentItem.start,
              end: currentDateTime,
              gapDuration: currentDateTime.difference(currentItem.start),
            );
            gaps.add(currentItem);
            currentItem = null;
          }
        } else {
          // ends a timeline value
          if (currentItem is TimelineValue) {
            final events = allEvents
                .inBetween(currentItem.start, currentDateTime)
                .toList();
            // final duration = events.map((e) {
            //   if (e.mediaDuration != null) return e.mediaDuration!;

            //   return e.updated.difference(e.published);
            // }).reduce((a, b) => a + b);

            var duration = Duration.zero;
            Event? previous;
            for (final event in events) {
              if (previous == null) {
                previous = event;
                final eventDuration = event.mediaDuration ??
                    event.updated.difference(event.published);

                duration = duration + eventDuration;
              } else {
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
            // print(currentDateTime.difference(currentItem.start));
            gaps.add(currentItem);
            currentItem = null;
          }
        }
      }
    }

    return gaps;
  }
}

class TimelineValue extends TimelineItem {
  final Iterable<Event> events;

  final DateTime start;
  final DateTime end;

  final Duration duration;

  const TimelineValue({
    required this.events,
    required this.start,
    required this.end,
    required this.duration,
  });
}

class TimelineGap extends TimelineItem {
  final Duration gapDuration;
  final DateTime start;
  final DateTime end;

  const TimelineGap({
    required this.gapDuration,
    required this.start,
    required this.end,
  });

  @override
  String toString() =>
      'TimelineGap(gapDuration: $gapDuration, start: $start, end: $end)';

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is TimelineGap &&
        other.gapDuration == gapDuration &&
        other.start == start &&
        other.end == end;
  }

  @override
  int get hashCode => gapDuration.hashCode ^ start.hashCode ^ end.hashCode;
}

class TimelineController extends ChangeNotifier {
  List<TimelineTile> tiles = [];
  Event? oldest;
  Event? newest;

  /// The duration of all events summed
  Duration duration = Duration.zero;
  List<TimelineItem> timeGaps = [];

  late Timer? timer;
  void startTimer() {
    timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      // currentItem = timeGaps.firstWhere((tg) {
      //   if (tg is TimelineGap) {

      //   }
      // });
      position = position + const Duration(seconds: 1);
      positionNotifier.notifyListeners();
    });
  }

  Duration position = Duration.zero;
  final positionNotifier = ChangeNotifier();

  double progress = 0.0;
  DateTime get currentPeriod => DateTime.now();
  TimelineItem? currentItem;

  double speed = 1;

  TimelineController() {
    startTimer();
  }

  bool get initialized {
    return timeGaps.isNotEmpty;
  }

  /// [events] all the events split by device
  ///
  /// [allEvents] all events in the history
  Future<void> initialize(
    EventsData events,
    List<Event> allEvents,
    TickerProvider vsync,
  ) async {
    HomeProvider.instance.loading(
      UnityLoadingReason.fetchingEventsPlaybackPeriods,
      notify: false,
    );
    await clear();
    notifyListeners();

    oldest = allEvents.oldest;
    newest = allEvents.newest;

    notifyListeners();

    for (final event in events.entries) {
      final id = event.key;
      final ev = event.value;
      final item = TimelineTile(
        deviceId: id,
        events: ev,
        player: UnityVideoPlayer.create(),
      );
      // item.player.onPlayingStateUpdate.listen((playing) {
      //   if (playing) controller?.forward();
      //   notifyListeners();
      // });
      // item.player
      //     .setMultipleDataSource(
      //   // we can ensure the url is not null because we filter for alarms above
      //   ev.where((event) => event.mediaURL != null).map((event) {
      //     return event.mediaURL!.toString();
      //   }).toList(),
      //   autoPlay: false,
      // )
      //     .then((value) {
      //   controller?.forward();
      // });
      tiles.add(item);
    }

    timeGaps = await compute(TimelineItem.findGaps, [
      oldest!.published,
      newest!.published,
      allEvents,
    ]);
    currentItem = timeGaps.first;

    duration = timeGaps.map((item) {
      if (item is TimelineValue) {
        return item.duration;
      } else if (item is TimelineGap) {
        return kGapDuration;
      } else {
        throw UnsupportedError('${item.runtimeType} is not supported');
      }
    }).reduce((a, b) => a + b);

    startTimer();

    HomeProvider.instance.notLoading(
      UnityLoadingReason.fetchingEventsPlaybackPeriods,
    );

    notifyListeners();
  }

  /// Starts all players
  Future<void> play() async {
    startTimer();

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
    await Future.wait(tiles.map((i) => i.player.pause()));
    // controller?.stop();
    timer?.cancel();

    notifyListeners();
  }

  Future<void> clear() async {
    for (final item in tiles) {
      await item.player.release();
      item.player.dispose();
    }

    tiles.clear();
    // periods.clear();
  }

  @override
  Future<void> dispose() async {
    super.dispose();
    clear();
    timer?.cancel();

    // controller?.dispose();
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
                scrollDirection: Axis.horizontal,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: timelineController.tiles.map((tile) {
                    return Container(
                      height: kTimelineTileHeight,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade400,
                        border: const Border(bottom: BorderSide()),
                      ),
                      child: Row(
                          children: timelineController.timeGaps.map((i) {
                        if (i is TimelineGap) {
                          return Container(
                            width: kGapWidth,
                            height: kTimelineTileHeight,
                            padding: const EdgeInsets.symmetric(horizontal: 5),
                            alignment: Alignment.center,
                            child: AutoSizeText(
                              i.gapDuration.humanReadableCompact(context, true),
                              maxLines: 1,
                              textAlign: TextAlign.center,
                            ),
                          );
                        } else if (i is TimelineValue) {
                          return SizedBox(
                            height: kTimelineTileHeight,
                            width: i.duration.inSeconds * kPeriodWidth,
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
                                    width: duration.inSeconds * kPeriodWidth,
                                    color: event == null
                                        ? null
                                        : event.isAlarm
                                            ? Colors.amber
                                            : Colors.green,
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 4),
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
              Positioned(
                left: timelineController.position.inSeconds.toDouble(),
                height: kTimelineViewHeight,
                width: 4.0,
                child: Container(
                  height: kTimelineViewHeight,
                  color: Colors.deepOrange,
                ),
              ),
          ]),
        ),
      ]),
    );

    // final maxWidth = timelineController.controller == null
    //     ? 100.0
    //     : timelineController.duration.inSeconds * kPeriodWidth;

    // final servers = context.read<ServersProvider>().servers;

    // return SizedBox(
    //   height: maxHeight,
    //   child: Row(children: [
    //     Column(
    //         children: timelineController.tiles.map((i) {
    //       // final device = servers.findDevice(i.deviceId)!;
    //       // final server = servers.firstWhere((s) => s.ip == device.server.ip);

    //       return SizedBox(
    //         height: kTimelineTileHeight,
    //         width: kDeviceNameWidth,
    //         child: Padding(
    //           padding: const EdgeInsets.symmetric(horizontal: 8.0),
    //           child: AutoSizeText(
    //             // '${server.name}/${device.name}',
    //             '${i.deviceId}',
    //             maxLines: 1,
    //             overflow: TextOverflow.fade,
    //           ),
    //         ),
    //       );
    //     }).toList()),
    //     const VerticalDivider(width: 2.0),
    //     Expanded(
    //       child: SingleChildScrollView(
    //         scrollDirection: Axis.horizontal,
    //         child: Container(
    //           width: maxWidth,
    //           height: maxHeight,
    //           color: Colors.grey.shade400,
    //           child: Stack(children: [
    //             Positioned.fill(
    //               child: Column(
    //                   children: timelineController.tiles.map((item) {
    //                 return Container(
    //                   height: kTimelineTileHeight,
    //                   width: maxWidth,
    //                   decoration: BoxDecoration(
    //                     border: Border(
    //                       bottom: BorderSide(
    //                         color: Theme.of(context).canvasColor,
    //                       ),
    //                     ),
    //                   ),
    //                   child: Stack(
    //                       children: item.events.map((event) {
    //                     final mediaDuration = event.mediaDuration ??
    //                         event.updated.difference(event.published);
    //                     // print(
    //                     //     '$maxWidth ${event.published.difference(timelineController.oldest!.published).inSeconds.toDouble() * kPeriodWidth} ${kPeriodWidth * mediaDuration.inSeconds}');
    //                     final to = event.published.add(mediaDuration);

    //                     return Positioned(
    //                       top: 0,
    //                       bottom: 0,
    //                       // left: timelineController.oldest!.published
    //                       //         .difference(event.published)
    //                       //         .inSeconds
    //                       //         .toDouble() *
    //                       //     kPeriodWidth,
    //                       left: event.published
    //                               .difference(
    //                                   timelineController.oldest!.published)
    //                               .inSeconds
    //                               .toDouble() *
    //                           kPeriodWidth,
    //                       width: kPeriodWidth * mediaDuration.inSeconds,
    //                       child: Tooltip(
    //                         message:
    //                             'From: ${SettingsProvider.instance.dateFormat.format(event.published)}'
    //                             ' at ${SettingsProvider.instance.timeFormat.format(event.published)} \n'
    //                             'to ${SettingsProvider.instance.dateFormat.format(to)}'
    //                             ' at ${SettingsProvider.instance.timeFormat.format(to)}',
    //                         child: Container(
    //                           decoration: BoxDecoration(
    //                             color: event.isAlarm
    //                                 ? Colors.red
    //                                 : Colors.green.shade700,
    //                           ),
    //                         ),
    //                       ),
    //                     );
    //                   }).toList()),
    //                 );
    //               }).toList()),
    //             ),
    //             if (timelineController.controller != null)
    //               AnimatedBuilder(
    //                 animation: timelineController.controller!,
    //                 builder: (context, child) {
    //                   final left = Tween<double>(
    //                     begin: 0,
    //                     end: maxWidth,
    //                   ).evaluate(timelineController.controller!);

    //                   return Positioned(
    //                     top: 0,
    //                     bottom: 0,
    //                     left: left,
    //                     child: child!,
    //                   );
    //                 },
    //                 child: GestureDetector(
    //                   onHorizontalDragStart: (_) {
    //                     timelineController.controller!.stop();
    //                   },
    //                   onHorizontalDragUpdate: (d) {
    //                     // if lower than 0 or greater than 1, it means it's off the
    //                     // bounds of the scroller
    //                     final pos =
    //                         (d.localPosition.dx / maxWidth).clamp(0.0, 1.0);
    //                     debugPrint('${d.localPosition.dx}/$maxWidth $pos');

    //                     timelineController.controller!.value = pos;
    //                   },
    //                   onHorizontalDragEnd: (_) {
    //                     timelineController.controller!.forward();

    //                     debugPrint('${timelineController.currentPeriod}');
    //                   },
    //                   child: Container(
    //                     height: double.infinity,
    //                     width: kPeriodWidth,
    //                     color: Colors.amber,
    //                   ),
    //                 ),
    //               ),
    //           ]),
    //         ),
    //       ),
    //     ),
    //   ]),
    // );
  }
}
