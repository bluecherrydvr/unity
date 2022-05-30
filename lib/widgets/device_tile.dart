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

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:dart_vlc/dart_vlc.dart' hide Device;
import 'package:fijkplayer/fijkplayer.dart';

import 'package:bluecherry_client/models/device.dart';
import 'package:bluecherry_client/widgets/misc.dart';

class DeviceTile extends StatefulWidget {
  final Device device;

  /// Taking [Player] as [Widget] argument to avoid disposition responsiblity & [Player] recreations due to UI re-draw.
  final Player? libvlcPlayer;

  /// Taking [FijkPlayer] as [Widget] argument to avoid disposition responsiblity & [FijkPlayer] recreations due to UI re-draw.
  final FijkPlayer? ijkPlayer;
  final double width;
  final double height;

  const DeviceTile({
    Key? key,
    required this.device,
    this.libvlcPlayer,
    this.ijkPlayer,
    this.width = 640.0,
    this.height = 360.0,
  }) : super(key: key);

  @override
  State<StatefulWidget> createState() => DeviceTileState();
}

class DeviceTileState extends State<DeviceTile> {
  bool hover = false;

  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(seconds: 1), () {
      setState(() {
        hover = false;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return isDesktop
        ? MouseRegion(
            onEnter: (e) {
              setState(() {
                hover = true;
              });
            },
            onExit: (e) {
              setState(() {
                hover = false;
              });
            },
            child: Card(
              clipBehavior: Clip.antiAlias,
              elevation: 4.0,
              margin: EdgeInsets.zero,
              key: PageStorageKey(widget.device.uri.hashCode),
              child: Stack(
                children: [
                  AnimatedScale(
                    scale: hover ? 1.05 : 1.0,
                    duration: const Duration(milliseconds: 200),
                    curve: Curves.easeInOut,
                    child: Video(
                      player: widget.libvlcPlayer,
                      showControls: false,
                    ),
                  ),
                  Positioned.fill(
                    child: AnimatedOpacity(
                      opacity: hover ? 1.0 : 0.0,
                      duration: const Duration(milliseconds: 200),
                      curve: Curves.easeInOut,
                      child: Container(
                        width: widget.width,
                        height: widget.height,
                        alignment: Alignment.bottomLeft,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Colors.transparent,
                              Colors.black.withOpacity(0.7),
                            ],
                            stops: const [0.0, 0.8],
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                          ),
                        ),
                        child: AnimatedSlide(
                          offset: Offset(0, hover ? 0.0 : 1.0),
                          duration: const Duration(milliseconds: 200),
                          curve: Curves.easeInOut,
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.camera_alt,
                                  color: Colors.white,
                                  size: 24.0,
                                ),
                                const SizedBox(width: 16.0),
                                Expanded(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    mainAxisSize: MainAxisSize.min,
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        widget.device.name,
                                        style: Theme.of(context)
                                            .textTheme
                                            .headline1
                                            ?.copyWith(
                                              color: Colors.white,
                                              fontSize: 18.0,
                                            ),
                                      ),
                                      Text(
                                        widget.device.uri,
                                        style: Theme.of(context)
                                            .textTheme
                                            .headline3
                                            ?.copyWith(
                                              color: Colors.white70,
                                            ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 16.0),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          )
        : GestureDetector(
            onTap: () {
              setState(() {
                hover = !hover;
              });
            },
            child: ClipRect(
              child: Stack(
                children: [
                  FijkView(
                    player: widget.ijkPlayer!,
                    color: Colors.black,
                    fit: FijkFit.fill,
                    panelBuilder: (player, _, ___, ____, _____) =>
                        player.value.exception.message != null
                            ? Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    const Icon(
                                      Icons.warning,
                                      color: Colors.white70,
                                      size: 32.0,
                                    ),
                                    const SizedBox(height: 8.0),
                                    Text(
                                      player.value.exception.message!
                                          .toLowerCase(),
                                      style: const TextStyle(
                                        color: Colors.white70,
                                        fontSize: 12.0,
                                      ),
                                    ),
                                  ],
                                ),
                              )
                            : [
                                FijkState.idle,
                                FijkState.asyncPreparing,
                              ].contains(player.state)
                                ? const Center(
                                    child: CircularProgressIndicator(
                                      valueColor:
                                          AlwaysStoppedAnimation(Colors.white),
                                      strokeWidth: 4.4,
                                    ),
                                  )
                                : const SizedBox.shrink(),
                  ),
                  Positioned(
                    bottom: 0.0,
                    left: 0.0,
                    right: 0.0,
                    child: AnimatedOpacity(
                      opacity: hover ? 1.0 : 0.0,
                      duration: const Duration(milliseconds: 200),
                      curve: Curves.easeInOut,
                      child: Container(
                        height: 56.0,
                        alignment: Alignment.centerRight,
                        color: Colors.black26,
                        child: AnimatedSlide(
                          offset: Offset(0, hover ? 0.0 : 1.0),
                          duration: const Duration(milliseconds: 200),
                          curve: Curves.easeInOut,
                          child: Row(
                            children: [
                              const SizedBox(width: 16.0),
                              const Icon(
                                Icons.camera_alt,
                                color: Colors.white,
                                size: 20.0,
                              ),
                              const SizedBox(width: 16.0),
                              Expanded(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  mainAxisSize: MainAxisSize.min,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      widget.device.name,
                                      style: Theme.of(context)
                                          .textTheme
                                          .headline1
                                          ?.copyWith(
                                            color: Colors.white,
                                            fontSize: 16.0,
                                          ),
                                    ),
                                    Text(
                                      widget.device.uri,
                                      style: Theme.of(context)
                                          .textTheme
                                          .headline3
                                          ?.copyWith(
                                            color: Colors.white70,
                                            fontSize: 12.0,
                                          ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 16.0),
                            ],
                          ),
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
