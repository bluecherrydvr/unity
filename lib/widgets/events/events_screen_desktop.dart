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
  final List<Event> events;

  const EventsScreenDesktop({super.key, required this.events});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final settings = context.watch<SettingsProvider>();

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
