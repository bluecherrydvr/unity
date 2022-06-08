/*
 * This file is a part of Bluecherry Client (https://https://github.com/bluecherrydvr/bluecherry_client).
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
import 'package:status_bar_control/status_bar_control.dart';

import 'package:bluecherry_client/api/api.dart';
import 'package:bluecherry_client/providers/server_provider.dart';

class DeviceSelectorScreen extends StatefulWidget {
  const DeviceSelectorScreen({
    Key? key,
  }) : super(key: key);

  @override
  State<DeviceSelectorScreen> createState() => _DeviceSelectorScreenState();
}

class _DeviceSelectorScreenState extends State<DeviceSelectorScreen> {
  @override
  void initState() {
    super.initState();
    StatusBarControl.setHidden(false);
  }

  @override
  void dispose() {
    StatusBarControl.setHidden(true);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('select_a_camera'.tr()),
      ),
      body: ListView.builder(
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
                                          e[0].toUpperCase() + e.substring(1))
                                      .join(' '),
                                ),
                                subtitle: Text([
                                  server.devices[index].status
                                      ? 'online'.tr()
                                      : 'offline'.tr(),
                                  server.devices[index].uri,
                                  '${server.devices[index].resolutionX}x${server.devices[index].resolutionY}',
                                ].join(' • ')),
                                onTap: () {
                                  Navigator.of(context)
                                      .pop(server.devices[index]);
                                },
                              );
                            }(),
                    )
                  : const Center(
                      child: SizedBox(
                        height: 72.0,
                        child: CircularProgressIndicator(),
                      ),
                    );
            },
          );
        },
      ),
    );
  }
}
