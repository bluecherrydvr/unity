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

import 'package:bluecherry_client/models/server.dart';
import 'package:bluecherry_client/providers/home_provider.dart';
import 'package:bluecherry_client/providers/server_provider.dart';
import 'package:bluecherry_client/providers/settings_provider.dart';
import 'package:bluecherry_client/screens/layouts/device_grid.dart';
import 'package:bluecherry_client/screens/servers/edit_server.dart';
import 'package:bluecherry_client/screens/servers/edit_server_settings.dart';
import 'package:bluecherry_client/screens/settings/desktop/advanced_options.dart';
import 'package:bluecherry_client/screens/settings/desktop/application.dart';
import 'package:bluecherry_client/screens/settings/desktop/events_and_downloads.dart';
import 'package:bluecherry_client/screens/settings/desktop/general.dart';
import 'package:bluecherry_client/screens/settings/desktop/server_and_devices.dart';
import 'package:bluecherry_client/screens/settings/desktop/updates_and_help.dart';
import 'package:bluecherry_client/utils/constants.dart';
import 'package:bluecherry_client/widgets/drawer_button.dart';
import 'package:bluecherry_client/widgets/misc.dart';
import 'package:bluecherry_client/widgets/squared_icon_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

part '../shared/server_tile.dart';

class MobileSettings extends StatefulWidget {
  const MobileSettings({super.key});

  @override
  State<MobileSettings> createState() => _MobileSettingsState();
}

class _MobileSettingsState extends State<MobileSettings> {
  @override
  void initState() {
    super.initState();
    SettingsProvider.instance.reloadInterface();
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final theme = Theme.of(context);

    return Material(
      type: MaterialType.transparency,
      child: SafeArea(
        child: Column(children: [
          if (Scaffold.of(context).hasDrawer)
            AppBar(
              leading: MaybeUnityDrawerButton(context),
              title: Text(loc.settings),
            ),
          Expanded(
            child: ListTileTheme(
              data: ListTileThemeData(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8.0),
                ),
                tileColor: theme.colorScheme.primaryContainer.withOpacity(0.42),
              ),
              child: ListView(
                padding: const EdgeInsetsDirectional.all(8.0),
                children: [
                  ListTile(
                    leading: const Icon(Icons.dashboard),
                    title: Text(loc.general),
                    subtitle:
                        const Text('Notifications, Data Usage, Wakelock, etc'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () {
                      showModalBottomSheet(
                        context: context,
                        showDragHandle: true,
                        scrollControlDisabledMaxHeightRatio: 0.9,
                        builder: (context) {
                          return const GeneralSettings();
                        },
                      );
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.dns),
                    title: const Text('Servers and Devices'),
                    subtitle: const Text('Servers, Devices, Streaming, etc'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () {
                      showModalBottomSheet(
                        context: context,
                        showDragHandle: true,
                        scrollControlDisabledMaxHeightRatio: 0.9,
                        builder: (context) {
                          return const ServerSettings();
                        },
                      );
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.event),
                    title: const Text('Events and Downloads'),
                    subtitle: const Text('Downloads, Events, Timeline, etc'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () {
                      showModalBottomSheet(
                        context: context,
                        showDragHandle: true,
                        scrollControlDisabledMaxHeightRatio: 0.9,
                        builder: (context) {
                          return const EventsAndDownloadsSettings();
                        },
                      );
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.style),
                    title: const Text('Application'),
                    subtitle: const Text(
                        'Theme, Language, Date and Time, Window, etc'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () {
                      showModalBottomSheet(
                        context: context,
                        showDragHandle: true,
                        scrollControlDisabledMaxHeightRatio: 0.9,
                        builder: (context) {
                          return const ApplicationSettings();
                        },
                      );
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.security),
                    title: const Text('Privacy and Security'),
                    subtitle: const Text('Diagnostics, Privacy, Security, etc'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () {},
                  ),
                  ListTile(
                    leading: const Icon(Icons.update),
                    title: const Text('Updates and Help'),
                    subtitle: const Text('Check for updates, Help, About, etc'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () {
                      showModalBottomSheet(
                        context: context,
                        showDragHandle: true,
                        scrollControlDisabledMaxHeightRatio: 0.9,
                        builder: (context) {
                          return const UpdatesSettings();
                        },
                      );
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.code),
                    title: const Text('Advanced Options'),
                    subtitle:
                        const Text('Beta Features, Developer Options, etc'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () {
                      showModalBottomSheet(
                        context: context,
                        showDragHandle: true,
                        scrollControlDisabledMaxHeightRatio: 0.9,
                        builder: (context) {
                          return const AdvancedOptionsSettings();
                        },
                      );
                    },
                  ),
                ]
                    .map((e) => Padding(
                          padding:
                              const EdgeInsetsDirectional.only(bottom: 8.0),
                          child: e,
                        ))
                    .toList(),
              ),
            ),
          ),
        ]),
      ),
    );
  }
}
