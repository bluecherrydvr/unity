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

import 'package:bluecherry_client/models/device.dart';
import 'package:bluecherry_client/providers/server_provider.dart';
import 'package:bluecherry_client/utils/extensions.dart';
import 'package:bluecherry_client/utils/theme.dart';
import 'package:bluecherry_client/widgets/error_warning.dart';
import 'package:bluecherry_client/widgets/misc.dart';
import 'package:bluecherry_client/widgets/squared_icon_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:provider/provider.dart';
import 'package:sliver_tools/sliver_tools.dart';

typedef EventsPerDevice = Map<Device, int>;

Future<Device?> showDeviceSelector(
  BuildContext context, {
  List<Device> selected = const [],
  Iterable<Device>? available,
  EventsPerDevice eventsPerDevice = const {},
}) {
  return showModalBottomSheet<Device>(
    context: context,
    isScrollControlled: true,
    clipBehavior: Clip.hardEdge,
    builder: (context) {
      return DraggableScrollableSheet(
        maxChildSize: 0.85,
        initialChildSize: 0.7,
        expand: false,
        builder: (context, controller) {
          return PrimaryScrollController(
            controller: controller,
            child: DeviceSelector(
              selected: selected,
              available: available,
              eventsPerDevice: eventsPerDevice,
            ),
          );
        },
      );
    },
  );
}

class DeviceSelector extends StatelessWidget {
  /// The devices already selected
  final Iterable<Device> selected;

  final Iterable<Device>? available;

  /// The amount of events per device
  final EventsPerDevice eventsPerDevice;

  const DeviceSelector({
    super.key,
    this.selected = const [],
    this.available,
    this.eventsPerDevice = const {},
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final servers = context.watch<ServersProvider>();
    final loc = AppLocalizations.of(context);
    final viewPadding = MediaQuery.viewPaddingOf(context);

    return Scaffold(
      appBar: AppBar(
        leading: SquaredIconButton(
          icon: const Icon(Icons.close),
          tooltip: MaterialLocalizations.of(context).closeButtonTooltip,
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        title: Text(loc.selectACamera),
      ),
      body: () {
        if (servers.servers.isEmpty) return const NoServerWarning();

        return Padding(
          padding: EdgeInsets.only(
            left: viewPadding.left,
            right: viewPadding.right,
            bottom: viewPadding.bottom,
          ),
          child: CustomScrollView(primary: true, slivers: [
            for (final server in servers.servers)
              MultiSliver(pushPinnedChildren: true, children: [
                SliverPinnedHeader(
                  child: SubHeader(
                    server.name,
                    materialType: MaterialType.canvas,
                    subtext: server.online
                        ? loc.nDevices(server.devices.length)
                        : loc.offline,
                    subtextStyle: TextStyle(
                      color: !server.online ? theme.colorScheme.error : null,
                    ),
                    trailing: servers.isServerLoading(server)
                        ? const SizedBox(
                            height: 16.0,
                            width: 16.0,
                            child: CircularProgressIndicator.adaptive(
                              strokeWidth: 1.5,
                            ),
                          )
                        : null,
                  ),
                ),
                SliverList.builder(
                  itemCount: server.devices.length,
                  addAutomaticKeepAlives: false,
                  addRepaintBoundaries: false,
                  itemBuilder: (context, index) {
                    final devices = server.devices.sorted(available: available);
                    final device = devices[index];

                    final isSelected = selected.contains(device);
                    final isAvailable = available?.contains(device) ?? true;
                    final enabled = device.status && !isSelected && isAvailable;

                    return ListTile(
                      enabled: enabled,
                      leading: CircleAvatar(
                        backgroundColor: Colors.transparent,
                        foregroundColor: device.status
                            ? enabled
                                ? theme.extension<UnityColors>()!.successColor
                                : theme.disabledColor
                            : theme.colorScheme.error,
                        child: Icon(
                          !device.status
                              ? Icons.videocam_off_outlined
                              : !enabled
                                  ? Icons.videocam
                                  : Icons.videocam_outlined,
                        ),
                      ),
                      title: RichText(
                        text: TextSpan(
                          style: theme.textTheme.bodyLarge?.copyWith(
                            color: enabled
                                ? theme.colorScheme.onSurface
                                : theme.disabledColor,
                          ),
                          children: [
                            TextSpan(text: device.name.uppercaseFirst),
                            if (eventsPerDevice[device] != null)
                              TextSpan(
                                text:
                                    '  (${loc.nEvents(eventsPerDevice[device]!)})',
                                style: theme.textTheme.labelSmall,
                              ),
                          ],
                        ),
                      ),
                      subtitle: Text([
                        device.uri,
                        '${device.resolutionX}x${device.resolutionY}',
                      ].join(' • ')),
                      trailing: device.hasPTZ
                          ? const Icon(Icons.videogame_asset)
                          : null,
                      onTap: () => Navigator.of(context).pop(device),
                    );
                  },
                ),
              ]),
          ]),
        );
      }(),
    );
  }
}
