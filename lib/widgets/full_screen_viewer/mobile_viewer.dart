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
  final bool ptzEnabled;

  const DeviceFullscreenViewerMobile({
    super.key,
    required this.device,
    required this.videoPlayerController,
    this.restoreStatusBarStyleOnDispose = false,
    this.ptzEnabled = false,
  });

  @override
  State<DeviceFullscreenViewerMobile> createState() =>
      _DeviceFullscreenViewerMobileState();
}

class _DeviceFullscreenViewerMobileState
    extends State<DeviceFullscreenViewerMobile> {
  /// Whether to show the video controls overlay
  bool overlay = true;
  UnityVideoFit fit = UnityVideoFit.contain;

  late bool ptzEnabled = widget.ptzEnabled;

  @override
  void initState() {
    super.initState();
    if (isMobile) {
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersive);
      HomeProvider.setDefaultStatusBarStyle();
      DeviceOrientations.instance.set([
        DeviceOrientation.landscapeLeft,
        DeviceOrientation.landscapeRight,
      ]);
    }

    // Hide the title overlay after 750ms
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await Future.delayed(const Duration(milliseconds: 750));
      if (mounted) setState(() => overlay = false);
    });
  }

  @override
  void dispose() {
    if (isMobile && widget.restoreStatusBarStyleOnDispose) {
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
      DeviceOrientations.instance.restoreLast();
    }
    super.dispose();
  }

  void toggleOverlay([PointerDeviceKind? kind]) {
    if (kind != null && kind != PointerDeviceKind.touch) return;
    if (mounted) setState(() => overlay = !overlay);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final loc = AppLocalizations.of(context);

    return Scaffold(
      backgroundColor: Colors.black,
      body: MouseRegion(
        onEnter: (_) => setState(() => overlay = true),
        onExit: (_) => setState(() => overlay = false),
        child: Stack(children: [
          AnimatedOpacity(
            duration: const Duration(milliseconds: 320),
            curve: Curves.easeInOut,
            opacity: overlay ? 0.75 : 1.0,
            child: GestureDetector(
              onTapUp: (event) => toggleOverlay(event.kind),
              onLongPressUp: toggleOverlay,
              onDoubleTapDown: (event) => toggleOverlay(event.kind),
              child: PTZController(
                device: widget.device,
                enabled: !overlay && ptzEnabled,
                builder: (context, commands) {
                  return UnityVideoView(
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
                      } else if (commands.isNotEmpty) {
                        return Align(
                          alignment: AlignmentDirectional.centerEnd,
                          child: Container(
                            margin: const EdgeInsetsDirectional.only(end: 16.0),
                            constraints: const BoxConstraints(minHeight: 140.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              mainAxisSize: MainAxisSize.min,
                              children: commands.map<String>((cmd) {
                                switch (cmd.command) {
                                  case PTZCommand.move:
                                    return '${cmd.command.locale(context)}: ${cmd.movement.locale(context)}';
                                  case PTZCommand.stop:
                                    return cmd.command.locale(context);
                                }
                              }).map<Widget>((text) {
                                return Text(
                                  text,
                                  style: const TextStyle(color: Colors.white),
                                );
                              }).toList(),
                            ),
                          ),
                        );
                      }

                      return const SizedBox.shrink();
                    },
                    // ),
                  );
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
              duration: const Duration(milliseconds: 320),
              curve: Curves.easeInOut,
              child: ColoredBox(
                color: Colors.black38,
                child: ListTile(
                  title: Text(
                    widget.device.name,
                    style: const TextStyle(color: Colors.white),
                  ),
                  subtitle: Text(
                    widget.device.server.name,
                    style: const TextStyle(color: Colors.white70),
                  ),
                  leading: IconButton(
                    onPressed: () => Navigator.of(context).maybePop(),
                    icon: Icon(
                      isCupertino ? Icons.arrow_back_ios : Icons.arrow_back,
                    ),
                    tooltip:
                        MaterialLocalizations.of(context).backButtonTooltip,
                    color: Colors.white,
                  ),
                  trailing: Row(mainAxisSize: MainAxisSize.min, children: [
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
                      color: Colors.white,
                    ),
                    if (widget.device.hasPTZ) ...[
                      IconButton(
                        icon: Icon(
                          Icons.videogame_asset,
                          color: ptzEnabled
                              ? Colors.white
                              : theme.colorScheme.onInverseSurface
                                  .withOpacity(0.86),
                        ),
                        tooltip: ptzEnabled ? loc.enabledPTZ : loc.disabledPTZ,
                        onPressed: () =>
                            setState(() => ptzEnabled = !ptzEnabled),
                      ),
                      // TODO(bdlukaa): enable presets when the API is ready
                      // IconButton(
                      //   icon: Icon(
                      //     Icons.dataset,
                      //     color: ptzEnabled ? Colors.white : theme.disabledColor,
                      //   ),
                      //   tooltip: ptzEnabled
                      //       ? loc.enabledPTZ
                      //       : loc.disabledPTZ,
                      //   onPressed: !ptzEnabled
                      //       ? null
                      //       : () {
                      //           showDialog(
                      //             context: context,
                      //             builder: (context) {
                      //               return PresetsDialog(device: widget.device);
                      //             },
                      //           );
                      //         },
                      // ),
                    ],
                    const SizedBox(width: 16.0),
                  ]),
                ),
              ),
            ),
          ),
          if (!overlay && ptzEnabled)
            PositionedDirectional(
              key: const ValueKey('restorer'),
              start: 14.0,
              top: 14.0,
              child: IconButton(
                icon: const Icon(
                  Icons.keyboard_arrow_down_rounded,
                  color: Colors.white,
                  size: 28.0,
                ),
                tooltip: MaterialLocalizations.of(context).showMenuTooltip,
                onPressed: toggleOverlay,
              ),
            ),
        ]),
      ),
    );
  }
}
