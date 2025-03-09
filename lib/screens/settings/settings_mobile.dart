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

import 'package:bluecherry_client/api/api.dart';
import 'package:bluecherry_client/models/server.dart';
import 'package:bluecherry_client/providers/home_provider.dart';
import 'package:bluecherry_client/providers/server_provider.dart';
import 'package:bluecherry_client/providers/settings_provider.dart';
import 'package:bluecherry_client/screens/layouts/device_grid.dart';
import 'package:bluecherry_client/screens/servers/edit_server.dart';
import 'package:bluecherry_client/screens/servers/edit_server_settings.dart';
import 'package:bluecherry_client/screens/settings/advanced_options.dart';
import 'package:bluecherry_client/screens/settings/application.dart';
import 'package:bluecherry_client/screens/settings/events_and_downloads.dart';
import 'package:bluecherry_client/screens/settings/general.dart';
import 'package:bluecherry_client/screens/settings/server_and_devices.dart';
import 'package:bluecherry_client/screens/settings/updates_and_help.dart';
import 'package:bluecherry_client/utils/constants.dart';
import 'package:bluecherry_client/utils/methods.dart';
import 'package:bluecherry_client/widgets/drawer_button.dart';
import 'package:bluecherry_client/widgets/misc.dart';
import 'package:bluecherry_client/widgets/squared_icon_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:provider/provider.dart';
import 'package:reorderables/reorderables.dart';
import 'package:url_launcher/url_launcher.dart';

part 'shared/server_tile.dart';

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
        child: Column(
          children: [
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
                  tileColor: theme.colorScheme.primaryContainer.withValues(
                    alpha: 0.42,
                  ),
                ),
                child: ListView(
                  padding: const EdgeInsetsDirectional.all(8.0),
                  children:
                      [
                        ListTile(
                          leading: const Icon(Icons.dashboard),
                          title: Text(loc.general),
                          subtitle: Text(loc.generalSettingsSuggestion),
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
                          title: Text(loc.serverAndDevices),
                          subtitle: Text(
                            loc.serverAndDevicesSettingsSuggestion,
                          ),
                          trailing: const Icon(Icons.chevron_right),
                          onTap: () {
                            showModalBottomSheet(
                              context: context,
                              showDragHandle: true,
                              scrollControlDisabledMaxHeightRatio: 0.9,
                              builder: (context) {
                                return const ServerAndDevicesSettings();
                              },
                            );
                          },
                        ),
                        ListTile(
                          leading: const Icon(Icons.event),
                          title: Text(loc.eventsAndDownloads),
                          subtitle: Text(
                            loc.eventsAndDownloadsSettingsSuggestion,
                          ),
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
                          title: Text(loc.application),
                          subtitle: Text(loc.applicationSettingsSuggestion),
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
                          leading: const Icon(Icons.update),
                          title: Text(loc.updatesHelpAndPrivacy),
                          subtitle: Text(
                            loc.updatesHelpAndPrivacySettingsSuggestion,
                          ),
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
                          title: Text(loc.advancedOptions),
                          subtitle: Text(loc.advancedOptionsSettingsSuggestion),
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
                      ].map((child) {
                        return Padding(
                          padding: const EdgeInsetsDirectional.only(
                            bottom: 8.0,
                          ),
                          child: child,
                        );
                      }).toList(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
