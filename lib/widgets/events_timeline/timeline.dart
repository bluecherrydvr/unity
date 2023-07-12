import 'dart:async';
import 'dart:math';

import 'package:bluecherry_client/providers/settings_provider.dart';
import 'package:bluecherry_client/utils/extensions.dart';
import 'package:bluecherry_client/utils/theme.dart';
import 'package:bluecherry_client/widgets/device_grid/device_grid.dart'
    show calculateCrossAxisCount;
import 'package:bluecherry_client/widgets/misc.dart';
import 'package:bluecherry_client/widgets/reorderable_static_grid.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:intl/intl.dart';
import 'package:unity_video_player/unity_video_player.dart';

class TimelineTile {
  final String device;
  final List<TimelineEvent> events;

  late final UnityVideoPlayer videoController;

  TimelineTile({
    required this.device,
    required this.events,
  }) {
    videoController = UnityVideoPlayer.create();
  }
}

class TimelineEvent {
  /// The duration of the event
  final Duration duration;

  /// When the event started
  final DateTime startTime;

  final String videoUrl;

  TimelineEvent({
    required this.duration,
    required this.startTime,
    this.videoUrl =
        'https://user-images.githubusercontent.com/28951144/229373695-22f88f13-d18f-4288-9bf1-c3e078d83722.mp4',
  });

  static List<TimelineEvent> get fakeData {
    return [
      TimelineEvent(
        duration: const Duration(minutes: 1),
        startTime: DateTime(2023).add(
          Duration(hours: Random().nextInt(4), minutes: Random().nextInt(60)),
        ),
      ),
      TimelineEvent(
        duration: const Duration(hours: 1),
        startTime: DateTime(2023).add(Duration(hours: Random().nextInt(4) + 5)),
      ),
      TimelineEvent(
        duration: const Duration(minutes: 1),
        startTime: DateTime(2023).add(Duration(hours: Random().nextInt(4) + 9)),
      ),
      TimelineEvent(
        duration: const Duration(minutes: 1),
        startTime: DateTime(2023).add(
          Duration(
            hours: Random().nextInt(4) + 13,
            minutes: Random().nextInt(60),
          ),
        ),
      ),
      TimelineEvent(
        duration: const Duration(minutes: 1),
        startTime: DateTime(2023).add(
          Duration(
            hours: Random().nextInt(4) + 14,
            minutes: Random().nextInt(60),
          ),
        ),
      ),
      TimelineEvent(
        duration: const Duration(minutes: 1),
        startTime: DateTime(2023).add(
          Duration(
            hours: Random().nextInt(4) + 20,
            minutes: Random().nextInt(60),
          ),
        ),
      ),
    ];
  }

  DateTime get endTime => startTime.add(duration);

  bool isPlaying(DateTime currentDate) {
    return currentDate.isInBetween(startTime, endTime);
  }

  /// The position of the video at the [currentDate]
  Duration position(DateTime currentDate) {
    return currentDate.difference(startTime);
  }
}

/// A timeline of events
///
/// Events are played as they happened in time. The timeline is limited to a
/// single day, so events are from hour 0 to 23.
class Timeline extends ChangeNotifier {
  /// Each tile of the timeline
  final List<TimelineTile> tiles;

  /// All the events must have happened in the same day
  final DateTime date;

  Timeline({required this.tiles, required this.date}) {
    assert(tiles.every((tile) {
      return tile.events.every((event) =>
          event.startTime.year == date.year &&
          event.startTime.month == date.month &&
          event.startTime.day == date.day);
    }), 'All events must have happened in the same day');
    tiles.removeWhere((tile) => tile.events.isEmpty);
  }

  Timeline.placeholder()
      : date = DateTime(2023),
        tiles = [];

  static Timeline get fakeTimeline {
    return Timeline(
      date: DateTime(2023),
      tiles: [
        TimelineTile(device: 'device1', events: TimelineEvent.fakeData),
        TimelineTile(device: 'device2', events: TimelineEvent.fakeData),
        TimelineTile(device: 'device3', events: TimelineEvent.fakeData),
        TimelineTile(device: 'device4', events: TimelineEvent.fakeData),
      ],
    );
  }

  void add(List<TimelineTile> tiles) {
    assert(tiles.every((tile) {
      return tile.events.every((event) =>
          event.startTime.year == date.year &&
          event.startTime.month == date.month &&
          event.startTime.day == date.day);
    }), 'All events must have happened in the same day');
    tiles.addAll(tiles);
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

  DateTime get currentDate => date.add(currentPosition);

  void seekTo(Duration position) {
    currentPosition = position;
    notifyListeners();

    // forEachEvent((device, event) {
    //   if (!event.isPlaying(currentDate)) return;

    //   final position = event.position(currentDate);
    //   event.videoController.seekTo(position);

    //   debugPrint('Seeking $device to $position');
    // });
  }

  double _volume = 1.0;
  bool get isMuted => volume == 0;
  double get volume => _volume;
  set volume(double value) {
    _volume = value;
    notifyListeners();
  }

  double _speed = 1.0;
  double get speed => _speed;
  set speed(double value) {
    _speed = value;
    stop();
    play();
    notifyListeners();
  }

  Timer? timer;
  bool get isPlaying => timer != null && timer!.isActive;

  void stop() {
    if (timer == null) return;

    timer?.cancel();
    timer = null;

    for (final tile in tiles) {
      tile.videoController.pause();
    }
  }

  void play() {
    timer ??= Timer.periodic(
      Duration(milliseconds: 1000 ~/ _speed),
      (timer) {
        currentPosition += const Duration(seconds: 1);
        notifyListeners();

        forEachEvent((tile, event) {
          if (event.isPlaying(currentDate)) {
            tile.videoController.seekTo(event.position(currentDate));
          }
        });
      },
    );
  }

  @override
  void dispose() {
    stop();
    for (final tile in tiles) {
      tile.videoController.dispose();
    }
    super.dispose();
  }
}

const _kDeviceNameWidth = 100.0;
const _kTimelineTileHeight = 30.0;
final _minutesInADay = const Duration(days: 1).inMinutes;

class TimelineEventsView extends StatefulWidget {
  final Timeline? timeline;

  const TimelineEventsView({super.key, required this.timeline});

  @override
  State<TimelineEventsView> createState() => _TimelineEventsViewState();
}

class _TimelineEventsViewState extends State<TimelineEventsView> {
  double? _speed;
  double? _volume;

  @override
  void initState() {
    super.initState();
    widget.timeline?.addListener(_updateCallback);
  }

  void _updateCallback() {
    if (mounted) setState(() {});
  }

  Timeline get timeline => widget.timeline ?? Timeline.placeholder();

  @override
  void didUpdateWidget(covariant TimelineEventsView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.timeline != oldWidget.timeline) {
      oldWidget.timeline?.removeListener(_updateCallback);
      widget.timeline?.addListener(_updateCallback);
    }
  }

  @override
  void dispose() {
    timeline.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final loc = AppLocalizations.of(context);

    return Column(children: [
      Expanded(
        child: AspectRatio(
          aspectRatio: 16 / 9,
          child: StaticGrid(
            reorderable: false,
            crossAxisCount: calculateCrossAxisCount(
              timeline.tiles.length,
            ),
            onReorder: (a, b) {},
            childAspectRatio: 16 / 9,
            emptyChild: const Center(
              child: Text('No events :/'),
            ),
            children: timeline.tiles.map((tile) {
              final device = tile.device;
              final events = tile.events;

              final currentEvent = events.firstWhereOrNull((event) {
                return event.isPlaying(timeline.currentDate);
              });

              final isPlaying = currentEvent != null;

              return Card(
                key: ValueKey(device),
                clipBehavior: Clip.antiAlias,
                color: isPlaying ? Colors.black : null,
                child: currentEvent != null
                    ? UnityVideoView(
                        player: tile.videoController,
                        paneBuilder: (context, controller) {
                          return Container(
                            padding: const EdgeInsets.all(16.0),
                            child: RichText(
                              text: TextSpan(text: '', children: [
                                TextSpan(
                                  text: device,
                                  style: theme.textTheme.titleMedium!.copyWith(
                                    shadows: outlinedText(strokeWidth: 0.75),
                                  ),
                                ),
                                const TextSpan(text: '\n'),
                                TextSpan(
                                  text: currentEvent
                                      .position(timeline.currentDate)
                                      .humanReadableCompact(context),
                                  style: theme.textTheme.labelLarge!.copyWith(
                                    shadows: outlinedText(strokeWidth: 0.75),
                                  ),
                                ),
                                if (kDebugMode) ...[
                                  const TextSpan(text: '\n'),
                                  TextSpan(
                                    text: controller.currentPos
                                        .humanReadableCompact(context),
                                    style: theme.textTheme.labelLarge!.copyWith(
                                      shadows: outlinedText(strokeWidth: 0.75),
                                    ),
                                  ),
                                  const TextSpan(text: '\n'),
                                  TextSpan(
                                    text: events
                                        .where((event) => event
                                            .isPlaying(timeline.currentDate))
                                        .length
                                        .toString(),
                                    style: theme.textTheme.labelLarge!.copyWith(
                                      shadows: outlinedText(strokeWidth: 0.75),
                                    ),
                                  ),
                                ]
                              ]),
                            ),
                          );
                        },
                      )
                    : Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Stack(children: [
                          Text(
                            device,
                            style: theme.textTheme.titleMedium,
                          ),
                          Center(
                            child: Text(loc.noRecords),
                          ),
                        ]),
                      ),
                // child: Text(
                //   '$device '
                //   '${currentEvent?.position(timeline.currentDate).humanReadableCompact(context)}',
                // ),
              );
            }).toList(),
          ),
        ),
      ),
      Card(
        clipBehavior: Clip.antiAlias,
        child: LayoutBuilder(builder: (context, constraints) {
          final minuteWidth =
              (constraints.maxWidth - _kDeviceNameWidth) / _minutesInADay;

          return Column(mainAxisAlignment: MainAxisAlignment.end, children: [
            Padding(
              padding: const EdgeInsetsDirectional.only(
                bottom: 4.0,
                top: 2.0,
                start: 8.0,
                end: 8.0,
              ),
              child:
                  Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                Expanded(
                  child:
                      Row(mainAxisAlignment: MainAxisAlignment.end, children: [
                    const TimelineCaption(),
                    const Spacer(),
                    Text(
                      '${(_speed ?? timeline.speed) == 1.0 ? '1' : (_speed ?? timeline.speed).toStringAsFixed(1)}'
                      'x',
                    ),
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 120.0),
                      child: Slider(
                        value: _speed ?? timeline.speed,
                        min: 0.5,
                        max: 2.0,
                        onChanged: (s) => setState(() => _speed = s),
                        onChangeEnd: (s) {
                          _speed = null;
                          timeline.speed = s;
                          FocusScope.of(context).unfocus();
                        },
                      ),
                    ),
                  ]),
                ),
                const SizedBox(width: 20.0),
                IconButton(
                  icon: Icon(
                    timeline.isPlaying ? Icons.pause : Icons.play_arrow,
                  ),
                  onPressed: () {
                    setState(() {
                      if (timeline.isPlaying) {
                        timeline.stop();
                      } else {
                        timeline.play();
                      }
                    });
                  },
                ),
                const SizedBox(width: 20.0),
                Expanded(
                  child: Row(children: [
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 120.0),
                      child: Slider(
                        value: _volume ??
                            (timeline.isMuted ? 0.0 : timeline.volume),
                        onChanged: (v) => setState(() => _volume = v),
                        onChangeEnd: (v) {
                          _volume = null;
                          timeline.volume = v;
                          FocusScope.of(context).unfocus();
                        },
                      ),
                    ),
                    Icon(() {
                      final volume = _volume ?? timeline.volume;
                      if ((_volume == null || _volume == 0.0) &&
                          (timeline.isMuted || volume == 0.0)) {
                        return Icons.volume_off;
                      } else if (volume < 0.5) {
                        return Icons.volume_down;
                      } else {
                        return Icons.volume_up;
                      }
                    }()),
                  ]),
                ),
              ]),
            ),
            Text(
              '${SettingsProvider.instance.dateFormat.format(timeline.currentDate)} '
              '${DateFormat('hh:mm:ss a').format(timeline.currentDate)}',
            ),
            Stack(children: [
              Column(children: [
                Row(children: [
                  const SizedBox(width: _kDeviceNameWidth),
                  ...List.generate(24, (index) {
                    final hour = index + 1;
                    if (hour == 24) {
                      return const Expanded(child: SizedBox.shrink());
                    }

                    return Expanded(
                      child: Transform.translate(
                        offset: Offset(
                          hour.toString().length * 4,
                          0.0,
                        ),
                        child: Text(
                          '$hour',
                          style: theme.textTheme.labelMedium,
                          textAlign: TextAlign.end,
                        ),
                      ),
                    );
                  }),
                ]),
                GestureDetector(
                  onHorizontalDragUpdate: (details) {
                    final pointerPosition =
                        (details.localPosition.dx - _kDeviceNameWidth) /
                            (constraints.maxWidth - _kDeviceNameWidth);
                    if (pointerPosition < 0 || pointerPosition > 1) return;

                    final minutes = (_minutesInADay * pointerPosition).round();
                    final position = Duration(minutes: minutes);
                    timeline.seekTo(position);
                  },
                  child: Column(children: [
                    ...timeline.tiles.map((tile) {
                      return _TimelineTile(tile: tile);
                    }),
                  ]),
                )
              ]),
              Positioned(
                left: (timeline.currentPosition.inMinutes * minuteWidth) +
                    _kDeviceNameWidth,
                width: 1.8,
                top: 16.0,
                height: _kTimelineTileHeight * timeline.tiles.length,
                child: const IgnorePointer(
                  child: ColoredBox(
                    color: Colors.white,
                  ),
                ),
              ),
            ]),
          ]);
        }),
      ),
    ]);
  }
}

class TimelineCaption extends StatelessWidget {
  const TimelineCaption({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(children: [
          Container(
            height: 11.0,
            width: 11.0,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(2.0),
              color: theme.colorScheme.primary,
            ),
            margin: const EdgeInsetsDirectional.only(end: 4.0),
          ),
          Text('Events', style: theme.textTheme.bodySmall),
        ]),
        Row(children: [
          Container(
            height: 11.0,
            width: 11.0,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(2.0),
              color: theme.extension<TimelineTheme>()!.eventColor,
            ),
            margin: const EdgeInsetsDirectional.only(end: 4.0),
          ),
          Text('Buffered events', style: theme.textTheme.bodySmall),
        ])
      ],
    );
  }
}

class _TimelineTile extends StatelessWidget {
  final TimelineTile tile;

  const _TimelineTile({super.key, required this.tile});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final border = Border(
      right: BorderSide(color: theme.disabledColor.withOpacity(0.5)),
      top: BorderSide(color: theme.dividerColor.withOpacity(0.5)),
    );

    return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Container(
        width: _kDeviceNameWidth,
        height: _kTimelineTileHeight,
        padding: const EdgeInsets.symmetric(horizontal: 3.0),
        decoration: BoxDecoration(
          color: theme.dialogBackgroundColor,
          border: border,
        ),
        alignment: AlignmentDirectional.centerStart,
        child: RichText(
          text: TextSpan(
            children: [
              TextSpan(text: tile.device),
              TextSpan(
                text: ' (${tile.events.length})',
                style: const TextStyle(fontSize: 11.0),
              ),
            ],
          ),
        ),
      ),
      ...List.generate(24, (index) {
        final hour = index;

        return Expanded(
          child: Container(
            height: _kTimelineTileHeight,
            decoration: BoxDecoration(border: border),
            child: LayoutBuilder(builder: (context, constraints) {
              if (!tile.events.any((event) => event.startTime.hour == hour)) {
                return const SizedBox.shrink();
              }

              final minuteWidth = constraints.maxWidth / 60;
              return Stack(clipBehavior: Clip.none, children: [
                for (final event in tile.events
                    .where((event) => event.startTime.hour == hour))
                  Positioned(
                    left: event.startTime.minute * minuteWidth,
                    width: event.duration.inMinutes * minuteWidth,
                    height: _kTimelineTileHeight,
                    child: ColoredBox(
                      color: theme.colorScheme.primary,
                    ),
                  ),
                // Positioned(
                //   left: event.startTime.minute * minuteWidth,
                //   width: tile.videoController.currentBuffer.inMinutes *
                //       minuteWidth,
                //   height: _kTimelineTileHeight,
                //   child: ColoredBox(
                //     color: theme.extension<TimelineTheme>()!.eventColor,
                //   ),
                // ),
              ]);
            }),
          ),
        );
      }),
    ]);
  }
}
