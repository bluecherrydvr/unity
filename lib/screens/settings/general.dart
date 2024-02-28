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
import 'package:bluecherry_client/widgets/misc.dart';
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
      OptionsChooserTile(
        title: loc.cycleTogglePeriod,
        description: loc.cycleTogglePeriodDescription,
        icon: Icons.timelapse,
        value: settings.kLayoutCyclePeriod.value,
        values: [5, 10, 30, 60, 60 * 5]
            .map((seconds) => Duration(seconds: seconds))
            .map((duration) {
          return Option(
            text: duration.humanReadableCompact(context),
            value: duration,
          );
        }),
        onChanged: (value) {
          settings.kLayoutCyclePeriod.value = value;
        },
      ),
      CheckboxListTile.adaptive(
        secondary: CircleAvatar(
          backgroundColor: Colors.transparent,
          foregroundColor: theme.iconTheme.color,
          child: const Icon(Icons.monitor),
        ),
        contentPadding: DesktopSettings.horizontalPadding,
        title: Text(loc.wakelock),
        subtitle: Text(loc.wakelockDescription),
        isThreeLine: true,
        value: settings.kWakelock.value,
        onChanged: (value) {
          settings.kWakelock.value = !settings.kWakelock.value;
        },
      ),
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
      ListTile(
        contentPadding: DesktopSettings.horizontalPadding,
        leading: CircleAvatar(
          backgroundColor: Colors.transparent,
          foregroundColor: theme.iconTheme.color,
          child: const Icon(Icons.notifications_paused),
        ),
        title: Text(loc.snoozeNotifications),
        subtitle: Text(
          settings.kSnoozeNotificationsUntil.value.isAfter(DateTime.now())
              ? loc.snoozedUntil(
                  [
                    if (settings.kSnoozeNotificationsUntil.value
                            .difference(DateTime.now()) >
                        const Duration(hours: 24))
                      settings
                          .formatDate(settings.kSnoozeNotificationsUntil.value),
                    settings
                        .formatTime(settings.kSnoozeNotificationsUntil.value),
                  ].join(' '),
                )
              : loc.notSnoozed,
        ),
        onTap: () async {
          if (settings.kSnoozeNotificationsUntil.value
              .isAfter(DateTime.now())) {
            settings.kSnoozeNotificationsUntil.value =
                SettingsProvider.instance.kSnoozeNotificationsUntil.def;
          } else {
            final timeOfDay = await showTimePicker(
              context: context,
              helpText: loc.snoozeNotificationsUntil.toUpperCase(),
              initialTime: TimeOfDay.fromDateTime(DateTime.now()),
              useRootNavigator: false,
            );
            if (timeOfDay != null) {
              settings.kSnoozeNotificationsUntil.value = DateTime(
                DateTime.now().year,
                DateTime.now().month,
                DateTime.now().day,
                timeOfDay.hour,
                timeOfDay.minute,
              );
            }
          }
        },
      ),
      OptionsChooserTile(
        title: loc.notificationClickBehavior,
        description: loc.notificationClickBehaviorDescription,
        icon: Icons.beenhere_rounded,
        value: settings.kNotificationClickBehavior.value,
        values: NotificationClickBehavior.values
            .map((behavior) => Option(
                  value: behavior,
                  icon: behavior.icon,
                  text: behavior.locale(context),
                ))
            .toList(),
        onChanged: (v) {
          settings.kNotificationClickBehavior.value = v;
        },
      ),
      const SubHeader(
        'Data Usage',
        padding: DesktopSettings.horizontalPadding,
      ),
      OptionsChooserTile(
        icon: Icons.data_usage,
        title: 'Automatic streaming',
        description: 'When to stream videos automatically on startup',
        value: '',
        values: const [
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
        values: const [
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
