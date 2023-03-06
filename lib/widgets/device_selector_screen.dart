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

import 'package:bluecherry_client/providers/server_provider.dart';
import 'package:bluecherry_client/widgets/error_warning.dart';
import 'package:bluecherry_client/widgets/misc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:provider/provider.dart';

class DeviceSelectorScreen extends StatefulWidget {
  const DeviceSelectorScreen({Key? key}) : super(key: key);

  @override
  State<DeviceSelectorScreen> createState() => _DeviceSelectorScreenState();
}

class _DeviceSelectorScreenState extends State<DeviceSelectorScreen> {
  @override
  Widget build(BuildContext context) {
    final servers = context.watch<ServersProvider>();

    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context).selectACamera),
      ),
      body: SafeArea(
        bottom: false,
        child: () {
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
                    child: const CircularProgressIndicator(),
                  ),
                );
              }

              return ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: server.devices.length + 1,
                itemBuilder: (context, index) {
                  if (index == 0) return SubHeader(server.name);
                  index--;
                  return ListTile(
                    enabled: server.devices[index].status,
                    leading: CircleAvatar(
                      backgroundColor: Colors.transparent,
                      foregroundColor: Theme.of(context).iconTheme.color,
                      child: const Icon(Icons.camera_alt),
                    ),
                    title: Text(
                      server.devices[index].name
                          .split(' ')
                          .map((e) => e[0].toUpperCase() + e.substring(1))
                          .join(' '),
                    ),
                    subtitle: Text([
                      server.devices[index].status
                          ? AppLocalizations.of(context).online
                          : AppLocalizations.of(context).offline,
                      server.devices[index].uri,
                      '${server.devices[index].resolutionX}x${server.devices[index].resolutionY}',
                    ].join(' • ')),
                    onTap: () {
                      Navigator.of(context).pop(server.devices[index]);
                    },
                  );
                },
              );
            },
          );
        }(),
      ),
    );
  }
}
