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
              backgroundColor: Colors.transparent,
              child: Icon(
                Icons.language,
                color: Theme.of(context).iconTheme.color,
              ),
            ),
            title: Row(children: [
              Expanded(child: Text(server.name)),
              if (isDesktop)
                IconButton(
                  onPressed: refresh,
                  tooltip: AppLocalizations.of(context).refresh,
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
                            '${DateFormat(
                              SettingsProvider.instance.dateFormat.pattern,
                            ).format(event.updated)} ${DateFormat(
                              SettingsProvider.instance.timeFormat.pattern,
                            ).format(event.updated).toUpperCase()}',
                          ].join('\n'),
                          overflow: TextOverflow.ellipsis,
                        ),
                        leading: CircleAvatar(
                          backgroundColor: Colors.transparent,
                          child: Icon(
                            Icons.warning,
                            color: Colors.amber.shade300,
                          ),
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
                                  .headlineSmall
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
                                  .headlineSmall
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
