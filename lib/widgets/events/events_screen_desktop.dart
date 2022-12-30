part of 'events_screen.dart';

class EventsScreenDesktop extends StatelessWidget {
  final EventsData events;

  // filters
  final List<Server> allowedServers;
  final EventsTimeFilter timeFilter;
  final EventsMinLevelFilter levelFilter;

  const EventsScreenDesktop({
    Key? key,
    required this.events,
    required this.allowedServers,
    required this.timeFilter,
    required this.levelFilter,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final now = DateTime.now();
    final int hourRange = {
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

        final parsedCategory = event.category?.split('/');
        final priority = parsedCategory?[1] ?? '';
        final isAlarm = priority == 'alarm' || priority == 'alrm';

        switch (levelFilter) {
          case EventsMinLevelFilter.alarming:
            if (!isAlarm) continue;
            break;
          case EventsMinLevelFilter.warning:
            if (priority != 'warn') continue;
            break;
          default:
            break;
        }

        yield event;
      }
    }).toList();

    return SingleChildScrollView(
      child: SizedBox(
        width: double.infinity,
        child: DataTable(
          horizontalMargin: 20.0,
          columnSpacing: 35.0,
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

            final dateFormatter = DateFormat(
              SettingsProvider.instance.dateFormat.pattern,
            );
            final timeFormatter = DateFormat(
              SettingsProvider.instance.timeFormat.pattern,
            );

            final parsedCategory = event.category?.split('/');
            final priority = parsedCategory?[1] ?? '';
            final isAlarm = priority == 'alarm' || priority == 'alrm';

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
                      Navigator.of(context)
                          .pushNamed('/events', arguments: event);
                    },
              cells: [
                // icon
                DataCell(Icon(
                  () {
                    if (isAlarm) {
                      return Icons.warning;
                    }
                    return null;
                  }(),
                  color: Colors.amber,
                )),
                // server
                DataCell(Text(event.server.name)),
                // device
                DataCell(Text(event.deviceName)),
                // event
                DataCell(Text((parsedCategory?.last ?? '').uppercaseFirst())),
                // duration
                DataCell(
                  Text(
                    (event.mediaDuration?.humanReadableCompact(context) ?? '')
                        .uppercaseFirst(),
                  ),
                ),
                // priority
                DataCell(Text(priority.uppercaseFirst())),
                // date
                DataCell(
                  Text(
                    dateFormatter.format(event.updated) +
                        ' ' +
                        timeFormatter.format(event.updated).toUpperCase(),
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
