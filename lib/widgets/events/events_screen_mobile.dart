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
  final Map<Server, bool> invalid;

  const EventsScreenMobile({
    super.key,
    required this.events,
    required this.refresh,
    required this.invalid,
  });

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsProvider>();
    final servers = context.watch<ServersProvider>();
    final loc = AppLocalizations.of(context);

    return Material(
      child: RefreshIndicator(
        onRefresh: refresh,
        triggerMode: RefreshIndicatorTriggerMode.anywhere,
        child: ListView.builder(
          itemCount: servers.servers.length,
          itemBuilder: (context, index) {
            final server = servers.servers[index];
            final hasEvents =
                events.containsKey(server) && events[server]!.isNotEmpty;

            return IgnorePointer(
              ignoring: !server.online || !hasEvents,
              child: ExpansionTile(
                initiallyExpanded: servers.servers.length.compareTo(1) == 0,
                maintainState: true,
                leading: CircleAvatar(
                  backgroundColor: Colors.transparent,
                  child: !server.online
                      ? Icon(
                          Icons.desktop_access_disabled,
                          color: Theme.of(context).colorScheme.error,
                        )
                      : !hasEvents
                          ? const SizedBox(
                              height: 20.0,
                              width: 20.0,
                              child: CircularProgressIndicator.adaptive(
                                strokeWidth: 2.0,
                              ),
                            )
                          : Icon(
                              Icons.language,
                              color: Theme.of(context).iconTheme.color,
                            ),
                ),
                trailing: server.online ? null : const SizedBox.shrink(),
                title: Text(server.name),
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
                children: !hasEvents
                    ? []
                    : events[server]?.map((event) {
                          return ListTile(
                            contentPadding: const EdgeInsetsDirectional.only(
                              start: 70.0,
                              end: 16.0,
                            ),
                            onTap: event.mediaURL == null
                                ? null
                                : () async {
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
                                '${event.type.locale(context)} • ${event.duration.humanReadable(context)}',
                                '${settings.formatDate(event.updated)}'
                                    ' ${settings.formatTime(event.updated).toUpperCase()}',
                              ].join('\n'),
                              overflow: TextOverflow.ellipsis,
                            ),
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
