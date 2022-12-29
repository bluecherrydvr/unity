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
import 'package:bluecherry_client/utils/extensions.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

import 'package:bluecherry_client/api/api.dart';
import 'package:bluecherry_client/providers/mobile_view_provider.dart';
import 'package:bluecherry_client/providers/server_provider.dart';
import 'package:bluecherry_client/widgets/misc.dart';

class DirectCameraScreen extends StatefulWidget {
  const DirectCameraScreen({Key? key}) : super(key: key);

  @override
  State<DirectCameraScreen> createState() => _DirectCameraScreenState();
}

class _DirectCameraScreenState extends State<DirectCameraScreen> {
  @override
  Widget build(BuildContext context) {
    // subscribe to updates to media query
    MediaQuery.of(context);

    return Scaffold(
      appBar: isDesktop
          ? null
          : AppBar(
              leading: Scaffold.of(context).hasDrawer
                  ? IconButton(
                      icon: const Icon(Icons.menu),
                      splashRadius: 20.0,
                      onPressed: Scaffold.of(context).openDrawer,
                    )
                  : null,
              title: Text(AppLocalizations.of(context).directCamera),
            ),
      body: () {
        if (ServersProvider.instance.servers.isEmpty) {
          return Center(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.dns,
                  size: 72.0,
                  color: Theme.of(context).iconTheme.color?.withOpacity(0.8),
                ),
                const SizedBox(height: 8.0),
                Text(
                  AppLocalizations.of(context).noServersAdded,
                  style: Theme.of(context)
                      .textTheme
                      .headline5
                      ?.copyWith(fontSize: 16.0),
                ),
              ],
            ),
          );
        } else {
          return RefreshIndicator(
            onRefresh: () async {
              for (final server in ServersProvider.instance.servers) {
                try {
                  await API.instance.getDevices(
                      await API.instance.checkServerCredentials(server));
                } catch (exception, stacktrace) {
                  debugPrint(exception.toString());
                  debugPrint(stacktrace.toString());
                }
              }
              setState(() {});
            },
            child: ListView.builder(
              padding: MediaQuery.of(context).viewPadding,
              itemCount: ServersProvider.instance.servers.length,
              itemBuilder: (context, i) {
                final server = ServersProvider.instance.servers[i];
                return CustomFutureBuilder<bool>(
                  future: () async {
                    if (server.devices.isEmpty) {
                      return API.instance.getDevices(
                        await API.instance.checkServerCredentials(server),
                      );
                    }
                    return Future.value(true);
                  }(),
                  loadingBuilder: (context) => const SizedBox(
                    height: 96.0,
                    child: Center(child: CircularProgressIndicator()),
                  ),
                  builder: (context, data) {
                    return _DevicesForServer(server: server);
                  },
                );
              },
            ),
          );
        }
      }(),
    );
  }
}

class _DevicesForServer extends StatelessWidget {
  final Server server;

  const _DevicesForServer({Key? key, required this.server}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (server.devices.isEmpty) {
      return SizedBox(
        height: 72.0,
        child: Center(
          child: Text(
            AppLocalizations.of(context).noDevices,
            style:
                Theme.of(context).textTheme.headline5?.copyWith(fontSize: 16.0),
          ),
        ),
      );
    }
    return LayoutBuilder(builder: (context, consts) {
      if (consts.maxWidth >= 800) {
        return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          SubHeader(server.name),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10.0),
            child: Wrap(
              children: server.devices.map<Widget>((device) {
                final foregroundColor = device.status
                    ? Colors.green.shade100
                    : Colors.red.withOpacity(0.75);

                return Card(
                  child: InkWell(
                    borderRadius: BorderRadius.circular(10.0),
                    onTap: device.status ? () => onTap(context, device) : null,
                    child: Padding(
                      padding: const EdgeInsetsDirectional.only(
                        end: 8.0,
                        // top: 8.0,
                        // bottom: 8.0,
                      ),
                      child: Column(children: [
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            CircleAvatar(
                              child: const Icon(Icons.camera_alt),
                              backgroundColor: Colors.transparent,
                              foregroundColor: foregroundColor,
                            ),
                            Text(
                              device.name,
                              style: TextStyle(
                                color: foregroundColor,
                              ),
                            ),
                          ],
                        ),
                      ]),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ]);
      }
      return Column(children: [
        SubHeader(server.name),
        ...server.devices.map((device) {
          return ListTile(
            enabled: device.status,
            leading: CircleAvatar(
              child: const Icon(Icons.camera_alt),
              backgroundColor: Colors.transparent,
              foregroundColor: Theme.of(context).iconTheme.color,
            ),
            title: Text(
              device.name.uppercaseFirst(),
            ),
            subtitle: Text([
              device.status
                  ? AppLocalizations.of(context).online
                  : AppLocalizations.of(context).offline,
              device.uri,
              '${device.resolutionX}x${device.resolutionY}',
            ].join(' • ')),
            onTap: () => onTap(context, device),
          );
        }),
      ]);
    });
  }

  void onTap(BuildContext context, Device device) async {
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
