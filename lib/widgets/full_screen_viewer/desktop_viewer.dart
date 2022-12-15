part of 'full_screen_viewer.dart';

class DeviceFullscreenViewerDesktop extends StatefulWidget {
  final Device device;
  final BluecherryVideoPlayerController videoPlayerController;

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
  CameraViewFit fit = CameraViewFit.contain;

  @override
  Widget build(BuildContext context) {
    return Material(
      child: Column(children: [
        Expanded(
          child: BluecherryVideoPlayer(
            controller: widget.videoPlayerController,
            fit: fit,
            paneBuilder: (context, controller, states) {
              if (controller.error != null) {
                return ErrorWarning(message: controller.error!);
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
              }

              return const SizedBox.shrink();
            },
          ),
        ),
      ]),
    );
  }
}
