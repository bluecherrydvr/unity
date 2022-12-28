library unity_video_player_desktop;

import 'dart:math';

import 'package:dart_vlc/dart_vlc.dart';
import 'package:flutter/material.dart';
import 'package:unity_video_player_platform_interface/unity_video_player_platform_interface.dart';

class UnityVideoPlayerDesktopInterface extends UnityVideoPlayerInterface {
  /// Registers this class as the default instance of [UnityVideoPlayerInterface].
  static void registerWith() {
    UnityVideoPlayerInterface.instance = UnityVideoPlayerDesktopInterface();
  }

  @override
  Future<void> initialize() async {
    DartVLC.initialize();
  }

  @override
  UnityVideoPlayer createPlayer() {
    return UnityVideoPlayerDesktop();
  }

  @override
  Widget createVideoView({
    required UnityVideoPlayer player,
    UnityVideoFit fit = UnityVideoFit.contain,
    UnityVideoPaneBuilder? paneBuilder,
    Color color = const Color(0xFF000000),
  }) {
    return Builder(builder: (context) {
      return Stack(children: [
        Positioned.fill(
          child: Video(
            player: (player as UnityVideoPlayerDesktop).vlcPlayer,
            fillColor: color,
            fit: {
              UnityVideoFit.contain: BoxFit.contain,
              UnityVideoFit.cover: BoxFit.cover,
              UnityVideoFit.fill: BoxFit.fill,
            }[fit]!,
            showControls: false,
          ),
        ),
        if (paneBuilder != null)
          Positioned.fill(
            child: Material(
              type: MaterialType.transparency,
              child: paneBuilder(context, player),
            ),
          ),
      ]);
    });
  }
}

class UnityVideoPlayerDesktop extends UnityVideoPlayer {
  Player vlcPlayer = Player(
    id: Random.secure().nextInt(100000),
    videoDimensions: const VideoDimensions(640, 360),
  );

  // stores the current volume, since vlc do not provide it
  double _currentVolume = 1.0;

  @override
  String? get dataSource => vlcPlayer.current.media?.resource;

  @override
  String? get error {
    if (vlcPlayer.error.isEmpty) return null;
    return vlcPlayer.error;
  }

  @override
  Duration get duration => vlcPlayer.position.duration ?? Duration.zero;

  @override
  Duration get currentPos => vlcPlayer.position.position ?? Duration.zero;

  @override
  bool get isBuffering => vlcPlayer.bufferingProgress != 1.0;

  @override
  bool get isSeekable => vlcPlayer.playback.isSeekable;

  @override
  Stream<Duration> get onCurrentPosUpdate =>
      vlcPlayer.positionStream.map<Duration>(
        (event) => event.position ?? Duration.zero,
      );
  @override
  Stream<bool> get onBufferStateUpdate =>
      vlcPlayer.bufferingProgressStream.map((event) => event != 1.0);

  @override
  bool get isPlaying => vlcPlayer.playback.isPlaying;

  @override
  Future<void> setDataSource(String url, {bool autoPlay = true}) async {
    vlcPlayer.open(Media.network(url));
  }

  @override
  Future<void> setVolume(double volume) async {
    vlcPlayer.setVolume(volume);
    _currentVolume = volume;
  }

  @override
  Future<double> get volume async => _currentVolume;

  @override
  Future<void> setSpeed(double speed) async => vlcPlayer.setRate(speed);
  @override
  Future<void> seekTo(int msec) async =>
      vlcPlayer.seek(Duration(milliseconds: msec));

  @override
  Future<void> start() async => vlcPlayer.play();
  @override
  Future<void> pause() async => vlcPlayer.pause();
  @override
  Future<void> release() async {}
  @override
  Future<void> reset() async => vlcPlayer.stop();

  @override
  void dispose() {
    vlcPlayer.dispose();
  }
}
