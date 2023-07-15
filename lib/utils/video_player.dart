import 'package:bluecherry_client/models/device.dart';
import 'package:flutter/foundation.dart';
import 'package:unity_video_player/unity_video_player.dart';

class UnityPlayers {
  const UnityPlayers._();

  /// Instances of video players corresponding to a particular [Device].
  ///
  /// This avoids redundantly creating new video player instance if a [Device]
  /// is already present in the camera grid on the screen or allows to use
  /// existing instance when switching tab (if common camera [Device] tile exists).
  ///
  static final Map<Device, UnityVideoPlayer> players = {};

  /// Helper method to create a video player with required configuration for a [Device].
  static UnityVideoPlayer forDevice(Device device) {
    debugPrint(device.streamURL);
    final controller = UnityVideoPlayer.create(
      quality: UnityVideoQuality.qualityForResolutionY(device.resolutionY),
    )
      ..setDataSource(device.streamURL)
      ..setVolume(0.0)
      ..setSpeed(1.0);

    return controller;
  }
}
