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

import 'package:bluecherry_client/screens/settings/desktop/settings.dart';
import 'package:bluecherry_client/screens/settings/shared/date_language.dart';
import 'package:bluecherry_client/screens/settings/shared/options_chooser_tile.dart';
import 'package:bluecherry_client/screens/settings/shared/tiles.dart';
import 'package:bluecherry_client/widgets/misc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class ApplicationSettings extends StatelessWidget {
  const ApplicationSettings({super.key});

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final theme = Theme.of(context);
    return ListView(padding: DesktopSettings.verticalPadding, children: [
      SubHeader(
        loc.theme,
        subtext: loc.themeDescription,
        padding: DesktopSettings.horizontalPadding,
      ),
      ...ThemeMode.values.map((mode) => ThemeTile(themeMode: mode)),
      const LanguageSection(),
      Padding(
        padding: DesktopSettings.horizontalPadding,
        child: Text(loc.dateFormat, style: theme.textTheme.titleMedium),
      ),
      const DateFormatSection(),
      Padding(
        padding: DesktopSettings.horizontalPadding,
        child: Text(loc.timeFormat, style: theme.textTheme.titleMedium),
      ),
      const TimeFormatSection(),
      Padding(
        padding: DesktopSettings.horizontalPadding,
        child: Text('Window', style: theme.textTheme.titleMedium),
      ),
      CheckboxListTile.adaptive(
        value: false,
        onChanged: (v) {},
        contentPadding: DesktopSettings.horizontalPadding,
        secondary: CircleAvatar(
          backgroundColor: Colors.transparent,
          foregroundColor: theme.iconTheme.color,
          child: const Icon(Icons.launch),
        ),
        title: const Text('Launch app on startup'),
        subtitle: const Text(
          'Whether to launchthe app when the system starts',
        ),
      ),
      CheckboxListTile.adaptive(
        value: false,
        onChanged: (v) {},
        contentPadding: DesktopSettings.horizontalPadding,
        secondary: CircleAvatar(
          backgroundColor: Colors.transparent,
          foregroundColor: theme.iconTheme.color,
          child: const Icon(Icons.sensor_door),
        ),
        title: const Text('Close app to tray'),
        subtitle: const Text(
          'Whether to close the app to the system tray when the window is closed. '
          'This will keep the app running in the background.',
        ),
      ),
    ]);
  }
}
