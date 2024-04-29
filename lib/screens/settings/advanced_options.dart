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

import 'dart:io';

import 'package:bluecherry_client/providers/settings_provider.dart';
import 'package:bluecherry_client/screens/layouts/desktop/external_stream.dart';
import 'package:bluecherry_client/screens/settings/settings_desktop.dart';
import 'package:bluecherry_client/screens/settings/shared/options_chooser_tile.dart';
import 'package:bluecherry_client/utils/config.dart';
import 'package:bluecherry_client/utils/logging.dart';
import 'package:bluecherry_client/utils/window.dart';
import 'package:bluecherry_client/widgets/misc.dart';
import 'package:file_picker/file_picker.dart';
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
      SubHeader(loc.matrixZoom),
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
        title: loc.defaultMatrixSize,
        icon: Icons.view_quilt,
        value: settings.kMatrixSize.value,
        values: MatrixType.values.map((size) {
          return Option(
            value: size,
            text: size.toString(),
          );
        }),
        onChanged: (v) {
          settings.kMatrixSize.value = v;
        },
      ),
      CheckboxListTile.adaptive(
        contentPadding: DesktopSettings.horizontalPadding,
        secondary: CircleAvatar(
          backgroundColor: Colors.transparent,
          foregroundColor: theme.iconTheme.color,
          child: const Icon(Icons.center_focus_strong),
        ),
        title: Text(loc.softwareZoom),
        subtitle: Text(
          Platform.isMacOS
              ? loc.softwareZoomDescriptionMacOS
              : loc.softwareZoomDescription,
        ),
        value: Platform.isMacOS ? true : settings.kSoftwareZooming.value,
        onChanged: Platform.isMacOS
            ? null
            : (v) {
                if (v != null) {
                  settings.kSoftwareZooming.value = v;
                }
              },
        dense: false,
      ),
      SubHeader(loc.developerOptions),
      if (!kIsWeb) ...[
        FutureBuilder(
          future: getLogFile(),
          builder: (context, snapshot) {
            return ListTile(
              contentPadding: DesktopSettings.horizontalPadding,
              leading: CircleAvatar(
                backgroundColor: Colors.transparent,
                foregroundColor: theme.iconTheme.color,
                child: const Icon(Icons.bug_report),
              ),
              title: Text(loc.openLogFile),
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
              leading: CircleAvatar(
                backgroundColor: Colors.transparent,
                foregroundColor: theme.iconTheme.color,
                child: const Icon(Icons.home),
              ),
              title: Text(loc.openAppDataDirectory),
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
      ],
      ListTile(
        contentPadding: DesktopSettings.horizontalPadding,
        leading: CircleAvatar(
          backgroundColor: Colors.transparent,
          foregroundColor: theme.iconTheme.color,
          child: const Icon(Icons.attachment),
        ),
        title: const Text('Import configuration file'),
        subtitle: const Text(
          'Import a .bluecherry configuration file that contains streaming information.',
        ),
        trailing: const Icon(Icons.navigate_next),
        dense: false,
        onTap: () async {
          final pickResult = await FilePicker.platform.pickFiles(
            dialogTitle: 'Import configuration file',
            allowedExtensions: ['bluecherry'],
            lockParentWindow: true,
          );
          if (pickResult == null || pickResult.count <= 0) return;

          final file = File(pickResult.files.first.path!);
          handleConfigurationFile(file);
        },
      ),
      CheckboxListTile.adaptive(
        contentPadding: DesktopSettings.horizontalPadding,
        secondary: CircleAvatar(
          backgroundColor: Colors.transparent,
          foregroundColor: theme.iconTheme.color,
          child: const Icon(Icons.adb),
        ),
        title: Text(loc.debugInfo),
        subtitle: Text(loc.debugInfoDescription),
        value: settings.kShowDebugInfo.value,
        onChanged: (v) {
          if (v != null) {
            settings.kShowDebugInfo.value = v;
          }
        },
        dense: false,
      ),
      if (settings.kShowDebugInfo.value)
        CheckboxListTile.adaptive(
          contentPadding: DesktopSettings.horizontalPadding,
          secondary: CircleAvatar(
            backgroundColor: Colors.transparent,
            foregroundColor: theme.iconTheme.color,
            child: const Icon(Icons.network_check),
          ),
          title: const Text('Network Usage'),
          subtitle: const Text(
            'Display network usage information over playing videos.',
          ),
          value: settings.kShowNetworkUsage.value,
          onChanged: (v) {
            if (v != null) {
              settings.kShowNetworkUsage.value = v;
            }
          },
          dense: false,
        ),
      ListTile(
        contentPadding: DesktopSettings.horizontalPadding,
        leading: CircleAvatar(
          backgroundColor: Colors.transparent,
          foregroundColor: theme.colorScheme.error,
          child: const Icon(Icons.restore),
        ),
        title: Text(loc.restoreDefaults),
        subtitle: Text(loc.restoreDefaultsDescription),
        trailing: const Icon(Icons.navigate_next),
        textColor: theme.colorScheme.error,
        iconColor: theme.colorScheme.error,
        onTap: () {
          showDialog(
            context: context,
            builder: (context) {
              return AlertDialog(
                title: Text(loc.areYouSure),
                content: Text(loc.areYouSureDescription),
                actions: [
                  FilledButton(
                    onPressed: () {
                      settings.restoreDefaults();
                      Navigator.of(context).pop();
                    },
                    child: Text(loc.yes),
                  ),
                  TextButton(
                    autofocus: true,
                    onPressed: Navigator.of(context).pop,
                    child: Text(loc.no),
                  ),
                ],
              );
            },
          );
        },
      ),
    ]);
  }
}
