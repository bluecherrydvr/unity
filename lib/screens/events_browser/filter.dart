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

import 'package:bluecherry_client/providers/server_provider.dart';
import 'package:bluecherry_client/utils/extensions.dart';
import 'package:bluecherry_client/widgets/tree_view.dart';
import 'package:bluecherry_client/screens/events_browser/events_screen.dart';
import 'package:bluecherry_client/widgets/misc.dart';
import 'package:bluecherry_client/widgets/search.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:provider/provider.dart';

enum EventsMinLevelFilter { any, info, warning, alarming, critical }

class EventsDevicesPicker extends StatelessWidget {
  final EventsData events;
  final Set<String> disabledDevices;
  final double checkboxScale;
  final double gapCheckboxText;

  final ValueChanged<String> onDisabledDeviceAdded;
  final ValueChanged<String> onDisabledDeviceRemoved;

  final String searchQuery;

  const EventsDevicesPicker({
    super.key,
    required this.events,
    required this.disabledDevices,
    required this.onDisabledDeviceAdded,
    required this.onDisabledDeviceRemoved,
    required this.searchQuery,
    this.checkboxScale = 0.8,
    this.gapCheckboxText = 0.0,
  });

  @override
  Widget build(BuildContext context) {
    final servers = context.watch<ServersProvider>();

    return SingleChildScrollView(
      child: TreeView(
        indent: 56,
        iconSize: 18.0,
        nodes: servers.servers.map((server) {
          final disabledDevicesForServer = disabledDevices.where(
              (d) => server.devices.any((device) => device.streamURL == d));
          final isTriState = disabledDevices.any(
              (d) => server.devices.any((device) => device.streamURL == d));
          final isOffline = !server.online;
          final serverEvents = events[server];

          return TreeNode(
            content: buildCheckbox(
              value: disabledDevicesForServer.length == server.devices.length ||
                      isOffline
                  ? false
                  : isTriState
                      ? null
                      : true,
              isError: isOffline,
              onChanged: (v) {
                if (v == true) {
                  for (final d in server.devices) {
                    onDisabledDeviceRemoved(d.streamURL);
                  }
                } else if (v == null || !v) {
                  for (final d in server.devices) {
                    onDisabledDeviceAdded(d.streamURL);
                  }
                }
              },
              checkboxScale: checkboxScale,
              text: server.name,
              secondaryText: isOffline ? null : '${server.devices.length}',
              gapCheckboxText: gapCheckboxText,
              textFit: FlexFit.tight,
              offlineIcon: Icons.domain_disabled_outlined,
            ),
            children: () {
              if (isOffline) {
                return <TreeNode>[];
              } else {
                return server.devices
                    .sorted(searchQuery: searchQuery)
                    .map((device) {
                  final enabled = isOffline
                      ? false
                      : !disabledDevices.contains(device.streamURL);
                  final eventsForDevice = serverEvents
                      ?.where((event) => event.deviceID == device.id);
                  return TreeNode(
                    content: IgnorePointer(
                      ignoring: !device.status,
                      child: buildCheckbox(
                        value: device.status ? enabled : false,
                        isError: !device.status,
                        onChanged: (v) {
                          if (!device.status) return;

                          if (enabled) {
                            onDisabledDeviceAdded(device.streamURL);
                          } else {
                            onDisabledDeviceRemoved(device.streamURL);
                          }
                        },
                        checkboxScale: checkboxScale,
                        text: device.name,
                        secondaryText: eventsForDevice != null && device.status
                            ? ' (${eventsForDevice.length})'
                            : null,
                        gapCheckboxText: gapCheckboxText,
                      ),
                    ),
                  );
                }).toList();
              }
            }(),
          );
        }).toList(),
      ),
    );
  }
}

class MobileFilterSheet extends StatefulWidget {
  final EventsData events;
  final Set<String> disabledDevices;

  final ValueChanged<String> onDisabledDeviceAdded;
  final ValueChanged<String> onDisabledDeviceRemoved;

  final EventsMinLevelFilter levelFilter;
  final ValueChanged<EventsMinLevelFilter> onLevelFilterChanged;

  final Widget timeFilterTile;

  const MobileFilterSheet({
    super.key,
    required this.events,
    required this.disabledDevices,
    required this.onDisabledDeviceAdded,
    required this.onDisabledDeviceRemoved,
    required this.levelFilter,
    required this.onLevelFilterChanged,
    required this.timeFilterTile,
  });

  @override
  State<MobileFilterSheet> createState() => _MobileFilterSheetState();
}

class _MobileFilterSheetState extends State<MobileFilterSheet> {
  final searchController = TextEditingController();
  final searchFocusNode = FocusNode();
  String searchQuery = '';
  bool searchVisible = false;

  @override
  void dispose() {
    searchController.dispose();
    searchFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    return ListView(primary: true, children: [
      SubHeader(loc.timeFilter, height: 20.0),
      widget.timeFilterTile,
      const SubHeader('Minimum level', height: 20.0),
      DropdownButtonHideUnderline(
        child: DropdownButton<EventsMinLevelFilter>(
          isExpanded: true,
          value: widget.levelFilter,
          items: EventsMinLevelFilter.values.map((level) {
            return DropdownMenuItem(
              value: level,
              child: Text(level.name.uppercaseFirst()),
            );
          }).toList(),
          onChanged: (filter) {
            if (filter != null) {
              widget.onLevelFilterChanged(filter);
            }
          },
        ),
      ),
      SubHeader(
        loc.servers,
        height: 38.0,
        trailing: SearchToggleButton(
          searchVisible: searchVisible,
          onPressed: () => setState(() => searchVisible = !searchVisible),
        ),
      ),
      ToggleSearchBar(
        searchVisible: searchVisible,
        searchController: searchController,
        searchFocusNode: searchFocusNode,
        onSearchChanged: (query) => setState(() => searchQuery = query),
      ),
      EventsDevicesPicker(
        events: widget.events,
        disabledDevices: widget.disabledDevices,
        gapCheckboxText: 10.0,
        checkboxScale: 1.15,
        onDisabledDeviceAdded: (device) =>
            setState(() => widget.disabledDevices.add(device)),
        onDisabledDeviceRemoved: (device) =>
            setState(() => widget.disabledDevices.remove(device)),
        searchQuery: searchQuery,
      )
    ]);
  }
}
