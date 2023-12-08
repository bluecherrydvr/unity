import 'dart:io';

import 'package:bluecherry_client/providers/settings_provider.dart';
import 'package:bluecherry_client/utils/extensions.dart';
import 'package:bluecherry_client/widgets/misc.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:provider/provider.dart';

class ThemeTile extends StatelessWidget {
  final ThemeMode themeMode;

  const ThemeTile({super.key, required this.themeMode});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final settings = context.watch<SettingsProvider>();
    final loc = AppLocalizations.of(context);

    return ListTile(
      leading: CircleAvatar(
        backgroundColor: Colors.transparent,
        foregroundColor: theme.iconTheme.color,
        child: Icon(switch (themeMode) {
          ThemeMode.system => Icons.brightness_auto,
          ThemeMode.light => Icons.light_mode,
          ThemeMode.dark => Icons.dark_mode,
        }),
      ),
      onTap: () => settings.themeMode = themeMode,
      trailing: Radio.adaptive(
        value: themeMode,
        groupValue: settings.themeMode,
        onChanged: (value) {
          settings.themeMode = themeMode;
        },
      ),
      title: Text(switch (themeMode) {
        ThemeMode.system => loc.system,
        ThemeMode.light => loc.light,
        ThemeMode.dark => loc.dark,
      }),
      subtitle: themeMode == ThemeMode.system
          ? Text(switch (MediaQuery.platformBrightnessOf(context)) {
              Brightness.dark => loc.dark,
              Brightness.light => loc.light,
            })
          : null,
    );
  }
}

class DirectoryChooseTile extends StatelessWidget {
  const DirectoryChooseTile({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsProvider>();
    final loc = AppLocalizations.of(context);

    return CorrectedListTile(
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
    );
  }
}

class SnoozeNotificationsTile extends StatelessWidget {
  const SnoozeNotificationsTile({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsProvider>();
    final loc = AppLocalizations.of(context);

    return CorrectedListTile(
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
    );
  }
}

class NavigationClickBehaviorTile extends StatelessWidget {
  const NavigationClickBehaviorTile({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final settings = context.watch<SettingsProvider>();
    final loc = AppLocalizations.of(context);

    return ExpansionTile(
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
        return RadioListTile<NotificationClickBehavior>.adaptive(
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
    );
  }
}

class CyclePeriodTile extends StatelessWidget {
  const CyclePeriodTile({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final settings = context.watch<SettingsProvider>();
    final loc = AppLocalizations.of(context);

    return ExpansionTile(
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
        return RadioListTile<Duration>.adaptive(
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
    );
  }
}

class WakelockTile extends StatelessWidget {
  const WakelockTile({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsProvider>();
    final loc = AppLocalizations.of(context);

    return CorrectedListTile(
      iconData: Icons.monitor,
      trailingWidget: Padding(
        padding: const EdgeInsetsDirectional.only(end: 4.0),
        child: IgnorePointer(
          child: Checkbox(
            value: settings.wakelockEnabled,
            onChanged: (v) {},
          ),
        ),
      ),
      title: loc.wakelock,
      subtitle: loc.wakelockDescription,
      height: 72.0,
      onTap: () => settings.wakelockEnabled = !settings.wakelockEnabled,
    );
  }
}
