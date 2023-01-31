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
import 'package:bluecherry_client/providers/mobile_view_provider.dart';
import 'package:bluecherry_client/widgets/error_warning.dart';
import 'package:bluecherry_client/widgets/misc.dart';
import 'package:flutter/material.dart';
import 'package:unity_video_player/unity_video_player.dart';

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
  UnityVideoPlayer? videoPlayer;

  @override
  void initState() {
    super.initState();
    videoPlayer = MobileViewProvider.instance.players[widget.device];
    if (isDesktop) {
      Future.delayed(const Duration(seconds: 1), () {
        if (mounted) {
          // setState(() {
          //   MobileViewProvider.instance.hoverStates[widget.tab]![widget.index] =
          //       false;
          // });
        }
      });
    }
  }

  @override
  void dispose() {
    super.dispose();
  }

  bool get hover =>
      MobileViewProvider.instance.hoverStates[widget.tab]?[widget.index] ??
      false;

  set hover(bool value) => MobileViewProvider.instance.hoverStates[widget.tab]
      ?[widget.index] = value;

  Widget get playerView {
    return StatefulBuilder(builder: (context, _) {
      videoPlayer = MobileViewProvider.instance.players[widget.device];
      debugPrint('${widget.device} ${videoPlayer?.dataSource.toString()}');

      return UnityVideoView(
        player: videoPlayer!,
        paneBuilder: (context, controller) {
          return Material(
            color: Colors.transparent,
            child: () {
              if (controller.error != null) {
                return ErrorWarning(message: controller.error!);
              } else if (controller.isBuffering) {
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
                      opacity: value,
                      child: IconButton(
                        splashRadius: 20.0,
                        onPressed: () async {
                          if (videoPlayer == null) return;

                          await Navigator.of(context).pushNamed(
                            '/fullscreen',
                            arguments: {
                              'device': widget.device,
                              'player': videoPlayer,
                            },
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
      onDoubleTap: () async {
        if (videoPlayer == null) return;

        await Navigator.of(context).pushNamed(
          '/fullscreen',
          arguments: {
            'device': widget.device,
            'player': videoPlayer,
          },
        );
      },
      child: ClipRect(
        child: Stack(children: [
          if (videoPlayer == null)
            Container(
              color: Colors.black,
              width: double.infinity,
              height: double.infinity,
            )
          else
            playerView,
          PositionedDirectional(
            bottom: 0.0,
            start: 0.0,
            end: 0.0,
            child: AnimatedSlide(
              offset: Offset(0, hover ? 0.0 : 1.0),
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeInOut,
              child: Container(
                height: 48.0,
                alignment: AlignmentDirectional.centerEnd,
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
                          style: Theme.of(context)
                              .textTheme
                              .displayLarge
                              ?.copyWith(
                                color: Colors.white,
                                fontSize: 14.0,
                              ),
                        ),
                        Text(
                          widget.device.uri,
                          style: Theme.of(context)
                              .textTheme
                              .displaySmall
                              ?.copyWith(
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
