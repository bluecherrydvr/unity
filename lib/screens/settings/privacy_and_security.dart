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

import 'package:bluecherry_client/providers/settings_provider.dart';
import 'package:bluecherry_client/screens/settings/settings_desktop.dart';
import 'package:bluecherry_client/screens/settings/shared/options_chooser_tile.dart';
import 'package:bluecherry_client/utils/extensions.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class PrivacySecuritySettings extends StatelessWidget {
  const PrivacySecuritySettings({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final settings = context.watch<SettingsProvider>();
    return ListView(children: [
      CheckboxListTile.adaptive(
        secondary: CircleAvatar(
          backgroundColor: Colors.transparent,
          foregroundColor: theme.iconTheme.color,
          child: const Icon(Icons.analytics),
        ),
        contentPadding: DesktopSettings.horizontalPadding,
        title: const Text('Allow Bluecherry to collect usage data'),
        subtitle: const Text(
          'Allow Bluecherry to collect data to improve the app and provide '
          'better services. Data is collected anonymously and does not contain '
          'any personal information.',
        ),
        isThreeLine: true,
        value: settings.kAllowDataCollection.value,
        onChanged: (value) {
          if (value != null) {
            settings.kAllowDataCollection.value = value;
          }
        },
      ),
      OptionsChooserTile<EnabledPreference>(
        title: 'Automatically report errors',
        description: 'Automatically report errors to Bluecherry to help us '
            'improve the app. Error reports may contain personal information.',
        icon: Icons.error,
        value: settings.kAllowCrashReports.value,
        values: EnabledPreference.values.map(
          (e) => Option(
            text: e.name.uppercaseFirst,
            value: e,
          ),
        ),
        onChanged: (v) {
          settings.kAllowCrashReports.value = v;
        },
      ),
      if (settings.kShowDebugInfo.value) ...[
        const Divider(),
        ListTile(
          contentPadding: DesktopSettings.horizontalPadding,
          leading: CircleAvatar(
            backgroundColor: Colors.transparent,
            foregroundColor: theme.iconTheme.color,
            child: const Icon(Icons.privacy_tip),
          ),
          title: const Text('Privacy Policy'),
          trailing: const Icon(Icons.chevron_right),
          onTap: () {},
        ),
        ListTile(
          contentPadding: DesktopSettings.horizontalPadding,
          leading: CircleAvatar(
            backgroundColor: Colors.transparent,
            foregroundColor: theme.iconTheme.color,
            child: const Icon(Icons.policy),
          ),
          title: const Text('Terms of Service'),
          trailing: const Icon(Icons.chevron_right),
          onTap: () {},
        ),
      ],
    ]);
  }
}
