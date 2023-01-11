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

part of 'full_screen_viewer.dart';

class DeviceFullscreenViewerDesktop extends StatefulWidget {
  final Device device;
  final UnityVideoPlayer videoPlayerController;

  const DeviceFullscreenViewerDesktop({
    Key? key,
    required this.device,
    required this.videoPlayerController,
  }) : super(key: key);

  @override
  State<DeviceFullscreenViewerDesktop> createState() =>
      _DeviceFullscreenViewerDesktopState();
}

class _DeviceFullscreenViewerDesktopState
    extends State<DeviceFullscreenViewerDesktop> {
  UnityVideoFit fit = UnityVideoFit.contain;

  @override
  Widget build(BuildContext context) {
    return Material(
      child: Column(children: [
        WindowButtons(title: widget.device.fullName, showNavigator: false),
        Expanded(
          child: UnityVideoView(
            player: widget.videoPlayerController,
            fit: fit,
            paneBuilder: (context, controller) {
              if (controller.error != null) {
                return ErrorWarning(message: controller.error!);
              } else if (!controller.isSeekable) {
                return const Center(
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation(Colors.white),
                    strokeWidth: 4.4,
                  ),
                );
              }

              return const SizedBox.shrink();
            },
          ),
        ),
      ]),
    );
  }
}
