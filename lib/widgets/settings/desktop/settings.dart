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

import 'package:bluecherry_client/utils/constants.dart';
import 'package:bluecherry_client/widgets/settings/shared/date_language.dart';
import 'package:bluecherry_client/widgets/settings/desktop/general.dart';
import 'package:bluecherry_client/widgets/settings/desktop/server.dart';
import 'package:bluecherry_client/widgets/settings/desktop/updates.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class DesktopSettings extends StatefulWidget {
  const DesktopSettings({super.key});

  static const horizontalPadding = EdgeInsets.symmetric(horizontal: 24.0);
  static const verticalPadding = EdgeInsets.symmetric(vertical: 16.0);

  @override
  State<DesktopSettings> createState() => _DesktopSettingsState();
}

class _DesktopSettingsState extends State<DesktopSettings> {
  int currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final theme = Theme.of(context);

    return LayoutBuilder(builder: (context, constraints) {
      return Row(children: [
        NavigationRail(
          extended: constraints.maxWidth >
              kMobileBreakpoint.width + kMobileBreakpoint.width / 4,
          destinations: [
            NavigationRailDestination(
              icon: const Icon(Icons.dashboard),
              label: Text(loc.general),
            ),
            NavigationRailDestination(
              icon: const Icon(Icons.dns),
              label: Text(loc.servers),
            ),
            NavigationRailDestination(
              icon: const Icon(Icons.update),
              label: Text(loc.updates),
            ),
            NavigationRailDestination(
              icon: const Icon(Icons.language),
              label: Text(loc.dateLanguage),
            ),
          ],
          selectedIndex: currentIndex,
          onDestinationSelected: (index) =>
              setState(() => currentIndex = index),
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
                      theme.colorScheme.background,
                      theme.colorScheme.surfaceTint,
                      4,
                    ),
                  ),
                ),
                child: AnimatedSwitcher(
                  duration: kThemeChangeDuration,
                  child: switch (currentIndex) {
                    0 => const GeneralSettings(),
                    1 => const ServerSettings(),
                    2 => const UpdatesSettings(),
                    3 => const LocalizationSettings(),
                    _ => const GeneralSettings(),
                  },
                ),
              ),
            ),
          ),
        ),
      ]);
    });
  }
}
