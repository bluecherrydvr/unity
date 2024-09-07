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

import 'dart:async';
import 'dart:io';

import 'package:bluecherry_client/models/event.dart';
import 'package:bluecherry_client/models/server.dart';
import 'package:bluecherry_client/providers/downloads_provider.dart';
import 'package:bluecherry_client/providers/events_provider.dart';
import 'package:bluecherry_client/providers/home_provider.dart';
import 'package:bluecherry_client/providers/server_provider.dart';
import 'package:bluecherry_client/providers/settings_provider.dart';
import 'package:bluecherry_client/screens/downloads/indicators.dart';
import 'package:bluecherry_client/screens/events_browser/date_time_filter.dart';
import 'package:bluecherry_client/screens/events_browser/filter.dart';
import 'package:bluecherry_client/screens/events_browser/sidebar.dart';
import 'package:bluecherry_client/screens/players/event_player_desktop.dart';
import 'package:bluecherry_client/utils/constants.dart';
import 'package:bluecherry_client/utils/date.dart';
import 'package:bluecherry_client/utils/extensions.dart';
import 'package:bluecherry_client/utils/methods.dart';
import 'package:bluecherry_client/widgets/desktop_buttons.dart';
import 'package:bluecherry_client/widgets/drawer_button.dart';
import 'package:bluecherry_client/widgets/error_warning.dart';
import 'package:bluecherry_client/widgets/misc.dart';
import 'package:bluecherry_client/widgets/squared_icon_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:provider/provider.dart';
import 'package:unity_video_player/unity_video_player.dart';

part '../players/event_player_mobile.dart';
part 'events_screen_desktop.dart';
part 'events_screen_mobile.dart';

final eventsScreenKey = GlobalKey<EventsScreenState>();

class EventsScreen extends StatefulWidget {
  const EventsScreen({required super.key});

  @override
  State<EventsScreen> createState() => EventsScreenState<EventsScreen>();
}

class EventsScreenState<T extends StatefulWidget> extends State<T> {
  /// Fetches the events from the servers.
  Future<void> fetch({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final home = context.read<HomeProvider>()
      ..loading(UnityLoadingReason.fetchingEventsHistory);

    await context.read<EventsProvider>().loadEvents(
          startDate: startDate,
          endDate: endDate,
        );

    home.notLoading(UnityLoadingReason.fetchingEventsHistory);
  }

  @override
  Widget build(BuildContext context) {
    if (ServersProvider.instance.servers.isEmpty) {
      return const NoServerWarning();
    }

    final eventsProvider = context.watch<EventsProvider>();
    final hasDrawer = Scaffold.hasDrawer(context);

    return LayoutBuilder(builder: (context, consts) {
      final events =
          (eventsProvider.loadedEvents?.filteredEvents ?? List.empty())
              .where((event) {
        final typeFilter = eventsProvider.eventTypeFilter;
        if (typeFilter == -1) return true;
        return event.type.index == typeFilter;
      });
      if (hasDrawer || consts.maxWidth < kMobileBreakpoint.width) {
        return EventsScreenMobile(
          events: events,
          loadedServers:
              eventsProvider.loadedEvents?.events.keys ?? List.empty(),
          refresh: fetch,
          invalid:
              eventsProvider.loadedEvents?.invalidResponses ?? List.empty(),
        );
      }

      return Material(
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          EventsScreenSidebar(fetch: fetch),
          Expanded(
            child: Card(
              margin: EdgeInsets.zero,
              shape: const RoundedRectangleBorder(
                borderRadius: BorderRadiusDirectional.only(
                  topStart: Radius.circular(12.0),
                ),
              ),
              child: EventsScreenDesktop(events: events),
            ),
          ),
        ]),
      );
    });
  }
}
