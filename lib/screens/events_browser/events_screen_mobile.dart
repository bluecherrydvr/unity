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
  final Iterable<Server> invalid;

  final Widget Function({required VoidCallback onSelect}) buildTimeFilterTile;

  const EventsScreenMobile({
    super.key,
    required this.events,
    required this.loadedServers,
    required this.refresh,
    required this.invalid,
    required this.buildTimeFilterTile,
  });

  @override
  State<EventsScreenMobile> createState() => _EventsScreenMobileState();
}

class _EventsScreenMobileState extends State<EventsScreenMobile> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => showFilterSheet(context, loadInitially: true),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
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
            SquaredIconButton(
              onPressed: () => eventsScreenKey.currentState?.fetch(),
              icon: const Icon(Icons.refresh, size: 20.0),
              tooltip: loc.refresh,
            ),
          Padding(
            padding: const EdgeInsetsDirectional.only(end: 15.0),
            child: SquaredIconButton(
              icon: const Icon(Icons.filter_list),
              tooltip: loc.filter,
              onPressed: () => showFilterSheet(context),
            ),
          ),
        ],
      ),
      body: () {
        if (widget.events.isEmpty) {
          final isLoading = HomeProvider.instance
              .isLoadingFor(UnityLoadingReason.fetchingEventsHistory);
          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                NoEventsLoaded(isLoading: isLoading),
                if (!isLoading) ...[
                  const SizedBox(height: 12.0),
                  ElevatedButton.icon(
                    onPressed: () => showFilterSheet(context),
                    icon: const Icon(Icons.filter_list),
                    label: Text(loc.filter),
                  ),
                ],
              ],
            ),
          );
        }

        final serversList = servers.servers.sorted((a, b) {
          final aEvents =
              widget.events.where((event) => event.server.id == a.id);
          final bEvents =
              widget.events.where((event) => event.server.id == b.id);

          final aOnline = a.online && aEvents.isNotEmpty;
          final bOnline = b.online && bEvents.isNotEmpty;

          if (aOnline && !bOnline) return -1;
          if (!aOnline && bOnline) return 1;

          return a.name.compareTo(b.name);
        });

        return Material(
          child: RefreshIndicator.adaptive(
            onRefresh: widget.refresh,
            triggerMode: RefreshIndicatorTriggerMode.anywhere,
            child: ListView.builder(
              itemCount: serversList.length,
              itemBuilder: (context, index) {
                final server = serversList[index];
                final serverEvents = widget.events
                    .where((event) => event.server.id == server.id);
                final hasEvents = serverEvents.isNotEmpty;

                return ListTile(
                  title: Text(
                    server.name,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(
                    !server.passedCertificates
                        ? loc.certificateNotPassed
                        : server.online
                            ? loc.nEvents(serverEvents.length)
                            : loc.offline,
                  ),
                  trailing: !server.online
                      ? Icon(
                          Icons.domain_disabled_outlined,
                          color: theme.colorScheme.error,
                          size: 20.0,
                        )
                      : hasEvents
                          ? const Icon(Icons.navigate_next, size: 20.0)
                          : null,
                  enabled: server.online && hasEvents,
                  onTap: () async {
                    if (!server.online || !hasEvents) return;

                    showEventsList(serverEvents);
                  },
                );
              },
            ),
          ),
        );
      }(),
    );
  }

  Future<void> showFilterSheet(
    BuildContext context, {
    bool loadInitially = false,
  }) async {
    /// This is used to update the screen when the bottom sheet is closed.
    var hasChanged = false;

    await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) {
        return DraggableScrollableSheet(
          expand: false,
          maxChildSize: 0.85,
          initialChildSize: 0.85,
          builder: (context, controller) {
            return PrimaryScrollController(
              controller: controller,
              child: MobileFilterSheet(
                onChanged: () {
                  hasChanged = true;
                },
                timeFilterTile: widget.buildTimeFilterTile(onSelect: () {
                  hasChanged = true;
                }),
              ),
            );
          },
        );
      },
    );

    if (hasChanged || loadInitially) widget.refresh();
  }

  Future<void> showEventsList(Iterable<Event> events) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) {
        return DraggableScrollableSheet(
          maxChildSize: 0.8,
          initialChildSize: 0.8,
          expand: false,
          builder: (context, controller) {
            final settings = context.watch<SettingsProvider>();
            return ListView.builder(
              controller: controller,
              itemCount: events.length,
              itemBuilder: (context, index) {
                final event = events.elementAt(index);
                return ListTile(
                  title: Row(children: [
                    Flexible(
                      child: Text(
                        event.deviceName,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    Text(
                      ' (${event.type.locale(context)})',
                      style: const TextStyle(fontSize: 10.0),
                    ),
                  ]),
                  dense: true,
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(children: [
                        const Icon(Icons.event, size: 16.0),
                        const SizedBox(width: 6.0),
                        Expanded(
                          child: Text(
                            '${settings.formatDate(event.updated)}'
                            ' • ${settings.formatTime(event.updated).toUpperCase()}',
                          ),
                        ),
                      ]),
                      Row(children: [
                        const Icon(Icons.timelapse, size: 16.0),
                        const SizedBox(width: 6.0),
                        Expanded(
                          child: Text(
                            event.duration.humanReadable(context),
                          ),
                        ),
                      ]),
                    ],
                  ),
                  trailing: const Icon(Icons.navigate_next, size: 20.0),
                  onTap: () async {
                    await Navigator.of(context).pushNamed(
                      '/events',
                      arguments: {'event': event, 'upcoming': events},
                    );
                  },
                );
              },
            );
          },
        );
      },
    );
  }
}
