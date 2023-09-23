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

import 'package:auto_size_text/auto_size_text.dart';
import 'package:bluecherry_client/providers/settings_provider.dart';
import 'package:bluecherry_client/widgets/device_grid/device_grid.dart';
import 'package:bluecherry_client/widgets/events/events_screen.dart';
import 'package:bluecherry_client/widgets/events_timeline/desktop/timeline.dart';
import 'package:bluecherry_client/widgets/events_timeline/events_playback.dart';
import 'package:bluecherry_client/widgets/misc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:provider/provider.dart';

class TimelineSidebar extends StatefulWidget {
  const TimelineSidebar({
    super.key,
    required this.timeline,
    required this.date,
    required this.onDateChanged,
    required this.onFetch,
  });

  final Timeline? timeline;

  final DateTime date;
  final ValueChanged<DateTime> onDateChanged;

  final VoidCallback onFetch;

  @override
  State<TimelineSidebar> createState() => _TimelineSidebarState();
}

class _TimelineSidebarState extends State<TimelineSidebar> {
  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final settings = context.watch<SettingsProvider>();

    final state = eventsPlaybackScreenKey.currentState!;

    return Container(
      constraints: kSidebarConstraints,
      height: double.infinity,
      child: Card(
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadiusDirectional.vertical(
            top: Radius.circular(12.0),
          ),
        ),
        margin: const EdgeInsetsDirectional.symmetric(horizontal: 4.0),
        child: Column(children: [
          SubHeader(loc.servers, height: 40.0),
          Expanded(
            child: EventsDevicesPicker(
              allowedServers: state.allowedServers,
              disabledDevices: state.disabledDevices,
              events: state.events,
              onServerAdded: (server) =>
                  setState(() => state.allowedServers.add(server)),
              onServerRemoved: (server) =>
                  setState(() => state.allowedServers.remove(server)),
              onDisabledDeviceAdded: (device) =>
                  setState(() => state.disabledDevices.add(device)),
              onDisabledDeviceRemoved: (device) =>
                  setState(() => state.disabledDevices.remove(device)),
            ),
            // child: buildTreeView(context, setState: setState),
          ),
          SubHeader(loc.timeFilter, height: 24.0),
          ListTile(
            title: AutoSizeText(
              settings.dateFormat.format(widget.date),
              maxLines: 1,
            ),
            onTap: () async {
              final date = await showDatePicker(
                context: context,
                initialDate: widget.date,
                firstDate: DateTime.utc(1970),
                lastDate: DateTime.now(),
                initialEntryMode: DatePickerEntryMode.calendarOnly,
                currentDate: widget.date,
              );
              if (date != null) {
                widget.onDateChanged(date);
                debugPrint('date: $date');
              }
            },
          ),
        ]),
      ),
    );
  }
}
