import 'dart:io';

import 'package:bluecherry_client/providers/settings_provider.dart';
import 'package:bluecherry_client/utils/extensions.dart';
import 'package:bluecherry_client/widgets/device_grid/desktop/stream_data.dart';
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
        loc.notificationClickBehaviorDescription,
        style: theme.textTheme.bodyMedium?.copyWith(
          color: theme.textTheme.bodySmall?.color,
        ),
      ),
      trailing: Text(settings.notificationClickBehavior.locale(context)),
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
    final periodList = [5, 10, 30, 60, 60 * 5].map((e) => Duration(seconds: e));

    return LayoutBuilder(builder: (context, constraints) {
      final isSmall = constraints.maxWidth < 600.0;
      return ExpansionTile(
        leading: CircleAvatar(
          backgroundColor: Colors.transparent,
          foregroundColor: theme.iconTheme.color,
          child: const Icon(Icons.timelapse),
        ),
        title: Text(loc.cycleTogglePeriod),
        textColor: theme.textTheme.bodyLarge?.color,
        subtitle: Text(
          loc.cycleTogglePeriodDescription,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.textTheme.bodySmall?.color,
          ),
        ),
        trailing: Text(
          settings.layoutCyclingTogglePeriod.humanReadableCompact(context),
        ),
        childrenPadding: const EdgeInsetsDirectional.all(12.0),
        children: [
          ToggleButtons(
            isSelected: periodList
                .map((d) => d == settings.layoutCyclingTogglePeriod)
                .toList(),
            onPressed: (index) => settings.layoutCyclingTogglePeriod =
                periodList.elementAt(index),
            children: periodList.map((dur) {
              return Padding(
                padding:
                    const EdgeInsetsDirectional.symmetric(horizontal: 12.0),
                child: Row(children: [
                  Text(
                    isSmall
                        ? dur.humanReadableCompact(context)
                        : dur.humanReadable(context),
                  ),
                  if (dur ==
                      SettingsProvider.kDefaultLayoutCyclingTogglePeriod) ...[
                    const SizedBox(width: 8.0),
                    const DefaultValueIcon(),
                  ]
                ]),
              );
            }).toList(),
          ),
        ],
      );
    });
  }
}

class CameraReloadPeriodTile extends StatelessWidget {
  const CameraReloadPeriodTile({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final settings = context.watch<SettingsProvider>();
    final loc = AppLocalizations.of(context);
    final periodList =
        [0, 5, 10, 30, 60, 60 * 5].map((e) => Duration(seconds: e));

    return LayoutBuilder(builder: (context, constraints) {
      final isSmall = constraints.maxWidth < 600.0;
      return ExpansionTile(
        leading: CircleAvatar(
          backgroundColor: Colors.transparent,
          foregroundColor: theme.iconTheme.color,
          child: const Icon(Icons.camera),
        ),
        title: Text(loc.cameraRefreshPeriod),
        textColor: theme.textTheme.bodyLarge?.color,
        subtitle: Text(
          loc.cameraRefreshPeriodDescription,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.textTheme.bodySmall?.color,
          ),
        ),
        trailing: Text(
          settings.cameraRefreshPeriod.humanReadableCompact(context),
        ),
        childrenPadding: const EdgeInsetsDirectional.all(12.0),
        children: [
          ToggleButtons(
            isSelected: periodList
                .map((d) => d == settings.cameraRefreshPeriod)
                .toList(),
            onPressed: (index) =>
                settings.cameraRefreshPeriod = periodList.elementAt(index),
            children: periodList.map((dur) {
              return Padding(
                padding:
                    const EdgeInsetsDirectional.symmetric(horizontal: 12.0),
                child: Row(children: [
                  Text(
                    dur == Duration.zero
                        ? loc.disabled
                        : isSmall
                            ? dur.humanReadableCompact(context)
                            : dur.humanReadable(context),
                  ),
                  if (dur == SettingsProvider.kDefaultCameraRefreshPeriod) ...[
                    const SizedBox(width: 8.0),
                    const DefaultValueIcon(),
                  ]
                ]),
              );
            }).toList(),
          ),
        ],
      );
    });
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
          child: Checkbox.adaptive(
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
