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
import 'package:bluecherry_client/providers/settings_provider.dart';
import 'package:bluecherry_client/screens/layouts/desktop/viewport.dart';
import 'package:bluecherry_client/widgets/desktop_buttons.dart';
import 'package:flutter/material.dart';
import 'package:unity_video_player/unity_video_player.dart';

class CameraView extends StatefulWidget {
  const CameraView({super.key, required this.device});

  final Device device;

  @override
  State<CameraView> createState() => _CameraViewState();
}

class _CameraViewState extends State<CameraView> {
  late final UnityVideoPlayer controller;
  late final StreamSubscription _durationSubscription;
  late UnityVideoFit fit = widget.device.server.additionalSettings.videoFit ??
      SettingsProvider.instance.kVideoFit.value;

  @override
  void initState() {
    super.initState();
    controller = UnityVideoPlayer.create(
      title: widget.device.fullName,
    )
      ..setDataSource(widget.device.streamURL)
      ..setVolume(0.0)
      ..setSpeed(1.0);

    _durationSubscription = controller.onDurationUpdate.listen((event) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _durationSubscription.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.black,
      child: Column(children: [
        WindowButtons(title: widget.device.name, showNavigator: false),
        Expanded(
          child: UnityVideoView(
            player: controller,
            fit: fit,
            paneBuilder: (context, controller) {
              return DesktopTileViewport(
                controller: controller,
                device: widget.device,
                onFitChanged: (fit) => setState(() => this.fit = fit),
              );
            },
          ),
        ),
      ]),
    );
  }
}
