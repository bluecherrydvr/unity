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
import 'package:bluecherry_client/widgets/full_screen_viewer.dart';
import 'package:bluecherry_client/widgets/video_player.dart';
import 'package:flutter/material.dart';
import 'package:fijkplayer/fijkplayer.dart';

import 'package:bluecherry_client/providers/mobile_view_provider.dart';
import 'package:bluecherry_client/models/device.dart';
import 'package:bluecherry_client/widgets/misc.dart';

class DeviceTile extends StatefulWidget {
  final Device device;
  final int tab;
  final int index;

  final double width;
  final double height;

  const DeviceTile({
    Key? key,
    required this.device,
    required this.tab,
    required this.index,
    this.width = 640.0,
    this.height = 360.0,
  }) : super(key: key);

  @override
  State<StatefulWidget> createState() => DeviceTileState();
}

class DeviceTileState extends State<DeviceTile> {
  BluecherryVideoPlayerController? videoPlayer;

  @override
  void initState() {
    super.initState();
    videoPlayer = MobileViewProvider.instance.players[widget.device];
    if (isDesktop) {
      Future.delayed(const Duration(seconds: 1), () {
        setState(() {
          MobileViewProvider.instance.hoverStates[widget.tab]![widget.index] =
              false;
        });
      });
    }
  }

  @override
  void dispose() {
    super.dispose();
  }

  bool get hover =>
      MobileViewProvider.instance.hoverStates[widget.tab]![widget.index];

  set hover(bool value) =>
      MobileViewProvider.instance.hoverStates[widget.tab]![widget.index] =
          value;

  Widget get ijkView {
    return StatefulBuilder(builder: (context, _) {
      videoPlayer = MobileViewProvider.instance.players[widget.device];
      debugPrint('${widget.device} ${videoPlayer?.dataSource.toString()}');

      return BluecherryVideoPlayer(
        controller: videoPlayer!,
        paneBuilder: (controller) {
          return Material(
            color: Colors.transparent,
            child: () {
              if (controller.error != null) {
                return Center(
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
                        controller.error!.toUpperCase(),
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 12.0,
                        ),
                      ),
                    ],
                  ),
                );
              } else if ([
                FijkState.idle,
                FijkState.asyncPreparing,
              ].contains(controller.ijkPlayer?.state)) {
                return const Center(
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation(Colors.white),
                    strokeWidth: 4.4,
                  ),
                );
              } else if (hover) {
                return TweenAnimationBuilder(
                  tween: Tween<double>(
                    begin: 0.0,
                    end: hover ? 1.0 : 0.0,
                  ),
                  duration: const Duration(milliseconds: 300),
                  builder: (context, value, child) => Center(
                    child: Opacity(
                      opacity: value as double,
                      child: IconButton(
                        splashRadius: 20.0,
                        onPressed: () async {
                          await Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) => DeviceFullscreenViewer(
                                device: widget.device,
                                videoPlayerController: videoPlayer,
                              ),
                            ),
                          );
                        },
                        icon: const Icon(
                          Icons.fullscreen,
                          color: Colors.white,
                          size: 32.0,
                        ),
                      ),
                    ),
                  ),
                );
              } else {
                return const SizedBox.shrink();
              }
            }(),
          );
        },
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetectorWithReducedDoubleTapTime(
      onTap: () {
        setState(() {
          hover = !hover;
        });
      },
      // Fullscreen on double-tap.
      onDoubleTap: () => Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => DeviceFullscreenViewer(
            device: widget.device,
            videoPlayerController: videoPlayer,
          ),
        ),
      ),
      child: ClipRect(
        child: Stack(children: [
          if (videoPlayer == null)
            Container(
              color: Colors.black,
              width: double.infinity,
              height: double.infinity,
            )
          else
            ijkView,
          Positioned(
            bottom: 0.0,
            left: 0.0,
            right: 0.0,
            child: AnimatedSlide(
              offset: Offset(0, hover ? 0.0 : 1.0),
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeInOut,
              child: Container(
                height: 48.0,
                alignment: Alignment.centerRight,
                color: Colors.black26,
                child: Row(children: [
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
                          widget.device.name
                              .split(' ')
                              .map((e) => e[0].toUpperCase() + e.substring(1))
                              .join(' '),
                          style:
                              Theme.of(context).textTheme.headline1?.copyWith(
                                    color: Colors.white,
                                    fontSize: 14.0,
                                  ),
                        ),
                        Text(
                          widget.device.uri,
                          style:
                              Theme.of(context).textTheme.headline3?.copyWith(
                                    color: Colors.white70,
                                    fontSize: 10.0,
                                  ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16.0),
                ]),
              ),
            ),
          ),
        ]),
      ),
    );
  }
}
