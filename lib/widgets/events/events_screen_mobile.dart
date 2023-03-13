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
    final settings = context.watch<SettingsProvider>();
    final loc = AppLocalizations.of(context);

    return Material(
      child: RefreshIndicator(
        onRefresh: refresh,
        child: ListView.builder(
          physics: const AlwaysScrollableScrollPhysics(),
          itemCount: ServersProvider.instance.servers.length,
          itemBuilder: (context, index) {
            final server = ServersProvider.instance.servers[index];
            return IgnorePointer(
              ignoring: isFirstTimeLoading || !server.online,
              child: ExpansionTile(
                initiallyExpanded:
                    ServersProvider.instance.servers.length.compareTo(1) == 0,
                maintainState: true,
                leading: !server.online
                    ? CircleAvatar(
                        backgroundColor: Colors.transparent,
                        child: Icon(
                          Icons.desktop_access_disabled,
                          color: Theme.of(context).colorScheme.error,
                        ),
                      )
                    : isFirstTimeLoading
                        ? const SizedBox(
                            height: 20.0,
                            width: 20.0,
                            child: CircularProgressIndicator.adaptive(
                              strokeWidth: 2.0,
                            ),
                          )
                        : CircleAvatar(
                            backgroundColor: Colors.transparent,
                            child: Icon(
                              Icons.language,
                              color: Theme.of(context).iconTheme.color,
                            ),
                          ),
                trailing: server.online ? null : const SizedBox.shrink(),
                title: Row(children: [
                  Expanded(child: Text(server.name)),
                  if (isDesktop)
                    IconButton(
                      onPressed: refresh,
                      tooltip: loc.refresh,
                      icon: const Icon(Icons.refresh),
                    ),
                ]),
                subtitle: !server.online
                    ? Text(
                        loc.offline,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.error,
                        ),
                      )
                    : Text(
                        '${loc.nDevices(server.devices.length)} • ${server.ip}',
                      ),
                children: isFirstTimeLoading
                    ? []
                    : events[server]?.map((event) {
                          return ListTile(
                            contentPadding: const EdgeInsetsDirectional.only(
                              start: 70.0,
                              end: 16.0,
                            ),
                            onTap: () async {
                              await Navigator.of(context).pushNamed(
                                '/events',
                                arguments: {
                                  'event': event,
                                  'upcoming': events[server],
                                },
                              );
                            },
                            title: Text(event.deviceName),
                            isThreeLine: true,
                            subtitle: Text(
                              [
                                '${event.priority.locale(context)} • ${event.duration.humanReadable(context)}',
                                '${settings.formatDate(event.updated)}'
                                    ' ${settings.formatTime(event.updated).toUpperCase()}',
                              ].join('\n'),
                              overflow: TextOverflow.ellipsis,
                            ),
                            // leading: CircleAvatar(
                            //   backgroundColor: Colors.transparent,
                            //   child: Icon(
                            //     Icons.warning,
                            //     color: Colors.amber.shade300,
                            //   ),
                            // ),
                          );
                        }).toList() ??
                        [
                          if (invalid[server] ?? true)
                            SizedBox(
                              height: 72.0,
                              child: Center(
                                child: Text(
                                  loc.invalidResponse,
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
                                  loc.noEventsFound,
                                  style: Theme.of(context)
                                      .textTheme
                                      .headlineSmall
                                      ?.copyWith(fontSize: 16.0),
                                ),
                              ),
                            ),
                        ],
              ),
            );
          },
        ),
      ),
    );
  }
}
