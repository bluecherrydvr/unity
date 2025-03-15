import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutterpi_gstreamer_video_player/flutterpi_gstreamer_video_player.dart';
import 'package:fvp/fvp.dart' as fvp;
import 'package:unity_video_player_platform_interface/unity_video_player_platform_interface.dart';
import 'package:video_player/video_player.dart';

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
        const SizedBox.expand(),
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

  @override
  bool get supportsFPS => false;

  @override
  bool get supportsHardwareZoom => false;
}

class UnityVideoPlayerFlutter extends UnityVideoPlayer {
  VideoPlayerController? player;

  final _videoStream = StreamController<VideoPlayerValue>.broadcast();

  RTSPProtocol? rtspProtocol;

  UnityVideoPlayerFlutter({
    super.width,
    super.height,
    bool enableCache = false,
    this.rtspProtocol,
    String? title,
  }) {
    if (title != null) this.title = title;
  }

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
  Duration get currentBuffer {
    if (player == null) return Duration.zero;
    if (player!.value.buffered.isEmpty) return Duration.zero;
    return player!.value.buffered.last.end;
  }

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
  Future<void> setDataSource(
    String url, {
    bool autoPlay = true,
    Map<String, String>? headers,
  }) async {
    if (url == dataSource) return Future.value();

    if (player != null) {
      debugPrint('Disposing player for $dataSource');
      await player?.dispose();
      player = null;
    }
    debugPrint('Playing $url');

    final uri = Uri.parse(url);

    // check if the url is a file
    if (uri.scheme == 'file') {
      player = VideoPlayerController.file(File.fromUri(uri));
    } else {
      player = VideoPlayerController.networkUrl(
        uri,
        httpHeaders: headers ?? const <String, String>{},
      );
    }

    try {
      await player!.initialize();
      player!.addListener(() {
        if (_videoStream.isClosed) return;
        _videoStream.add(player!.value);
      });
      onReady();
      if (autoPlay) {
        await player!.play();
      }
    } catch (e, stackTrace) {
      error = e.toString();
      _videoStream.addError(e, stackTrace);
      notifyListeners();
    }
  }

  var _multipleDataSources = <String>[];

  @override
  Future<void> setMultipleDataSource(
    Iterable<String> url, {
    bool autoPlay = true,
    int startIndex = 0,
  }) {
    _multipleDataSources = url.toList();
    return setDataSource(url.elementAt(startIndex), autoPlay: autoPlay);
  }

  @override
  Future<void> jumpToIndex(int index) {
    if (index < 0 || index >= _multipleDataSources.length) {
      return Future.error('Index out of range');
    }

    return setDataSource(_multipleDataSources[index]);
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
  double get aspectRatio => player?.value.aspectRatio ?? 0;

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
    if (!kIsWeb) {
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
    debugPrint('Disposing player for $dataSource');
    await release();
    await super.dispose();
    await _videoStream.close();
    player
      ?..pause()
      ..dispose();
    UnityVideoPlayerInterface.unregisterPlayer(this);
  }
}
