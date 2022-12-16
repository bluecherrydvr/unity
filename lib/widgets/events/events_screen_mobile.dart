part of 'events_screen.dart';

class EventsScreenMobile extends StatelessWidget {
  final EventsData events;
  final RefreshCallback refresh;
  final bool isFirstTimeLoading;
  final Map<Server, bool> invalid;

  const EventsScreenMobile({
    Key? key,
    required this.events,
    required this.refresh,
    required this.isFirstTimeLoading,
    required this.invalid,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: refresh,
      child: ListView.builder(
        physics: const AlwaysScrollableScrollPhysics(),
        itemCount: ServersProvider.instance.servers.length,
        itemBuilder: (context, index) {
          final server = ServersProvider.instance.servers[index];
          return ExpansionTile(
            initiallyExpanded:
                ServersProvider.instance.servers.length.compareTo(1) == 0,
            maintainState: true,
            leading: CircleAvatar(
              child: Icon(
                Icons.language,
                color: Theme.of(context).iconTheme.color,
              ),
              backgroundColor: Colors.transparent,
            ),
            title: Row(children: [
              Expanded(child: Text(server.name)),
              if (isDesktop)
                IconButton(
                  onPressed: refresh,
                  tooltip: 'Refresh',
                  icon: const Icon(Icons.refresh),
                ),
            ]),
            subtitle: server.name != server.ip ? Text(server.ip) : null,
            children: isFirstTimeLoading
                ? <Widget>[
                    const SizedBox(
                      height: 96.0,
                      child: Center(
                        child: CircularProgressIndicator(),
                      ),
                    )
                  ]
                : events[server]?.map((event) {
                      return ListTile(
                        contentPadding: const EdgeInsetsDirectional.only(
                          start: 64.0,
                          end: 16.0,
                        ),
                        onTap: () async {
                          await Navigator.of(context).pushNamed(
                            '/events',
                            arguments: event,
                          );
                        },
                        title: Text(event.deviceName),
                        isThreeLine: true,
                        subtitle: Text(
                          [
                            event.title.split('event on').first.trim(),
                            DateFormat(
                                  SettingsProvider.instance.dateFormat.pattern,
                                ).format(event.updated) +
                                ' ' +
                                DateFormat(
                                  SettingsProvider.instance.timeFormat.pattern,
                                ).format(event.updated).toUpperCase(),
                          ].join('\n'),
                          overflow: TextOverflow.ellipsis,
                        ),
                        leading: CircleAvatar(
                          child: Icon(
                            Icons.warning,
                            color: Colors.amber.shade300,
                          ),
                          backgroundColor: Colors.transparent,
                        ),
                      );
                    }).toList() ??
                    [
                      if (invalid[server] ?? true)
                        SizedBox(
                          height: 72.0,
                          child: Center(
                            child: Text(
                              AppLocalizations.of(context).invalidResponse,
                              style: Theme.of(context)
                                  .textTheme
                                  .headline5
                                  ?.copyWith(fontSize: 16.0),
                            ),
                          ),
                        )
                      else
                        SizedBox(
                          height: 72.0,
                          child: Center(
                            child: Text(
                              AppLocalizations.of(context).noEventsFound,
                              style: Theme.of(context)
                                  .textTheme
                                  .headline5
                                  ?.copyWith(fontSize: 16.0),
                            ),
                          ),
                        ),
                    ],
          );
        },
      ),
    );
  }
}
