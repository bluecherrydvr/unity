import 'dart:math';

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
        startTime: DateTime(2023),
      ),
      Event(
        duration: const Duration(hours: 1),
        startTime: DateTime(2023).add(const Duration(hours: 3)),
      ),
      Event(
        duration: const Duration(minutes: 40),
        startTime: DateTime(2023).add(const Duration(hours: 6)),
      ),
      Event(
        duration: const Duration(minutes: 15),
        startTime: DateTime(2023).add(const Duration(hours: 8, minutes: 15)),
      ),
    ]..shuffle());
  }
}

/// A timeline of events
///
/// Events are played as they happened in time. The timeline is limited to a
/// single day, so events are from hour 0 to 23.
class Timeline {
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

  /// The current hour of the timeline.
  ///
  /// The timeline starts at hour 0 and ends at hour 23.
  int currentHour = 0;
}

const _kDeviceNameWidth = 100.0;
const _kTimelineTileHeight = 30.0;

class TimelineEventsView extends StatefulWidget {
  final Timeline timeline;

  const TimelineEventsView({super.key, required this.timeline});

  @override
  State<TimelineEventsView> createState() => _TimelineEventsViewState();
}

class _TimelineEventsViewState extends State<TimelineEventsView> {
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
            children: [
              for (final device in widget.timeline.devices.keys) ...[
                Card(
                  key: ValueKey(device),
                  // aspectRatio: 16 / 9,
                  child: Text(device),
                ),
              ],
            ],
          ),
        ),
      ),
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
          ...widget.timeline.devices.entries.map((entry) {
            final device = entry.key;
            final events = entry.value;
            return TimelineTile(
              events: events,
            );
          }),
        ]),
      ),
    ]);
  }
}

class TimelineTile extends StatelessWidget {
  final List<Event> events;

  const TimelineTile({super.key, required this.events});

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
