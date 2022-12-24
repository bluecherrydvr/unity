library unity_video_player_mobile;

import 'package:fijkplayer/fijkplayer.dart';
import 'package:flutter/widgets.dart';
import 'package:unity_video_player_platform_interface/unity_video_player_platform_interface.dart';

class UnityVideoPlayerMobileInterface extends UnityVideoPlayerInterface {
  /// Registers this class as the default instance of [UnityVideoPlayerInterface].
  static void registerWith() {
    UnityVideoPlayerInterface.instance = UnityVideoPlayerMobileInterface();
  }

  @override
  Future<void> initialize() async {}

  @override
  UnityVideoPlayer createPlayer() {
    return UnityVideoPlayerMobile();
  }

  /// Creates a video view
  @override
  Widget createVideoView({
    required UnityVideoPlayer player,
    UnityVideoFit fit = UnityVideoFit.contain,
    UnityVideoPaneBuilder? paneBuilder,
    Color color = const Color(0xFF000000),
  }) {
    return FijkView(
      player: (player as UnityVideoPlayerMobile).ijkPlayer,
      color: color,
      fit: {
        UnityVideoFit.contain: FijkFit.contain,
        UnityVideoFit.fill: FijkFit.fill,
        UnityVideoFit.cover: FijkFit.cover,
      }[fit]!,
      panelBuilder: (p, v, c, s, t) {
        return paneBuilder?.call(c, player) ?? const SizedBox.shrink();
      },
    );
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
  bool get isSeekable => ijkPlayer.state == FijkState.asyncPreparing;

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
