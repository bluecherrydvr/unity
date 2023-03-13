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

import 'package:bluecherry_client/models/server.dart';
import 'package:bluecherry_client/providers/home_provider.dart';
import 'package:bluecherry_client/providers/server_provider.dart';
import 'package:bluecherry_client/providers/settings_provider.dart';
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
  final ChangeTabCallback changeCurrentTab;

  const Settings({
    Key? key,
    required this.changeCurrentTab,
  }) : super(key: key);

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

    return SafeArea(
      bottom: false,
      child: Column(children: [
        showIf(
              isMobile,
              child: AppBar(
                leading: MaybeUnityDrawerButton(context),
                title: Text(AppLocalizations.of(context).settings),
              ),
            ) ??
            const SizedBox.shrink(),
        Expanded(
          child: CustomScrollView(slivers: [
            SubHeader(AppLocalizations.of(context).servers),
            SliverToBoxAdapter(
              child: ServersList(changeCurrentTab: widget.changeCurrentTab),
            ),
            SubHeader(AppLocalizations.of(context).theme),
            SliverList(
              delegate: SliverChildListDelegate(ThemeMode.values.map((e) {
                return ListTile(
                  leading: CircleAvatar(
                    backgroundColor: Colors.transparent,
                    foregroundColor: Theme.of(context).iconTheme.color,
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
                    ThemeMode.system: AppLocalizations.of(context).system,
                    ThemeMode.light: AppLocalizations.of(context).light,
                    ThemeMode.dark: AppLocalizations.of(context).dark,
                  }[e]!),
                );
              }).toList()),
            ),
            divider,
            SubHeader(AppLocalizations.of(context).miscellaneous),
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
                      helpText: AppLocalizations.of(context)
                          .snoozeNotificationsUntil
                          .toUpperCase(),
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
                title: AppLocalizations.of(context).snoozeNotifications,
                height: 72.0,
                subtitle: settings.snoozedUntil.isAfter(DateTime.now())
                    ? AppLocalizations.of(context).snoozedUntil(
                        [
                          if (settings.snoozedUntil.difference(DateTime.now()) >
                              const Duration(hours: 24))
                            settings.formatDate(settings.snoozedUntil),
                          settings.formatTime(settings.snoozedUntil),
                        ].join(' '),
                      )
                    : AppLocalizations.of(context).notSnoozed,
              ),
              ExpansionTile(
                leading: CircleAvatar(
                  backgroundColor: Colors.transparent,
                  foregroundColor: Theme.of(context).iconTheme.color,
                  child: const Icon(Icons.beenhere_rounded),
                ),
                title:
                    Text(AppLocalizations.of(context).notificationClickAction),
                textColor: Theme.of(context).textTheme.bodyLarge?.color,
                subtitle: Text(
                  settings.notificationClickAction.str(context),
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).textTheme.bodySmall?.color,
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
                      padding: const EdgeInsetsDirectional.only(start: 8.0),
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
                  foregroundColor: Theme.of(context).iconTheme.color,
                  child: const Icon(Icons.camera_alt),
                ),
                title: Text(AppLocalizations.of(context).cameraViewFit),
                textColor: Theme.of(context).textTheme.bodyLarge?.color,
                subtitle: Text(
                  settings.cameraViewFit.str(context),
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).textTheme.bodySmall?.color,
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
                      padding: const EdgeInsetsDirectional.only(start: 8.0),
                      child: Text(
                        e.str(context),
                      ),
                    ),
                  );
                }).toList(),
              ),
              CorrectedListTile(
                iconData: Icons.download,
                title: AppLocalizations.of(context).downloadPath,
                subtitle: settings.downloadsDirectory,
                height: 72.0,
                onTap: () async {
                  final selectedDirectory =
                      await FilePicker.platform.getDirectoryPath(
                    dialogTitle: AppLocalizations.of(context).downloadPath,
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
            ])),
            divider,
            SubHeader(AppLocalizations.of(context).dateFormat),
            const SliverToBoxAdapter(child: DateFormatSection()),
            divider,
            SubHeader(AppLocalizations.of(context).timeFormat),
            SliverList(
                delegate: SliverChildListDelegate([
              'HH:mm',
              'hh:mm a',
            ].map((e) {
              return ListTile(
                onTap: () {
                  settings.timeFormat = DateFormat(e, 'en_US');
                },
                trailing: Radio(
                  value: e,
                  groupValue: settings.timeFormat.pattern,
                  onChanged: (value) {
                    settings.timeFormat = DateFormat(e, 'en_US');
                  },
                ),
                title: Padding(
                  padding: const EdgeInsetsDirectional.only(start: 8.0),
                  child: Text(
                    DateFormat(e, 'en_US')
                        .format(DateTime.utc(1969, 7, 20, 14, 18, 04)),
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
            SubHeader(AppLocalizations.of(context).version),
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
                      AppLocalizations.of(context).versionText,
                      style: Theme.of(context).textTheme.displayMedium,
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
                        AppLocalizations.of(context).website,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.primary,
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
    );
  }
}

// ignore: non_constant_identifier_names
Widget SubHeader(String text, {Widget? trailing}) {
  return SliverToBoxAdapter(
    child: Builder(builder: (context) {
      return Material(
        type: MaterialType.transparency,
        child: Container(
          height: 56.0,
          alignment: AlignmentDirectional.centerStart,
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Row(children: [
            Expanded(
              child: Text(
                text.toUpperCase(),
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: Theme.of(context).textTheme.displaySmall?.color,
                      fontSize: 12.0,
                      fontWeight: FontWeight.w600,
                    ),
              ),
            ),
            if (trailing != null) trailing,
          ]),
        ),
      );
    }),
  );

  // return SliverPersistentHeader(
  //   delegate: _SubHeaderDelegate(text),
  //   pinned: true,
  // );
}

// class _SubHeaderDelegate extends SliverPersistentHeaderDelegate {
//   final String text;

//   _SubHeaderDelegate(this.text);

//   @override
//   Widget build(context, double shrinkOffset, bool overlapsContent) {
//     return Material(
//       child: Container(
//         height: 56.0,
//         alignment: AlignmentDirectional.centerStart,
//         padding: const EdgeInsets.symmetric(horizontal: 16.0),
//         child: Text(
//           text.toUpperCase(),
//           style: Theme.of(context).textTheme.overline?.copyWith(
//                 color: Theme.of(context).textTheme.headline3?.color,
//                 fontSize: 12.0,
//                 fontWeight: FontWeight.w600,
//               ),
//         ),
//       ),
//     );
//   }

//   @override
//   double get maxExtent => 56.0;

//   @override
//   double get minExtent => 56.0;

//   @override
//   bool shouldRebuild(covariant SliverPersistentHeaderDelegate oldDelegate) {
//     return true;
//   }
// }
