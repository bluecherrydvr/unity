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

import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';

import 'package:bluecherry_client/widgets/device_tile.dart';
import 'package:bluecherry_client/providers/mobile_view_provider.dart';
import 'package:bluecherry_client/providers/server_provider.dart';
import 'package:bluecherry_client/api/api.dart';

class DirectCameraScreen extends StatefulWidget {
  const DirectCameraScreen({Key? key}) : super(key: key);

  @override
  State<DirectCameraScreen> createState() => _DirectCameraScreenState();
}

class _DirectCameraScreenState extends State<DirectCameraScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.menu),
          splashRadius: 20.0,
          onPressed: Scaffold.of(context).openDrawer,
        ),
        title: Text('direct_camera'.tr()),
      ),
      body: ServersProvider.instance.servers.isEmpty
          ? Center(
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
                    'no_servers_added'.tr(),
                    style: Theme.of(context)
                        .textTheme
                        .headline5
                        ?.copyWith(fontSize: 16.0),
                  ),
                ],
              ),
            )
          : ListView.builder(
              itemCount: ServersProvider.instance.servers.length,
              itemBuilder: (context, i) {
                final server = ServersProvider.instance.servers[i];
                return FutureBuilder(
                  future: (() async => server.devices.isEmpty
                      ? API.instance.getDevices(
                          await API.instance.checkServerCredentials(server))
                      : true)(),
                  builder: (context, snapshot) {
                    return snapshot.hasData
                        ? ListView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: server.devices.length + 1,
                            itemBuilder: (context, index) => index == 0
                                ? Padding(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 24.0,
                                      vertical: 16.0,
                                    ),
                                    child: Text(
                                      server.name.toUpperCase(),
                                      style: Theme.of(context)
                                          .textTheme
                                          .overline
                                          ?.copyWith(
                                            fontWeight: FontWeight.w500,
                                          ),
                                    ),
                                  )
                                : () {
                                    index--;
                                    return ListTile(
                                      enabled: server.devices[index].status,
                                      leading: CircleAvatar(
                                        child: const Icon(Icons.camera_alt),
                                        backgroundColor: Colors.transparent,
                                        foregroundColor:
                                            Theme.of(context).iconTheme.color,
                                      ),
                                      title: Text(
                                        server.devices[index].name
                                            .split(' ')
                                            .map((e) =>
                                                e[0].toUpperCase() +
                                                e.substring(1))
                                            .join(' '),
                                      ),
                                      subtitle: Text([
                                        server.devices[index].status
                                            ? 'online'.tr()
                                            : 'offline'.tr(),
                                        server.devices[index].uri,
                                        '${server.devices[index].resolutionX}x${server.devices[index].resolutionY}',
                                      ].join(' • ')),
                                      onTap: () async {
                                        final player = MobileViewProvider
                                            .instance
                                            .getVideoPlayerController(
                                                server.devices[index]);
                                        await Navigator.of(context).push(
                                          MaterialPageRoute(
                                            builder: (context) =>
                                                DeviceFullscreenViewer(
                                              device: server.devices[index],
                                              ijkPlayer: player,
                                              restoreStatusBarStyleOnDispose:
                                                  true,
                                            ),
                                          ),
                                        );
                                        await player.release();
                                        await player.release();
                                      },
                                    );
                                  }(),
                          )
                        : Center(
                            child: Container(
                              alignment: Alignment.center,
                              height: 156.0,
                              child: const CircularProgressIndicator(),
                            ),
                          );
                  },
                );
              },
            ),
    );
  }
}
