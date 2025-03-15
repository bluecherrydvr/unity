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

import 'package:bluecherry_client/l10n/generated/app_localizations.dart';
import 'package:bluecherry_client/providers/settings_provider.dart';
import 'package:bluecherry_client/screens/settings/advanced_options.dart';
import 'package:bluecherry_client/screens/settings/application.dart';
import 'package:bluecherry_client/screens/settings/events_and_downloads.dart';
import 'package:bluecherry_client/screens/settings/general.dart';
import 'package:bluecherry_client/screens/settings/server_and_devices.dart';
import 'package:bluecherry_client/screens/settings/updates_and_help.dart';
import 'package:bluecherry_client/utils/constants.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class DesktopSettings extends StatelessWidget {
  const DesktopSettings({super.key});

  static const horizontalPadding = EdgeInsetsDirectional.symmetric(
    horizontal: 24.0,
  );
  static const verticalPadding = EdgeInsetsDirectional.symmetric(
    vertical: 16.0,
  );

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final settings = context.watch<SettingsProvider>();

    return LayoutBuilder(
      builder: (context, constraints) {
        return Row(
          children: [
            NavigationRail(
              extended:
                  constraints.maxWidth >
                  kMobileBreakpoint.width + kMobileBreakpoint.width / 4,
              destinations: [
                NavigationRailDestination(
                  icon: const Icon(Icons.dashboard),
                  label: Text(loc.general),
                ),
                NavigationRailDestination(
                  icon: const Icon(Icons.dns),
                  label: Text(loc.serverAndDevices),
                ),
                NavigationRailDestination(
                  icon: const Icon(Icons.event),
                  label: Text(loc.eventsAndDownloads),
                ),
                NavigationRailDestination(
                  icon: const Icon(Icons.style),
                  label: Text(loc.application),
                ),
                NavigationRailDestination(
                  icon: const Icon(Icons.update),
                  label: Text(loc.updatesHelpAndPrivacy),
                ),
                NavigationRailDestination(
                  icon: const Icon(Icons.code),
                  label: Text(loc.advancedOptions),
                ),
              ],
              selectedIndex: settings.settingsIndex,
              onDestinationSelected: (index) => settings.settingsIndex = index,
            ),
            Expanded(
              child: Card(
                margin: EdgeInsetsDirectional.zero,
                shape: const RoundedRectangleBorder(
                  borderRadius: BorderRadiusDirectional.only(
                    topStart: Radius.circular(12.0),
                  ),
                ),
                child: DropdownButtonHideUnderline(
                  child: Theme(
                    data: theme.copyWith(
                      cardTheme: CardTheme(
                        color: ElevationOverlay.applySurfaceTint(
                          theme.colorScheme.surface,
                          theme.colorScheme.surfaceTint,
                          4,
                        ),
                      ),
                    ),
                    child: AnimatedSwitcher(
                      duration: kThemeChangeDuration,
                      child: switch (settings.settingsIndex) {
                        0 => const GeneralSettings(),
                        1 => const ServerAndDevicesSettings(),
                        2 => const EventsAndDownloadsSettings(),
                        3 => const ApplicationSettings(),
                        4 => const UpdatesSettings(),
                        5 => const AdvancedOptionsSettings(),
                        _ => const GeneralSettings(),
                      },
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
