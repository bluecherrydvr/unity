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
import 'package:bluecherry_client/providers/server_provider.dart';
import 'package:bluecherry_client/utils/extensions.dart';
import 'package:bluecherry_client/widgets/misc.dart';
import 'package:bluecherry_client/widgets/search.dart';
import 'package:bluecherry_client/widgets/tree_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:provider/provider.dart';

enum EventsMinLevelFilter { any, info, warning, alarming, critical }

class EventsDevicesPicker extends StatefulWidget {
  final double checkboxScale;
  final double gapCheckboxText;
  final String searchQuery;
  final VoidCallback? onChanged;

  const EventsDevicesPicker({
    super.key,
    required this.searchQuery,
    this.checkboxScale = 0.8,
    this.gapCheckboxText = 0.0,
    this.onChanged,
  });

  @override
  State<EventsDevicesPicker> createState() => _EventsDevicesPickerState();
}

class _EventsDevicesPickerState extends State<EventsDevicesPicker> {
  final treeViewController = TreeController(allNodesExpanded: false);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final eventsProvider = context.read<EventsProvider>();
      final serversProvider = context.read<ServersProvider>();

      for (var server in serversProvider.servers) {
        if (server.devices.length < 7 ||
            eventsProvider.selectedDevices.any(
                (d) => server.devices.any((device) => device.streamURL == d))) {
          setState(
              () => treeViewController.toggleNodeExpanded(ValueKey(server.ip)));
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final serversProvider = context.watch<ServersProvider>();
    final eventsProvider = context.watch<EventsProvider>();

    return SingleChildScrollView(
      child: TreeView(
        treeController: treeViewController,
        indent: 56,
        iconSize: 18.0,
        nodes: serversProvider.servers.map((server) {
          final enabledDevicesForServer = eventsProvider.selectedDevices.where(
            (deviceUrl) => server.devices.any(
              (device) => device.streamURL == deviceUrl,
            ),
          );
          final isOffline = !server.online;
          final serverEvents = (eventsProvider.loadedEvents?.events ?? {})
              .entries
              .firstWhereOrNull((entry) => entry.key.ip == server.ip)
              ?.value;

          return TreeNode(
            key: ValueKey(server.ip),
            content: buildCheckbox(
              value: enabledDevicesForServer.isEmpty || isOffline
                  ? false
                  : enabledDevicesForServer.length ==
                          server.devices.where((device) => device.status).length
                      ? true
                      : null,
              isError: isOffline,
              onChanged: (v) {
                if (v == true) {
                  eventsProvider.selectDevices(
                    server.devices
                        .where((device) => device.status)
                        .map((device) => device.streamURL),
                  );
                  widget.onChanged?.call();
                } else if (v == null || !v) {
                  final toUnselectDevices = server.devices
                      .map((device) => device.streamURL)
                      .where((d) => eventsProvider.selectedDevices.contains(d));
                  eventsProvider.unselectDevices(toUnselectDevices);
                  widget.onChanged?.call();
                }
              },
              checkboxScale: widget.checkboxScale,
              text: server.name,
              secondaryText: isOffline ? null : '${server.devices.length}',
              gapCheckboxText: widget.gapCheckboxText,
              textFit: FlexFit.tight,
              offlineIcon: Icons.domain_disabled_outlined,
            ),
            children: () {
              if (isOffline) {
                return <TreeNode>[];
              } else {
                return server.devices
                    .sorted(searchQuery: widget.searchQuery)
                    .map((device) {
                  final enabled = isOffline
                      ? false
                      : eventsProvider.selectedDevices
                          .contains(device.streamURL);
                  final eventsForDevice = serverEvents
                      ?.where((event) => event.deviceID == device.id);
                  return TreeNode(
                    key: ValueKey(device.streamURL),
                    content: IgnorePointer(
                      ignoring: !device.status,
                      child: buildCheckbox(
                        value: device.status ? enabled : false,
                        isError: !device.status,
                        onChanged: (v) {
                          if (!device.status) return;

                          if (enabled) {
                            eventsProvider.unselectDevices([device.streamURL]);
                            widget.onChanged?.call();
                          } else {
                            eventsProvider.selectDevices([device.streamURL]);
                            widget.onChanged?.call();
                          }
                        },
                        checkboxScale: widget.checkboxScale,
                        text: device.name,
                        secondaryText: eventsForDevice != null && device.status
                            ? ' (${eventsForDevice.length})'
                            : null,
                        gapCheckboxText: widget.gapCheckboxText,
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
  final Widget timeFilterTile;
  final VoidCallback? onChanged;

  const MobileFilterSheet({
    super.key,
    required this.timeFilterTile,
    this.onChanged,
  });

  @override
  State<MobileFilterSheet> createState() => _MobileFilterSheetState();
}

class _MobileFilterSheetState extends State<MobileFilterSheet> with Searchable {
  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final eventsProvider = context.watch<EventsProvider>();
    return ListView(primary: true, children: [
      widget.timeFilterTile,
      const SubHeader('Minimum level', height: 20.0),
      DropdownButtonHideUnderline(
        child: DropdownButton<EventsMinLevelFilter>(
          isExpanded: true,
          value: eventsProvider.levelFilter,
          items: EventsMinLevelFilter.values.map((level) {
            return DropdownMenuItem(
              value: level,
              child: Text(level.name.uppercaseFirst),
            );
          }).toList(),
          onChanged: (filter) {
            if (filter != null) {
              eventsProvider.levelFilter = filter;
            }
          },
        ),
      ),
      SubHeader(
        loc.servers,
        height: 38.0,
        trailing: SearchToggleButton(searchable: this),
      ),
      ToggleSearchBar(searchable: this),
      EventsDevicesPicker(
        gapCheckboxText: 10.0,
        checkboxScale: 1.15,
        searchQuery: searchQuery,
        onChanged: widget.onChanged,
      )
    ]);
  }
}
