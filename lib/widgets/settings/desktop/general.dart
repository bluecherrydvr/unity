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
import 'package:bluecherry_client/utils/extensions.dart';
import 'package:bluecherry_client/widgets/misc.dart';
import 'package:bluecherry_client/widgets/settings/desktop/settings.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:provider/provider.dart';

class GeneralSettings extends StatelessWidget {
  const GeneralSettings({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final loc = AppLocalizations.of(context);
    final settings = context.watch<SettingsProvider>();
    return ListView(padding: DesktopSettings.verticalPadding, children: [
      SubHeader(
        loc.theme,
        subtext: loc.themeDescription,
        padding: DesktopSettings.horizontalPadding,
      ),
      ...ThemeMode.values.map((e) {
        return ListTile(
          leading: CircleAvatar(
            backgroundColor: Colors.transparent,
            foregroundColor: theme.iconTheme.color,
            child: Icon(switch (e) {
              ThemeMode.system => Icons.brightness_auto,
              ThemeMode.light => Icons.light_mode,
              ThemeMode.dark => Icons.dark_mode,
            }),
          ),
          onTap: () {
            settings.themeMode = e;
          },
          trailing: Radio(
            value: e,
            groupValue: settings.themeMode,
            onChanged: (value) {
              settings.themeMode = e;
            },
          ),
          title: Text(switch (e) {
            ThemeMode.system => loc.system,
            ThemeMode.light => loc.light,
            ThemeMode.dark => loc.dark,
          }),
        );
      }),
      SubHeader(loc.miscellaneous, padding: DesktopSettings.horizontalPadding),
      CorrectedListTile(
        iconData: Icons.notifications_paused,
        onTap: () async {
          if (settings.snoozedUntil.isAfter(DateTime.now())) {
            settings.snoozedUntil = SettingsProvider.defaultSnoozedUntil;
          } else {
            final timeOfDay = await showTimePicker(
              context: context,
              helpText: loc.snoozeNotificationsUntil.toUpperCase(),
              initialTime: TimeOfDay.fromDateTime(DateTime.now()),
              useRootNavigator: false,
            );
            if (timeOfDay != null) {
              settings.snoozedUntil = DateTime(
                DateTime.now().year,
                DateTime.now().month,
                DateTime.now().day,
                timeOfDay.hour,
                timeOfDay.minute,
              );
            }
          }
        },
        title: loc.snoozeNotifications,
        height: 72.0,
        subtitle: settings.snoozedUntil.isAfter(DateTime.now())
            ? loc.snoozedUntil(
                [
                  if (settings.snoozedUntil.difference(DateTime.now()) >
                      const Duration(hours: 24))
                    settings.formatDate(settings.snoozedUntil),
                  settings.formatTime(settings.snoozedUntil),
                ].join(' '),
              )
            : loc.notSnoozed,
      ),
      ExpansionTile(
        leading: CircleAvatar(
          backgroundColor: Colors.transparent,
          foregroundColor: theme.iconTheme.color,
          child: const Icon(Icons.beenhere_rounded),
        ),
        title: Text(loc.notificationClickBehavior),
        textColor: theme.textTheme.bodyLarge?.color,
        subtitle: Text(
          settings.notificationClickBehavior.locale(context),
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.textTheme.bodySmall?.color,
          ),
        ),
        children: NotificationClickBehavior.values.map((behavior) {
          return RadioListTile(
            contentPadding: const EdgeInsetsDirectional.only(
              start: 68.0,
              end: 16.0,
            ),
            value: behavior,
            groupValue: settings.notificationClickBehavior,
            onChanged: (value) {
              settings.notificationClickBehavior = behavior;
            },
            secondary: Icon(behavior.icon),
            controlAffinity: ListTileControlAffinity.trailing,
            title: Padding(
              padding: const EdgeInsetsDirectional.only(start: 16.0),
              child: Text(behavior.locale(context)),
            ),
          );
        }).toList(),
      ),
      CorrectedListTile(
        iconData: Icons.folder,
        trailing: Icons.navigate_next,
        title: loc.downloadPath,
        subtitle: settings.downloadsDirectory,
        height: 72.0,
        onTap: () async {
          final selectedDirectory = await FilePicker.platform.getDirectoryPath(
            dialogTitle: loc.downloadPath,
            initialDirectory: settings.downloadsDirectory,
            lockParentWindow: true,
          );

          if (selectedDirectory != null) {
            settings.downloadsDirectory = Directory(selectedDirectory).path;
          }
        },
      ),
      ExpansionTile(
        leading: CircleAvatar(
          backgroundColor: Colors.transparent,
          foregroundColor: theme.iconTheme.color,
          child: const Icon(Icons.timelapse),
        ),
        title: Text(loc.cycleTogglePeriod),
        textColor: theme.textTheme.bodyLarge?.color,
        subtitle: Text(
          settings.layoutCyclingTogglePeriod.humanReadable(context),
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.textTheme.bodySmall?.color,
          ),
        ),
        children: [5, 10, 30, 60, 60 * 5].map((e) {
          final dur = Duration(seconds: e);
          return RadioListTile(
            value: dur,
            groupValue: settings.layoutCyclingTogglePeriod,
            onChanged: (value) {
              settings.layoutCyclingTogglePeriod = dur;
            },
            secondary: const Icon(null),
            controlAffinity: ListTileControlAffinity.trailing,
            title: Padding(
              padding: const EdgeInsetsDirectional.only(start: 16.0),
              child: Text(
                dur.humanReadable(context),
              ),
            ),
          );
        }).toList(),
      ),
    ]);
  }
}
