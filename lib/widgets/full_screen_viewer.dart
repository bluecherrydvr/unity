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

import 'dart:io';

import 'package:bluecherry_client/models/device.dart';
import 'package:bluecherry_client/providers/settings_provider.dart';
import 'package:bluecherry_client/utils/methods.dart';
import 'package:bluecherry_client/widgets/misc.dart';
import 'package:bluecherry_client/widgets/video_player.dart';
import 'package:fijkplayer/fijkplayer.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:status_bar_control/status_bar_control.dart';

class DeviceFullscreenViewer extends StatefulWidget {
  final Device device;
  final BluecherryVideoPlayerController? videoPlayerController;
  final bool restoreStatusBarStyleOnDispose;

  const DeviceFullscreenViewer({
    Key? key,
    required this.device,
    required this.videoPlayerController,
    this.restoreStatusBarStyleOnDispose = false,
  }) : super(key: key);

  @override
  State<DeviceFullscreenViewer> createState() => _DeviceFullscreenViewerState();
}

class _DeviceFullscreenViewerState extends State<DeviceFullscreenViewer> {
  bool overlay = false;
  CameraViewFit fit = CameraViewFit.contain;
  Brightness? brightness;

  @override
  void initState() {
    super.initState();
    if (!isDesktop) {
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        brightness = Theme.of(context).brightness;
        await StatusBarControl.setHidden(true);
        await StatusBarControl.setStyle(
          getStatusBarStyleFromBrightness(Theme.of(context).brightness),
        );
        DeviceOrientations.instance.set([
          DeviceOrientation.landscapeLeft,
          DeviceOrientation.landscapeRight,
        ]);
      });
    }
  }

  @override
  void dispose() async {
    if (widget.restoreStatusBarStyleOnDispose && brightness != null) {
      await StatusBarControl.setHidden(false);
      await StatusBarControl.setStyle(
        getStatusBarStyleFromBrightness(brightness!),
      );
      DeviceOrientations.instance.restoreLast();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(children: [
        GestureDetector(
          onTap: () {
            setState(() {
              overlay = !overlay;
            });
          },
          child: InteractiveViewer(
            child: BluecherryVideoPlayer(
              controller: widget.videoPlayerController!,
              fit: fit,
              paneBuilder: (controller) {
                return Scaffold(
                  backgroundColor: Colors.transparent,
                  body: () {
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
                    } else {
                      return [
                        FijkState.idle,
                        FijkState.asyncPreparing,
                      ].contains(controller.ijkPlayer?.state)
                          ? const Center(
                              child: CircularProgressIndicator(
                                valueColor:
                                    AlwaysStoppedAnimation(Colors.white),
                                strokeWidth: 4.4,
                              ),
                            )
                          : const SizedBox.shrink();
                    }
                  }(),
                );
              },
            ),
          ),
        ),
        Positioned(
          top: 0.0,
          left: 0.0,
          right: 0.0,
          child: AnimatedSlide(
            offset: Offset(0, overlay ? 0.0 : -1.0),
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeInOut,
            child: AppBar(
              backgroundColor: Colors.black38,
              title: Text(
                widget.device.name
                    .split(' ')
                    .map((e) => e[0].toUpperCase() + e.substring(1))
                    .join(' '),
                style: const TextStyle(color: Colors.white70),
              ),
              leading: IconButton(
                splashRadius: 22.0,
                onPressed: Navigator.of(context).maybePop,
                icon: Icon(
                  Platform.isIOS ? Icons.arrow_back_ios : Icons.arrow_back,
                  color: Colors.white.withOpacity(0.87),
                ),
              ),
              centerTitle: Platform.isIOS,
              actions: [
                IconButton(
                  splashRadius: 20.0,
                  onPressed: () {
                    setState(() {
                      fit = fit == CameraViewFit.fill
                          ? CameraViewFit.contain
                          : CameraViewFit.fill;
                    });
                  },
                  icon: Icon(
                    Icons.aspect_ratio,
                    color: fit == CameraViewFit.fill
                        ? Colors.white.withOpacity(0.87)
                        : Colors.white.withOpacity(0.54),
                  ),
                ),
                const SizedBox(width: 16.0),
              ],
            ),
          ),
        ),
      ]),
    );
  }
}
