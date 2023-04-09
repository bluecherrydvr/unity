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

class DeviceFullscreenViewerMobile extends StatefulWidget {
  final Device device;
  final UnityVideoPlayer videoPlayerController;
  final bool restoreStatusBarStyleOnDispose;

  const DeviceFullscreenViewerMobile({
    Key? key,
    required this.device,
    required this.videoPlayerController,
    this.restoreStatusBarStyleOnDispose = false,
  }) : super(key: key);

  @override
  State<DeviceFullscreenViewerMobile> createState() =>
      _DeviceFullscreenViewerMobileState();
}

class _DeviceFullscreenViewerMobileState
    extends State<DeviceFullscreenViewerMobile> {
  /// Whether to show the video controls overlay
  bool overlay = false;
  UnityVideoFit fit = UnityVideoFit.contain;
  Brightness? brightness;

  @override
  void initState() {
    super.initState();
    if (isMobile) {
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        brightness = Theme.of(context).brightness;
        await StatusBarControl.setHidden(true);
        await StatusBarControl.setStyle(
          getStatusBarStyleFromBrightness(brightness!),
        );
        DeviceOrientations.instance.set([
          DeviceOrientation.landscapeLeft,
          DeviceOrientation.landscapeRight,
        ]);
      });
    }
  }

  @override
  void dispose() {
    if (isMobile &&
        widget.restoreStatusBarStyleOnDispose &&
        brightness != null) {
      StatusBarControl.setHidden(false);
      StatusBarControl.setStyle(
        getStatusBarStyleFromBrightness(brightness!),
      );
      DeviceOrientations.instance.restoreLast();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);

    return Scaffold(
      body: MouseRegion(
        onEnter: (e) {
          setState(() => overlay = true);
        },
        onExit: (e) {
          setState(() => overlay = false);
        },
        child: Stack(children: [
          GestureDetector(
            onTapUp: (event) {
              if (event.kind == PointerDeviceKind.touch) {
                setState(() => overlay = !overlay);
              }
            },
            child: InteractiveViewer(
              child: UnityVideoView(
                player: widget.videoPlayerController,
                fit: fit,
                paneBuilder: (context, controller) {
                  if (controller.error != null) {
                    return ErrorWarning(message: controller.error!);
                  } else if (controller.isBuffering ||
                      controller.dataSource == null) {
                    return const Center(
                      child: CircularProgressIndicator.adaptive(
                        valueColor: AlwaysStoppedAnimation(Colors.white),
                        strokeWidth: 4.4,
                      ),
                    );
                  }

                  return const SizedBox.shrink();
                },
              ),
            ),
          ),
          PositionedDirectional(
            top: 0.0,
            start: 0.0,
            end: 0.0,
            child: AnimatedSlide(
              offset: Offset(0, overlay ? 0.0 : -1.0),
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeInOut,
              child: AppBar(
                backgroundColor: Colors.black38,
                foregroundColor: Colors.white.withOpacity(0.87),
                title: Text(widget.device.fullName),
                leading: IconButton(
                  onPressed: () => Navigator.of(context).maybePop(),
                  icon: Icon(
                    Platform.isIOS ? Icons.arrow_back_ios : Icons.arrow_back,
                  ),
                  tooltip: MaterialLocalizations.of(context).backButtonTooltip,
                ),
                actions: [
                  IconButton(
                    tooltip: loc.cameraViewFit,
                    onPressed: () {
                      setState(() {
                        fit = fit == UnityVideoFit.fill
                            ? UnityVideoFit.contain
                            : UnityVideoFit.fill;
                      });
                    },
                    icon: const Icon(Icons.aspect_ratio),
                  ),
                  const SizedBox(width: 16.0),
                ],
              ),
            ),
          ),
        ]),
      ),
    );
  }
}
