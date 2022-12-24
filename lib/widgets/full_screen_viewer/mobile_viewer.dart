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
  bool overlay = false;
  UnityVideoFit fit = UnityVideoFit.contain;
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
            child: UnityVideoView(
              player: widget.videoPlayerController,
              fit: fit,
              paneBuilder: (context, controller) {
                return Scaffold(
                  backgroundColor: Colors.transparent,
                  body: () {
                    if (controller.error != null) {
                      return ErrorWarning(message: controller.error!);
                    } else if (controller.isBuffering) {
                      return const Center(
                        child: CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation(Colors.white),
                          strokeWidth: 4.4,
                        ),
                      );
                    } else {
                      return const SizedBox.shrink();
                    }
                  }(),
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
                      fit = fit == UnityVideoFit.fill
                          ? UnityVideoFit.contain
                          : UnityVideoFit.fill;
                    });
                  },
                  icon: Icon(
                    Icons.aspect_ratio,
                    color: fit == UnityVideoFit.fill
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
