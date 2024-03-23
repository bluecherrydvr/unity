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
import 'package:bluecherry_client/screens/settings/shared/options_chooser_tile.dart';
import 'package:bluecherry_client/utils/extensions.dart';
import 'package:bluecherry_client/widgets/misc.dart';
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
    return ListView(children: [
      SubHeader(loc.servers),
      const ServersList(),
      const SizedBox(height: 8.0),
      SubHeader(loc.streamingSettings),
      const SizedBox(height: 8.0),
      const StreamingSettings(),
      const SizedBox(height: 12.0),
    ]);
  }
}

class StreamingSettings extends StatelessWidget {
  const StreamingSettings({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final settings = context.watch<SettingsProvider>();
    final loc = AppLocalizations.of(context);

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      OptionsChooserTile(
        title: loc.streamingType,
        icon: Icons.sensors,
        value: settings.kStreamingType.value,
        values: StreamingType.values.map((value) {
          return Option(
            value: value,
            // Disable RTSP on web
            enabled: !kIsWeb || value != StreamingType.rtsp,
            text: value.name.toUpperCase(),
          );
        }),
        onChanged: (v) {
          settings.kStreamingType.value = v;
        },
      ),
      const SizedBox(height: 8.0),
      OptionsChooserTile<RTSPProtocol>(
        title: loc.rtspProtocol,
        icon: Icons.sensors,
        value: settings.kRTSPProtocol.value,
        values: RTSPProtocol.values.map((value) {
          return Option(
            value: value,
            text: value.name.toUpperCase(),
          );
        }),
        onChanged:
            !kIsWeb && settings.kStreamingType.value == StreamingType.rtsp
                ? (v) {
                    settings.kRTSPProtocol.value = v;
                  }
                : null,
      ),
      if (!kIsWeb)
        OptionsChooserTile(
          title: loc.renderingQuality,
          description: loc.renderingQualityDescription,
          icon: Icons.hd,
          value: settings.kRenderingQuality.value,
          values: RenderingQuality.values.map((value) {
            return Option(
              value: value,
              text: value.locale(context),
            );
          }),
          onChanged: (v) {
            settings.kRenderingQuality.value = v;
          },
        ),
      const SizedBox(height: 8.0),
      OptionsChooserTile(
        title: loc.cameraViewFit,
        description: loc.cameraViewFitDescription,
        icon: Icons.fit_screen,
        value: settings.kVideoFit.value,
        values: UnityVideoFit.values.map((value) {
          return Option(
            value: value,
            text: value.locale(context),
          );
        }),
        onChanged: (v) {
          settings.kVideoFit.value = v;
        },
      ),
      if (settings.kShowDebugInfo.value) ...[
        const SizedBox(height: 8.0),
        OptionsChooserTile(
          title: 'Refresh Period',
          description: 'How often to refresh the cameras',
          icon: Icons.sync,
          value: settings.kRefreshRate.value,
          values: const [
            Duration.zero,
            Duration(seconds: 30),
            Duration(minutes: 2),
            Duration(minutes: 5),
          ].map((q) {
            return Option(
              value: q,
              text: q.humanReadableCompact(context),
            );
          }),
          onChanged: (v) {
            settings.kRefreshRate.value = v;
          },
        ),
      ],
      const SizedBox(height: 8.0),
      OptionsChooserTile<LateVideoBehavior>(
        title: loc.lateStreamBehavior,
        description: loc.lateStreamBehaviorDescription,
        subtitle: RichText(
          text: TextSpan(
            text: loc.lateStreamBehaviorDescription,
            style: theme.textTheme.bodyMedium,
            children: [
              const TextSpan(text: '\n'),
              switch (settings.kLateStreamBehavior.value) {
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
        icon: Icons.watch_later,
        value: settings.kLateStreamBehavior.value,
        values: LateVideoBehavior.values.map((value) {
          return Option(
            value: value,
            text: value.locale(context),
          );
        }),
        onChanged: (v) {
          settings.kLateStreamBehavior.value = v;
        },
      ),
      const SizedBox(height: 8.0),
      if (settings.kShowDebugInfo.value) ...[
        CheckboxListTile.adaptive(
          secondary: CircleAvatar(
            backgroundColor: Colors.transparent,
            foregroundColor: theme.iconTheme.color,
            child: const Icon(Icons.history),
          ),
          title: const Text('Automatically reload timed out streams'),
          subtitle:
              const Text('When to reload timed out streams automatically'),
          contentPadding: DesktopSettings.horizontalPadding,
          value: settings.kReloadTimedOutStreams.value,
          onChanged: (v) {
            if (v != null) {
              settings.kReloadTimedOutStreams.value = v;
            }
          },
        ),
        const SizedBox(height: 8.0),
        CheckboxListTile.adaptive(
          secondary: CircleAvatar(
            backgroundColor: Colors.transparent,
            foregroundColor: theme.iconTheme.color,
            child: const Icon(Icons.memory),
          ),
          title: const Text('Hardware decoding'),
          subtitle: const Text(
            'Use hardware decoding when available. This improves the '
            'performance of the video streams and reduce the CPU usage. '
            'If not supported, it will fall back to software rendering. ',
          ),
          isThreeLine: true,
          contentPadding: DesktopSettings.horizontalPadding,
          value: settings.kUseHardwareDecoding.value,
          onChanged: (v) {
            if (v != null) {
              settings.kUseHardwareDecoding.value = v;
            }
          },
        ),
        const SizedBox(height: 8.0),
        ListTile(
          title: const Text('Run a video test'),
          trailing: const Icon(Icons.play_arrow),
          contentPadding: DesktopSettings.horizontalPadding,
          onTap: () {},
        ),
      ],
    ]);
  }
}
