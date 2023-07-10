import 'dart:async';

import 'package:bluecherry_client/providers/settings_provider.dart';
import 'package:bluecherry_client/utils/extensions.dart';
import 'package:bluecherry_client/widgets/device_grid/device_grid.dart'
    show calculateCrossAxisCount;
import 'package:bluecherry_client/widgets/reorderable_static_grid.dart';
import 'package:flutter/material.dart';

class Event {
  /// The duration of the event
  final Duration duration;

  /// When the event started
  final DateTime startTime;

  const Event({
    required this.duration,
    required this.startTime,
  });

  static List<Event> get fakeData {
    return ([
      Event(
        duration: const Duration(minutes: 30),
        startTime: DateTime(2023).add(const Duration(hours: 3)),
      ),
      Event(
        duration: const Duration(hours: 1),
        startTime: DateTime(2023).add(const Duration(hours: 6)),
      ),
      Event(
        duration: const Duration(minutes: 40),
        startTime: DateTime(2023).add(const Duration(hours: 8)),
      ),
      Event(
        duration: const Duration(minutes: 15),
        startTime: DateTime(2023).add(const Duration(hours: 11, minutes: 15)),
      ),
      Event(
        duration: const Duration(minutes: 45),
        startTime: DateTime(2023).add(const Duration(hours: 22, minutes: 5)),
      ),
    ]..shuffle());
  }
}

/// A timeline of events
///
/// Events are played as they happened in time. The timeline is limited to a
/// single day, so events are from hour 0 to 23.
class Timeline extends ChangeNotifier {
  /// The events grouped by device
  final Map<String, List<Event>> devices;

  /// All the events must have happened in the same day
  final DateTime date;

  Timeline({required this.devices, required this.date}) {
    assert(devices.values.every((events) {
      return events.every((event) =>
          event.startTime.year == date.year &&
          event.startTime.month == date.month &&
          event.startTime.day == date.day);
    }), 'All events must have happened in the same day');
  }

  static Timeline get fakeTimeline {
    return Timeline(
      date: DateTime(2023),
      devices: {
        'device1': Event.fakeData,
        'device2': Event.fakeData,
        'device3': Event.fakeData,
        'device4': Event.fakeData,
      },
    );
  }

  /// The current position of the timeline
  var currentPosition = const Duration();

  DateTime get currentDate => date.add(currentPosition);

  Timer? timer;
  bool get isPlaying => timer != null && timer!.isActive;

  void pause() {
    timer?.cancel();
    timer = null;
  }

  void play() {
    timer ??= Timer.periodic(const Duration(seconds: 1), (timer) {
      currentPosition += const Duration(seconds: 1);
      notifyListeners();
    });
  }
}

const _kDeviceNameWidth = 100.0;
const _kTimelineTileHeight = 30.0;
final _minutesInADay = const Duration(days: 1).inMinutes;

class TimelineEventsView extends StatefulWidget {
  final Timeline timeline;

  const TimelineEventsView({super.key, required this.timeline});

  @override
  State<TimelineEventsView> createState() => _TimelineEventsViewState();
}

class _TimelineEventsViewState extends State<TimelineEventsView> {
  @override
  void initState() {
    super.initState();
    widget.timeline.addListener(() {
      if (mounted) setState(() {});
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(children: [
      Expanded(
        child: Center(
          child: StaticGrid(
            crossAxisCount: calculateCrossAxisCount(
              widget.timeline.devices.length,
            ),
            onReorder: (a, b) {},
            childAspectRatio: 16 / 9,
            children: widget.timeline.devices.entries.map((entry) {
              final device = entry.key;
              final events = entry.value;

              final isPlaying = events.any((event) {
                widget.timeline.currentPosition;

                return widget.timeline.currentDate.isInBetween(
                  event.startTime,
                  event.startTime.add(event.duration),
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
        child: LayoutBuilder(builder: (context, constraints) {
          final minuteWidth =
              (constraints.maxWidth - _kDeviceNameWidth) / _minutesInADay;

          return Column(mainAxisAlignment: MainAxisAlignment.end, children: [
            Padding(
              padding: const EdgeInsets.only(bottom: 4.0, top: 2.0),
              child:
                  Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                IconButton(
                  icon: Icon(
                    widget.timeline.isPlaying ? Icons.pause : Icons.play_arrow,
                  ),
                  onPressed: () {
                    setState(() {
                      if (widget.timeline.isPlaying) {
                        widget.timeline.pause();
                      } else {
                        widget.timeline.play();
                      }
                    });
                  },
                ),
              ]),
            ),
            Text(
              '${SettingsProvider.instance.dateFormat.format(
                widget.timeline.date.add(widget.timeline.currentPosition),
              )} '
              '${widget.timeline.currentPosition.humanReadableCompact(context)}',
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
                      widget.timeline.currentPosition = position;
                    });
                  },
                  child: Column(children: [
                    ...widget.timeline.devices.entries.map((entry) {
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
                left:
                    (widget.timeline.currentPosition.inMinutes * minuteWidth) +
                        _kDeviceNameWidth,
                width: 1.8,
                top: 16.0,
                height: _kTimelineTileHeight * widget.timeline.devices.length,
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
  final List<Event> events;

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
              return Stack(children: [
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
