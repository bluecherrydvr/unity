library unity_video_player_mobile;

import 'dart:async';

import 'package:video_player/video_player.dart';
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
    final player = UnityVideoPlayerMobile();
    UnityVideoPlayerInterface.registerPlayer(player);
    return player;
  }

  /// Creates a video view
  @override
  Widget createVideoView({
    required UnityVideoPlayer player,
    UnityVideoFit fit = UnityVideoFit.contain,
    UnityVideoPaneBuilder? paneBuilder,
    Color color = const Color(0xFF000000),
  }) {
    return ColoredBox(
      color: color,
      child: Builder(builder: (context) {
        final controller = (player as UnityVideoPlayerMobile)._controller;
        return Stack(children: [
          if (controller != null) VideoPlayer(controller),
          if (paneBuilder != null) paneBuilder(context, player),
        ]);
      }),
    );
  }
}

class UnityVideoPlayerMobile extends UnityVideoPlayer {
  VideoPlayerController? _controller;

  final _listenerBroadcaster = StreamController.broadcast();

  @override
  String? get dataSource {
    return _controller?.dataSource;
  }

  @override
  String? get error => _controller?.value.errorDescription;

  @override
  Duration get duration => _controller?.value.duration ?? Duration.zero;

  @override
  Duration get currentPos => _controller?.value.position ?? Duration.zero;

  @override
  Stream<Duration> get onCurrentPosUpdate =>
      _listenerBroadcaster.stream.map((_) => duration);

  @override
  bool get isBuffering => _controller?.value.isBuffering ?? false;

  @override
  Stream<bool> get onBufferStateUpdate =>
      _listenerBroadcaster.stream.map((_) => isBuffering);

  @override
  bool get isPlaying => _controller?.value.isPlaying ?? false;

  @override
  Stream<bool> get onPlayingStateUpdate =>
      _listenerBroadcaster.stream.map((_) => isPlaying);

  @override
  bool get isSeekable => _controller?.value.isInitialized ?? false;

  @override
  Future<void> setDataSource(String url, {bool autoPlay = true}) async {
    _controller = VideoPlayerController.network(
      url,
      videoPlayerOptions: VideoPlayerOptions(allowBackgroundPlayback: false),
    );
    await _controller!.initialize();
    _controller!.addListener(() {
      _listenerBroadcaster.add(null);
    });
  }

  @override
  Future<void> setMultipleDataSource(
    List<String> url, {
    bool autoPlay = true,
  }) async {
    // TODO(bdlukaa): playlist in mobile player
  }

  @override
  Future<void> setVolume(double volume) async {
    await _controller?.setVolume(volume);
  }

  @override
  Future<double> get volume async => _controller?.value.volume ?? 0.0;

  @override
  Future<void> setSpeed(double speed) async {
    await _controller?.setPlaybackSpeed(speed);
  }

  @override
  Future<void> seekTo(Duration position) async {
    await _controller?.seekTo(position);
  }

  @override
  Future<void> start() async => await _controller?.play();
  @override
  Future<void> pause() async => await _controller?.pause();
  @override
  Future<void> release() async {}

  @override
  Future<void> reset() async {
    await pause();
    await seekTo(Duration.zero);
  }

  @override
  void dispose() {
    _controller?.dispose();
    _listenerBroadcaster.close();
    UnityVideoPlayerInterface.unregisterPlayer(this);
  }
}
