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
import 'package:bluecherry_client/providers/update_provider.dart';
import 'package:bluecherry_client/utils/constants.dart';
import 'package:bluecherry_client/utils/extensions.dart';
import 'package:bluecherry_client/utils/widgets/squared_icon_button.dart';
import 'package:bluecherry_client/widgets/misc.dart';
import 'package:bluecherry_client/widgets/servers/edit_server.dart';
import 'package:bluecherry_client/widgets/servers/edit_server_settings.dart';
import 'package:bluecherry_client/widgets/settings/shared/date_language.dart';
import 'package:bluecherry_client/widgets/settings/shared/tiles.dart';
import 'package:bluecherry_client/widgets/settings/shared/update.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_localized_locales/flutter_localized_locales.dart';
import 'package:provider/provider.dart';
import 'package:unity_video_player/unity_video_player.dart';
import 'package:url_launcher/url_launcher.dart';

part '../shared/server_tile.dart';

class MobileSettings extends StatefulWidget {
  const MobileSettings({super.key});

  @override
  State<MobileSettings> createState() => _MobileSettingsState();
}

class _MobileSettingsState extends State<MobileSettings> {
  @override
  void initState() {
    super.initState();
    SettingsProvider.instance.reloadInterface();
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final settings = context.watch<SettingsProvider>();
    final update = context.watch<UpdateManager>();
    final servers = context.watch<ServersProvider>();

    return Material(
      type: MaterialType.transparency,
      child: SafeArea(
        child: Column(children: [
          if (Scaffold.of(context).hasDrawer)
            AppBar(
              leading: MaybeUnityDrawerButton(context),
              title: Text(loc.settings),
            ),
          Expanded(
            child: CustomScrollView(slivers: [
              SliverToBoxAdapter(
                child: SubHeader(
                  loc.servers,
                  subtext: loc.nServers(servers.servers.length),
                ),
              ),
              const SliverToBoxAdapter(child: ServersList()),
              SliverToBoxAdapter(
                child: SubHeader(loc.theme, subtext: loc.themeDescription),
              ),
              SliverList.list(
                children: ThemeMode.values
                    .map((mode) => ThemeTile(themeMode: mode))
                    .toList(),
              ),
              SliverToBoxAdapter(child: SubHeader(loc.miscellaneous)),
              SliverList.list(children: [
                const SnoozeNotificationsTile(),
                const NavigationClickBehaviorTile(),
                ExpansionTile(
                  leading: CircleAvatar(
                    backgroundColor: const Color.fromRGBO(0, 0, 0, 0),
                    foregroundColor: theme.iconTheme.color,
                    child: const Icon(Icons.fit_screen),
                  ),
                  title: Text(loc.cameraViewFit),
                  textColor: theme.textTheme.bodyLarge?.color,
                  subtitle: Text(
                    settings.cameraViewFit.locale(context),
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.textTheme.bodySmall?.color,
                    ),
                  ),
                  children: UnityVideoFit.values.map((e) {
                    return RadioListTile<UnityVideoFit>.adaptive(
                      contentPadding: const EdgeInsetsDirectional.only(
                        start: 68.0,
                        end: 16.0,
                      ),
                      value: e,
                      groupValue: settings.cameraViewFit,
                      onChanged: (_) => settings.cameraViewFit = e,
                      secondary: Icon(e.icon),
                      controlAffinity: ListTileControlAffinity.trailing,
                      title: Padding(
                        padding: const EdgeInsetsDirectional.only(start: 16.0),
                        child: Text(e.locale(context)),
                      ),
                    );
                  }).toList(),
                ),
                const DirectoryChooseTile(),
                const CyclePeriodTile(),
                const CameraReloadPeriodTile(),
              ]),
              SliverToBoxAdapter(
                child: CorrectedListTile(
                  iconData: Icons.language,
                  trailing: Icons.navigate_next,
                  title: loc.dateLanguage,
                  subtitle: '${settings.dateFormat.format(DateTime.now())} '
                      '${settings.timeFormat.format(DateTime.now())}; '
                      '${LocaleNames.of(context)!.nameOf(settings.locale.toLanguageTag())}',
                  height: 80.0,
                  onTap: () {
                    showModalBottomSheet(
                      context: context,
                      showDragHandle: true,
                      isScrollControlled: true,
                      builder: (context) {
                        return DraggableScrollableSheet(
                          expand: false,
                          maxChildSize: 0.8,
                          minChildSize: 0.8,
                          initialChildSize: 0.8,
                          builder: (context, controller) {
                            return LocalizationSettings(controller: controller);
                          },
                        );
                      },
                    );
                  },
                ),
              ),
              const SliverToBoxAdapter(child: WakelockTile()),
              if (update.isUpdatingSupported) ...[
                SliverToBoxAdapter(
                  child: SubHeader(
                    loc.updates,
                    subtext: loc.runningOn(() {
                      if (Platform.isLinux) {
                        return loc.linux(UpdateManager.linuxEnvironment.name);
                      } else if (Platform.isWindows) {
                        return loc.windows;
                      }

                      return defaultTargetPlatform.name;
                    }()),
                  ),
                ),
                const SliverToBoxAdapter(child: AppUpdateCard()),
                const SliverToBoxAdapter(child: AppUpdateOptions()),
              ],
              SliverToBoxAdapter(child: SubHeader(loc.about)),
              const SliverToBoxAdapter(child: About()),
              const SliverToBoxAdapter(child: SizedBox(height: 16.0)),
            ]),
          ),
        ]),
      ),
    );
  }
}
