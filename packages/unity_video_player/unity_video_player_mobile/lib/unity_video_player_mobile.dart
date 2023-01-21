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
  UnityVideoPlayer createPlayer({int? width, int? height}) {
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

  // stores the current volume, since ijkPlayer do not provide it
  double _currentVolume = 1.0;

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
  Stream<Duration> get onCurrentPosUpdate => ijkPlayer.onCurrentPosUpdate;

  @override
  bool get isBuffering => ijkPlayer.isBuffering;
  @override
  Stream<bool> get onBufferStateUpdate => ijkPlayer.onBufferStateUpdate;

  @override
  bool get isPlaying => ijkPlayer.state == FijkState.started;

  @override
  Stream<bool> get onPlayingStateUpdate =>
      Stream.fromFuture(Future.value(ijkPlayer.isPlayable()));

  @override
  bool get isSeekable => ijkPlayer.state == FijkState.asyncPreparing;

  @override
  Future<void> setDataSource(String url, {bool autoPlay = true}) async {
    await ijkPlayer.setDataSource(
      url,
      autoPlay: autoPlay,
    );

    await ijkPlayer.setOption(
      FijkOption.playerCategory,
      'packet-buffering',
      '0',
    );
  }

  @override
  Future<void> setVolume(double volume) async {
    await ijkPlayer.setVolume(volume);
    _currentVolume = volume;
  }

  @override
  Future<double> get volume async => _currentVolume;

  @override
  Future<void> setSpeed(double speed) => ijkPlayer.setSpeed(speed);
  @override
  Future<void> seekTo(Duration position) =>
      ijkPlayer.seekTo(position.inMilliseconds);

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
