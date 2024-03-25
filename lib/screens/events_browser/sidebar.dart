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

import 'package:bluecherry_client/providers/events_provider.dart';
import 'package:bluecherry_client/providers/home_provider.dart';
import 'package:bluecherry_client/providers/server_provider.dart';
import 'package:bluecherry_client/screens/events_browser/filter.dart';
import 'package:bluecherry_client/screens/layouts/device_grid.dart';
import 'package:bluecherry_client/widgets/misc.dart';
import 'package:bluecherry_client/widgets/search.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:provider/provider.dart';

class EventsScreenSidebar extends StatelessWidget {
  final bool searchVisible;
  final String searchQuery;
  final TextEditingController searchController;
  final FocusNode searchFocusNode;
  final ValueChanged<String> onSearchChanged;
  final VoidCallback onSearchVisibilityToggle;
  final WidgetBuilder buildTimeFilterTile;
  final VoidCallback fetch;

  const EventsScreenSidebar({
    super.key,
    required this.searchVisible,
    required this.searchQuery,
    required this.searchController,
    required this.searchFocusNode,
    required this.onSearchChanged,
    required this.onSearchVisibilityToggle,
    required this.buildTimeFilterTile,
    required this.fetch,
  });

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final serversProvider = context.watch<ServersProvider>();
    final eventsProvider = context.watch<EventsProvider>();
    final homeProvider = context.watch<HomeProvider>();
    final isLoading = homeProvider.isLoadingFor(
      UnityLoadingReason.fetchingEventsHistory,
    );
    return ConstrainedBox(
      constraints: kSidebarConstraints,
      child: SafeArea(
        child: DropdownButtonHideUnderline(
          child: Column(children: [
            SubHeader(
              loc.servers,
              height: 38.0,
              trailing: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Padding(
                    padding: const EdgeInsetsDirectional.only(end: 6.0),
                    child: SearchToggleButton(
                      searchVisible: searchVisible,
                      onPressed: () {
                        onSearchVisibilityToggle();
                        if (searchVisible) {
                          searchFocusNode.requestFocus();
                        }
                      },
                    ),
                  ),
                  Text('${serversProvider.servers.length}'),
                ],
              ),
            ),
            ToggleSearchBar(
              searchVisible: searchVisible,
              searchController: searchController,
              searchFocusNode: searchFocusNode,
              onSearchChanged: onSearchChanged,
            ),
            Expanded(
              child: SingleChildScrollView(
                child: EventsDevicesPicker(searchQuery: searchQuery),
              ),
            ),
            const Divider(),
            Builder(builder: buildTimeFilterTile),
            // const SubHeader('Minimum level', height: 24.0),
            // DropdownButton<EventsMinLevelFilter>(
            //   isExpanded: true,
            //   value: levelFilter,
            //   items: EventsMinLevelFilter.values.map((level) {
            //     return DropdownMenuItem(
            //       value: level,
            //       child: Text(level.name.uppercaseFirst),
            //     );
            //   }).toList(),
            //   onChanged: (v) => setState(
            //     () => levelFilter = v ?? levelFilter,
            //   ),
            // ),
            const SizedBox(height: 8.0),
            FilledButton(
              onPressed: isLoading ? null : fetch,
              child: Text(
                loc.loadEvents(eventsProvider.selectedDevices.length),
              ),
            ),
            const SizedBox(height: 12.0),
          ]),
        ),
      ),
    );
  }
}
