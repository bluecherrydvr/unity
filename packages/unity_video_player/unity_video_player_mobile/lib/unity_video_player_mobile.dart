library unity_video_player_mobile;

import 'package:fijkplayer/fijkplayer.dart';
import 'package:unity_video_player_platform_interface/unity_video_player_platform_interface.dart';

class UnityVideoPlayerMobileInterface extends UnityVideoPlayerInterface {
  /// Registers this class as the default instance of [UrlLauncherPlatform].
  static void registerWith() {
    UnityVideoPlayerInterface.instance = UnityVideoPlayerMobileInterface();
  }

  @override
  Future<void> initialize() async {}

  @override
  UnityVideoPlayer createPlayer() {
    return UnityVideoPlayerMobile();
  }
}

class UnityVideoPlayerMobile extends UnityVideoPlayer {
  FijkPlayer ijkPlayer = FijkPlayer();

  @override
  String? get dataSource {
    return ijkPlayer.dataSource;
  }

  @override
  String? get error => ijkPlayer.value.exception.message;

  @override
  Duration get duration => ijkPlayer.value.duration;

  @override
  Duration get currentPos => ijkPlayer.currentPos;

  @override
  bool get isBuffering => ijkPlayer.isBuffering;
  @override
  Stream<Duration> get onCurrentPosUpdate => ijkPlayer.onCurrentPosUpdate;
  @override
  Stream<bool> get onBufferStateUpdate => ijkPlayer.onBufferStateUpdate;

  @override
  bool get isPlaying => ijkPlayer.state == FijkState.started;

  @override
  Future<void> setDataSource(String url, {bool autoPlay = true}) async {
    await ijkPlayer.setDataSource(
      url,
      autoPlay: autoPlay,
    );
  }

  @override
  Future<void> setVolume(double volume) => ijkPlayer.setVolume(volume);
  @override
  Future<void> setSpeed(double speed) => ijkPlayer.setSpeed(speed);
  @override
  Future<void> seekTo(int msec) => ijkPlayer.seekTo(msec);

  @override
  Future<void> start() => ijkPlayer.start();
  @override
  Future<void> pause() => ijkPlayer.pause();
  @override
  Future<void> release() => ijkPlayer.release();
  @override
  Future<void> reset() => ijkPlayer.reset();

  @override
  void dispose() {
    ijkPlayer.dispose();
  }
}
