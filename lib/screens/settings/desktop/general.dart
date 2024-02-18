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
import 'package:bluecherry_client/screens/settings/shared/options_chooser_tile.dart';
import 'package:bluecherry_client/screens/settings/shared/tiles.dart';
import 'package:bluecherry_client/widgets/misc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class GeneralSettings extends StatelessWidget {
  const GeneralSettings({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final loc = AppLocalizations.of(context);
    return ListView(padding: DesktopSettings.verticalPadding, children: [
      const CyclePeriodTile(),
      const WakelockTile(),
      const SubHeader(
        'Notifications',
        padding: DesktopSettings.horizontalPadding,
      ),
      CheckboxListTile.adaptive(
        secondary: CircleAvatar(
          backgroundColor: Colors.transparent,
          foregroundColor: theme.iconTheme.color,
          child: const Icon(Icons.crop),
        ),
        contentPadding: DesktopSettings.horizontalPadding,
        title: const Text('Notifications enabled'),
        value: true,
        onChanged: (value) {},
      ),
      const SnoozeNotificationsTile(),
      const NotificationClickBehaviorTile(),
      const SubHeader(
        'Data Usage',
        padding: DesktopSettings.horizontalPadding,
      ),
      OptionsChooserTile(
        icon: Icons.data_usage,
        title: 'Automatic streaming',
        description: 'When to stream videos automatically on startup',
        value: '',
        values: [
          Option(value: '', icon: Icons.insights, text: 'Auto'),
          Option(value: '', icon: Icons.wifi, text: 'Wifi only'),
          Option(value: '', icon: Icons.not_interested, text: 'Never'),
        ],
        onChanged: (value) {},
      ),
      OptionsChooserTile(
        icon: Icons.cloud_done,
        title: 'Keep streams playing on background',
        description:
            'When to keep streams playing when the app is in background',
        value: '',
        values: [
          Option(value: '', icon: Icons.insights, text: 'Auto'),
          Option(value: '', icon: Icons.wifi, text: 'Wifi only'),
          Option(value: '', icon: Icons.not_interested, text: 'Never'),
        ],
        onChanged: (value) {},
      ),
      ListTile(
        leading: CircleAvatar(
          backgroundColor: Colors.transparent,
          foregroundColor: theme.iconTheme.color,
          child: const Icon(Icons.show_chart),
        ),
        contentPadding: DesktopSettings.horizontalPadding,
        title: const Text('View previous data usage'),
        trailing: const Icon(Icons.navigate_next),
      ),
    ]);
  }
}
