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

import 'package:animations/animations.dart';
import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:dart_vlc/dart_vlc.dart' hide Device;
import 'package:provider/provider.dart';
import 'package:reorderable_grid_view/reorderable_grid_view.dart';

import 'package:bluecherry_client/models/server.dart';
import 'package:bluecherry_client/models/device.dart';
import 'package:bluecherry_client/utils/constants.dart';
import 'package:bluecherry_client/widgets/misc.dart';
import 'package:bluecherry_client/widgets/device_tile.dart';
import 'package:bluecherry_client/widgets/device_tile_selector.dart';
import 'package:bluecherry_client/providers/mobile_view_provider.dart';

class DeviceGrid extends StatelessWidget {
  const DeviceGrid({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (isDesktop) {
      // TODO: missing implementation.
      // WIP: [DesktopDeviceGrid].
      throw Exception('[DeviceGrid] is not supported on desktop.');
    } else {
      return const MobileDeviceGrid();
    }
  }
}

/// A draggable grid view showing [DeviceTile]s to the user.
class DesktopDeviceGrid extends StatefulWidget {
  final Server server;
  final double width;
  final double height;
  const DesktopDeviceGrid({
    Key? key,
    required this.server,
    this.width = double.infinity,
    this.height = double.infinity,
  }) : super(key: key);

  @override
  State<DesktopDeviceGrid> createState() => _DesktopDeviceGridState();
}

class _DesktopDeviceGridState extends State<DesktopDeviceGrid> {
  final List<Player> players = <Player>[];
  final List<DeviceTile> tiles = <DeviceTile>[];

  @override
  void initState() {
    super.initState();
    if (isDesktop) {
      for (final device in widget.server.devices) {
        players.add(Player(
          id: Random().nextInt((pow(2, 16)) ~/ 1 - 1),
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
            Media.network(device.streamURL),
          ));
        tiles.add(
          DeviceTile(
            key: ValueKey(device.hashCode),
            device: device,
            libvlcPlayer: players.last,
            width: kDeviceTileWidth,
            height: kDeviceTileHeight,
            tab: -1,
            index: -1,
          ),
        );
      }
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

const double kMobileBottomBarHeight = 48.0;

class MobileDeviceGrid extends StatefulWidget {
  const MobileDeviceGrid({
    Key? key,
  }) : super(key: key);

  @override
  State<MobileDeviceGrid> createState() => _MobileDeviceGridState();
}

class _MobileDeviceGridState extends State<MobileDeviceGrid> {
  @override
  Widget build(BuildContext context) {
    return Consumer<MobileViewProvider>(
      builder: (context, view, _) => SizedBox(
        child: Column(
          children: [
            view.tab == -1
                ? const Spacer()
                : Expanded(
                    child: PageTransitionSwitcher(
                      child: {
                        4: () => const _MobileDeviceGridChild(tab: 4),
                        2: () => const _MobileDeviceGridChild(tab: 2),
                        1: () => const _MobileDeviceGridChild(tab: 1),
                      }[view.tab]!(),
                      transitionBuilder:
                          (child, primaryAnimation, secondaryAnimation) =>
                              FadeThroughTransition(
                        animation: primaryAnimation,
                        secondaryAnimation: secondaryAnimation,
                        child: child,
                        fillColor: Colors.black,
                      ),
                    ),
                  ),
            Container(
              decoration: const BoxDecoration(
                boxShadow: [
                  BoxShadow(color: Colors.black45, blurRadius: 8.0),
                ],
              ),
              child: Material(
                color: Theme.of(context).primaryColor,
                child: Container(
                  height: kMobileBottomBarHeight,
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  width: MediaQuery.of(context).size.width,
                  child: Row(
                    children: <Widget>[
                          IconButton(
                            onPressed: Scaffold.of(context).openDrawer,
                            icon: const Icon(Icons.menu),
                            iconSize: 18.0,
                            color: Colors.white,
                            splashRadius: 24.0,
                          ),
                          const Spacer(),
                        ] +
                        [4, 2, 1].map((e) {
                          final child = view.tab == e
                              ? Card(
                                  margin: EdgeInsets.zero,
                                  elevation: 4.0,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(20.0),
                                  ),
                                  child: Container(
                                    height: 40.0,
                                    width: 40.0,
                                    alignment: Alignment.center,
                                    child: Container(
                                      height: 28.0,
                                      width: 28.0,
                                      alignment: Alignment.center,
                                      child: Text(
                                        e.toString(),
                                        style: const TextStyle(
                                          color: Colors.black,
                                          fontSize: 18.0,
                                        ),
                                      ),
                                      decoration: BoxDecoration(
                                        border: Border.all(
                                          color: Theme.of(context).primaryColor,
                                          width: 2.0,
                                        ),
                                        borderRadius:
                                            BorderRadius.circular(14.0),
                                      ),
                                    ),
                                  ),
                                  color: Colors.white,
                                )
                              : Text(
                                  e.toString(),
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 18.0,
                                  ),
                                );
                          return Container(
                            height: 48.0,
                            width: 48.0,
                            alignment: Alignment.centerRight,
                            child: IconButton(
                              onPressed: () => view.setTab(e),
                              icon: child,
                            ),
                          );
                        }).toList(),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MobileDeviceGridChild extends StatelessWidget {
  final int tab;
  const _MobileDeviceGridChild({
    Key? key,
    required this.tab,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Consumer<MobileViewProvider>(builder: (context, view, _) {
      if (tab == 1) {
        return DeviceTileSelector(
          key: ValueKey(Random().nextInt((pow(2, 31)) ~/ 1 - 1)),
          index: 0,
          tab: 1,
        );
      }
      // Since, multiple tiles showing same camera can exist in a same tab.
      // This [Map] is used for assigning unique [ValueKey] to each.
      final counts = <Device?, int>{};
      for (final device in view.devices[tab]!) {
        counts[device] = !counts.containsKey(device) ? 1 : counts[device]! + 1;
      }
      final children = view.devices[tab]!.asMap().entries.map(
        (e) {
          counts[e.value] = counts[e.value]! - 1;
          debugPrint(
              '${e.value}.${e.value?.server.serverUUID}.${counts[e.value]}');
          return DeviceTileSelector(
            key: ValueKey(
                '${e.value}.${e.value?.server.serverUUID}.${counts[e.value]}'),
            index: e.key,
            tab: tab,
          );
        },
      ).toList();
      return Container(
        color: Colors.black,
        height: double.infinity,
        width: double.infinity,
        child: ReorderableGridView.count(
          physics: const NeverScrollableScrollPhysics(),
          shrinkWrap: true,
          crossAxisCount: <int, int>{
            4: 2,
            2: 2,
          }[tab]!,
          childAspectRatio: <int, double>{
            4: (MediaQuery.of(context).size.width -
                    MediaQuery.of(context).padding.horizontal) /
                (MediaQuery.of(context).size.height -
                    kMobileBottomBarHeight -
                    MediaQuery.of(context).padding.bottom),
            2: (MediaQuery.of(context).size.width -
                    MediaQuery.of(context).padding.horizontal) *
                0.5 /
                (MediaQuery.of(context).size.height -
                    kMobileBottomBarHeight -
                    MediaQuery.of(context).padding.bottom),
          }[tab]!,
          mainAxisSpacing: 0.0,
          crossAxisSpacing: 0.0,
          padding: EdgeInsets.zero,
          onReorder: (initial, end) => view.reorder(tab, initial, end),
          children: children,
          dragStartBehavior: DragStartBehavior.start,
        ),
      );
    });
  }
}
