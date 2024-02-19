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
import 'package:bluecherry_client/screens/layouts/video_status_label.dart';
import 'package:bluecherry_client/screens/settings/settings_desktop.dart';
import 'package:bluecherry_client/screens/settings/settings_mobile.dart';
import 'package:bluecherry_client/utils/extensions.dart';
import 'package:flutter/foundation.dart';
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
      const StreamingSettings(),
      const SizedBox(height: 12.0),
      Padding(
        padding: DesktopSettings.horizontalPadding,
        child: Text('Devices Settings', style: theme.textTheme.titleMedium),
      ),
      const SizedBox(height: 8.0),
      const CamerasSettings(),
    ]);
  }
}

class StreamingSettings extends StatelessWidget {
  const StreamingSettings({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsProvider>();
    final loc = AppLocalizations.of(context);
    final theme = Theme.of(context);

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      ListTile(
        leading: CircleAvatar(
          backgroundColor: Colors.transparent,
          foregroundColor: theme.iconTheme.color,
          child: const Icon(Icons.sensors),
        ),
        title: Text(loc.streamingType),
        contentPadding: DesktopSettings.horizontalPadding,
        trailing: DropdownButton<StreamingType>(
          value: settings.streamingType,
          onChanged: (v) {
            if (v != null) {
              settings.streamingType = v;
            }
          },
          items: StreamingType.values.map((value) {
            return DropdownMenuItem(
              value: value,
              // Disable RTSP on web
              enabled: !kIsWeb || value != StreamingType.rtsp,
              child: Text(value.name.toUpperCase()),
            );
          }).toList(),
        ),
      ),
      const SizedBox(height: 8.0),
      ListTile(
        enabled: settings.streamingType == StreamingType.rtsp,
        title: Text(loc.rtspProtocol),
        leading: CircleAvatar(
          backgroundColor: Colors.transparent,
          foregroundColor: theme.iconTheme.color,
          child: const Icon(Icons.sensors),
        ),
        contentPadding: DesktopSettings.horizontalPadding,
        trailing: DropdownButton<RTSPProtocol>(
          value: settings.rtspProtocol,
          onChanged: !kIsWeb && settings.streamingType == StreamingType.rtsp
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
    ]);
  }
}

class CamerasSettings extends StatelessWidget {
  const CamerasSettings({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final settings = context.watch<SettingsProvider>();
    final loc = AppLocalizations.of(context);
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      if (!kIsWeb)
        ListTile(
          leading: CircleAvatar(
            backgroundColor: Colors.transparent,
            foregroundColor: theme.iconTheme.color,
            child: const Icon(Icons.hd),
          ),
          title: Text(loc.renderingQuality),
          subtitle: Text(loc.renderingQualityDescription),
          contentPadding: DesktopSettings.horizontalPadding,
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
      const SizedBox(height: 8.0),
      ListTile(
        leading: CircleAvatar(
          backgroundColor: Colors.transparent,
          foregroundColor: theme.iconTheme.color,
          child: const Icon(Icons.fit_screen),
        ),
        title: Text(loc.cameraViewFit),
        subtitle: Text(loc.cameraViewFitDescription),
        contentPadding: DesktopSettings.horizontalPadding,
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
      const SizedBox(height: 8.0),
      ListTile(
        leading: CircleAvatar(
          backgroundColor: Colors.transparent,
          foregroundColor: theme.iconTheme.color,
          child: const Icon(Icons.sync),
        ),
        title: const Text('Refresh Period'),
        subtitle: const Text('How often to refresh the cameras'),
        contentPadding: DesktopSettings.horizontalPadding,
        trailing: DropdownButton<Duration>(
          value: Duration.zero,
          onChanged: (v) {},
          items: const [
            Duration.zero,
            Duration(seconds: 30),
            Duration(minutes: 2),
            Duration(minutes: 5),
          ].map((q) {
            return DropdownMenuItem(
              value: q,
              child: Row(children: [
                // Icon(q.icon),
                // const SizedBox(width: 8.0),
                Text(q.humanReadableCompact(context)),
              ]),
            );
          }).toList(),
        ),
      ),
      const SizedBox(height: 8.0),
      ListTile(
        leading: CircleAvatar(
          backgroundColor: Colors.transparent,
          foregroundColor: theme.iconTheme.color,
          child: const Icon(Icons.watch_later),
        ),
        title: Text(loc.lateStreamBehavior),
        subtitle: RichText(
          text: TextSpan(
            text: loc.lateStreamBehaviorDescription,
            style: theme.textTheme.bodyMedium,
            children: [
              const TextSpan(text: '\n'),
              switch (settings.lateVideoBehavior) {
                LateVideoBehavior.automatic => TextSpan(
                    text: loc.automaticBehaviorDescription,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                LateVideoBehavior.manual => TextSpan(
                    children: [
                      ...() {
                        final list = loc
                            .manualBehaviorDescription(
                              'manualBehaviorDescription',
                            )
                            .split(' ');

                        return list.map((part) {
                          if (part == 'manualBehaviorDescription') {
                            return const WidgetSpan(
                              child: Padding(
                                padding: EdgeInsetsDirectional.only(
                                  start: 2.0,
                                  end: 6.0,
                                ),
                                child: VideoStatusLabelIndicator(
                                  status: VideoLabel.late,
                                ),
                              ),
                            );
                          } else {
                            return TextSpan(text: '$part ');
                          }
                        });
                      }()
                    ],
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                LateVideoBehavior.never => TextSpan(
                    text: loc.neverBehaviorDescription,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  )
              },
            ],
          ),
        ),
        contentPadding: DesktopSettings.horizontalPadding,
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
      const SizedBox(height: 8.0),
      CheckboxListTile.adaptive(
        secondary: CircleAvatar(
          backgroundColor: Colors.transparent,
          foregroundColor: theme.iconTheme.color,
          child: const Icon(Icons.history),
        ),
        title: const Text('Automatically reload timed out streams'),
        subtitle: const Text('When to reload timed out streams automatically'),
        contentPadding: DesktopSettings.horizontalPadding,
        value: true,
        onChanged: (v) {},
      ),
      const SizedBox(height: 8.0),
      CheckboxListTile.adaptive(
        secondary: CircleAvatar(
          backgroundColor: Colors.transparent,
          foregroundColor: theme.iconTheme.color,
          child: const Icon(Icons.memory),
        ),
        title: const Text('Hardware rendering'),
        subtitle: const Text('Use hardware rendering when available'),
        contentPadding: DesktopSettings.horizontalPadding,
        value: true,
        onChanged: (v) {},
      ),
      const SizedBox(height: 8.0),
      ListTile(
        title: const Text('Run a video test'),
        trailing: const Icon(Icons.play_arrow),
        contentPadding: DesktopSettings.horizontalPadding,
        onTap: () {},
      ),
    ]);
  }
}
