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

Widget _buildTilePart({required Widget child, Widget? icon, int flex = 1}) {
  return Expanded(
    flex: flex,
    child: Container(
      height: 40.0,
      margin: const EdgeInsetsDirectional.only(start: 10.0),
      alignment: AlignmentDirectional.centerStart,
      child: Row(children: [
        if (icon != null) ...[
          IconTheme.merge(data: const IconThemeData(size: 14.0), child: icon),
          const SizedBox(width: 6.0),
        ],
        Flexible(child: child),
      ]),
    ),
  );
}

class EventsScreenDesktop extends StatelessWidget {
  final Iterable<Event> events;

  const EventsScreenDesktop({super.key, required this.events});

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsProvider>();

    if (events.isEmpty) {
      return NoEventsLoaded(
        isLoading: context
            .watch<HomeProvider>()
            .isLoadingFor(UnityLoadingReason.fetchingEventsHistory),
      );
    }

    return Material(
      child: SafeArea(
        child: CustomScrollView(slivers: [
          SliverPersistentHeader(
            delegate: _TableHeader(eventsAmount: events.length),
            pinned: true,
          ),
          SliverFixedExtentList.builder(
            itemCount: events.length,
            itemExtent: 48.0,
            addAutomaticKeepAlives: false,
            addRepaintBoundaries: false,
            findChildIndexCallback: (key) {
              final k = key as ValueKey<Event>;
              return events.indexed
                  .firstWhereOrNull((e) => e.$2 == k.value)
                  ?.$1;
            },
            itemBuilder: (context, index) {
              final event = events.elementAt(index);

              return InkWell(
                key: ValueKey(event),
                onTap: event.mediaURL == null
                    ? null
                    : () {
                        debugPrint('Displaying event $event');
                        Navigator.of(context).pushNamed(
                          '/events',
                          arguments: {'event': event, 'upcoming': events},
                        );
                      },
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20.0),
                  child: Row(children: [
                    Container(
                      width: 40.0,
                      height: 40.0,
                      alignment: AlignmentDirectional.center,
                      child: DownloadIndicator(event: event),
                    ),
                    _buildTilePart(child: Text(event.server.name), flex: 2),
                    _buildTilePart(child: Text(event.deviceName)),
                    _buildTilePart(
                      child: Text(event.type.locale(context).uppercaseFirst()),
                    ),
                    _buildTilePart(
                      child: Text(event.duration
                          .humanReadableCompact(context)
                          .uppercaseFirst()),
                    ),
                    _buildTilePart(
                      child:
                          Text(event.priority.locale(context).uppercaseFirst()),
                    ),
                    _buildTilePart(
                      child: Text(
                        '${settings.formatDate(event.updated)} ${settings.formatTime(event.updated).toUpperCase()}',
                      ),
                      flex: 2,
                    ),
                  ]),
                ),
              );
            },
          ),
        ]),
      ),
    );
  }
}

class _TableHeader extends SliverPersistentHeaderDelegate {
  final int eventsAmount;

  _TableHeader({required this.eventsAmount});

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    final loc = AppLocalizations.of(context);
    final theme = Theme.of(context);

    return Material(
      child: Card(
        child: Container(
          height: 50,
          margin: const EdgeInsets.symmetric(horizontal: 15.0),
          child: DefaultTextStyle(
            style: theme.textTheme.headlineSmall ?? const TextStyle(),
            child: Row(children: [
              SizedBox(
                width: 40.0,
                height: 40.0,
                child: Center(
                  child: Text(
                    '$eventsAmount',
                    style: theme.textTheme.labelMedium,
                  ),
                ),
              ),
              _buildTilePart(
                icon: const Icon(Icons.dns),
                child: Text(loc.server),
                flex: 2,
              ),
              _buildTilePart(
                child: Text(loc.device),
                icon: const Icon(Icons.videocam),
              ),
              _buildTilePart(
                child: Text(loc.event),
                icon: const Icon(Icons.subscriptions),
              ),
              _buildTilePart(
                child: Text(loc.duration),
                icon: const Icon(Icons.timer),
              ),
              _buildTilePart(
                child: Text(loc.priority),
                icon: const Icon(Icons.priority_high),
              ),
              _buildTilePart(
                child: Text(loc.date),
                icon: const Icon(Icons.calendar_today),
                flex: 2,
              ),
            ]),
          ),
        ),
      ),
    );
  }

  @override
  double get maxExtent => 50;

  @override
  double get minExtent => 50;

  @override
  bool shouldRebuild(covariant _TableHeader oldDelegate) {
    return eventsAmount != oldDelegate.eventsAmount;
  }
}

class NoEventsLoaded extends StatelessWidget {
  final bool isLoading;

  const NoEventsLoaded({super.key, this.isLoading = false});

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final theme = Theme.of(context);

    if (isLoading) {
      return const Center(
        child: CircularProgressIndicator.adaptive(
          strokeWidth: 2.0,
        ),
      );
    }

    return Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      const Icon(Icons.production_quantity_limits, size: 48.0),
      Text(
        loc.noEventsLoaded,
        textAlign: TextAlign.center,
        style: theme.textTheme.bodyLarge,
      ),
      const SizedBox(height: 6.0),
      const Divider(),
      const SizedBox(height: 6.0),
      Text(
        loc.noEventsLoadedTips,
        style: theme.textTheme.bodySmall,
      ),
    ]);
  }
}
