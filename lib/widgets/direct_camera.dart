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
import 'package:bluecherry_client/models/server.dart';
import 'package:bluecherry_client/providers/server_provider.dart';
import 'package:bluecherry_client/utils/constants.dart';
import 'package:bluecherry_client/utils/extensions.dart';
import 'package:bluecherry_client/utils/methods.dart';
import 'package:bluecherry_client/utils/theme.dart';
import 'package:bluecherry_client/widgets/error_warning.dart';
import 'package:bluecherry_client/widgets/misc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:provider/provider.dart';

class DirectCameraScreen extends StatefulWidget {
  const DirectCameraScreen({super.key});

  @override
  State<DirectCameraScreen> createState() => _DirectCameraScreenState();
}

class _DirectCameraScreenState extends State<DirectCameraScreen> {
  @override
  Widget build(BuildContext context) {
    final serversProviders = context.watch<ServersProvider>();

    return Column(children: [
      showIf(
            Scaffold.hasDrawer(context),
            child: AppBar(
              leading: MaybeUnityDrawerButton(context),
              title: Text(AppLocalizations.of(context).directCamera),
            ),
          ) ??
          const SizedBox.shrink(),
      Expanded(
        child: () {
          if (serversProviders.servers.isEmpty) {
            return const NoServerWarning();
          } else {
            return RefreshIndicator(
              onRefresh: serversProviders.refreshDevices,
              child: ListView.builder(
                padding: MediaQuery.viewPaddingOf(context),
                itemCount: serversProviders.servers.length,
                itemBuilder: (context, i) {
                  final server = serversProviders.servers[i];
                  return _DevicesForServer(server: server);
                },
              ),
            );
          }
        }(),
      ),
    ]);
  }
}

class _DevicesForServer extends StatelessWidget {
  final Server server;

  const _DevicesForServer({required this.server});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final servers = context.watch<ServersProvider>();
    final hasDrawer = Scaffold.hasDrawer(context);
    final isLoading = servers.isServerLoading(server);

    final serverIndicator = SubHeader(
      server.name,
      subtext: server.online
          ? AppLocalizations.of(context).nDevices(
              server.devices.length,
            )
          : AppLocalizations.of(context).offline,
      subtextStyle: TextStyle(
        color: !server.online ? theme.colorScheme.error : null,
      ),
      trailing: isLoading
          ? const SizedBox(
              height: 16.0,
              width: 16.0,
              child: CircularProgressIndicator.adaptive(strokeWidth: 1.5),
            )
          : null,
    );

    if (isLoading || !server.online) return serverIndicator;

    if (server.devices.isEmpty) {
      return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        serverIndicator,
        SizedBox(
          height: 72.0,
          child: Center(
            child: Text(
              AppLocalizations.of(context).noDevices,
              style: Theme.of(context)
                  .textTheme
                  .headlineSmall
                  ?.copyWith(fontSize: 16.0),
            ),
          ),
        ),
      ]);
    }

    final devices = server.devices.sorted();
    return Material(
      type: MaterialType.transparency,
      child: LayoutBuilder(builder: (context, consts) {
        if (hasDrawer || consts.maxWidth < kMobileBreakpoint.width) {
          return Column(children: [
            SubHeader(server.name),
            ...devices.map((device) {
              return ListTile(
                enabled: device.status,
                leading: CircleAvatar(
                  backgroundColor: Colors.transparent,
                  foregroundColor: device.status
                      ? theme.extension<UnityColors>()!.successColor
                      : theme.colorScheme.error,
                  child: const Icon(Icons.camera_alt),
                ),
                title: Text(
                  device.name.uppercaseFirst(),
                ),
                subtitle: Text([
                  device.uri,
                  '${device.resolutionX}x${device.resolutionY}',
                ].join(' • ')),
                onTap: () => onTap(context, device),
              );
            }),
          ]);
        }

        return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          serverIndicator,
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10.0),
            child: Wrap(
              children: devices.map<Widget>((device) {
                final foregroundColor = device.status
                    ? theme.extension<UnityColors>()!.successColor
                    : theme.colorScheme.error;

                return Card(
                  child: InkWell(
                    borderRadius: BorderRadius.circular(10.0),
                    onTap: device.status ? () => onTap(context, device) : null,
                    child: Padding(
                      padding: const EdgeInsetsDirectional.only(end: 8.0),
                      child: Column(children: [
                        Row(mainAxisSize: MainAxisSize.min, children: [
                          CircleAvatar(
                            backgroundColor: Colors.transparent,
                            foregroundColor: foregroundColor,
                            child: const Icon(Icons.camera_alt),
                          ),
                          Text(
                            device.name,
                            style: TextStyle(color: foregroundColor),
                          ),
                        ]),
                      ]),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ]);
      }),
    );
  }

  Future<void> onTap(BuildContext context, Device device) async {
    final player = getVideoPlayerControllerForDevice(
      device,
    );

    await Navigator.of(context).pushNamed(
      '/fullscreen',
      arguments: {
        'device': device,
        'player': player,
      },
    );
    await player.release();
  }
}
