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
import 'package:bluecherry_client/utils/extensions.dart';
import 'package:bluecherry_client/widgets/settings/desktop/settings.dart';
import 'package:bluecherry_client/widgets/settings/mobile/settings.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:provider/provider.dart';
import 'package:unity_video_player/unity_video_player.dart';

class ServerSettings extends StatelessWidget {
  const ServerSettings({super.key});

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final theme = Theme.of(context);
    return ListView(padding: DesktopSettings.verticalPadding, children: [
      Padding(
        padding: DesktopSettings.horizontalPadding,
        child: Text(loc.servers, style: theme.textTheme.titleMedium),
      ),
      const ServersList(),
      const SizedBox(height: 8.0),
      Padding(
        padding: DesktopSettings.horizontalPadding,
        child: Text(loc.streamingSettings, style: theme.textTheme.titleMedium),
      ),
      const SizedBox(height: 8.0),
      const Padding(
        padding: DesktopSettings.horizontalPadding,
        child: StreamingSettings(),
      ),
      const SizedBox(height: 12.0),
      Padding(
        padding: DesktopSettings.horizontalPadding,
        child: Text(loc.camerasSettings, style: theme.textTheme.titleMedium),
      ),
      const SizedBox(height: 8.0),
      const Padding(
        padding: DesktopSettings.horizontalPadding,
        child: CamerasSettings(),
      ),
    ]);
  }
}

class StreamingSettings extends StatelessWidget {
  const StreamingSettings({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsProvider>();
    final loc = AppLocalizations.of(context);

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Material(
        borderRadius: BorderRadius.circular(6.0),
        child: ListTile(
          title: Text(loc.streamingType),
          trailing: DropdownButton<StreamingType>(
            value: settings.streamingType,
            onChanged: (v) {
              if (v != null) {
                settings.streamingType = v;
              }
            },
            items: StreamingType.values.map((q) {
              return DropdownMenuItem(
                value: q,
                child: Text(q.name.toUpperCase()),
              );
            }).toList(),
          ),
        ),
      ),
      const SizedBox(height: 8.0),
      Material(
        borderRadius: BorderRadius.circular(6.0),
        child: ListTile(
          enabled: settings.streamingType == StreamingType.rtsp,
          title: Text(loc.rtspProtocol),
          trailing: DropdownButton<RTSPProtocol>(
            value: settings.rtspProtocol,
            onChanged: settings.streamingType == StreamingType.rtsp
                ? (v) {
                    if (v != null) {
                      settings.rtspProtocol = v;
                    }
                  }
                : null,
            items: RTSPProtocol.values.map((p) {
              return DropdownMenuItem(
                value: p,
                child: Text(p.name.toUpperCase()),
              );
            }).toList(),
          ),
        ),
      ),
    ]);
  }
}

class CamerasSettings extends StatelessWidget {
  const CamerasSettings({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsProvider>();
    final loc = AppLocalizations.of(context);
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Material(
        borderRadius: BorderRadius.circular(6.0),
        child: ListTile(
          title: Text(loc.renderingQuality),
          subtitle: Text(loc.renderingQualityDescription),
          trailing: DropdownButton<RenderingQuality>(
            value: settings.videoQuality,
            onChanged: (v) {
              if (v != null) {
                settings.videoQuality = v;
              }
            },
            items: RenderingQuality.values.map((q) {
              return DropdownMenuItem(
                value: q,
                child: Text(q.locale(context)),
              );
            }).toList(),
          ),
        ),
      ),
      const SizedBox(height: 8.0),
      Material(
        borderRadius: BorderRadius.circular(6.0),
        child: ListTile(
          title: Text(loc.cameraViewFit),
          subtitle: Text(loc.cameraViewFitDescription),
          trailing: DropdownButton<UnityVideoFit>(
            value: settings.cameraViewFit,
            onChanged: (v) {
              if (v != null) {
                settings.cameraViewFit = v;
              }
            },
            items: UnityVideoFit.values.map((q) {
              return DropdownMenuItem(
                value: q,
                child: Row(children: [
                  Icon(q.icon),
                  const SizedBox(width: 8.0),
                  Text(q.locale(context)),
                ]),
              );
            }).toList(),
          ),
        ),
      ),
      const SizedBox(height: 8.0),
      Material(
        borderRadius: BorderRadius.circular(6.0),
        child: ListTile(
          title: const Text('Late Stream Behavior'),
          subtitle: const Text('What to do when a stream is late'),
          trailing: DropdownButton<LateVideoBehavior>(
            value: settings.lateVideoBehavior,
            onChanged: (v) {
              if (v != null) {
                settings.lateVideoBehavior = v;
              }
            },
            items: LateVideoBehavior.values.map((q) {
              return DropdownMenuItem(
                value: q,
                child: Row(children: [
                  Icon(q.icon),
                  const SizedBox(width: 8.0),
                  Text(q.locale(context)),
                ]),
              );
            }).toList(),
          ),
        ),
      ),
    ]);
  }
}
