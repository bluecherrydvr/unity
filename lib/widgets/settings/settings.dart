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

import 'package:auto_size_text/auto_size_text.dart';
import 'package:bluecherry_client/models/server.dart';
import 'package:bluecherry_client/providers/home_provider.dart';
import 'package:bluecherry_client/providers/server_provider.dart';
import 'package:bluecherry_client/providers/settings_provider.dart';
import 'package:bluecherry_client/utils/constants.dart';
import 'package:bluecherry_client/utils/extensions.dart';
import 'package:bluecherry_client/utils/methods.dart';
import 'package:bluecherry_client/widgets/edit_server.dart';
import 'package:bluecherry_client/widgets/misc.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:unity_video_player/unity_video_player.dart';
import 'package:url_launcher/url_launcher.dart';

part 'date_format_section.dart';
part 'server_tile.dart';

typedef ChangeTabCallback = void Function(int tab);

class Settings extends StatefulWidget {
  const Settings({super.key});

  @override
  State<Settings> createState() => _SettingsState();
}

class _SettingsState extends State<Settings> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      SettingsProvider.instance.reload();
    });
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final settings = context.watch<SettingsProvider>();

    const divider = SliverToBoxAdapter(
      child: Padding(
        padding: EdgeInsetsDirectional.only(top: 8.0),
        child: Divider(
          height: 1.0,
          thickness: 1.0,
        ),
      ),
    );

    return Material(
      type: MaterialType.transparency,
      child: SafeArea(
        bottom: false,
        child: Column(children: [
          if (isMobile)
            AppBar(
              leading: MaybeUnityDrawerButton(context),
              title: Text(loc.settings),
            ),
          Expanded(
            child: CustomScrollView(slivers: [
              SliverToBoxAdapter(
                child: SubHeader(loc.servers),
              ),
              const SliverToBoxAdapter(child: ServersList()),
              SliverToBoxAdapter(
                child: SubHeader(loc.theme),
              ),
              SliverList(
                delegate: SliverChildListDelegate(ThemeMode.values.map((e) {
                  return ListTile(
                    leading: CircleAvatar(
                      backgroundColor: Colors.transparent,
                      foregroundColor: theme.iconTheme.color,
                      child: Icon({
                        ThemeMode.system: Icons.brightness_auto,
                        ThemeMode.light: Icons.light_mode,
                        ThemeMode.dark: Icons.dark_mode,
                      }[e]!),
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
                    title: Text({
                      ThemeMode.system: loc.system,
                      ThemeMode.light: loc.light,
                      ThemeMode.dark: loc.dark,
                    }[e]!),
                  );
                }).toList()),
              ),
              divider,
              SliverToBoxAdapter(
                child: SubHeader(loc.miscellaneous),
              ),
              SliverList(
                  delegate: SliverChildListDelegate([
                CorrectedListTile(
                  iconData: Icons.message,
                  onTap: () async {
                    if (settings.snoozedUntil.isAfter(DateTime.now())) {
                      settings.snoozedUntil =
                          SettingsProvider.defaultSnoozedUntil;
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
                            if (settings.snoozedUntil
                                    .difference(DateTime.now()) >
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
                  title: Text(loc.notificationClickAction),
                  textColor: theme.textTheme.bodyLarge?.color,
                  subtitle: Text(
                    settings.notificationClickAction.str(context),
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.textTheme.bodySmall?.color,
                    ),
                  ),
                  children: NotificationClickAction.values.map((e) {
                    return RadioListTile(
                      value: e,
                      groupValue: settings.notificationClickAction,
                      onChanged: (value) {
                        settings.notificationClickAction = e;
                      },
                      secondary: const Icon(null),
                      controlAffinity: ListTileControlAffinity.trailing,
                      title: Padding(
                        padding: const EdgeInsetsDirectional.only(start: 16.0),
                        child: Text(
                          e.str(context),
                        ),
                      ),
                    );
                  }).toList(),
                ),
                ExpansionTile(
                  leading: CircleAvatar(
                    backgroundColor: Colors.transparent,
                    foregroundColor: theme.iconTheme.color,
                    child: const Icon(Icons.camera_alt),
                  ),
                  title: Text(loc.cameraViewFit),
                  textColor: theme.textTheme.bodyLarge?.color,
                  subtitle: Text(
                    settings.cameraViewFit.str(context),
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.textTheme.bodySmall?.color,
                    ),
                  ),
                  children: UnityVideoFit.values.map((e) {
                    return RadioListTile(
                      value: e,
                      groupValue: settings.cameraViewFit,
                      onChanged: (value) {
                        settings.cameraViewFit = e;
                      },
                      secondary: const Icon(null),
                      controlAffinity: ListTileControlAffinity.trailing,
                      title: Padding(
                        padding: const EdgeInsetsDirectional.only(start: 16.0),
                        child: Text(
                          e.str(context),
                        ),
                      ),
                    );
                  }).toList(),
                ),
                CorrectedListTile(
                  iconData: Icons.download,
                  title: loc.downloadPath,
                  subtitle: settings.downloadsDirectory,
                  height: 72.0,
                  onTap: () async {
                    final selectedDirectory =
                        await FilePicker.platform.getDirectoryPath(
                      dialogTitle: loc.downloadPath,
                      initialDirectory:
                          SettingsProvider.instance.downloadsDirectory,
                      lockParentWindow: true,
                    );

                    if (selectedDirectory != null) {
                      settings.downloadsDirectory =
                          Directory(selectedDirectory).path;
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
                ExpansionTile(
                  leading: CircleAvatar(
                    backgroundColor: Colors.transparent,
                    foregroundColor: theme.iconTheme.color,
                    child: const Icon(Icons.hd),
                  ),
                  title: Text(loc.defaultResolution),
                  textColor: theme.textTheme.bodyLarge?.color,
                  subtitle: Text(
                    settings.videoQuality.str(context),
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.textTheme.bodySmall?.color,
                    ),
                  ),
                  children: UnityVideoQuality.values.map((quality) {
                    return RadioListTile<UnityVideoQuality>(
                      value: quality,
                      groupValue: settings.videoQuality,
                      onChanged: (value) {
                        settings.videoQuality = quality;
                      },
                      secondary: const Icon(null),
                      controlAffinity: ListTileControlAffinity.trailing,
                      title: Padding(
                        padding: const EdgeInsetsDirectional.only(start: 16.0),
                        child: RichText(
                          text: TextSpan(
                            text: quality.str(context),
                            children: [
                              if (quality.isHD)
                                const WidgetSpan(child: Icon(Icons.hd)),
                            ],
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ])),
              divider,
              SliverToBoxAdapter(child: SubHeader(loc.dateFormat)),
              const SliverToBoxAdapter(child: DateFormatSection()),
              divider,
              SliverToBoxAdapter(child: SubHeader(loc.timeFormat)),
              SliverList(
                  delegate: SliverChildListDelegate([
                'HH:mm',
                'hh:mm a',
              ].map((pattern) {
                return ListTile(
                  onTap: () {
                    settings.timeFormat = DateFormat(pattern, 'en_US');
                  },
                  trailing: Radio(
                    value: pattern,
                    groupValue: settings.timeFormat.pattern,
                    onChanged: (value) {
                      settings.timeFormat = DateFormat(pattern, 'en_US');
                    },
                  ),
                  title: Padding(
                    padding: const EdgeInsetsDirectional.only(start: 8.0),
                    child: Text(
                      DateFormat(pattern, 'en_US').format(
                        DateTime.utc(1969, 7, 20, 14, 18, 04),
                      ),
                    ),
                  ),
                );
              }).toList())),
              divider,
              // SubHeader('Language'),
              // SliverList(
              //   delegate: SliverChildListDelegate(
              //     AppLocalizations.supportedLocales.map((locale) {
              //       return ListTile(
              //         title: Text(locale.languageCode),
              //       );
              //     }).toList(),
              //   ),
              // ),
              // divider,
              SliverToBoxAdapter(
                child: SubHeader(loc.version),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 8.0),
                      FutureBuilder<String>(
                        future: appVersion,
                        builder: (context, snapshot) {
                          return Text(snapshot.data ?? '');
                        },
                      ),
                      const SizedBox(height: 8.0),
                      Text(
                        loc.versionText,
                        style: theme.textTheme.displayMedium,
                      ),
                      const SizedBox(height: 8.0),
                      MaterialButton(
                        onPressed: () {
                          launchUrl(
                            Uri.https('www.bluecherrydvr.com', '/'),
                            mode: LaunchMode.externalApplication,
                          );
                        },
                        padding: EdgeInsets.zero,
                        minWidth: 0.0,
                        child: Text(
                          loc.website,
                          style: TextStyle(
                            color: theme.colorScheme.primary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 16.0)),
            ]),
          ),
        ]),
      ),
    );
  }
}
