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

Widget _buildTilePart({required Widget child, int flex = 1}) {
  return Expanded(
    flex: flex,
    child: Container(
      height: 40.0,
      margin: const EdgeInsetsDirectional.only(start: 10.0),
      alignment: AlignmentDirectional.centerStart,
      child: child,
    ),
  );
}

class EventsScreenDesktop extends StatelessWidget {
  final Iterable<Event> events;

  const EventsScreenDesktop({super.key, required this.events});

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final settings = context.watch<SettingsProvider>();

    if (events.isEmpty) {
      return Center(
        child: Text(
          loc.noEventsFound,
          textAlign: TextAlign.center,
        ),
      );
    }

    return Material(
      child: CustomScrollView(slivers: [
        SliverPersistentHeader(delegate: _TableHeader(), pinned: true),
        SliverFixedExtentList.builder(
          itemCount: events.length,
          itemExtent: 50.0,
          itemBuilder: (context, index) {
            final event = events.elementAt(index);

            return InkWell(
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
                      '${settings.formatDate(event.updated.toLocal())} ${settings.formatTime(event.updated).toUpperCase()}',
                    ),
                    flex: 2,
                  ),
                ]),
              ),
            );
          },
        ),
      ]),
    );
  }
}

class _TableHeader extends SliverPersistentHeaderDelegate {
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
          margin: const EdgeInsets.symmetric(horizontal: 20.0),
          child: DefaultTextStyle(
            style: theme.textTheme.headlineSmall ?? const TextStyle(),
            child: Row(children: [
              const SizedBox(width: 40.0, height: 40.0),
              _buildTilePart(
                child: Text(loc.server),
                flex: 2,
              ),
              _buildTilePart(
                child: Text(loc.device),
              ),
              _buildTilePart(
                child: Text(loc.event),
              ),
              _buildTilePart(
                child: Text(loc.duration),
              ),
              _buildTilePart(
                child: Text(loc.priority),
              ),
              _buildTilePart(
                child: Text(loc.date),
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
  bool shouldRebuild(SliverPersistentHeaderDelegate oldDelegate) {
    return false;
  }
}
