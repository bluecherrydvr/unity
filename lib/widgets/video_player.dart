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

import 'dart:math';

import 'package:bluecherry_client/providers/settings_provider.dart';
import 'package:bluecherry_client/widgets/misc.dart';
import 'package:dart_vlc/dart_vlc.dart';
import 'package:fijkplayer/fijkplayer.dart';
import 'package:flutter/material.dart';

class BluecherryVideoPlayerController {
  /// Player for the mobile client
  FijkPlayer? ijkPlayer;

  /// Player for the desktop client
  Player? vlcPlayer;

  BluecherryVideoPlayerController() {
    if (isDesktop) {
      vlcPlayer = Player(id: Random.secure().nextInt(100000));
    } else {
      ijkPlayer = FijkPlayer();
    }
  }

  String? get dataSource {
    if (isDesktop) {
      return vlcPlayer?.current.media?.resource;
    } else {
      return ijkPlayer?.dataSource;
    }
  }

  /// Human readable exception message
  String? get error {
    if (isDesktop) {
      if (vlcPlayer!.error.isEmpty) return null;
      return vlcPlayer!.error;
    } else {
      return ijkPlayer!.value.exception.message;
    }
  }

  Duration get duration {
    if (isDesktop) {
      return vlcPlayer!.position.duration ?? Duration.zero;
    } else {
      return ijkPlayer!.value.duration;
    }
  }

  Duration get currentPos {
    if (isDesktop) {
      return vlcPlayer!.position.position ?? Duration.zero;
    } else {
      return ijkPlayer!.currentPos;
    }
  }

  bool get isBuffering {
    if (isDesktop) {
      return vlcPlayer!.bufferingProgress != 1.0;
    } else {
      return ijkPlayer!.isBuffering;
    }
  }

  Stream<Duration> get onCurrentPosUpdate {
    if (isDesktop) {
      return vlcPlayer!.positionStream.map<Duration>(
        (event) => event.position ?? Duration.zero,
      );
    } else {
      return ijkPlayer!.onCurrentPosUpdate;
    }
  }

  Stream<bool> get onBufferStateUpdate {
    if (isDesktop) {
      return vlcPlayer!.bufferingProgressStream.map((event) => event != 1.0);
    } else {
      return ijkPlayer!.onBufferStateUpdate;
    }
  }

  bool get isPlaying {
    if (isDesktop) {
      return vlcPlayer!.playback.isPlaying;
    } else {
      return ijkPlayer!.state == FijkState.started;
    }
  }

  Future<void> setDataSource(String url, {bool autoPlay = true}) async {
    await ijkPlayer?.setDataSource(
      url,
      autoPlay: autoPlay,
    );

    vlcPlayer?.open(Media.network(url));
  }

  Future<void> setVolume(double volume) async {
    await ijkPlayer?.setVolume(volume);

    vlcPlayer?.setVolume(volume);
  }

  Future<void> setSpeed(double speed) async {
    await ijkPlayer?.setSpeed(speed);

    vlcPlayer?.setRate(speed);
  }

  Future<void> seekTo(int msec) async {
    await ijkPlayer?.seekTo(msec);

    vlcPlayer?.seek(Duration(milliseconds: msec));
  }

  Future<void> start() async {
    await ijkPlayer?.start();

    vlcPlayer?.play();
  }

  Future<void> pause() async {
    await ijkPlayer?.pause();

    vlcPlayer?.pause();
  }

  Future<void> release() async {
    await ijkPlayer?.release();
  }

  void dispose() {
    ijkPlayer?.dispose();
    vlcPlayer?.dispose();
  }

  Future<void> reset() async {
    await ijkPlayer?.reset();
    vlcPlayer?.stop();
  }
}

typedef BluecherryPaneBuilder = Widget Function(
    BluecherryVideoPlayerController controller)?;

/// An adaptive video player with support for multiple platforms.
///
/// On mobile (android and ios), [FijkView] is used
///
/// On desktop (windows, macOS and linux), [Video] from vlc is used
///
/// See also:
///
///   * [FijkView], the view used on mobile platforms
///   * [Video], the view used on desktop platforms
///   * [BluecherryVideoPlayerController], used to control ho the video behave
class BluecherryVideoPlayer extends StatefulWidget {
  /// Creates a bluecherry video player.
  const BluecherryVideoPlayer({
    Key? key,
    required this.controller,
    this.fit = CameraViewFit.contain,
    this.paneBuilder,
  }) : super(key: key);

  /// The video controller
  final BluecherryVideoPlayerController controller;

  /// How the video should fit into the view
  final CameraViewFit fit;

  /// Build a pane above the video view
  final BluecherryPaneBuilder? paneBuilder;

  @override
  State<BluecherryVideoPlayer> createState() => _BluecherryVideoPlayerState();
}

class _BluecherryVideoPlayerState extends State<BluecherryVideoPlayer> {
  @override
  Widget build(BuildContext context) {
    final builder =
        widget.paneBuilder?.call(widget.controller) ?? const SizedBox.shrink();
    if (isDesktop) {
      return Stack(children: [
        Positioned.fill(
          child: Video(
            player: widget.controller.vlcPlayer!,
            fillColor: Colors.black,
            fit: {
              CameraViewFit.contain: BoxFit.contain,
              CameraViewFit.cover: BoxFit.cover,
              CameraViewFit.fill: BoxFit.fill,
            }[widget.fit]!,
            // showControls: false,
          ),
        ),
        Positioned.fill(child: builder),
      ]);
    } else {
      return FijkView(
        player: widget.controller.ijkPlayer!,
        color: Colors.black,
        fit: {
          CameraViewFit.contain: FijkFit.contain,
          CameraViewFit.fill: FijkFit.fill,
          CameraViewFit.cover: FijkFit.cover,
        }[widget.fit]!,
        panelBuilder: (p, v, c, s, t) {
          return builder;
        },
      );
    }
  }
}
