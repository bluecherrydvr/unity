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

import 'package:bluecherry_client/widgets/misc.dart';
import 'package:dart_vlc/dart_vlc.dart';
import 'package:fijkplayer/fijkplayer.dart';
import 'package:flutter/material.dart';

class BluecherryVideoPlayerController {
  /// Player for the mobile client
  FijkPlayer? ijkPlayer;

  /// Player for the desktop client
  Player? player;

  BluecherryVideoPlayerController() {
    if (isDesktop) {
      player = Player(id: Random.secure().nextInt(100000));
    } else {
      ijkPlayer = FijkPlayer();
    }
  }

  Future<void> setDataSource(String url, {bool autoPlay = true}) async {
    ijkPlayer?.setDataSource(
      url,
      autoPlay: autoPlay,
    );

    player?.open(Media.network(url));
  }

  Future<void> setVolume(double volume) async {
    await ijkPlayer?.setVolume(volume);

    player?.setVolume(volume);
  }

  Future<void> setSpeed(double speed) async {
    await ijkPlayer?.setSpeed(speed);

    player?.setRate(speed);
  }

  Future<void> release() async {
    await ijkPlayer?.release();
  }

  void dispose() {
    ijkPlayer?.dispose();
    player?.dispose();
  }

  Future<void> reset() async {
    await ijkPlayer?.reset();
    player?.stop();
  }
}

class BluecherryVideoPlayer extends StatefulWidget {
  const BluecherryVideoPlayer({
    Key? key,
    required this.controller,
  }) : super(key: key);

  final BluecherryVideoPlayerController controller;

  @override
  State<BluecherryVideoPlayer> createState() => _BluecherryVideoPlayerState();
}

class _BluecherryVideoPlayerState extends State<BluecherryVideoPlayer> {
  @override
  Widget build(BuildContext context) {
    if (isDesktop) {
      return Video(
        player: widget.controller.player!,
      );
    } else {
      return FijkView(player: widget.controller.ijkPlayer!);
    }
    return Container();
  }
}
