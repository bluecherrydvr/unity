/*
 * This file is a part of Bluecherry Client (https://github.com/bluecherrydvr/unity).
 *
 * Copyright 2022 Bluecherry, LLC
 *
 * This program is free software; you can redistribute it and/or
 * modify it under the terms of the GNU General Public License as
 * published by the Free Software Foundation; either version 3 of
 * the License, or (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program. If not, see <http://www.gnu.org/licenses/>.
 */

import 'package:bluecherry_client/api/api.dart';
import 'package:bluecherry_client/models/event.dart';
import 'package:bluecherry_client/providers/events_playback_provider.dart';
import 'package:bluecherry_client/providers/server_provider.dart';
import 'package:bluecherry_client/widgets/events_playback/events_playback_desktop.dart';
import 'package:flutter/material.dart';

// Device Id : Events for device
typedef EventsData = Map<String, List<Event>>;

class EventsPlayback extends StatefulWidget {
  const EventsPlayback({Key? key}) : super(key: key);

  @override
  State<EventsPlayback> createState() => _EventsPlaybackState();
}

class _EventsPlaybackState extends State<EventsPlayback> {
  bool isFirstTimeLoading = true;
  EventsData eventsForDevice = {};

  Future<void> fetch() async {
    try {
      for (final server in ServersProvider.instance.servers) {
        try {
          final events = await API.instance.getEvents(
            await API.instance.checkServerCredentials(server),
          );

          for (final event in events) {
            if (!server.devices.any((d) => d.name == event.deviceName)) {
              continue;
            }

            final device =
                server.devices.firstWhere((d) => d.name == event.deviceName);
            final id = EventsProvider.idForDevice(device);

            if (eventsForDevice.containsKey(id)) {
              eventsForDevice[id]!.add(event);
            } else {
              eventsForDevice[id] = [event];
            }
          }
        } catch (exception, stacktrace) {
          debugPrint(exception.toString());
          debugPrint(stacktrace.toString());
        }
      }
    } catch (exception, stacktrace) {
      debugPrint(exception.toString());
      debugPrint(stacktrace.toString());
    }
    if (mounted) {
      setState(() {
        isFirstTimeLoading = false;
      });
    }
  }

  @override
  void initState() {
    super.initState();

    fetch();
  }

  @override
  Widget build(BuildContext context) {
    return EventsPlaybackDesktop(events: eventsForDevice);
  }
}
