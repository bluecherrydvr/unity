/*
 * This file is a part of Bluecherry Client (https://https://github.com/bluecherrydvr/bluecherry_client).
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

import 'package:flutter/material.dart';
import 'package:dart_vlc/dart_vlc.dart';

import 'package:bluecherry_client/models/camera.dart';

class CameraTile extends StatelessWidget {
  final Camera camera;

  /// Taking [Player] as [Widget] argument to avoid disposition responsiblity & [Player] recreations due to UI re-draw.
  final Player player;

  final double width;
  final double height;

  const CameraTile({
    Key? key,
    required this.camera,
    required this.player,
    this.width = 640.0,
    this.height = 360.0,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      elevation: 4.0,
      margin: EdgeInsets.zero,
      key: PageStorageKey(camera.uri.hashCode),
      child: Video(
        player: player,
        width: width,
        height: height,
        showControls: false,
      ),
    );
  }
}
