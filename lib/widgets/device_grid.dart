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

import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:dart_vlc/dart_vlc.dart';
import 'package:reorderable_grid_view/reorderable_grid_view.dart';

import 'package:bluecherry_client/widgets/device_tile.dart';
import 'package:bluecherry_client/models/server.dart';
import 'package:bluecherry_client/utils/constants.dart';

/// A draggable grid view showing [DeviceTile]s to the user.
class DeviceGrid extends StatefulWidget {
  final double width;
  final double height;
  final Server server;
  const DeviceGrid({
    Key? key,
    required this.server,
    this.width = double.infinity,
    this.height = double.infinity,
  }) : super(key: key);

  @override
  State<DeviceGrid> createState() => _DeviceGridState();
}

class _DeviceGridState extends State<DeviceGrid> {
  final List<Player> players = <Player>[];
  final List<DeviceTile> tiles = <DeviceTile>[];

  @override
  void initState() {
    super.initState();
    for (final device in widget.server.devices) {
      players.add(Player(
        id: Random().nextInt(1 << 16),
        // Clamp to reasonable [VideoDimensions], if [widget.width] and
        // [widget.height] is passed. Avoids redundant CPU load caused by libvlc
        // 3.0 pixel buffer based video callbacks.
        videoDimensions: const VideoDimensions(
          kDeviceTileWidth ~/ 1,
          kDeviceTileHeight ~/ 1,
        ),
        commandlineArguments: kLibVLCFlags +
            [
              '--rtsp-user=${widget.server.login}',
              '--rtsp-pwd=${widget.server.password}',
            ],
      )..open(
          Media.network(device.streamURL(widget.server)),
        ));
      tiles.add(
        DeviceTile(
          key: ValueKey(device.hashCode),
          device: device,
          player: players.last,
          width: kDeviceTileWidth,
          height: kDeviceTileHeight,
        ),
      );
    }
  }

  @override
  void dispose() {
    // Dispose [Player] instance if the [VideoView] is removed from the [Widget]
    // tree.
    for (final element in players) {
      element.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: widget.width,
      height: widget.height,
      child: PageStorage(
        bucket: PageStorageBucket(),
        child: ReorderableGridView.count(
          shrinkWrap: true,
          crossAxisCount: 2,
          childAspectRatio: kDeviceTileWidth / kDeviceTileHeight,
          mainAxisSpacing: kDeviceTileMargin,
          crossAxisSpacing: kDeviceTileMargin,
          padding: const EdgeInsets.all(kDeviceTileMargin),
          onReorder: (int oldIndex, int newIndex) {
            setState(() {
              final e = players.removeAt(oldIndex);
              players.insert(newIndex, e);
              final f = tiles.removeAt(oldIndex);
              tiles.insert(newIndex, f);
            });
          },
          children: tiles,
          dragStartBehavior: DragStartBehavior.start,
          dragWidgetBuilder: (i, c) => tiles[i],
        ),
      ),
    );
  }
}
