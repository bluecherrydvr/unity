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
import 'package:bluecherry_client/utils/theme.dart';
import 'package:bluecherry_client/utils/video_player.dart';
import 'package:bluecherry_client/widgets/error_warning.dart';
import 'package:bluecherry_client/widgets/misc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:provider/provider.dart';
import 'package:sliver_tools/sliver_tools.dart';

class DirectCameraScreen extends StatelessWidget {
  const DirectCameraScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final serversProviders = context.watch<ServersProvider>();
    final loc = AppLocalizations.of(context);
    final hasDrawer = Scaffold.hasDrawer(context);

    return SafeArea(
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        if (hasDrawer)
          AppBar(
            leading: MaybeUnityDrawerButton(context),
            title: Text(loc.directCamera),
          ),
        Expanded(child: () {
          if (serversProviders.servers.isEmpty) {
            return const NoServerWarning();
          } else {
            return LayoutBuilder(builder: (context, consts) {
              return RefreshIndicator.adaptive(
                onRefresh: serversProviders.refreshDevices,
                child: CustomScrollView(slivers: <Widget>[
                  ...serversProviders.servers.map((server) {
                    return _DevicesForServer(
                      server: server,
                      isCompact: hasDrawer ||
                          consts.maxWidth < kMobileBreakpoint.width,
                    );
                  }),
                ]),
              );
            });
          }
        }()),
      ]),
    );
  }
}

class _DevicesForServer extends StatelessWidget {
  final Server server;
  final bool isCompact;

  const _DevicesForServer({required this.server, required this.isCompact});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final loc = AppLocalizations.of(context);
    final servers = context.watch<ServersProvider>();

    final isLoading = servers.isServerLoading(server);

    final serverIndicator = Material(
      child: SubHeader(
        server.name,
        subtext:
            server.online ? loc.nDevices(server.devices.length) : loc.offline,
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
      ),
    );

    if (isLoading || !server.online) {
      return SliverToBoxAdapter(child: serverIndicator);
    }

    if (server.devices.isEmpty) {
      return SliverList.list(children: [
        serverIndicator,
        SizedBox(
          height: 72.0,
          child: Center(
            child: Text(
              loc.noDevices,
              style: theme.textTheme.headlineSmall?.copyWith(fontSize: 16.0),
            ),
          ),
        ),
      ]);
    }

    final devices = server.devices.sorted();

    if (isCompact) {
      return MultiSliver(pushPinnedChildren: true, children: [
        SliverPinnedHeader(child: serverIndicator),
        SliverList.builder(
          itemCount: devices.length,
          itemBuilder: (context, index) {
            final device = devices[index];
            return ListTile(
              enabled: device.status,
              leading: CircleAvatar(
                backgroundColor: Colors.transparent,
                foregroundColor: device.status
                    ? theme.extension<UnityColors>()!.successColor
                    : theme.colorScheme.error,
                child: Icon(
                  device.status
                      ? Icons.videocam_outlined
                      : Icons.videocam_off_outlined,
                ),
              ),
              title: Text(device.name.uppercaseFirst()),
              subtitle: Text([
                device.uri,
                '${device.resolutionX}x${device.resolutionY}',
              ].join(' • ')),
              trailing:
                  device.hasPTZ ? const Icon(Icons.videogame_asset) : null,
              onTap: () => onTap(context, device),
            );
          },
        ),
      ]);
    }

    return MultiSliver(children: [
      SliverPinnedHeader(child: serverIndicator),
      SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsetsDirectional.symmetric(horizontal: 10.0),
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
                          child: Icon(
                            device.status
                                ? Icons.videocam_outlined
                                : Icons.videocam_off,
                          ),
                        ),
                        Text(
                          device.name,
                          style: TextStyle(color: foregroundColor),
                        ),
                        if (device.hasPTZ)
                          Padding(
                            padding: const EdgeInsetsDirectional.only(start: 6),
                            child: Icon(
                              Icons.videogame_asset,
                              color: foregroundColor,
                            ),
                          )
                      ]),
                    ]),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ),
    ]);
  }

  Future<void> onTap(BuildContext context, Device device) async {
    final player =
        UnityPlayers.players[device.uuid] ?? UnityPlayers.forDevice(device);

    await Navigator.of(context).pushNamed(
      '/fullscreen',
      arguments: {'device': device, 'player': player},
    );

    if (!UnityPlayers.players.containsKey(device.uuid)) await player.dispose();
  }
}
