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
          columns: const [
            DataColumn(label: SizedBox.shrink()),
            DataColumn(label: Text('Server')),
            DataColumn(label: Text('Device')),
            DataColumn(label: Text('Event')),
            DataColumn(label: Text('Duration')),
            DataColumn(label: Text('Priority')),
            DataColumn(label: Text('Date')),
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
                  : null,
              onSelectChanged: (_) {
                Navigator.of(context).pushNamed(
                  '/events',
                  arguments: event,
                  // MaterialPageRoute(builder: (context) {
                  //   return EventPlayerScreen(event: event);
                  // }),
                );
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
                DataCell(
                  Text(event.deviceName),
                ),
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
