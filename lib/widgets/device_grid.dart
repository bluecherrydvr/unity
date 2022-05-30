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
import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:dart_vlc/dart_vlc.dart';
import 'package:fijkplayer/fijkplayer.dart';
import 'package:flutter/services.dart';
import 'package:reorderable_grid_view/reorderable_grid_view.dart';

import 'package:bluecherry_client/widgets/device_tile.dart';
import 'package:bluecherry_client/models/server.dart';
import 'package:bluecherry_client/utils/constants.dart';
import 'package:bluecherry_client/widgets/misc.dart';
import 'package:status_bar_control/status_bar_control.dart';

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
    if (isMobile) {
      return SizedBox(
        width: widget.width,
        height: widget.height,
        child: MobileDeviceGrid(server: widget.server),
      );
    }
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
  final Server server;
  const MobileDeviceGrid({
    Key? key,
    required this.server,
  }) : super(key: key);

  @override
  State<MobileDeviceGrid> createState() => _MobileDeviceGridState();
}

class _MobileDeviceGridState extends State<MobileDeviceGrid> {
  int view = 4;

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
  }

  @override
  void dispose() {
    SystemChrome.setPreferredOrientations(
      DeviceOrientation.values,
    );
    StatusBarControl.setHidden(
      false,
      animation: StatusBarAnimation.SLIDE,
    );
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      child: Column(
        children: [
          Expanded(
            child: PageTransitionSwitcher(
              child: {
                4: () => MobileDeviceGrid4(server: widget.server),
                2: () => MobileDeviceGrid2(server: widget.server),
                1: () {
                  return Padding(
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
                  );
                },
              }[view]!(),
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
                        final child = view == e
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
                            onPressed: () {
                              if (view == e) return;
                              setState(() {
                                view = e;
                              });
                            },
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
    );
  }
}

class MobileDeviceGrid4 extends StatefulWidget {
  final Server server;
  const MobileDeviceGrid4({
    Key? key,
    required this.server,
  }) : super(key: key);

  @override
  State<MobileDeviceGrid4> createState() => _MobileDeviceGrid4State();
}

class _MobileDeviceGrid4State extends State<MobileDeviceGrid4> {
  List<FijkPlayer> players = <FijkPlayer>[];
  List<Widget> tiles = <Widget>[];

  @override
  void initState() {
    super.initState();
    for (final device in widget.server.devices) {
      players.add(
        FijkPlayer()
          ..setDataSource(
            device.streamURL(
              widget.server,
            ),
            autoPlay: true,
          ),
      );
      tiles.add(
        DeviceTile(
          key: ValueKey(device.hashCode),
          device: device,
          ijkPlayer: players.last,
          width: kDeviceTileWidth,
          height: kDeviceTileHeight,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return PageStorage(
      bucket: PageStorageBucket(),
      child: SafeArea(
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

class MobileDeviceGrid2 extends StatefulWidget {
  final Server server;
  const MobileDeviceGrid2({
    Key? key,
    required this.server,
  }) : super(key: key);

  @override
  _MobileDeviceGrid2State createState() => _MobileDeviceGrid2State();
}

class _MobileDeviceGrid2State extends State<MobileDeviceGrid2> {
  List<FijkPlayer> players = <FijkPlayer>[];
  List<Widget> tiles = <Widget>[];

  @override
  void initState() {
    super.initState();
    for (final device in widget.server.devices) {
      players.add(
        FijkPlayer()
          ..setDataSource(
            device.streamURL(
              widget.server,
            ),
            autoPlay: true,
          ),
      );
      tiles.add(
        DeviceTile(
          key: ValueKey(device.hashCode),
          device: device,
          ijkPlayer: players.last,
          width: kDeviceTileWidth,
          height: kDeviceTileHeight,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return PageStorage(
      bucket: PageStorageBucket(),
      child: SafeArea(
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
