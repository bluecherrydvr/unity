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

import 'package:bluecherry_client/l10n/generated/app_localizations.dart';
import 'package:bluecherry_client/models/device.dart';
import 'package:bluecherry_client/providers/layouts_provider.dart';
import 'package:bluecherry_client/providers/settings_provider.dart';
import 'package:bluecherry_client/screens/layouts/desktop/multicast_view.dart';
import 'package:bluecherry_client/screens/layouts/desktop/stream_data.dart';
import 'package:bluecherry_client/screens/layouts/video_status_label.dart';
import 'package:bluecherry_client/screens/multi_window/window.dart';
import 'package:bluecherry_client/utils/methods.dart';
import 'package:bluecherry_client/utils/video_player.dart';
import 'package:bluecherry_client/utils/window.dart';
import 'package:bluecherry_client/widgets/error_warning.dart';
import 'package:bluecherry_client/widgets/hover_button.dart';
import 'package:bluecherry_client/widgets/misc.dart';
import 'package:bluecherry_client/widgets/ptz.dart';
import 'package:bluecherry_client/widgets/squared_icon_button.dart';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as path;
import 'package:provider/provider.dart';
import 'package:unity_video_player/unity_video_player.dart';

class DesktopDeviceTile extends StatefulWidget {
  const DesktopDeviceTile({super.key, required this.device});

  final Device device;

  @override
  State<DesktopDeviceTile> createState() => _DesktopDeviceTileState();
}

class _DesktopDeviceTileState extends State<DesktopDeviceTile> {
  late UnityVideoFit fit =
      widget.device.server.additionalSettings.videoFit ??
      SettingsProvider.instance.kVideoFit.value;

  @override
  Widget build(BuildContext context) {
    // watch for changes in the players list. usually happens when reloading
    // or releasing a device
    context.watch<UnityPlayers>();
    final videoPlayer = UnityPlayers.players[widget.device.uuid];

    if (videoPlayer == null) {
      return Card(
        clipBehavior: Clip.hardEdge,
        child: DesktopTileViewport(
          controller: null,
          device: widget.device,
          onFitChanged: (fit) => setState(() => this.fit = fit),
        ),
      );
    }

    return UnityVideoView(
      key: ValueKey(widget.device.fullName),
      heroTag: widget.device.streamURL,
      player: videoPlayer,
      fit: fit,
      paneBuilder: (context, controller) {
        return DesktopTileViewport(
          controller: controller,
          device: widget.device,
          onFitChanged: (fit) => setState(() => this.fit = fit),
        );
      },
    );
  }
}

class DesktopTileViewport extends StatefulWidget {
  final UnityVideoPlayer? controller;
  final Device device;
  final ValueChanged<UnityVideoFit> onFitChanged;
  final bool? showDebugInfo;

  const DesktopTileViewport({
    super.key,
    required this.controller,
    required this.device,
    required this.onFitChanged,
    this.showDebugInfo,
  });

  @override
  State<DesktopTileViewport> createState() => _DesktopTileViewportState();
}

class _DesktopTileViewportState extends State<DesktopTileViewport> {
  bool ptzEnabled = false;

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final view = context.watch<LayoutsProvider>();
    final settings = context.watch<SettingsProvider>();
    var video = UnityVideoView.maybeOf(context);
    final isSubView = AlternativeWindow.maybeOf(context) != null;
    final showDebugInfo = widget.showDebugInfo ?? settings.kShowDebugInfo.value;

    if (showDebugInfo && widget.controller != null) {
      video ??= VideoViewInheritance(
        error: null,
        position: Duration.zero,
        duration: Duration.zero,
        lastImageUpdate: DateTime.now(),
        fps: 0,
        player: widget.controller!,
        fit: UnityVideoFit.fill,
        child: const SizedBox.shrink(),
      );
    }

    Widget foreground = PTZController(
      enabled: ptzEnabled,
      device: widget.device,
      builder: (context, commands, constraints) {
        final states = HoverButton.of(context).states;

        final fit =
            context.findAncestorWidgetOfExactType<UnityVideoView>()?.fit ??
            widget.device.server.additionalSettings.videoFit ??
            settings.kVideoFit.value;

        return Stack(
          children: [
            Positioned.fill(child: MulticastViewport(device: widget.device)),
            if (video?.error != null)
              Positioned.fill(child: ErrorWarning(message: video!.error!)),
            IgnorePointer(
              child: Padding(
                padding: const EdgeInsetsDirectional.symmetric(
                  horizontal: 12.0,
                  vertical: 8.0,
                ),
                child: RichText(
                  text: TextSpan(
                    style: theme.textTheme.labelLarge?.copyWith(
                      color: Colors.white,
                      shadows: outlinedText(),
                    ),
                    children: [
                      settings.kShowCameraNameOn.value.build(
                        TextSpan(text: widget.device.name),
                        const TextSpan(),
                        states,
                      ),
                      settings.kShowServerNameOn.value.build(
                        TextSpan(
                          text: () {
                            String? nameToDisplay;
                            try {
                              nameToDisplay ??=
                                  widget.device.externalData?.rackName;
                              if (widget.device.server.isDump) {
                                nameToDisplay ??= path.basename(
                                  widget.device.url ?? widget.device.streamURL,
                                );
                              } else {
                                nameToDisplay ??= widget.device.server.name;
                              }
                              return '\n$nameToDisplay';
                            } catch (error) {
                              return '\n${loc.unknown}';
                            }
                          }(),
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: Colors.white,
                            shadows: outlinedText(),
                          ),
                        ),
                        const TextSpan(),
                        states,
                      ),
                      if (states.isHovering && showDebugInfo)
                        TextSpan(
                          text:
                              '\nsource: ${video?.player.dataSource ?? loc.unknown}'
                              '\nposition: ${video?.player.currentPos}'
                              '\nduration ${video?.player.duration}',
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: Colors.white,
                            shadows: outlinedText(),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
            PositionedDirectional(
              end: 16.0,
              top: 50.0,
              child: PTZData(commands: commands),
            ),
            if (video != null) ...[
              PositionedDirectional(
                end: 0,
                start: 0,
                bottom: 4.0,
                child: DeviceOptions(
                  device: widget.device,
                  onPTZEnabledChanged: (enabled) {
                    setState(() => ptzEnabled = enabled);
                  },
                  onFitChanged: widget.onFitChanged,
                ),
              ),
              if (!isSubView &&
                  view.currentLayout.devices.contains(widget.device))
                PositionedDirectional(
                  top: 4.0,
                  end: 4.0,
                  child: AnimatedOpacity(
                    opacity: !states.isHovering ? 0 : 1,
                    duration: const Duration(milliseconds: 200),
                    curve: Curves.easeInOut,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        SquaredIconButton(
                          icon: Icon(
                            moreIconData,
                            shadows: outlinedIcon(),
                            color: Colors.white,
                          ),
                          tooltip: loc.more,
                          onPressed: () async {
                            final device = await showStreamDataDialog(
                              context,
                              device: widget.device,
                              ptzEnabled: ptzEnabled,
                              onPTZEnabledChanged:
                                  (enabled) => setState(() {
                                    ptzEnabled = enabled;
                                  }),
                              fit: fit,
                              onFitChanged: widget.onFitChanged,
                            );
                            if (device != null && mounted) {
                              view.updateDevice(
                                widget.device,
                                device,
                                reload:
                                    device.url != widget.device.url ||
                                    device.preferredStreamingType !=
                                        widget.device.preferredStreamingType,
                              );
                            }
                          },
                        ),
                        SquaredIconButton(
                          icon: Icon(
                            Icons.close_outlined,
                            color: theme.colorScheme.error,
                          ),
                          tooltip: loc.removeCamera,
                          onPressed: () => view.remove(widget.device),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ],
        );
      },
    );

    return TooltipTheme(
      data: TooltipTheme.of(context).copyWith(
        preferBelow: false,
        verticalOffset: 20.0,
        decoration: BoxDecoration(
          color:
              theme.brightness == Brightness.light
                  ? Colors.black
                  : Colors.white,
          borderRadius:
              isMobile
                  ? BorderRadius.circular(16.0)
                  : BorderRadius.circular(6.0),
        ),
      ),
      child: foreground,
    );
  }
}

class DeviceOptions extends StatefulWidget {
  final Device device;
  final ValueChanged<bool> onPTZEnabledChanged;
  final ValueChanged<UnityVideoFit> onFitChanged;
  final bool isFullScreen;

  const DeviceOptions({
    super.key,
    required this.device,
    required this.onPTZEnabledChanged,
    required this.onFitChanged,
    this.isFullScreen = false,
  });

  @override
  State<DeviceOptions> createState() => _DeviceOptionsState();
}

class _DeviceOptionsState extends State<DeviceOptions> {
  @override
  Widget build(BuildContext context) {
    final states = HoverButton.of(context).states;
    final loc = AppLocalizations.of(context);
    final settings = context.watch<SettingsProvider>();
    final video = UnityVideoView.of(context);
    final controller = video.player;
    final isAlternativeWindow = AlternativeWindow.maybeOf(context) != null;
    final ptzEnabled = PTZController.of(context).enabled;

    final reloadButton = SquaredIconButton(
      icon: Icon(
        Icons.replay_outlined,
        shadows: outlinedIcon(),
        color: Colors.white,
        size: 16.0,
      ),
      tooltip: loc.reloadCamera,
      onPressed: () async {
        await UnityPlayers.reloadDevice(widget.device);
        if (mounted) setState(() {});
      },
    );

    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (states.isHovering && video.error == null && !video.isLoading) ...[
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              reverse: true,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                spacing: 6.0,
                children: [
                  if (widget.device.hasPTZ)
                    PTZToggleButton(
                      ptzEnabled: ptzEnabled,
                      onChanged:
                          (enabled) => widget.onPTZEnabledChanged(enabled),
                    ),
                  if (!video.isLoading)
                    StreamBuilder<double>(
                      stream: controller.volumeStream,
                      builder: (context, snapshot) {
                        final isMuted = snapshot.data == 0.0;
                        return SquaredIconButton(
                          icon: Icon(
                            isMuted
                                ? Icons.volume_mute_rounded
                                : Icons.volume_up_rounded,
                            shadows: outlinedIcon(),
                            color: Colors.white,
                            size: 16.0,
                          ),
                          tooltip: isMuted ? loc.enableAudio : loc.disableAudio,
                          onPressed: () async {
                            if (!isMuted) {
                              await controller.setVolume(0.0);
                            } else {
                              await controller.setVolume(1.0);
                            }
                          },
                        );
                      },
                    ),
                  if (isDesktopPlatform &&
                      !isAlternativeWindow &&
                      !video.isLoading)
                    SquaredIconButton(
                      icon: Icon(
                        Icons.open_in_new_sharp,
                        shadows: outlinedIcon(),
                        color: Colors.white,
                        size: 16.0,
                      ),
                      tooltip: loc.openInANewWindow,
                      onPressed: widget.device.openInANewWindow,
                    ),
                  if (!isAlternativeWindow &&
                      !video.isLoading &&
                      !widget.isFullScreen)
                    SquaredIconButton(
                      icon: Icon(
                        Icons.fullscreen_rounded,
                        shadows: outlinedIcon(),
                        color: Colors.white,
                        size: 16.0,
                      ),
                      tooltip: loc.showFullscreenCamera,
                      onPressed: () async {
                        UnityPlayers.openFullscreen(
                          context,
                          widget.device,
                          ptzEnabled: ptzEnabled,
                        );
                      },
                    ),
                  reloadButton,
                  // CameraViewFitButton(
                  //   fit: video.fit,
                  //   onChanged: widget.onFitChanged,
                  // ),
                ],
              ),
            ),
          ),
        ] else ...[
          const Spacer(),
          if (states.isHovering) reloadButton,
        ],
        settings.kShowVideoStatusLabelOn.value.build(
          Padding(
            padding: const EdgeInsetsDirectional.only(
              start: 6.0,
              end: 6.0,
              bottom: 6.0,
            ),
            child: VideoStatusLabel(
              video: video,
              device: widget.device,
              position:
                  widget.isFullScreen || isAlternativeWindow
                      ? VideoStatusLabelPosition.top
                      : VideoStatusLabelPosition.bottom,
            ),
          ),
          const SizedBox.shrink(),
          states,
        ),
      ],
    );
  }
}
