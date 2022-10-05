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
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

import 'package:bluecherry_client/api/api.dart';
import 'package:bluecherry_client/providers/server_provider.dart';
import 'package:bluecherry_client/widgets/misc.dart';

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
    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context).selectACamera),
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
                    AppLocalizations.of(context).noServersAdded,
                    style: Theme.of(context)
                        .textTheme
                        .headline5
                        ?.copyWith(fontSize: 16.0),
                  ),
                ],
              ),
            )
          : SafeArea(
              bottom: false,
              child: ListView.builder(
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
                                  ? SubHeader(server.name)
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
                                              ? AppLocalizations.of(context)
                                                  .online
                                              : AppLocalizations.of(context)
                                                  .offline,
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
            ),
    );
  }
}
