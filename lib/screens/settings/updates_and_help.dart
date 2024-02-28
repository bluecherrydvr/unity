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
import 'package:bluecherry_client/providers/update_provider.dart';
import 'package:bluecherry_client/screens/settings/shared/update.dart';
import 'package:bluecherry_client/utils/logging.dart';
import 'package:bluecherry_client/utils/window.dart';
import 'package:bluecherry_client/widgets/misc.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:provider/provider.dart';

class UpdatesSettings extends StatelessWidget {
  const UpdatesSettings({super.key});

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);

    return ListView(children: [
      if (!kIsWeb) ...[
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          SubHeader(
            loc.updates,
            subtext: loc.runningOn(() {
              if (kIsWeb) {
                return 'WEB';
              } else if (Platform.isLinux) {
                return loc.linux(UpdateManager.linuxEnvironment.name);
              } else if (Platform.isWindows) {
                return loc.windows;
              }

              return defaultTargetPlatform.name;
            }()),
          ),
        ]),
        const AppUpdateCard(),
        const AppUpdateOptions(),
      ],
      // TODO(bdlukaa): Show option to downlaod the native client when running
      //                on the web.
      // Padding(
      //   padding: DesktopSettings.horizontalPadding,
      //   child: Text('Beta Features', style: theme.textTheme.titleMedium),
      // ),
      // const BetaFeatures(),
      const Divider(),
      const About(),
    ]);
  }
}

class BetaFeatures extends StatelessWidget {
  const BetaFeatures({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final loc = AppLocalizations.of(context);
    final settings = context.watch<SettingsProvider>();

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      CheckboxListTile.adaptive(
        secondary: CircleAvatar(
          backgroundColor: Colors.transparent,
          foregroundColor: theme.iconTheme.color,
          child: const Icon(Icons.crop),
        ),
        title: Text(loc.matrixedViewZoom),
        subtitle: Text(loc.matrixedViewZoomDescription),
        value: settings.kDefaultBetaMatrixedZoomEnabled.value,
        onChanged: (value) {
          if (value != null) {
            settings.kDefaultBetaMatrixedZoomEnabled.value = value;
          }
        },
      ),
      ExpansionTile(
        leading: CircleAvatar(
          backgroundColor: Colors.transparent,
          foregroundColor: theme.iconTheme.color,
          child: const Icon(Icons.developer_mode),
        ),
        title: const Text('Developer options'),
        subtitle:
            const Text('Most of these options are for debugging purposes'),
        children: [
          if (!kIsWeb)
            FutureBuilder(
              future: getLogFile(),
              builder: (context, snapshot) {
                return ListTile(
                  contentPadding: const EdgeInsetsDirectional.only(
                    start: 68.0,
                    end: 26.0,
                  ),
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
          CheckboxListTile(
            contentPadding: const EdgeInsetsDirectional.only(
              start: 68.0,
              end: 26.0,
            ),
            secondary: const Icon(Icons.adb),
            title: const Text('Show debug info'),
            subtitle: const Text('Display useful information for debugging'),
            value: settings.kShowDebugInfo.value,
            onChanged: (v) {
              if (v != null) {
                settings.kShowDebugInfo.value = v;
              }
            },
            dense: false,
          )
        ],
      ),
    ]);
  }
}
