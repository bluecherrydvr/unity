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

part of 'events_screen.dart';

class EventsScreenDesktop extends StatelessWidget {
  final EventsData events;

  // filters
  final List<Server> allowedServers;
  final List<String> disabledDevices;
  final EventsTimeFilter timeFilter;
  final EventsMinLevelFilter levelFilter;

  const EventsScreenDesktop({
    Key? key,
    required this.events,
    required this.allowedServers,
    required this.disabledDevices,
    required this.timeFilter,
    required this.levelFilter,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final settings = context.watch<SettingsProvider>();

    final now = DateTime.now();
    final hourRange = {
      EventsTimeFilter.last12Hours: 12,
      EventsTimeFilter.last24Hours: 24,
      EventsTimeFilter.last6Hours: 6,
      EventsTimeFilter.lastHour: 1,
      EventsTimeFilter.any: -1,
    }[timeFilter]!;

    final events = this.events.values.expand((events) sync* {
      for (final event in events) {
        // allow events from the allowed servers
        if (!allowedServers.any((element) => event.server.ip == element.ip)) {
          continue;
        }

        // allow events within the time range
        if (timeFilter != EventsTimeFilter.any) {
          if (now.difference(event.published).inHours > hourRange) continue;
        }

        switch (levelFilter) {
          case EventsMinLevelFilter.alarming:
            if (!event.isAlarm) continue;
            break;
          case EventsMinLevelFilter.warning:
            if (event.priority != EventPriority.warning) continue;
            break;
          default:
            break;
        }

        // This is hacky. Maybe find a way to move this logic to [API.getEvents]
        // It'd also be useful to find a way to get the device at Event creation time
        final devices = event.server.devices.where((device) =>
            device.name.toLowerCase() == event.deviceName.toLowerCase());
        if (devices.isNotEmpty) {
          if (disabledDevices.contains(devices.first.streamURL)) continue;
        }

        yield event;
      }
    }).toList();

    if (events.isEmpty) {
      return Center(
        child: Text(
          AppLocalizations.of(context).noEventsFound,
          textAlign: TextAlign.center,
        ),
      );
    }

    return SingleChildScrollView(
      child: SizedBox(
        width: double.infinity,
        child: DataTable(
          horizontalMargin: 20.0,
          columnSpacing: 30.0,
          columns: [
            const DataColumn(label: SizedBox.shrink()),
            DataColumn(label: Text(AppLocalizations.of(context).server)),
            DataColumn(label: Text(AppLocalizations.of(context).device)),
            DataColumn(label: Text(AppLocalizations.of(context).event)),
            DataColumn(label: Text(AppLocalizations.of(context).duration)),
            DataColumn(label: Text(AppLocalizations.of(context).priority)),
            DataColumn(label: Text(AppLocalizations.of(context).date)),
          ],
          showCheckboxColumn: false,
          rows: events.map<DataRow>((Event event) {
            final index = events.indexOf(event);

            return DataRow(
              key: ValueKey<Event>(event),
              color: index.isEven
                  ? MaterialStateProperty.resolveWith((states) {
                      return theme.appBarTheme.backgroundColor
                          ?.withOpacity(0.75);
                    })
                  : MaterialStateProperty.resolveWith((states) {
                      return theme.appBarTheme.backgroundColor
                          ?.withOpacity(0.25);
                    }),
              onSelectChanged: event.mediaURL == null
                  ? null
                  : (_) {
                      debugPrint('Displaying event $event');
                      Navigator.of(context).pushNamed(
                        '/events',
                        arguments: {
                          'event': event,
                          'upcoming': events,
                        },
                      );
                    },
              cells: [
                // icon
                DataCell(Container(
                  width: 40.0,
                  height: 40.0,
                  alignment: AlignmentDirectional.center,
                  child: DownloadIndicator(event: event),
                )),
                // server
                DataCell(Text(event.server.name)),
                // device
                DataCell(Text(event.deviceName)),
                // event
                DataCell(Text(event.type.locale(context).uppercaseFirst())),
                // duration
                DataCell(
                  Text(
                    event.duration
                        .humanReadableCompact(context)
                        .uppercaseFirst(),
                  ),
                ),
                // priority
                DataCell(Text(event.priority.locale(context).uppercaseFirst())),
                // date
                DataCell(
                  Text(
                    '${settings.formatDate(event.updated.toLocal())} ${settings.formatTime(event.updated).toUpperCase()}',
                  ),
                ),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }
}
