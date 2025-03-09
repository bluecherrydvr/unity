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

import 'package:bluecherry_client/models/device.dart';
import 'package:bluecherry_client/models/server.dart';
import 'package:bluecherry_client/providers/settings_provider.dart';
import 'package:bluecherry_client/screens/layouts/desktop/viewport.dart';
import 'package:bluecherry_client/screens/layouts/video_status_label.dart';
import 'package:bluecherry_client/screens/settings/settings_desktop.dart';
import 'package:bluecherry_client/screens/settings/settings_mobile.dart';
import 'package:bluecherry_client/screens/settings/shared/options_chooser_tile.dart';
import 'package:bluecherry_client/utils/extensions.dart';
import 'package:bluecherry_client/utils/methods.dart';
import 'package:bluecherry_client/widgets/misc.dart';
import 'package:bluecherry_client/widgets/video_test.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:provider/provider.dart';
import 'package:unity_video_player/unity_video_player.dart';

class ServerAndDevicesSettings extends StatelessWidget {
  const ServerAndDevicesSettings({super.key});

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    return ListView(
      children: [
        SubHeader(loc.servers, padding: DesktopSettings.horizontalPadding),
        const ServersList(),
        SubHeader(
          loc.serverSettings,
          padding: DesktopSettings.horizontalPadding,
        ),
        const ServerSettings(),
        SubHeader(
          loc.streamingSettings,
          padding: DesktopSettings.horizontalPadding,
        ),
        const StreamingSettings(),
        SubHeader(
          loc.matrixMagnification,
          padding: DesktopSettings.horizontalPadding,
        ),
        AreaMagnificationSettings(),
        SubHeader(
          loc.devicesSettings,
          padding: DesktopSettings.horizontalPadding,
        ),
        const DevicesSettings(),
      ],
    );
  }
}

class ServerSettings extends StatelessWidget {
  const ServerSettings({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final settings = context.watch<SettingsProvider>();
    final loc = AppLocalizations.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CheckboxListTile.adaptive(
          title: Text(loc.connectToServerAutomaticallyAtStartup),
          subtitle: Text(loc.connectToServerAutomaticallyAtStartupDescription),
          secondary: CircleAvatar(
            backgroundColor: Colors.transparent,
            foregroundColor: theme.iconTheme.color,
            child: const Icon(Icons.connect_without_contact),
          ),
          contentPadding: DesktopSettings.horizontalPadding,
          value: settings.kConnectAutomaticallyAtStartup.value,
          onChanged: (v) {
            if (v != null) {
              settings.kConnectAutomaticallyAtStartup.value = v;
            }
          },
        ),
        CheckboxListTile.adaptive(
          title: Text(loc.allowUntrustedCertificates),
          subtitle: Text(loc.allowUntrustedCertificatesDescription),
          secondary: CircleAvatar(
            backgroundColor: Colors.transparent,
            foregroundColor: theme.iconTheme.color,
            child: const Icon(Icons.approval),
          ),
          contentPadding: DesktopSettings.horizontalPadding,
          value: settings.kAllowUntrustedCertificates.value,
          onChanged: (v) {
            if (v != null) {
              settings.kAllowUntrustedCertificates.value = v;
            }
          },
        ),
        OptionsChooserTile<int>(
          title: loc.addServerTimeout,
          description: loc.addServerTimeoutDescription,
          icon: Icons.av_timer,
          value: settings.kAddServerTimeout.value.inSeconds,
          values: [
            Option(value: 15, text: '15s'),
            Option(value: 30, text: '30s'),
            Option(value: 45, text: '45s'),
            Option(value: 60, text: '60s'),
          ],
          onChanged: (v) {
            settings.kAddServerTimeout.value = Duration(seconds: v);
          },
        ),
      ],
    );
  }
}

class StreamingSettings extends StatelessWidget {
  const StreamingSettings({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final settings = context.watch<SettingsProvider>();
    final loc = AppLocalizations.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        OptionsChooserTile(
          title: loc.preferredStreamingProtocol,
          subtitle: Text(loc.preferredStreamingProtocolDescription),
          icon: Icons.live_tv,
          value: settings.kStreamingType.value,
          values: StreamingType.values.map((type) {
            return Option(
              value: type,
              // Disable RTSP on web
              enabled: !kIsWeb || type != StreamingType.rtsp,
              text: type.name.toUpperCase(),
            );
          }),
          onChanged: (v) {
            settings.kStreamingType.value = v;
          },
        ),
        const SizedBox(height: 8.0),
        OptionsChooserTile<RTSPProtocol>(
          title: loc.rtspProtocol,
          icon: Icons.settings_input_antenna,
          value: settings.kRTSPProtocol.value,
          values: RTSPProtocol.values.map((protocol) {
            return Option(value: protocol, text: protocol.name.toUpperCase());
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
            values: RenderingQuality.values.map((quality) {
              return Option(value: quality, text: quality.locale(context));
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
          values: UnityVideoFit.values.map((fit) {
            return Option(value: fit, text: fit.locale(context));
          }),
          onChanged: (v) {
            settings.kVideoFit.value = v;
          },
        ),
        const SizedBox(height: 8.0),
        OptionsChooserTile(
          title: loc.streamRefreshPeriod,
          description: loc.streamRefreshPeriodDescription,
          icon: Icons.sync,
          value: settings.kRefreshRate.value,
          values: const [
            Duration.zero,
            Duration(seconds: 30),
            Duration(minutes: 2),
            Duration(minutes: 5),
          ].map((period) {
            return Option(
              value: period,
              text: period.humanReadableCompact(context),
            );
          }),
          onChanged: (v) {
            settings.kRefreshRate.value = v;
          },
        ),
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
                      }(),
                    ],
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  LateVideoBehavior.never => TextSpan(
                    text: loc.neverBehaviorDescription,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                },
              ],
            ),
          ),
          icon: Icons.watch_later,
          value: settings.kLateStreamBehavior.value,
          values: LateVideoBehavior.values.map((behavior) {
            return Option(value: behavior, text: behavior.locale(context));
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
            subtitle: const Text(
              'When to reload timed out streams automatically',
            ),
            contentPadding: DesktopSettings.horizontalPadding,
            value: settings.kReloadTimedOutStreams.value,
            onChanged: (v) {
              if (v != null) {
                settings.kReloadTimedOutStreams.value = v;
              }
            },
          ),
          const SizedBox(height: 8.0),
          /* 
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
        */
        ],
      ],
    );
  }
}

class DevicesSettings extends StatefulWidget {
  const DevicesSettings({super.key});

  @override
  State<DevicesSettings> createState() => _DevicesSettingsState();
}

class _DevicesSettingsState extends State<DevicesSettings> {
  final _testPlayer = UnityVideoPlayer.create();

  @override
  void dispose() {
    _testPlayer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final settings = context.watch<SettingsProvider>();
    final theme = Theme.of(context);

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CheckboxListTile.adaptive(
          secondary: CircleAvatar(
            backgroundColor: Colors.transparent,
            foregroundColor: theme.colorScheme.error,
            child: const Icon(Icons.videocam_off),
          ),
          title: Text(loc.listOfflineDevices),
          subtitle: Text(loc.listOfflineDevicesDescriptions),
          contentPadding: DesktopSettings.horizontalPadding,
          value: settings.kListOfflineDevices.value,
          onChanged: (v) {
            if (v != null) {
              settings.kListOfflineDevices.value = v;
            }
          },
        ),
        const SizedBox(height: 8.0),
        ListTile(
          leading: CircleAvatar(
            backgroundColor: Colors.transparent,
            foregroundColor: theme.iconTheme.color,
            child: const Icon(Icons.equalizer),
          ),
          contentPadding: DesktopSettings.horizontalPadding,
          title: Text(loc.initialDeviceVolume),
          subtitle: Text(
            '${(settings.kInitialDevicesVolume.value * 100).toInt()}%',
          ),
          trailing: SizedBox(
            width: 160.0,
            child: Slider(
              value: settings.kInitialDevicesVolume.value.clamp(
                settings.kInitialDevicesVolume.min!,
                settings.kInitialDevicesVolume.max!,
              ),
              min: settings.kInitialDevicesVolume.min!,
              max: settings.kInitialDevicesVolume.max!,
              onChanged: (v) {
                settings.kInitialDevicesVolume.value = v;
              },
            ),
          ),
        ),
        const SizedBox(height: 8.0),
        ListTile(
          leading: CircleAvatar(
            backgroundColor: Colors.transparent,
            foregroundColor: theme.iconTheme.color,
            child: const Icon(Icons.ondemand_video),
          ),
          title: Text(loc.runVideoTest),
          subtitle: Text(loc.runVideoTestDescription),
          trailing: const Icon(Icons.play_arrow),
          contentPadding: DesktopSettings.horizontalPadding,
          onTap: () => _runVideoTest(context),
        ),
        if (isDesktop) ...[
          const SizedBox(height: 8.0),
          Card(
            margin: DesktopSettings.horizontalPadding,
            child: AspectRatio(
              aspectRatio: 16 / 9,
              child: DesktopTileViewport(
                controller: _testPlayer,
                device: Device.dump(name: 'Camera Viewport', id: 1)
                  ..server = Server.dump(name: 'Server Name'),
                onFitChanged: (_) {},
                showDebugInfo: true,
              ),
            ),
          ),
          const SizedBox(height: 8.0),
          OptionsChooserTile<DisplayOn>(
            title: 'Show Camera Name',
            icon: Icons.camera_outlined,
            value: settings.kShowCameraNameOn.value,
            values: DisplayOn.options(context),
            onChanged: (v) => settings.kShowCameraNameOn.value = v,
          ),
          OptionsChooserTile<DisplayOn>(
            title: 'Show Server Name',
            icon: Icons.dvr,
            value: settings.kShowServerNameOn.value,
            values: DisplayOn.options(context),
            onChanged: (v) => settings.kShowServerNameOn.value = v,
          ),
          OptionsChooserTile<DisplayOn>(
            title: 'Show Video Status Label',
            icon: Icons.dvr,
            value: settings.kShowVideoStatusLabelOn.value,
            values: DisplayOn.options(context),
            onChanged: (v) => settings.kShowVideoStatusLabelOn.value = v,
          ),
          const SizedBox(height: 20.0),
        ],
      ],
    );
  }

  void _runVideoTest(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) {
        return const VideoTest();
      },
    );
  }
}

class AreaMagnificationSettings extends StatelessWidget {
  const AreaMagnificationSettings({super.key});

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final settings = context.watch<SettingsProvider>();
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        CheckboxListTile.adaptive(
          secondary: CircleAvatar(
            backgroundColor: Colors.transparent,
            foregroundColor: theme.iconTheme.color,
            child: const Icon(Icons.crop),
          ),
          contentPadding: DesktopSettings.horizontalPadding,
          title: Text(loc.matrixedViewMagnification),
          subtitle: Text(loc.matrixedViewMagnificationDescription),
          value: settings.kMatrixedZoomEnabled.value,
          onChanged: (value) {
            if (value != null) {
              settings.kMatrixedZoomEnabled.value = value;
            }
          },
        ),
        OptionsChooserTile<MatrixType>(
          title: loc.defaultMatrixSize,
          icon: Icons.view_quilt,
          value: settings.kMatrixSize.value,
          values: MatrixType.values.map((size) {
            return Option(value: size, text: size.toString());
          }),
          onChanged: (v) {
            settings.kMatrixSize.value = v;
          },
        ),
        CheckboxListTile.adaptive(
          contentPadding: DesktopSettings.horizontalPadding,
          secondary: CircleAvatar(
            backgroundColor: Colors.transparent,
            foregroundColor: theme.iconTheme.color,
            child: const Icon(Icons.zoom_in_map),
          ),
          title: Text(loc.softwareMagnification),
          subtitle: Text(
            isMacOS
                ? loc.softwareMagnificationDescriptionMacOS
                : loc.softwareMagnificationDescription,
          ),
          value: settings.kSoftwareZooming.value,
          onChanged:
              isMacOS
                  ? null
                  : (v) {
                    if (v != null) {
                      settings.kSoftwareZooming.value = v;
                    }
                  },
          dense: false,
        ),
        CheckboxListTile.adaptive(
          contentPadding: DesktopSettings.horizontalPadding,
          secondary: CircleAvatar(
            backgroundColor: Colors.transparent,
            foregroundColor: theme.iconTheme.color,
            child: const Icon(Icons.center_focus_weak),
          ),
          title: Text(loc.eventMagnification),
          subtitle: Text(loc.eventMagnificationDescription),
          value: settings.kEventsMatrixedZoom.value,
          onChanged: (v) {
            if (v != null) {
              settings.kEventsMatrixedZoom.value = v;
            }
          },
          dense: false,
        ),
      ],
    );
  }
}
