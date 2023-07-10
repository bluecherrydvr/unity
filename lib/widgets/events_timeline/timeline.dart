import 'dart:math';

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
    return [
      Event(
        duration: const Duration(minutes: 30),
        startTime: DateTime(2023),
      ),
      Event(
        duration: const Duration(hours: 1),
        startTime: DateTime(2023).add(const Duration(hours: 3)),
      ),
    ];
  }
}

/// A timeline of events
///
/// Events are played as they happened in time. The timeline is limited to a
/// single day, so events are from hour 0 to 23.
class Timeline {
  /// The events in the timeline
  final Map<String, Event> events;

  Timeline({required this.events});

  /// The current hour of the timeline.
  ///
  /// The timeline starts at hour 0 and ends at hour 23.
  int currentHour = 0;
}

const _kDeviceNameWidth = 100.0;
const _kTimelineTileHeight = 30.0;

class TimelineEventsView extends StatefulWidget {
  const TimelineEventsView({super.key});

  @override
  State<TimelineEventsView> createState() => _TimelineEventsViewState();
}

class _TimelineEventsViewState extends State<TimelineEventsView> {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(children: [
      const Spacer(),
      Card(
        child: Column(mainAxisAlignment: MainAxisAlignment.end, children: [
          Row(children: [
            const SizedBox(width: _kDeviceNameWidth),
            ...List.generate(24, (index) {
              final hour = index + 1;
              if (hour == 24) return const Expanded(child: SizedBox.shrink());

              return Expanded(
                child: Text(
                  '$hour',
                  style: theme.textTheme.labelMedium,
                  textAlign: TextAlign.end,
                ),
              );
            }),
          ]),
          TimelineTile(
              event: Event.fakeData[Random().nextInt(Event.fakeData.length)]),
          TimelineTile(
              event: Event.fakeData[Random().nextInt(Event.fakeData.length)]),
          TimelineTile(
              event: Event.fakeData[Random().nextInt(Event.fakeData.length)]),
          TimelineTile(
              event: Event.fakeData[Random().nextInt(Event.fakeData.length)]),
        ]),
      ),
    ]);
  }
}

class TimelineTile extends StatelessWidget {
  final Event event;

  const TimelineTile({super.key, required this.event});

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
        child: const Text('Device name'),
      ),
      ...List.generate(24, (index) {
        final hour = index;

        return Expanded(
          child: Container(
            height: _kTimelineTileHeight,
            decoration: BoxDecoration(border: border),
            child: LayoutBuilder(builder: (context, constraints) {
              if (event.startTime.hour != hour) return const SizedBox.shrink();

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
