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

import 'package:intl/intl.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

import 'package:bluecherry_client/providers/server_provider.dart';
import 'package:bluecherry_client/providers/settings_provider.dart';
import 'package:bluecherry_client/models/server.dart';
import 'package:bluecherry_client/api/api.dart';
import 'package:bluecherry_client/utils/constants.dart';
import 'package:bluecherry_client/widgets/misc.dart';

class Settings extends StatefulWidget {
  final void Function(int) changeCurrentTab;
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
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.menu),
          splashRadius: 20.0,
          onPressed: Scaffold.of(context).openDrawer,
        ),
        title: Text(AppLocalizations.of(context).settings),
      ),
      body: SafeArea(
        bottom: false,
        child:
            ListView(padding: const EdgeInsets.only(bottom: 16.0), children: [
          SubHeader(AppLocalizations.of(context).servers),
          Consumer<ServersProvider>(builder: (context, serversProvider, _) {
            return Column(children: [
              ...serversProvider.servers
                  .map((e) => ServerTile(server: e))
                  .toList(),
              ListTile(
                leading: CircleAvatar(
                  child: const Icon(Icons.add),
                  backgroundColor: Colors.transparent,
                  foregroundColor: Theme.of(context).iconTheme.color,
                ),
                title: Text(AppLocalizations.of(context).addNewServer),
                onTap: () {
                  // Go to the "Add Server" tab.
                  widget.changeCurrentTab.call(3);
                },
              ),
            ]);
          }),
          const Padding(
            padding: EdgeInsets.only(top: 8.0),
            child: Divider(
              height: 1.0,
              thickness: 1.0,
            ),
          ),
          SubHeader(AppLocalizations.of(context).theme),
          Consumer<SettingsProvider>(builder: (context, settings, _) {
            return Column(
              children: ThemeMode.values.map((e) {
                return ListTile(
                  leading: CircleAvatar(
                    child: Icon({
                      ThemeMode.system: Icons.brightness_auto,
                      ThemeMode.light: Icons.light_mode,
                      ThemeMode.dark: Icons.dark_mode,
                    }[e]!),
                    backgroundColor: Colors.transparent,
                    foregroundColor: Theme.of(context).iconTheme.color,
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
              }).toList(),
            );
          }),
          const Padding(
            padding: EdgeInsets.only(top: 8.0),
            child: Divider(
              height: 1.0,
              thickness: 1.0,
            ),
          ),
          SubHeader(AppLocalizations.of(context).miscellaneous),
          Consumer<SettingsProvider>(builder: (context, settings, _) {
            return Column(children: [
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
                      builder: (_, child) => Theme.of(context).brightness ==
                              Brightness.dark
                          ? Theme(
                              data: ThemeData.dark().copyWith(
                                primaryColor: Theme.of(context).primaryColor,
                                colorScheme: ColorScheme.fromSwatch(
                                  primarySwatch: Colors.indigo,
                                  brightness: Brightness.dark,
                                ),
                                dialogTheme: const DialogTheme(
                                  backgroundColor: Colors.black,
                                ),
                                scaffoldBackgroundColor: Colors.black,
                              ),
                              child: TimePickerTheme(
                                data: const TimePickerThemeData(
                                  backgroundColor: Color(0xFF191919),
                                ),
                                child: child!,
                              ),
                            )
                          : child!,
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
                            SettingsProvider.instance.dateFormat
                                .format(settings.snoozedUntil),
                          SettingsProvider.instance.timeFormat
                              .format(settings.snoozedUntil),
                        ].join(' '),
                      )
                    : AppLocalizations.of(context).notSnoozed,
              ),
              Theme(
                data: Theme.of(context).copyWith(
                  dividerColor: Colors.transparent,
                ),
                child: ExpansionTile(
                  leading: CircleAvatar(
                    backgroundColor: Colors.transparent,
                    foregroundColor: Theme.of(context).iconTheme.color,
                    child: const Icon(Icons.beenhere_rounded),
                  ),
                  title: Text(
                      AppLocalizations.of(context).notificationClickAction),
                  textColor: Theme.of(context).textTheme.bodyText1?.color,
                  subtitle: Text(
                    settings.notificationClickAction.str(context),
                    style: Theme.of(context).textTheme.bodyText2?.copyWith(
                          color: Theme.of(context).textTheme.caption?.color,
                        ),
                  ),
                  children: NotificationClickAction.values.map((e) {
                    return ListTile(
                      onTap: () {
                        settings.notificationClickAction = e;
                      },
                      trailing: Radio(
                        value: e,
                        groupValue: settings.notificationClickAction,
                        onChanged: (value) {
                          settings.notificationClickAction = e;
                        },
                      ),
                      title: Padding(
                        padding: const EdgeInsets.only(left: 8.0),
                        child: Text(
                          e.str(context),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
              Theme(
                data: Theme.of(context).copyWith(
                  dividerColor: Colors.transparent,
                ),
                child: ExpansionTile(
                  leading: CircleAvatar(
                    backgroundColor: Colors.transparent,
                    foregroundColor: Theme.of(context).iconTheme.color,
                    child: const Icon(Icons.camera_alt),
                  ),
                  title: Text(AppLocalizations.of(context).cameraViewFit),
                  textColor: Theme.of(context).textTheme.bodyText1?.color,
                  subtitle: Text(
                    settings.cameraViewFit.str(context),
                    style: Theme.of(context).textTheme.bodyText2?.copyWith(
                          color: Theme.of(context).textTheme.caption?.color,
                        ),
                  ),
                  children: CameraViewFit.values.map((e) {
                    return ListTile(
                      onTap: () {
                        settings.cameraViewFit = e;
                      },
                      trailing: Radio(
                        value: e,
                        groupValue: settings.cameraViewFit,
                        onChanged: (value) {
                          settings.cameraViewFit = e;
                        },
                      ),
                      title: Padding(
                        padding: const EdgeInsets.only(left: 8.0),
                        child: Text(
                          e.str(context),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ]);
          }),
          const Padding(
            padding: EdgeInsets.only(top: 8.0),
            child: Divider(
              height: 1.0,
              thickness: 1.0,
            ),
          ),
          SubHeader(AppLocalizations.of(context).dateFormat),
          Consumer<SettingsProvider>(builder: (context, settings, _) {
            return Column(
              children: [
                'dd MMMM yyyy',
                'EEEE, dd MMMM yyyy',
                'EE, dd MMMM yyyy',
                'MM/dd/yyyy',
                'dd/MM/yyyy',
                'MM-dd-yyyy',
                'dd-MM-yyyy',
                'yyyy-MM-dd'
              ].map((e) {
                return ListTile(
                  onTap: () {
                    settings.dateFormat = DateFormat(e, 'en_US');
                  },
                  trailing: Radio(
                    value: e,
                    groupValue: settings.dateFormat.pattern,
                    onChanged: (value) {
                      settings.dateFormat = DateFormat(e, 'en_US');
                    },
                  ),
                  title: Padding(
                    padding: const EdgeInsets.only(left: 8.0),
                    child: Text(
                      DateFormat(e, 'en_US')
                          .format(DateTime.utc(1969, 7, 20, 14, 18, 04)),
                    ),
                  ),
                );
              }).toList(),
            );
          }),
          const Padding(
            padding: EdgeInsets.only(top: 8.0),
            child: Divider(
              height: 1.0,
              thickness: 1.0,
            ),
          ),
          SubHeader(AppLocalizations.of(context).timeFormat),
          Consumer<SettingsProvider>(builder: (context, settings, _) {
            return Column(
              children: [
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
                    padding: const EdgeInsets.only(left: 8.0),
                    child: Text(
                      DateFormat(e, 'en_US')
                          .format(DateTime.utc(1969, 7, 20, 14, 18, 04)),
                    ),
                  ),
                );
              }).toList(),
            );
          }),
          const Padding(
            padding: EdgeInsets.only(top: 8.0),
            child: Divider(
              height: 1.0,
              thickness: 1.0,
            ),
          ),
          SubHeader(AppLocalizations.of(context).version),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 8.0),
                Text(
                  kAppVersion,
                  style: Theme.of(context).textTheme.headline2,
                ),
                const SizedBox(height: 8.0),
                Text(
                  AppLocalizations.of(context).versionText,
                  style: Theme.of(context).textTheme.headline2,
                ),
                const SizedBox(height: 8.0),
                MaterialButton(
                  onPressed: () {
                    launchUrl(
                      Uri.https(
                        'www.bluecherrydvr.com',
                        '/',
                      ),
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
        ]),
      ),
    );
  }
}

class ServerTile extends StatefulWidget {
  final Server server;
  const ServerTile({Key? key, required this.server}) : super(key: key);

  @override
  State<ServerTile> createState() => _ServerTileState();
}

class _ServerTileState extends State<ServerTile> {
  bool fetched = false;

  @override
  void initState() {
    super.initState();
    if (widget.server.devices.isEmpty) {
      WidgetsBinding.instance.addPostFrameCallback(
        (_) async {
          await API.instance.getDevices(
            await API.instance.checkServerCredentials(widget.server),
          );
          if (mounted) {
            setState(() {
              fetched = true;
            });
          }
        },
      );
    } else {
      setState(() => fetched = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ServersProvider>(builder: (context, serversProvider, _) {
      return ListTile(
        leading: CircleAvatar(
          child: const Icon(Icons.dns),
          backgroundColor: Colors.transparent,
          foregroundColor: Theme.of(context).iconTheme.color,
        ),
        title: Text(
          widget.server.name,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Text(
          fetched
              ? [
                  if (widget.server.name != widget.server.ip) widget.server.ip,
                  AppLocalizations.of(context)
                      .nDevices(widget.server.devices.length),
                ].join(' • ')
              : AppLocalizations.of(context).gettingDevices,
          overflow: TextOverflow.ellipsis,
        ),
        trailing: IconButton(
          icon: const Icon(
            Icons.delete,
          ),
          splashRadius: 24.0,
          onPressed: () {
            showDialog(
              context: context,
              builder: (context) => AlertDialog(
                title: Text(AppLocalizations.of(context).remove),
                content: Text(
                  AppLocalizations.of(context)
                      .removeServerDescription(widget.server.name),
                  style: Theme.of(context).textTheme.headline4,
                  textAlign: TextAlign.start,
                ),
                actions: [
                  MaterialButton(
                    onPressed: Navigator.of(context).maybePop,
                    child: Text(
                      AppLocalizations.of(context).no.toUpperCase(),
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.secondary,
                      ),
                    ),
                  ),
                  MaterialButton(
                    onPressed: () {
                      serversProvider.remove(widget.server);
                      Navigator.of(context).maybePop();
                    },
                    child: Text(
                      AppLocalizations.of(context).yes.toUpperCase(),
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.secondary,
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      );
    });
  }
}

extension on NotificationClickAction {
  String str(BuildContext context) => {
        NotificationClickAction.showFullscreenCamera:
            AppLocalizations.of(context).showFullscreenCamera,
        NotificationClickAction.showEventsScreen:
            AppLocalizations.of(context).showEventsScreen,
      }[this]!;
}

extension on CameraViewFit {
  String str(BuildContext context) => {
        CameraViewFit.contain: AppLocalizations.of(context).contain,
        CameraViewFit.cover: AppLocalizations.of(context).cover,
        CameraViewFit.fill: AppLocalizations.of(context).fill,
      }[this]!;
}
