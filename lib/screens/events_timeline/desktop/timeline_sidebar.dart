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
import 'package:bluecherry_client/screens/events_browser/filter.dart';
import 'package:bluecherry_client/utils/date.dart';
import 'package:bluecherry_client/utils/methods.dart';
import 'package:bluecherry_client/widgets/collapsable_sidebar.dart';
import 'package:bluecherry_client/widgets/misc.dart';
import 'package:bluecherry_client/widgets/search.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

class TimelineSidebar extends StatefulWidget {
  const TimelineSidebar({
    super.key,
    required this.date,
    required this.onDateChanged,
  });

  final DateTime date;
  final ValueChanged<DateTime> onDateChanged;

  @override
  State<TimelineSidebar> createState() => _TimelineSidebarState();
}

class _TimelineSidebarState extends State<TimelineSidebar> with Searchable {
  final _eventTypeFilterTileKey = GlobalKey();

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final eventsProvider = context.watch<EventsProvider>();
    final theme = Theme.of(context);

    return Card(
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadiusDirectional.vertical(
          top: Radius.circular(12.0),
        ),
      ),
      margin: const EdgeInsetsDirectional.only(end: 4.0, top: 4.0, start: 4.0),
      child: CollapsableSidebar(
        // TODO(bdlukaa): This is not working because offline devices are being
        //                marked as selected.
        initiallyClosed:
            eventsProvider.selectedDevices.isNotEmpty || isEmbedded,
        left: false,
        builder: (context, collapsed, collapseButton) {
          collapseButton = Padding(
            padding: const EdgeInsetsDirectional.only(top: 4.0),
            child: collapseButton,
          );
          if (collapsed) return collapseButton;

          return Column(children: [
            SubHeader(
              loc.servers,
              height: 40.0,
              trailing: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  SearchToggleButton(searchable: this, iconSize: 22.0),
                  collapseButton,
                ],
              ),
              padding: const EdgeInsetsDirectional.only(start: 16.0, end: 4.0),
            ),
            ToggleSearchBar(searchable: this),
            Expanded(child: EventsDevicesPicker(searchQuery: searchQuery)),
            const Divider(),
            ListTile(
              dense: true,
              title: Text(
                loc.dateFilter,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              trailing: AutoSizeText(
                widget.date.formatDecoratedDate(
                  context,
                  DateFormat('EEE, dd MMM yyyy'),
                ),
                maxLines: 1,
              ),
              onTap: () async {
                final result = await showDatePicker(
                  context: context,
                  initialDate: widget.date,
                  firstDate: DateTime.utc(1970),
                  lastDate: DateTimeExtension.now(),
                  initialEntryMode: DatePickerEntryMode.calendarOnly,
                  currentDate: widget.date,
                );
                if (result != null) {
                  debugPrint('date picked: from ${widget.date} to $result');
                  widget.onDateChanged(result);
                }
              },
            ),
            ListTile(
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
                final box = _eventTypeFilterTileKey.currentContext!
                    .findRenderObject() as RenderBox;

                showMenu(
                  context: context,
                  position: RelativeRect.fromRect(
                    box.localToGlobal(
                          Offset.zero,
                          ancestor:
                              Navigator.of(context).context.findRenderObject(),
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
            ),
          ]);
        },
      ),
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
