import 'dart:async';
import 'dart:math';

import 'package:bluecherry_client/providers/settings_provider.dart';
import 'package:bluecherry_client/utils/extensions.dart';
import 'package:bluecherry_client/widgets/device_grid/device_grid.dart'
    show calculateCrossAxisCount;
import 'package:bluecherry_client/widgets/reorderable_static_grid.dart';
import 'package:flutter/material.dart';

class TimelineEvent {
  /// The duration of the event
  final Duration duration;

  /// When the event started
  final DateTime startTime;

  const TimelineEvent({
    required this.duration,
    required this.startTime,
  });

  static List<TimelineEvent> get fakeData {
    return [
      TimelineEvent(
        duration: const Duration(minutes: 30),
        startTime: DateTime(2023).add(
          Duration(hours: Random().nextInt(4), minutes: Random().nextInt(60)),
        ),
      ),
      TimelineEvent(
        duration: const Duration(hours: 1),
        startTime: DateTime(2023).add(Duration(hours: Random().nextInt(4) + 5)),
      ),
      TimelineEvent(
        duration: const Duration(minutes: 40),
        startTime: DateTime(2023).add(Duration(hours: Random().nextInt(4) + 9)),
      ),
      TimelineEvent(
        duration: const Duration(minutes: 15),
        startTime: DateTime(2023).add(
          Duration(
            hours: Random().nextInt(4) + 13,
            minutes: Random().nextInt(60),
          ),
        ),
      ),
      TimelineEvent(
        duration: const Duration(minutes: 45),
        startTime: DateTime(2023).add(
          Duration(
            hours: Random().nextInt(4) + 14,
            minutes: Random().nextInt(60),
          ),
        ),
      ),
    ];
  }

  DateTime get endTime => startTime.add(duration);
}

/// A timeline of events
///
/// Events are played as they happened in time. The timeline is limited to a
/// single day, so events are from hour 0 to 23.
class Timeline extends ChangeNotifier {
  /// The events grouped by device
  final Map<String, List<TimelineEvent>> devices;

  /// All the events must have happened in the same day
  final DateTime date;

  Timeline({required this.devices, required this.date}) {
    assert(devices.values.every((events) {
      return events.every((event) =>
          event.startTime.year == date.year &&
          event.startTime.month == date.month &&
          event.startTime.day == date.day);
    }), 'All events must have happened in the same day');
    devices.removeWhere((key, value) => value.isEmpty);
  }

  Timeline.placeholder()
      : date = DateTime(2023),
        devices = {};

  static Timeline get fakeTimeline {
    return Timeline(
      date: DateTime(2023),
      devices: {
        'device1': TimelineEvent.fakeData,
        'device2': TimelineEvent.fakeData,
        'device3': TimelineEvent.fakeData,
        'device4': TimelineEvent.fakeData,
      },
    );
  }

  void add(Map<String, List<TimelineEvent>> devices) {
    assert(devices.values.every((events) {
      return events.every((event) =>
          event.startTime.year == date.year &&
          event.startTime.month == date.month &&
          event.startTime.day == date.day);
    }), 'All events must have happened in the same day');
    this.devices.addAll(devices);
  }

  /// The current position of the timeline
  var currentPosition = const Duration();

  DateTime get currentDate => date.add(currentPosition);

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
    timer?.cancel();
    timer = null;
  }

  void play() {
    timer ??= Timer.periodic(
      Duration(milliseconds: 1000 ~/ _speed),
      (timer) {
        currentPosition += const Duration(seconds: 1);
        notifyListeners();
      },
    );
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
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(children: [
      Expanded(
        child: Center(
          child: StaticGrid(
            reorderable: false,
            crossAxisCount: calculateCrossAxisCount(
              timeline.devices.length,
            ),
            onReorder: (a, b) {},
            childAspectRatio: 16 / 9,
            emptyChild: const Center(
              child: Text('No events :/'),
            ),
            children: timeline.devices.entries.map((entry) {
              final device = entry.key;
              final events = entry.value;

              final isPlaying = events.any((event) {
                return timeline.currentDate.isInBetween(
                  event.startTime,
                  event.endTime,
                );
              });

              return Card(
                key: ValueKey(device),
                color: isPlaying ? theme.colorScheme.primary : null,
                child: Text(device),
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
              padding: const EdgeInsets.only(bottom: 4.0, top: 2.0),
              child:
                  Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                Expanded(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
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
                    ],
                  ),
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
              '${SettingsProvider.instance.dateFormat.format(
                timeline.date.add(timeline.currentPosition),
              )} '
              '${timeline.currentPosition.humanReadableCompact(context)}',
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
                      child: Text(
                        '$hour',
                        style: theme.textTheme.labelMedium,
                        textAlign: TextAlign.end,
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

                    setState(() {
                      timeline.currentPosition = position;
                    });
                  },
                  child: Column(children: [
                    ...timeline.devices.entries.map((entry) {
                      final device = entry.key;
                      final events = entry.value;
                      return TimelineTile(
                        device: device,
                        events: events,
                      );
                    }),
                  ]),
                )
              ]),
              Positioned(
                left: (timeline.currentPosition.inMinutes * minuteWidth) +
                    _kDeviceNameWidth,
                width: 1.8,
                top: 16.0,
                height: _kTimelineTileHeight * timeline.devices.length,
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

class TimelineTile extends StatelessWidget {
  final String device;
  final List<TimelineEvent> events;

  const TimelineTile({super.key, required this.device, required this.events});

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
        child: Text(device),
      ),
      ...List.generate(24, (index) {
        final hour = index;

        final event =
            events.firstWhereOrNull((event) => event.startTime.hour == hour);

        return Expanded(
          child: Container(
            height: _kTimelineTileHeight,
            decoration: BoxDecoration(border: border),
            child: LayoutBuilder(builder: (context, constraints) {
              if (event == null || event.startTime.hour != hour) {
                return const SizedBox.shrink();
              }

              final minuteWidth = constraints.maxWidth / 60;
              return Stack(clipBehavior: Clip.none, children: [
                Positioned(
                  left: event.startTime.minute * minuteWidth,
                  width: event.duration.inMinutes * minuteWidth,
                  height: _kTimelineTileHeight,
                  child: ColoredBox(
                    color: theme.colorScheme.primary,
                  ),
                ),
              ]);
            }),
          ),
        );
      }),
    ]);
  }
}
