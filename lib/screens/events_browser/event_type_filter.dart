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

import 'package:auto_size_text/auto_size_text.dart';
import 'package:bluecherry_client/models/event.dart';
import 'package:bluecherry_client/providers/events_provider.dart';
import 'package:bluecherry_client/widgets/misc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:provider/provider.dart';

class EventTypeFilterTile extends StatefulWidget {
  const EventTypeFilterTile({super.key});

  @override
  State<EventTypeFilterTile> createState() => _EventTypeFilterTileState();
}

class _EventTypeFilterTileState extends State<EventTypeFilterTile> {
  final _eventTypeFilterTileKey = GlobalKey();

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final eventsProvider = context.watch<EventsProvider>();
    final theme = Theme.of(context);

    return ListTile(
      key: _eventTypeFilterTileKey,
      dense: true,
      title: Text(
        loc.eventType,
        style: const TextStyle(fontWeight: FontWeight.bold),
      ),
      trailing: AutoSizeText(
        () {
          final type = eventsProvider.eventTypeFilter;
          // For some reason I can not use a switch here
          if (type == EventType.motion.index) {
            return loc.motion;
          } else if (type == EventType.continuous.index) {
            return loc.continuous;
          } else {
            return 'All';
          }
        }(),
        maxLines: 1,
      ),
      onTap: () async {
        final box = _eventTypeFilterTileKey.currentContext!.findRenderObject()
            as RenderBox;

        showMenu(
          context: context,
          position: RelativeRect.fromRect(
            box.localToGlobal(
                  Offset.zero,
                  ancestor: Navigator.of(context).context.findRenderObject(),
                ) &
                box.size,
            Offset.zero & MediaQuery.of(context).size,
          ),
          constraints: BoxConstraints(
            minWidth: box.size.width - 8,
            maxWidth: box.size.width - 8,
          ),
          items: <PopupMenuEntry>[
            PopupMenuLabel(
              label: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16.0,
                  vertical: 6.0,
                ),
                child: Text(
                  loc.eventType,
                  maxLines: 1,
                  style: theme.textTheme.labelSmall,
                ),
              ),
            ),
            const PopupMenuDivider(),
            _buildMenuItem(
              value: -1,
              child: const Text('All'),
            ),
            _buildMenuItem(
              value: EventType.motion.index,
              child: Text(loc.motion),
            ),
            _buildMenuItem(
              value: EventType.continuous.index,
              child: Text(loc.continuous),
            ),
          ],
        );
      },
    );
  }

  PopupMenuItem _buildMenuItem({required Widget child, required int value}) {
    final eventsProvider = context.read<EventsProvider>();
    final selected = eventsProvider.eventTypeFilter == value;

    return CheckedPopupMenuItem(
      value: value,
      padding: const EdgeInsets.symmetric(horizontal: 20.0),
      checked: selected,
      // enabled: !selected,
      onTap: () {
        eventsProvider.eventTypeFilter = value;
      },
      child: Align(
        alignment: AlignmentDirectional.centerEnd,
        child: child,
      ),
    );
  }
}
