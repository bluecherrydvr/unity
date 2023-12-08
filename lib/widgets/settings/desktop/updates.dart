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
import 'package:bluecherry_client/widgets/settings/desktop/settings.dart';
import 'package:bluecherry_client/widgets/settings/shared/update.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:provider/provider.dart';

class UpdatesSettings extends StatelessWidget {
  const UpdatesSettings({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final loc = AppLocalizations.of(context);
    final update = context.watch<UpdateManager>();

    return ListView(padding: DesktopSettings.verticalPadding, children: [
      Padding(
        padding: DesktopSettings.horizontalPadding,
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(
            loc.updates,
            style: theme.textTheme.titleMedium,
          ),
          Text(
            loc.runningOn(() {
              if (Platform.isLinux) {
                return loc.linux(update.linuxEnvironment ?? '');
              } else if (Platform.isWindows) {
                return loc.windows;
              }

              return defaultTargetPlatform.name;
            }()),
            style: theme.textTheme.labelSmall,
          ),
        ]),
      ),
      const AppUpdateCard(),
      const AppUpdateOptions(),
      Padding(
        padding: DesktopSettings.horizontalPadding,
        child: Text('Beta Features', style: theme.textTheme.titleMedium),
      ),
      const BetaFeatures(),
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
        value: settings.betaMatrixedZoomEnabled,
        onChanged: (value) {
          if (value != null) {
            settings.betaMatrixedZoomEnabled = value;
          }
        },
      ),
    ]);
  }
}
