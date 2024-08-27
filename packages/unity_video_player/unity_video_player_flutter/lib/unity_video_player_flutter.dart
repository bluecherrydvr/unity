library unity_video_player_flutter;

import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutterpi_gstreamer_video_player/flutterpi_gstreamer_video_player.dart';
import 'package:video_player/video_player.dart';
import 'package:unity_video_player_platform_interface/unity_video_player_platform_interface.dart';
import 'package:fvp/fvp.dart' as fvp;

class UnityVideoPlayerFlutterInterface extends UnityVideoPlayerInterface {
  /// Registers this class as the default instance of [UnityVideoPlayerInterface].
  static void registerWith() {
//    if ('pi' case const String.fromEnvironment('linux_environment')) {
    UnityVideoPlayerInterface.instance = UnityVideoPlayerFlutterInterface();
//      return;
//    }
//    UnityVideoPlayerInterface.instance = UnityVideoPlayerMediaKitInterface();
  }

  @override
  Future<void> initialize() async {
    if ('pi' case const String.fromEnvironment('linux_environment')) {
      FlutterpiVideoPlayer.registerWith();
    } else {
      fvp.registerWith(options: {
        'player': {
          'avformat.analyzeduration': '10000',
          'avformat.probesize': '1000',
          'avformat.fpsprobesize': '0',
          'avformat.fflags': '+nobuffer',
          'avformat.avioflags': 'direct',
        }
      });
    }
  }

  @override
  UnityVideoPlayer createPlayer({
    int? width,
    int? height,
    bool enableCache = false,
    RTSPProtocol? rtspProtocol,
    VoidCallback? onReload,
    String? title,
    MatrixType matrixType = MatrixType.t16,
    bool softwareZoom = false,
  }) {
    final player = UnityVideoPlayerFlutter(
      width: width,
      height: height,
      enableCache: enableCache,
      title: title,
    );
    UnityVideoPlayerInterface.registerPlayer(player);
    return player;
  }

  @override
  Widget createVideoView({
    Key? key,
    required covariant UnityVideoPlayerFlutter player,
    UnityVideoFit fit = UnityVideoFit.contain,
    UnityVideoPaneBuilder? paneBuilder,
    UnityVideoBuilder? videoBuilder,
    Color color = const Color(0xFF000000),
  }) {
    videoBuilder ??= (context, video) => video;

    return Builder(builder: (context) {
      return Stack(children: [
        Positioned.fill(
          child: videoBuilder!(
            context,
            ColoredBox(
              color: color,
              child: player.player == null
                  ? const SizedBox.expand()
                  : VideoPlayer(player.player!),
            ),
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

class UnityVideoPlayerFlutter extends UnityVideoPlayer {
  VideoPlayerController? player;

  final _videoStream = StreamController<VideoPlayerValue>.broadcast();

  UnityVideoPlayerFlutter({
    super.width,
    super.height,
    bool enableCache = false,
    RTSPProtocol? rtspProtocol,
    String? title,
  });

  @override
  String? get dataSource => player?.dataSource;

  @override
  Stream<String> get onError => _videoStream.stream
      .where((v) => v.errorDescription != null)
      .map((e) => e.errorDescription!);

  @override
  Duration get duration => player?.value.duration ?? Duration.zero;

  @override
  Stream<Duration> get onDurationUpdate => _videoStream.stream
      .where((value) => value.duration != Duration.zero)
      .map((value) => value.duration);

  @override
  Duration get currentPos => player?.value.position ?? Duration.zero;

  @override
  Stream<Duration> get onCurrentPosUpdate =>
      _videoStream.stream.map((value) => value.position);

  @override
  Duration get currentBuffer =>
      player?.value.buffered.last.end ?? Duration.zero;

  @override
  Stream<Duration> get onBufferUpdate => _videoStream.stream
      .where((value) => value.buffered.isNotEmpty)
      .map((value) => value.buffered.last.end);

  @override
  bool get isSeekable => duration > Duration.zero;

  @override
  bool get isBuffering => player?.value.isBuffering ?? false;
  @override
  Stream<bool> get onBufferStateUpdate =>
      _videoStream.stream.map((value) => value.isBuffering);

  @override
  bool get isPlaying => player?.value.isPlaying ?? false;

  @override
  Stream<bool> get onPlayingStateUpdate =>
      _videoStream.stream.map((value) => value.isPlaying);

  @override
  Future<void> setDataSource(String url, {bool autoPlay = true}) async {
    if (url == dataSource) return Future.value();
    debugPrint('Playing $url');

    if (player != null) {
      await player?.dispose();
    }

    final uri = Uri.parse(url);

    // check if the url is a file
    if (uri.scheme == 'file') {
      player = VideoPlayerController.file(File.fromUri(uri));
    } else {
      player = VideoPlayerController.networkUrl(uri);
    }

    try {
      await player!.initialize();
      player!.addListener(() {
        _videoStream.add(player!.value);
      });
      onReady();
      if (autoPlay) {
        await player!.play();
      }
    } catch (e, _) {
      error = e.toString();
      notifyListeners();

      rethrow;
    }
  }

  @override
  Future<void> setMultipleDataSource(Iterable<String> url,
      {bool autoPlay = true}) {
    throw UnsupportedError(
      'setMultipleDataSource is not supported on this platform',
    );
  }

  @override
  Future<void> jumpToIndex(int index) {
    throw UnsupportedError(
      'jumpToIndex is not supported on this platform',
    );
  }

  // Volume in media kit goes from 0 to 100
  @override
  Future<void> setVolume(double volume) async =>
      await player?.setVolume(volume);

  @override
  double get volume => (player?.value.volume ?? 0.0);

  @override
  Stream<double> get volumeStream => _videoStream.stream.map((_) => volume);

  @override
  double get fps => 0.0;
  @override
  Stream<double> get fpsStream => Stream.value(fps);

  @override
  double get aspectRatio => player?.value.aspectRatio ?? 1.0;

  @override
  Future<String> getProperty(String propertyName) {
    throw UnsupportedError(
      'getProperty is not supported on this platform',
    );
  }

  @override
  Future<void> setSpeed(double speed) async =>
      await player?.setPlaybackSpeed(speed);
  @override
  Future<void> seekTo(Duration position) async =>
      await player?.seekTo(position);

  @override
  Future<void> setSize(Size size) => Future.value();

  @override
  Future<void> start() async => await player?.play();

  @override
  Future<void> pause() async => await player?.pause();

  @override
  Future<void> release() async {
    if (!kIsWeb && Platform.isLinux) {
      await pause();
      await Future.delayed(const Duration(milliseconds: 150));
    }
  }

  @override
  Future<void> reset() async {
    await pause();
    await seekTo(Duration.zero);
  }

  @override
  Future<void> dispose() async {
    await release();
    await super.dispose();
    await _videoStream.close();
    UnityVideoPlayerInterface.unregisterPlayer(this);
  }
}
