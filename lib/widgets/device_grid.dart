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

import 'package:animations/animations.dart';
import 'package:bluecherry_client/providers/server_provider.dart';
import 'package:bluecherry_client/widgets/device_tile_selector.dart';
import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:dart_vlc/dart_vlc.dart' hide Device;
import 'package:fijkplayer/fijkplayer.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:status_bar_control/status_bar_control.dart';
import 'package:reorderable_grid_view/reorderable_grid_view.dart';

import 'package:bluecherry_client/widgets/device_tile.dart';
import 'package:bluecherry_client/models/server.dart';
import 'package:bluecherry_client/models/device.dart';
import 'package:bluecherry_client/utils/constants.dart';
import 'package:bluecherry_client/widgets/misc.dart';
import 'package:bluecherry_client/providers/mobile_view_provider.dart';

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
            libvlcPlayer: players.last,
            width: kDeviceTileWidth,
            height: kDeviceTileHeight,
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
            if (isDesktop) {
              setState(() {
                final e = players.removeAt(oldIndex);
                players.insert(newIndex, e);
                final f = tiles.removeAt(oldIndex);
                tiles.insert(newIndex, f);
              });
            } else {
              setState(() {
                final e = players.removeAt(oldIndex);
                players.insert(newIndex, e);
                final f = tiles.removeAt(oldIndex);
                tiles.insert(newIndex, f);
              });
            }
          },
          children: tiles,
          dragStartBehavior: DragStartBehavior.start,
          dragWidgetBuilder: (i, c) => tiles[i],
        ),
      ),
    );
  }
}

const double kBottomBarHeight = 48.0;

class MobileDeviceGrid extends StatefulWidget {
  const MobileDeviceGrid({
    Key? key,
  }) : super(key: key);

  @override
  State<MobileDeviceGrid> createState() => _MobileDeviceGridState();
}

class _MobileDeviceGridState extends State<MobileDeviceGrid> {
  /// For sharing instance of [FijkPlayer] between the various camera tabs & prevent redundant buffering.
  Map<Device, FijkPlayer> players = {};

  @override
  void initState() {
    super.initState();
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    StatusBarControl.setHidden(
      true,
      animation: StatusBarAnimation.SLIDE,
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = Provider.of<MobileViewProvider>(context, listen: false);

      /// TODO: Currently only single server is implemented.
      final server = ServersProvider.instance.servers.first;
      for (final device in provider.current) {
        if (device != null) {
          players[device] = FijkPlayer()
            ..setDataSource(
              device.streamURL(server),
              autoPlay: true,
            )
            ..setVolume(0.0)
            ..setSpeed(1.0);
        }
      }
    });
  }

  void switchView(int value) {
    final provider = Provider.of<MobileViewProvider>(context, listen: false);
    if (provider.tab == value) {
      return;
    }
    final devices = provider.devices[value]!;

    /// TODO: Currently only single server is implemented.
    final server = ServersProvider.instance.servers.first;
    for (final device in devices) {
      if (!players.keys.contains(device) && device != null) {
        players[device] = FijkPlayer()
          ..setDataSource(
            device.streamURL(server),
            autoPlay: true,
          )
          ..setVolume(0.0)
          ..setSpeed(1.0);
      }
    }
    players.removeWhere((key, value) {
      final result = devices.contains(key);
      if (!result) {
        value.release();
        value.dispose();
      }
      return !result;
    });
    provider.setTab(value);
  }

  @override
  void dispose() {
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
    StatusBarControl.setHidden(
      false,
      animation: StatusBarAnimation.SLIDE,
    );
    super.dispose();
  }

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
                        4: () => MobileDeviceGrid4(players: players),
                        2: () => MobileDeviceGrid2(players: players),
                        1: () {
                          return Material(
                            color: Colors.black,
                            child: Padding(
                              padding: MediaQuery.of(context).padding,
                              child: InkWell(
                                onTap: () {},
                                child: Container(
                                  alignment: Alignment.center,
                                  child: const Icon(
                                    Icons.add,
                                    size: 36.0,
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
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
                  height: kBottomBarHeight,
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  width: MediaQuery.of(context).size.width,
                  child: Row(
                    children: <Widget>[
                          IconButton(
                            onPressed: () {},
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
                                    child: Text(
                                      e.toString(),
                                      style: const TextStyle(
                                        color: Colors.black,
                                        fontSize: 18.0,
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
                              onPressed: () => switchView(e),
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

class MobileDeviceGrid4 extends StatefulWidget {
  final Map<Device, FijkPlayer> players;
  const MobileDeviceGrid4({
    Key? key,
    required this.players,
  }) : super(key: key);

  @override
  State<MobileDeviceGrid4> createState() => _MobileDeviceGrid4State();
}

class _MobileDeviceGrid4State extends State<MobileDeviceGrid4> {
  @override
  Widget build(BuildContext context) {
    return Consumer<MobileViewProvider>(builder: (context, view, _) {
      final children = view.devices[4]!
          .map((e) => DeviceTileSelector(
                players: widget.players,
                key: ValueKey(Random().nextInt(1 << 32)),
                index: view.devices[4]!.indexOf(e),
                tab: 4,
              ))
          .toList();
      return Container(
        color: Colors.black,
        height: double.infinity,
        width: double.infinity,
        child: ReorderableGridView.count(
          physics: const NeverScrollableScrollPhysics(),
          shrinkWrap: true,
          crossAxisCount: 2,
          childAspectRatio: (MediaQuery.of(context).size.width -
                  MediaQuery.of(context).padding.horizontal) /
              (MediaQuery.of(context).size.height -
                  kBottomBarHeight -
                  MediaQuery.of(context).padding.vertical),
          mainAxisSpacing: 0.0,
          crossAxisSpacing: 0.0,
          padding: EdgeInsets.zero,
          onReorder: (int oldIndex, int newIndex) =>
              MobileViewProvider.instance.move(4, oldIndex, newIndex),
          children: children,
          dragStartBehavior: DragStartBehavior.start,
        ),
      );
    });
  }
}

class MobileDeviceGrid2 extends StatefulWidget {
  final Map<Device, FijkPlayer> players;
  const MobileDeviceGrid2({
    Key? key,
    required this.players,
  }) : super(key: key);

  @override
  _MobileDeviceGrid2State createState() => _MobileDeviceGrid2State();
}

class _MobileDeviceGrid2State extends State<MobileDeviceGrid2> {
  @override
  Widget build(BuildContext context) {
    return Consumer<MobileViewProvider>(builder: (context, view, _) {
      final children = view.devices[2]!
          .map((e) => DeviceTileSelector(
                players: widget.players,
                key: ValueKey(Random().nextInt(1 << 32)),
                index: view.devices[2]!.indexOf(e),
                tab: 2,
              ))
          .toList();
      return Container(
        color: Colors.black,
        height: double.infinity,
        width: double.infinity,
        child: ReorderableGridView.count(
          physics: const NeverScrollableScrollPhysics(),
          shrinkWrap: true,
          crossAxisCount: 2,
          childAspectRatio: (MediaQuery.of(context).size.width -
                  MediaQuery.of(context).padding.horizontal) *
              0.5 /
              (MediaQuery.of(context).size.height -
                  kBottomBarHeight -
                  MediaQuery.of(context).padding.vertical),
          mainAxisSpacing: 0.0,
          crossAxisSpacing: 0.0,
          padding: EdgeInsets.zero,
          onReorder: (int oldIndex, int newIndex) =>
              MobileViewProvider.instance.move(2, oldIndex, newIndex),
          children: children,
          dragStartBehavior: DragStartBehavior.start,
        ),
      );
    });
  }
}
