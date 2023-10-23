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

import 'dart:async';

import 'package:bluecherry_client/models/device.dart';
import 'package:bluecherry_client/providers/home_provider.dart';
import 'package:bluecherry_client/providers/settings_provider.dart';
import 'package:bluecherry_client/utils/methods.dart';
import 'package:bluecherry_client/utils/window.dart';
import 'package:bluecherry_client/widgets/desktop_buttons.dart';
import 'package:bluecherry_client/widgets/device_grid/video_status_label.dart';
import 'package:bluecherry_client/widgets/error_warning.dart';
import 'package:bluecherry_client/widgets/misc.dart';
import 'package:bluecherry_client/widgets/multi_window/window.dart';
import 'package:bluecherry_client/widgets/player/widgets.dart';
import 'package:bluecherry_client/widgets/ptz.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:unity_video_player/unity_video_player.dart';

/// The player that plays the streams in full-screen.
class LivePlayer extends StatefulWidget {
  final UnityVideoPlayer player;
  final Device device;
  final bool ptzEnabled;

  /// Creates a live player.
  const LivePlayer({
    super.key,
    required this.player,
    required this.device,
    this.ptzEnabled = false,
  });

  LivePlayer.fromUrl({
    super.key,
    required String url,
    required this.device,
    this.ptzEnabled = false,
  }) : player = UnityVideoPlayerInterface.instance.createPlayer()
          ..setDataSource(url);

  @override
  State<LivePlayer> createState() => _LivePlayerState();
}

class _LivePlayerState extends State<LivePlayer> {
  @override
  void initState() {
    super.initState();
    if (isMobile) {
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersive);
      HomeProvider.setDefaultStatusBarStyle();
      DeviceOrientations.instance.set([
        DeviceOrientation.landscapeLeft,
        DeviceOrientation.landscapeRight,
      ]);
    }
  }

  @override
  void dispose() {
    if (isMobile) {
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
      DeviceOrientations.instance.restoreLast();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, consts) {
      if (isMobilePlatform) {
        return _MobileLivePlayer(
          player: widget.player,
          device: widget.device,
          ptzEnabled: widget.ptzEnabled,
        );
      } else {
        return _DesktopLivePlayer(
          player: widget.player,
          device: widget.device,
          ptzEnabled: widget.ptzEnabled,
        );
      }
    });
  }
}

class _MobileLivePlayer extends StatefulWidget {
  final UnityVideoPlayer player;
  final Device device;
  final bool ptzEnabled;

  const _MobileLivePlayer({
    required this.player,
    required this.device,
    required this.ptzEnabled,
  });

  @override
  State<_MobileLivePlayer> createState() => __MobileLivePlayerState();
}

class __MobileLivePlayerState extends State<_MobileLivePlayer> {
  bool overlay = true;
  late UnityVideoFit fit = SettingsProvider.instance.cameraViewFit;

  late bool ptzEnabled = widget.ptzEnabled;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await Future.delayed(const Duration(milliseconds: 750));
      if (mounted) setState(() => overlay = false);
    });
  }

  void toggleOverlay([PointerDeviceKind? kind]) {
    if (kind != null && kind != PointerDeviceKind.touch) return;
    if (mounted) setState(() => overlay = !overlay);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: PTZController(
          device: widget.device,
          enabled: !overlay && ptzEnabled,
          builder: (context, commands, constraints) {
            return UnityVideoView(
              heroTag: widget.device.streamURL,
              player: widget.player,
              fit: fit,
              videoBuilder: (context, child) {
                return AnimatedOpacity(
                  duration: const Duration(milliseconds: 320),
                  curve: Curves.easeInOut,
                  opacity: overlay ? 0.75 : 1.0,
                  child: child,
                );
              },
              paneBuilder: (context, controller) {
                final error = UnityVideoView.of(context).error;

                return GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTapDown: (event) => toggleOverlay(event.kind),
                  child: Stack(children: [
                    const Positioned.fill(child: SizedBox.expand()),
                    if (error != null)
                      ErrorWarning(message: error)
                    else if (!controller.isSeekable ||
                        controller.dataSource == null)
                      const Center(
                        child: CircularProgressIndicator.adaptive(
                          valueColor: AlwaysStoppedAnimation(Colors.white),
                          strokeWidth: 3.45,
                        ),
                      )
                    else if (commands.isNotEmpty)
                      PTZData(commands: commands),
                    PositionedDirectional(
                      top: 0.0,
                      start: 0.0,
                      end: 0.0,
                      child: AnimatedSlide(
                        offset: Offset(0, overlay ? 0.0 : -1.0),
                        duration: const Duration(milliseconds: 320),
                        curve: Curves.easeInOut,
                        child: ColoredBox(
                          color: Colors.black38,
                          child: ListTile(
                            title: Text(
                              widget.device.name,
                              style: const TextStyle(color: Colors.white),
                            ),
                            subtitle: Text(
                              widget.device.server.name,
                              style: const TextStyle(color: Colors.white70),
                            ),
                            leading: IconButton(
                              onPressed: () => Navigator.of(context).maybePop(),
                              icon: Icon(
                                isCupertino
                                    ? Icons.arrow_back_ios
                                    : Icons.arrow_back,
                              ),
                              tooltip: MaterialLocalizations.of(context)
                                  .backButtonTooltip,
                              color: Colors.white,
                            ),
                            trailing:
                                Row(mainAxisSize: MainAxisSize.min, children: [
                              CameraViewFitButton(
                                fit: fit,
                                onChanged: (newFit) {
                                  setState(() => fit = newFit);
                                },
                              ),
                              if (widget.device.hasPTZ)
                                PTZToggleButton(
                                  ptzEnabled: ptzEnabled,
                                  onChanged: (enabled) =>
                                      setState(() => ptzEnabled = enabled),
                                ),
                              const SizedBox(width: 16.0),
                            ]),
                          ),
                        ),
                      ),
                    ),
                    if (!overlay && ptzEnabled)
                      PositionedDirectional(
                        key: const ValueKey('restorer'),
                        start: 14.0,
                        top: 14.0,
                        child: IconButton(
                          icon: const Icon(
                            Icons.keyboard_arrow_down_rounded,
                            color: Colors.white,
                            size: 28.0,
                          ),
                          tooltip:
                              MaterialLocalizations.of(context).showMenuTooltip,
                          onPressed: toggleOverlay,
                        ),
                      ),
                    Positioned(
                      bottom: 8.0,
                      right: 8.0,
                      child: VideoStatusLabel(
                        device: widget.device,
                        video: UnityVideoView.of(context),
                      ),
                    ),
                  ]),
                );
              },
            );
          },
        ),
      ),
    );
  }
}

class _DesktopLivePlayer extends StatefulWidget {
  final UnityVideoPlayer player;
  final Device device;
  final bool ptzEnabled;

  const _DesktopLivePlayer({
    required this.player,
    required this.device,
    required this.ptzEnabled,
  });

  @override
  State<_DesktopLivePlayer> createState() => __DesktopLivePlayerState();
}

class __DesktopLivePlayerState extends State<_DesktopLivePlayer> {
  late UnityVideoFit fit = SettingsProvider.instance.cameraViewFit;
  late bool ptzEnabled = widget.ptzEnabled;

  late StreamSubscription<double> _volumeStreamSubscription;
  double get volume => widget.player.volume;

  @override
  void initState() {
    super.initState();
    _volumeStreamSubscription = widget.player.volumeStream.listen((event) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _volumeStreamSubscription.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final isSubView = AlternativeWindow.maybeOf(context) != null;

    return Column(children: [
      WindowButtons(
        title: widget.device.fullName,
        showNavigator: false,
      ),
      Expanded(
        child: PTZController(
          device: widget.device,
          enabled: ptzEnabled,
          builder: (context, commands, constraints) {
            return UnityVideoView(
              heroTag: widget.device.streamURL,
              player: widget.player,
              fit: fit,
              paneBuilder: (context, player) {
                return Stack(children: [
                  if (commands.isNotEmpty) PTZData(commands: commands),
                  PositionedDirectional(
                    bottom: 8.0,
                    end: 8.0,
                    start: 8.0,
                    child: Row(children: [
                      if (widget.device.hasPTZ)
                        IconButton(
                          icon: Icon(
                            Icons.videogame_asset,
                            color: ptzEnabled ? Colors.white : null,
                            shadows: outlinedText(),
                          ),
                          tooltip:
                              ptzEnabled ? loc.enabledPTZ : loc.disabledPTZ,
                          onPressed: () =>
                              setState(() => ptzEnabled = !ptzEnabled),
                        ),
                      const Spacer(),
                      () {
                        final isMuted = widget.player.volume == 0.0;

                        return IconButton(
                          icon: Icon(
                            isMuted
                                ? Icons.volume_mute_rounded
                                : Icons.volume_up_rounded,
                            shadows: outlinedText(),
                          ),
                          tooltip: isMuted ? loc.enableAudio : loc.disableAudio,
                          color: Colors.white,
                          iconSize: 18.0,
                          onPressed: () async {
                            if (isMuted) {
                              await widget.player.setVolume(1.0);
                            } else {
                              await widget.player.setVolume(0.0);
                            }
                          },
                        );
                      }(),
                      if (isDesktopPlatform && !isSubView)
                        IconButton(
                          icon: Icon(
                            Icons.open_in_new,
                            shadows: outlinedText(),
                          ),
                          tooltip: loc.openInANewWindow,
                          color: Colors.white,
                          iconSize: 18.0,
                          onPressed: () {
                            widget.device.openInANewWindow();
                          },
                        ),
                      CameraViewFitButton(
                        fit: fit,
                        onChanged: (newFit) {
                          setState(() => fit = newFit);
                        },
                      ),
                      const SizedBox(width: 8.0),
                      VideoStatusLabel(
                        device: widget.device,
                        video: UnityVideoView.of(context),
                      ),
                    ]),
                  ),
                ]);
              },
            );
          },
        ),
      ),
    ]);
  }
}
