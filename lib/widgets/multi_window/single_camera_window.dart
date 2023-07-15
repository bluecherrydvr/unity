import 'package:bluecherry_client/models/device.dart';
import 'package:bluecherry_client/widgets/device_grid/device_grid.dart';
import 'package:flutter/material.dart';
import 'package:unity_video_player/unity_video_player.dart';

class CameraView extends StatefulWidget {
  const CameraView({super.key, required this.device});

  final Device device;

  @override
  State<CameraView> createState() => _CameraViewState();
}

class _CameraViewState extends State<CameraView> {
  late UnityVideoPlayer controller;

  @override
  void initState() {
    super.initState();
    controller = UnityVideoPlayer.create(quality: UnityVideoQuality.p720)
      ..setDataSource(widget.device.streamURL)
      ..setVolume(0.0)
      ..setSpeed(1.0);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: Column(children: [
        Expanded(
          child: UnityVideoView(
            player: controller,
            color: Colors.grey.shade900,
            paneBuilder: (context, controller) {
              return DesktopTileViewport(
                controller: controller,
                device: widget.device,
                isSubView: true,
              );
            },
          ),
        ),
      ]),
    );
  }
}
