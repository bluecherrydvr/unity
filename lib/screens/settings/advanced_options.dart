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
import 'package:bluecherry_client/screens/layouts/desktop/external_stream.dart';
import 'package:bluecherry_client/screens/settings/settings_desktop.dart';
import 'package:bluecherry_client/screens/settings/shared/options_chooser_tile.dart';
import 'package:bluecherry_client/utils/logging.dart';
import 'package:bluecherry_client/utils/window.dart';
import 'package:bluecherry_client/widgets/misc.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';

class AdvancedOptionsSettings extends StatelessWidget {
  const AdvancedOptionsSettings({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final loc = AppLocalizations.of(context);
    final settings = context.watch<SettingsProvider>();
    return ListView(children: [
      const SubHeader('Matrix Zoom'),
      CheckboxListTile.adaptive(
        secondary: CircleAvatar(
          backgroundColor: Colors.transparent,
          foregroundColor: theme.iconTheme.color,
          child: const Icon(Icons.crop),
        ),
        contentPadding: DesktopSettings.horizontalPadding,
        title: Text(loc.matrixedViewZoom),
        subtitle: Text(loc.matrixedViewZoomDescription),
        value: settings.kDefaultBetaMatrixedZoomEnabled.value,
        onChanged: (value) {
          if (value != null) {
            settings.kDefaultBetaMatrixedZoomEnabled.value = value;
          }
        },
      ),
      OptionsChooserTile<MatrixType>(
        title: 'Default Matrix Size',
        icon: Icons.view_quilt,
        value: MatrixType.t4,
        values: MatrixType.values.map((size) {
          return Option(
            value: size,
            text: size.toString(),
          );
        }),
        onChanged: (v) {},
      ),
      const SubHeader('Developer Options'),
      if (!kIsWeb) ...[
        FutureBuilder(
          future: getLogFile(),
          builder: (context, snapshot) {
            return ListTile(
              contentPadding: DesktopSettings.horizontalPadding,
              leading: const Icon(Icons.bug_report),
              title: const Text('Open log file'),
              subtitle: Text(snapshot.data?.path ?? loc.loading),
              trailing: const Icon(Icons.navigate_next),
              dense: false,
              onTap: snapshot.data == null
                  ? null
                  : () {
                      launchFileExplorer(snapshot.data!.path);
                    },
            );
          },
        ),
        FutureBuilder(
          future: getApplicationSupportDirectory(),
          builder: (context, snapshot) {
            return ListTile(
              contentPadding: DesktopSettings.horizontalPadding,
              leading: const Icon(Icons.home),
              title: const Text('Open app data'),
              subtitle: Text(snapshot.data?.path ?? loc.loading),
              trailing: const Icon(Icons.navigate_next),
              dense: false,
              onTap: snapshot.data == null
                  ? null
                  : () {
                      launchFileExplorer(snapshot.data!.path);
                    },
            );
          },
        ),
        CheckboxListTile(
          contentPadding: DesktopSettings.horizontalPadding,
          secondary: const Icon(Icons.adb),
          title: const Text('Debug info'),
          subtitle: const Text(
            'Display useful information for debugging, such as video metadata '
            'and other useful information for debugging purposes.',
          ),
          value: settings.kShowDebugInfo.value,
          onChanged: (v) {
            if (v != null) {
              settings.kShowDebugInfo.value = v;
            }
          },
          dense: false,
        ),
        CheckboxListTile(
          contentPadding: DesktopSettings.horizontalPadding,
          secondary: const Icon(Icons.network_check),
          title: const Text('Network Usage'),
          subtitle: const Text(
            'Display network usage information over playing videos.',
          ),
          value: false,
          onChanged: (v) {},
          dense: false,
        ),
        ListTile(
          contentPadding: DesktopSettings.horizontalPadding,
          leading: const Icon(Icons.restore),
          title: const Text('Restore Defaults'),
          subtitle: const Text(
            'Restore all settings to their default values. This will not '
            'affect your servers or any other data.',
          ),
          trailing: const Icon(Icons.navigate_next),
          onTap: () {},
        ),
      ],
    ]);
  }
}
