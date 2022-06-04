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
  Widget build(BuildContext context) {
    /// TODO: Currently only single server is implemented.
    final server = ServersProvider.instance.servers.first;
    return Scaffold(
      appBar: AppBar(
        title: Text('select_a_camera'.tr()),
      ),
      body: FutureBuilder(
        future: (() async => server.devices.isEmpty
            ? API.instance.getDevices(
                await API.instance.checkServerCredentials(server),
              )
            : true)(),
        builder: (context, snapshot) {
          return snapshot.hasData
              ? ListView.builder(
                  itemCount: server.devices.length,
                  itemBuilder: (context, index) => ListTile(
                    enabled: server.devices[index].status,
                    leading: CircleAvatar(
                      child: const Icon(Icons.camera_alt),
                      backgroundColor: Colors.transparent,
                      foregroundColor: Theme.of(context).iconTheme.color,
                    ),
                    isThreeLine: true,
                    title: Text(server.devices[index].name),
                    subtitle: Text([
                      server.devices[index].status
                          ? 'online'.tr()
                          : 'offline'.tr(),
                      server.devices[index].uri,
                      '${server.devices[index].resolutionX}x${server.devices[index].resolutionY}\n${server.name}',
                    ].join(' • ')),
                    onTap: () {
                      Navigator.of(context).pop(server.devices[index]);
                    },
                  ),
                )
              : const Center(
                  child: CircularProgressIndicator(),
                );
        },
      ),
    );
  }
}
