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
import 'package:bluecherry_client/utils/methods.dart';
import 'package:bluecherry_client/widgets/desktop_buttons.dart';
import 'package:bluecherry_client/widgets/error_warning.dart';
import 'package:bluecherry_client/widgets/misc.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:status_bar_control/status_bar_control.dart';
import 'package:unity_video_player/unity_video_player.dart';

part 'desktop_viewer.dart';
part 'mobile_viewer.dart';

class DeviceFullscreenViewer extends StatelessWidget {
  final Device device;
  final UnityVideoPlayer videoPlayerController;
  final bool restoreStatusBarStyleOnDispose;

  const DeviceFullscreenViewer({
    Key? key,
    required this.device,
    required this.videoPlayerController,
    this.restoreStatusBarStyleOnDispose = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, consts) {
      // if (consts.maxWidth >= 800) {
      //   return DeviceFullscreenViewerDesktop(
      //     device: device,
      //     videoPlayerController: videoPlayerController,
      //   );
      // } else {
      return DeviceFullscreenViewerMobile(
        device: device,
        videoPlayerController: videoPlayerController,
        restoreStatusBarStyleOnDispose: restoreStatusBarStyleOnDispose,
      );
      // }
    });
  }
}
