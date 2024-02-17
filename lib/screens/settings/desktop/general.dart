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

import 'package:bluecherry_client/widgets/misc.dart';
import 'package:bluecherry_client/screens/settings/desktop/settings.dart';
import 'package:bluecherry_client/screens/settings/shared/tiles.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class GeneralSettings extends StatelessWidget {
  const GeneralSettings({super.key});

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    return ListView(padding: DesktopSettings.verticalPadding, children: [
      SubHeader(
        loc.theme,
        subtext: loc.themeDescription,
        padding: DesktopSettings.horizontalPadding,
      ),
      ...ThemeMode.values.map((mode) => ThemeTile(themeMode: mode)),
      SubHeader(loc.miscellaneous, padding: DesktopSettings.horizontalPadding),
      const SnoozeNotificationsTile(),
      const NavigationClickBehaviorTile(),
      const DirectoryChooseTile(),
      const CyclePeriodTile(),
      const CameraReloadPeriodTile(),
      const WakelockTile(),
    ]);
  }
}
