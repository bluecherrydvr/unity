import 'package:bluecherry_client/api/api.dart';
import 'package:bluecherry_client/models/event.dart';
import 'package:bluecherry_client/providers/home_provider.dart';
import 'package:bluecherry_client/providers/server_provider.dart';
import 'package:bluecherry_client/utils/extensions.dart';
import 'package:bluecherry_client/widgets/events_timeline/timeline.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

final eventsPlaybackScreenKey = GlobalKey<_EventsPlaybackState>();

class EventsPlayback extends StatefulWidget {
  EventsPlayback() : super(key: eventsPlaybackScreenKey);

  @override
  State<EventsPlayback> createState() => _EventsPlaybackState();
}

class _EventsPlaybackState extends State<EventsPlayback> {
  Timeline? timeline;
  final focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => fetch());
    focusNode.requestFocus();
  }

  Map<String, List<Event>> devices = {};

  Future<void> fetch() async {
    setState(() {
      timeline?.dispose();
      timeline = null;
    });
    final home = context.read<HomeProvider>()
      ..loading(UnityLoadingReason.fetchingEventsPlayback);
    var date = DateTime(
      DateTime.now().year,
      DateTime.now().month,
      DateTime.now().day,
    );
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

      // If there are any events for today, use today as the date
      if (events.any(
        (event) => DateUtils.isSameDay(
          event.published.toUtc(),
          DateTime.now().toUtc(),
        ),
      )) {
        date = DateTime(
          DateTime.now().year,
          DateTime.now().month,
          DateTime.now().day,
        );
      } else {
        // Otherwise, use the most recent date that has events
        final recentDate = (events.toList()
              ..sort((a, b) => b.published.compareTo(a.published)))
            .first
            .published;
        date = DateTime(
          recentDate.year,
          recentDate.month,
          recentDate.day,
        );
      }

      for (final event in events) {
        // If the event is not long enough to be displayed, do not add it
        if (event.duration < const Duration(minutes: 1)) {
          continue;
        }

        if (!DateUtils.isSameDay(event.published, date)) continue;

        devices[event.deviceName] ??= [];

        // If there is already an event that conflicts with this one in time, do
        // not add it
        if (devices[event.deviceName]!.any((e) {
          return e.published.isInBetween(
            event.published,
            event.published.add(event.duration),
          );
        })) continue;

        devices[event.deviceName] ??= [];
        devices[event.deviceName]!.add(event);
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
            event: event,
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
    return Focus(
      autofocus: true,
      focusNode: focusNode,
      onKeyEvent: (node, event) {
        if (timeline == null ||
            !(event is KeyDownEvent || event is KeyRepeatEvent)) {
          return KeyEventResult.ignored;
        }

        debugPrint(event.logicalKey.debugName);
        if (event.logicalKey == LogicalKeyboardKey.space) {
          if (timeline!.isPlaying) {
            timeline!.stop();
          } else {
            timeline!.play();
          }
          return KeyEventResult.handled;
        } else if (event.logicalKey == LogicalKeyboardKey.keyM) {
          if (timeline!.isMuted) {
            timeline!.volume = 1.0;
          } else {
            timeline!.volume = 0.0;
          }
          return KeyEventResult.handled;
        } else if (event.logicalKey == LogicalKeyboardKey.keyR ||
            event.logicalKey == LogicalKeyboardKey.f5) {
          fetch();
          return KeyEventResult.handled;
        } else if (event.logicalKey == LogicalKeyboardKey.arrowRight) {
          timeline!.seekForward();
          return KeyEventResult.handled;
        } else if (event.logicalKey == LogicalKeyboardKey.arrowLeft) {
          timeline!.seekBackward();
          return KeyEventResult.handled;
        }

        return KeyEventResult.ignored;
      },
      child: TimelineEventsView(
        key: ValueKey(timeline),
        // timeline: kDebugMode ? Timeline.fakeTimeline : timeline,
        timeline: timeline,
      ),
    );
  }
}
