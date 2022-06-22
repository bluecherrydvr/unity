/*
 * This file is a part of Bluecherry Client (https://https://github.com/bluecherrydvr/bluecherry_client).
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

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:easy_localization/easy_localization.dart';

import 'package:bluecherry_client/providers/server_provider.dart';
import 'package:bluecherry_client/providers/settings_provider.dart';
import 'package:bluecherry_client/models/server.dart';
import 'package:bluecherry_client/api/api.dart';
import 'package:bluecherry_client/utils/constants.dart';

class Settings extends StatefulWidget {
  const Settings({Key? key}) : super(key: key);

  @override
  State<Settings> createState() => _SettingsState();
}

class _SettingsState extends State<Settings> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.menu),
          splashRadius: 20.0,
          onPressed: Scaffold.of(context).openDrawer,
        ),
        title: Text('settings'.tr()),
        // actions: [
        //   IconButton(
        //     icon: const Icon(Icons.info),
        //     splashRadius: 20.0,
        //     onPressed: () {},
        //   ),
        // ],
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: 16.0),
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 24.0,
              vertical: 12.0,
            ),
            child: Text(
              'servers'.tr().toUpperCase(),
              style: Theme.of(context).textTheme.overline?.copyWith(
                    fontWeight: FontWeight.w500,
                    color: Theme.of(context).iconTheme.color,
                  ),
            ),
          ),
          Consumer<ServersProvider>(
            builder: (context, serversProvider, _) =>
                serversProvider.servers.isEmpty
                    ? Center(
                        child: Container(
                          alignment: Alignment.center,
                          height: 72.0,
                          child: Text(
                            'no_servers_added'.tr(),
                            style: Theme.of(context).textTheme.headline5,
                          ),
                        ),
                      )
                    : Column(
                        children: serversProvider.servers
                            .map((e) => ServerTile(server: e))
                            .toList(),
                      ),
          ),
          const Divider(),
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 24.0,
              vertical: 12.0,
            ),
            child: Text(
              'theme'.tr().toUpperCase(),
              style: Theme.of(context).textTheme.overline?.copyWith(
                    fontWeight: FontWeight.w500,
                    color: Theme.of(context).iconTheme.color,
                  ),
            ),
          ),
          Consumer<SettingsProvider>(
            builder: (context, settings, _) => Column(
              children: ThemeMode.values
                  .map(
                    (e) => ListTile(
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
                      title: Text(e.name.tr()),
                    ),
                  )
                  .toList(),
            ),
          ),
          const Divider(),
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 24.0,
              vertical: 12.0,
            ),
            child: Text(
              'date_format'.tr().toUpperCase(),
              style: Theme.of(context).textTheme.overline?.copyWith(
                    fontWeight: FontWeight.w500,
                    color: Theme.of(context).iconTheme.color,
                  ),
            ),
          ),
          Consumer<SettingsProvider>(
            builder: (context, settings, _) => Column(
              children: [
                'dd MMMM yyyy',
                'EEEE, dd MMMM yyyy',
                'EE, dd MMMM yyyy',
                'MM/dd/yyyy',
                'dd/MM/yyyy',
                'MM-dd-yyyy',
                'dd-MM-yyyy',
                'yyyy-MM-dd'
              ]
                  .map(
                    (e) => ListTile(
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
                    ),
                  )
                  .toList(),
            ),
          ),
          const Divider(),
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 24.0,
              vertical: 12.0,
            ),
            child: Text(
              'time_format'.tr().toUpperCase(),
              style: Theme.of(context).textTheme.overline?.copyWith(
                    fontWeight: FontWeight.w500,
                    color: Theme.of(context).iconTheme.color,
                  ),
            ),
          ),
          Consumer<SettingsProvider>(
            builder: (context, settings, _) => Column(
              children: [
                'HH:mm',
                'hh:mm a',
              ]
                  .map(
                    (e) => ListTile(
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
                    ),
                  )
                  .toList(),
            ),
          ),
          const Divider(),
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 24.0,
              vertical: 12.0,
            ),
            child: Text(
              'version'.tr().toUpperCase(),
              style: Theme.of(context).textTheme.overline?.copyWith(
                    fontWeight: FontWeight.w500,
                    color: Theme.of(context).iconTheme.color,
                  ),
            ),
          ),
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
                  'version_text'.tr(),
                  style: Theme.of(context).textTheme.headline2,
                ),
                const SizedBox(height: 8.0),
                MaterialButton(
                  onPressed: () {
                    launchUrl(
                      Uri.https(
                        'www.bluecherry.com',
                        '/',
                      ),
                    );
                  },
                  padding: EdgeInsets.zero,
                  minWidth: 0.0,
                  child: Text(
                    'website'.tr().toUpperCase(),
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Text(
          //   'ヾ(＠⌒ー⌒＠)ノ',
          //   style: Theme.of(context).textTheme.headline5?.copyWith(
          //         fontSize: 20.0,
          //       ),
          // ),
          // const SizedBox(height: 12.0),
          // Text(
          //   'Nothing here yet.',
          //   style: Theme.of(context)
          //       .textTheme
          //       .headline5
          //       ?.copyWith(fontSize: 16.0),
          // ),
        ],
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
  @override
  void initState() {
    super.initState();
    if (widget.server.devices.isEmpty) {
      WidgetsBinding.instance.addPostFrameCallback(
        (_) async {
          await API.instance.getDevices(
            await API.instance.checkServerCredentials(widget.server),
          );
          setState(() {});
        },
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ServersProvider>(
      builder: (context, serversProvider, _) => ListTile(
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
          [
            if (widget.server.name != widget.server.ip) widget.server.ip,
            'n_devices'.tr(args: [widget.server.devices.length.toString()]),
          ].join(' • '),
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
                title: Text('remove'.tr()),
                content: Text(
                  'remove_server_description'.tr(
                    args: [widget.server.name],
                  ),
                  style: Theme.of(context).textTheme.headline4,
                  textAlign: TextAlign.start,
                ),
                actions: [
                  MaterialButton(
                    onPressed: Navigator.of(context).pop,
                    child: Text(
                      'no'.tr().toUpperCase(),
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.secondary,
                      ),
                    ),
                  ),
                  MaterialButton(
                    onPressed: () {
                      serversProvider.remove(widget.server);
                    },
                    child: Text(
                      'yes'.tr().toUpperCase(),
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
      ),
    );
  }
}
