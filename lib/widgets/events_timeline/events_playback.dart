import 'package:bluecherry_client/api/api.dart';
import 'package:bluecherry_client/models/event.dart';
import 'package:bluecherry_client/providers/home_provider.dart';
import 'package:bluecherry_client/providers/server_provider.dart';
import 'package:bluecherry_client/widgets/events_timeline/timeline.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class EventsPlayback extends StatefulWidget {
  const EventsPlayback({super.key});

  @override
  State<EventsPlayback> createState() => _EventsPlaybackState();
}

class _EventsPlaybackState extends State<EventsPlayback> {
  Timeline? timeline;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => fetch());
  }

  Map<String, List<Event>> devices = {};

  Future<void> fetch() async {
    final home = context.read<HomeProvider>()
      ..loading(UnityLoadingReason.fetchingEventsPlayback);
    late DateTime date;
    for (final server in ServersProvider.instance.servers) {
      if (!server.online) continue;

      final events = (await API.instance.getEvents(
        await API.instance.checkServerCredentials(server),
      ))
          .where((event) => !event.isAlarm)
          .toList()
        ..sort((a, b) {
          return a.published.compareTo(b.published);
        });

      date = DateTime(2023, 7, 10);

      for (final event in events
          .where((event) => DateUtils.isSameDay(event.published, date))) {
        // If the event is not long enough to be displayed, do not add it
        if (event.duration < const Duration(minutes: 1)) continue;

        // If the event is not in the same day as the [date], do not add it
        if (!DateUtils.isSameDay(event.published, date)) {
          continue;
        }

        devices[event.deviceName] ??= [];

        // If there is already an event that conflicts with this one in time, do
        // not add it
        if (devices[event.deviceName]!.any((event) {
          return devices[event.deviceName]!.every((e) {
            return event.published.isAtSameMomentAs(e.published) ||
                event.published.isAtSameMomentAs(e.published.add(e.duration));
          });
        })) continue;

        devices[event.deviceName] ??= [];

        if (!devices[event.deviceName]!.any((event) {
          return devices[event.deviceName]!.every(
            (e) => event.published.isAtSameMomentAs(e.published),
          );
        })) {
          devices[event.deviceName]!.add(event);
        }
      }
    }

    final parsedDevices =
        devices.map<String, List<TimelineEvent>>((device, events) {
      debugPrint('Loaded ${events.length} events for $device');
      return MapEntry(
        device,
        events.map((event) {
          debugPrint(
            '${event.published} - ${event.published.add(event.duration)}}}',
          );
          return TimelineEvent(
            startTime: event.published,
            duration: event.duration,
          );
        }).toList(),
      );
    });

    home.notLoading(UnityLoadingReason.fetchingEventsPlayback);

    setState(() {
      timeline = Timeline(
        devices: parsedDevices,
        date: date,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return TimelineEventsView(timeline: timeline);
  }
}
