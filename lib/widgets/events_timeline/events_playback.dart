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
          .where((event) => event.mediaURL != null)
          .toList()
        ..sort((a, b) {
          return a.published.compareTo(b.published);
        });

      if (events.isEmpty) continue;

      // date = DateTime(
      //   events.first.published.year,
      //   events.first.published.month,
      //   events.first.published.day,
      // );
      date = DateTime(
        DateTime.now().year,
        DateTime.now().month,
        DateTime.now().day,
      );

      for (final event in events) {
        // If the event is not long enough to be displayed, do not add it
        if (event.duration < const Duration(minutes: 1)) {
          continue;
        }

        if (!DateUtils.isSameDay(event.published.toUtc(), date.toUtc())) {
          continue;
        }

        devices[event.deviceName] ??= [];

        // If there is already an event that conflicts with this one in time, do
        // not add it
        // if (devices[event.deviceName]!.any((event) {
        //   return devices[event.deviceName]!.every((e) {
        //     return event.published.isAtSameMomentAs(e.published) ||
        //         event.published.isAtSameMomentAs(e.published.add(e.duration));
        //   });
        // })) continue;

        devices[event.deviceName] ??= [];

        // if (!devices[event.deviceName]!.any((event) {
        //   return devices[event.deviceName]!.every(
        //     (e) => event.published.isAtSameMomentAs(e.published),
        //   );
        // })) {
        devices[event.deviceName]!.add(event);
        // }
      }
    }

    final parsedTiles = devices.entries.map((e) {
      final device = e.key;
      final events = e.value;
      debugPrint('Loaded ${events.length} events for $device');

      return TimelineTile(
        device: device,
        events: events.map((event) {
          return TimelineEvent(
            startTime: event.published,
            duration: event.duration,
            videoUrl: event.mediaURL!.toString(),
          );
        }).toList(),
      );
    });

    home.notLoading(UnityLoadingReason.fetchingEventsPlayback);

    setState(() {
      timeline = Timeline(
        tiles: parsedTiles.toList(),
        date: date,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return TimelineEventsView(
      // timeline: Timeline.fakeTimeline,
      timeline: timeline,
    );
  }
}
