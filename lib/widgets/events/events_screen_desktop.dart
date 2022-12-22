part of 'events_screen.dart';

class EventsScreenDesktop extends StatelessWidget {
  final EventsData events;

  const EventsScreenDesktop({Key? key, required this.events}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final events = this.events.values.expand((element) sync* {
      for (final e in element) {
        yield e;
      }
    }).toList();

    return SingleChildScrollView(
      child: SizedBox(
        width: double.infinity,
        child: DataTable(
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

            final parsedCategory = event.category?.split('/');
            final dateFormatter = DateFormat(
              SettingsProvider.instance.dateFormat.pattern,
            );
            final timeFormatter = DateFormat(
              SettingsProvider.instance.timeFormat.pattern,
            );

            final priority = parsedCategory?[1] ?? '';
            final isAlarm = priority == 'alarm' || priority == 'alrm';

            return DataRow(
              color: index.isEven
                  ? MaterialStateProperty.resolveWith((states) {
                      return theme.appBarTheme.backgroundColor;
                    })
                  : MaterialStateProperty.resolveWith((states) {
                      return theme.appBarTheme.backgroundColor
                          ?.withOpacity(0.4);
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
                DataCell(Text((event.mediaDuration?.humanReadableCompact ?? '')
                    .uppercaseFirst())),
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
