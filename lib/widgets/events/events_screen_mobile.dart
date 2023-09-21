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

class EventsScreenMobile extends StatefulWidget {
  final Iterable<Event> events;
  final Iterable<Server> loadedServers;

  final RefreshCallback refresh;
  final Map<Server, bool> invalid;

  final VoidCallback showFilter;

  const EventsScreenMobile({
    super.key,
    required this.events,
    required this.loadedServers,
    required this.refresh,
    required this.invalid,
    required this.showFilter,
  });

  @override
  State<EventsScreenMobile> createState() => _EventsScreenMobileState();
}

class _EventsScreenMobileState extends State<EventsScreenMobile> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => widget.showFilter());
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final settings = context.watch<SettingsProvider>();
    final servers = context.watch<ServersProvider>();
    final loc = AppLocalizations.of(context);

    final isLoading = context.watch<HomeProvider>().isLoadingFor(
          UnityLoadingReason.fetchingEventsHistory,
        );

    return Scaffold(
      appBar: AppBar(
        leading: MaybeUnityDrawerButton(context),
        title: Text(loc.eventBrowser),
        actions: [
          if (!isLoading)
            IconButton(
              onPressed: () => eventsScreenKey.currentState?.fetch(),
              icon: const Icon(Icons.refresh),
              iconSize: 20.0,
              tooltip: loc.refresh,
            ),
          Padding(
            padding: const EdgeInsetsDirectional.only(end: 15.0),
            child: IconButton(
              icon: const Icon(Icons.filter_list),
              tooltip: loc.filter,
              onPressed: widget.showFilter,
            ),
          ),
        ],
      ),
      body: () {
        if (widget.events.isEmpty) {
          if (HomeProvider.instance
              .isLoadingFor(UnityLoadingReason.fetchingEventsHistory)) {
            return const Center(
              child: CircularProgressIndicator.adaptive(
                strokeWidth: 2.0,
              ),
            );
          }

          return Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            const Icon(Icons.production_quantity_limits, size: 48.0),
            Text(
              loc.noEventsFound,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyLarge,
            ),
            const SizedBox(height: 6.0),
            const Divider(),
            const SizedBox(height: 6.0),
            Text(
              loc.noEventsFoundTips,
              style: theme.textTheme.bodySmall,
            ),
            const SizedBox(height: 12.0),
            ElevatedButton.icon(
              onPressed: widget.showFilter,
              icon: const Icon(Icons.filter_list),
              label: Text(loc.filter),
            ),
          ]);
        }

        return Material(
          child: RefreshIndicator.adaptive(
            onRefresh: widget.refresh,
            triggerMode: RefreshIndicatorTriggerMode.anywhere,
            child: ListView.builder(
              itemCount: servers.servers.length,
              itemBuilder: (context, index) {
                final server = servers.servers[index];
                final isLoaded = widget.loadedServers.contains(server);
                final serverEvents = widget.events
                    .where((event) => event.server.id == server.id);
                final hasEvents = serverEvents.isNotEmpty;

                return IgnorePointer(
                  ignoring: !server.online || !isLoaded,
                  child: ExpansionTile(
                    initiallyExpanded: servers.servers.length == 1,
                    maintainState: true,
                    leading: CircleAvatar(
                      backgroundColor: Colors.transparent,
                      child: !server.online
                          ? Icon(
                              Icons.desktop_access_disabled,
                              color: theme.colorScheme.error,
                            )
                          : !isLoaded
                              ? const SizedBox(
                                  height: 20.0,
                                  width: 20.0,
                                  child: CircularProgressIndicator.adaptive(
                                    strokeWidth: 2.0,
                                  ),
                                )
                              : Icon(
                                  Icons.language,
                                  color: theme.iconTheme.color,
                                ),
                    ),
                    trailing: server.online ? null : const SizedBox.shrink(),
                    title: Text(server.name),
                    subtitle: !server.online
                        ? Text(
                            loc.offline,
                            style: TextStyle(
                              color: theme.colorScheme.error,
                              fontWeight: FontWeight.w600,
                            ),
                          )
                        : Text(
                            '${loc.nDevices(server.devices.length)} • ${server.ip}  • ${serverEvents.length} events',
                          ),
                    children: !hasEvents
                        ? [
                            if (isLoaded)
                              if (widget.invalid[server] ?? true)
                                SizedBox(
                                  height: 72.0,
                                  child: Center(
                                    child: Text(
                                      loc.invalidResponse,
                                      style: theme.textTheme.headlineSmall
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
                                      style: theme.textTheme.headlineSmall
                                          ?.copyWith(fontSize: 16.0),
                                    ),
                                  ),
                                ),
                          ]
                        : serverEvents.map((event) {
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
                                          'upcoming': serverEvents,
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
                          }).toList(),
                  ),
                );
              },
            ),
          ),
        );
      }(),
    );
  }
}
