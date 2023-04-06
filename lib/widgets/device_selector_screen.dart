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
import 'package:bluecherry_client/widgets/error_warning.dart';
import 'package:bluecherry_client/widgets/misc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:provider/provider.dart';

class DeviceSelectorScreen extends StatelessWidget {
  /// The devices already selected
  final Iterable<Device> selected;

  const DeviceSelectorScreen({
    Key? key,
    this.selected = const [],
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final servers = context.watch<ServersProvider>();
    final loc = AppLocalizations.of(context);
    final viewPadding = MediaQuery.viewPaddingOf(context);

    return Scaffold(
      appBar: AppBar(title: Text(loc.selectACamera)),
      body: () {
        if (servers.servers.isEmpty) {
          return const NoServerWarning();
        }

        return ListView.builder(
          itemCount: servers.servers.length,
          itemBuilder: (context, index) {
            final server = servers.servers[index];
            final isLoading = servers.isServerLoading(server);

            if (isLoading) {
              return Center(
                child: Container(
                  alignment: AlignmentDirectional.center,
                  height: 156.0,
                  child: const CircularProgressIndicator.adaptive(),
                ),
              );
            }

            final devices = server.devices.sorted();

            return ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: devices.length + 1,
              // EdgeInsetsDirectional can not be used here because viewPadding
              // is EdgeInsets. We are just avoiding the top
              padding: EdgeInsets.only(
                left: viewPadding.left,
                right: viewPadding.right,
                bottom: viewPadding.bottom,
              ),
              itemBuilder: (context, index) {
                if (index == 0) {
                  return SubHeader(
                    server.name,
                    subtext: server.online
                        ? loc.nDevices(devices.length)
                        : loc.offline,
                    subtextStyle: TextStyle(
                      color: !server.online ? theme.colorScheme.error : null,
                    ),
                    trailing: isLoading
                        ? const SizedBox(
                            height: 16.0,
                            width: 16.0,
                            child: CircularProgressIndicator.adaptive(
                              strokeWidth: 1.5,
                            ),
                          )
                        : null,
                  );
                }

                index--;

                final device = devices[index];
                final isSelected = selected.contains(device);

                return ListTile(
                  enabled: device.status && !isSelected,
                  leading: CircleAvatar(
                    backgroundColor: Colors.transparent,
                    foregroundColor: device.status
                        ? Colors.green.shade100
                        : Theme.of(context).colorScheme.error,
                    child: const Icon(Icons.camera_alt),
                  ),
                  title: Text(
                    device.name
                        .split(' ')
                        .map((e) => e[0].toUpperCase() + e.substring(1))
                        .join(' '),
                  ),
                  subtitle: Text(
                    [
                      device.uri,
                      '${device.resolutionX}x${device.resolutionY}',
                    ].join(' • '),
                  ),
                  onTap: () => Navigator.of(context).pop(device),
                );
              },
            );
          },
        );
      }(),
    );
  }
}
