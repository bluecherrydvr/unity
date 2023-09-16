library unity_video_player_main;

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';
import 'package:path_provider/path_provider.dart';
import 'package:unity_video_player_platform_interface/unity_video_player_platform_interface.dart';

class UnityVideoPlayerMediaKitInterface extends UnityVideoPlayerInterface {
  /// Registers this class as the default instance of [UnityVideoPlayerInterface].
  static void registerWith() {
    UnityVideoPlayerInterface.instance = UnityVideoPlayerMediaKitInterface();
  }

  @override
  Future<void> initialize() async {
    MediaKit.ensureInitialized();
  }

  @override
  UnityVideoPlayer createPlayer({
    int? width,
    int? height,
    bool enableCache = false,
  }) {
    final player = UnityVideoPlayerMediaKit(
      width: width,
      height: height,
      enableCache: enableCache,
    );
    UnityVideoPlayerInterface.registerPlayer(player);
    return player;
  }

  @override
  Widget createVideoView({
    Key? key,
    required UnityVideoPlayer player,
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
            _MKVideo(
              key: ValueKey(player),
              player: (player as UnityVideoPlayerMediaKit).mkPlayer,
              videoController: player.mkVideoController,
              color: color,
              fit: () {
                return switch (fit) {
                  UnityVideoFit.contain => BoxFit.contain,
                  UnityVideoFit.cover => BoxFit.cover,
                  UnityVideoFit.fill => BoxFit.fill,
                };
              }(),
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

class _MKVideo extends StatelessWidget {
  const _MKVideo({
    super.key,
    required this.player,
    required this.videoController,
    required this.fit,
    required this.color,
  });

  final Player player;
  final VideoController videoController;
  final BoxFit fit;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Video(
      controller: videoController,
      fill: color,
      fit: fit,
      controls: NoVideoControls,
    );
  }
}

class UnityVideoPlayerMediaKit extends UnityVideoPlayer {
  Player mkPlayer = Player();
  late VideoController mkVideoController;
  late StreamSubscription errorStream;

  double _fps = 0;
  @override
  double get fps => _fps;
  final _fpsStreamController = StreamController<double>.broadcast();
  @override
  Stream<double> get fpsStream => _fpsStreamController.stream;

  UnityVideoPlayerMediaKit({
    int? width,
    int? height,
    bool enableCache = false,
  }) {
    final pixelRatio = PlatformDispatcher.instance.views.first.devicePixelRatio;
    if (width != null) width = (width * pixelRatio).toInt();
    if (height != null) height = (height * pixelRatio).toInt();

    debugPrint('Pixel ratio: $pixelRatio');

    mkVideoController = VideoController(
      mkPlayer,
      configuration: VideoControllerConfiguration(width: width, height: height),
    );

    // Check type. Only true for libmpv based platforms. Currently Windows & Linux.
    if (mkPlayer.platform is NativePlayer) {
      final platform = (mkPlayer.platform as NativePlayer)
        ..observeProperty('estimated-vf-fps', (fps) async {
          _fps = double.parse(fps);
          _fpsStreamController.add(_fps);
        });

      if (enableCache) {
        // https://mpv.io/manual/stable/#options-cache
        platform
          ..setProperty('cache', 'yes')
          // https://mpv.io/manual/stable/#options-cache-pause-initial
          ..setProperty('cache-pause-initial', 'yes')
          // https://mpv.io/manual/stable/#options-cache-pause-wait
          ..setProperty('cache-pause-wait', '1');
        getTemporaryDirectory().then((value) {
          platform
            ..setProperty('cache-on-disk', 'yes')
            ..setProperty('cache-dir', value.path);
        });
      } else {
        platform
          ..setProperty('cache', 'no')
          ..setProperty('video-sync', 'audio');
        // these two properties reduce latency, but it causes problems with FPS
        // platform.setProperty("profile", "low-latency");
        // platform.setProperty("untimed", "");
      }
    }

    errorStream = mkPlayer.stream.error.listen((event) {
      debugPrint('==== VIDEO ERROR HAPPENED with $dataSource');
      debugPrint('==== $event');
    });
  }

  Future<void> ensureVideoControllerInitialized(
    Future<void> Function(VideoController controller) cb,
  ) async {
    await cb(mkVideoController);
  }

  @override
  String? get dataSource {
    if (mkPlayer.state.playlist.medias.isEmpty) return null;

    var index = mkPlayer.state.playlist.index;
    if (index.isNegative) return null;

    return mkPlayer.state.playlist.medias[index].uri;
  }

  @override
  Stream<String> get onError => mkPlayer.stream.error.map((event) => event);

  @override
  Duration get duration => mkPlayer.state.duration;

  @override
  Stream<Duration> get onDurationUpdate => mkPlayer.stream.duration;

  @override
  Duration get currentPos => mkPlayer.state.position;

  @override
  Stream<Duration> get onCurrentPosUpdate => mkPlayer.stream.position;

  @override
  bool get isBuffering => mkPlayer.state.buffering;

  @override
  Duration get currentBuffer => mkPlayer.state.buffer;

  @override
  Stream<Duration> get onBufferUpdate => mkPlayer.stream.buffer;

  @override
  bool get isSeekable => duration > Duration.zero;

  @override
  Stream<bool> get onBufferStateUpdate => mkPlayer.stream.buffering;

  @override
  bool get isPlaying => mkPlayer.state.playing;

  @override
  Stream<bool> get onPlayingStateUpdate => mkPlayer.stream.playing;

  @override
  Future<void> setDataSource(String url, {bool autoPlay = true}) {
    if (url == dataSource) return Future.value();
    return ensureVideoControllerInitialized((controller) async {
      mkPlayer.setPlaylistMode(PlaylistMode.loop);
      // do not use mkPlayer.add because it doesn't support auto play
      await mkPlayer.open(Playlist([Media(url)]), play: autoPlay);
    });
  }

  @override
  Future<void> setMultipleDataSource(
    List<String> url, {
    bool autoPlay = true,
  }) {
    return ensureVideoControllerInitialized((controller) async {
      await mkPlayer.open(
        Playlist(url.map(Media.new).toList()),
        play: autoPlay,
      );
    });
  }

  // Volume in media kit goes from 0 to 100
  @override
  Future<void> setVolume(double volume) async =>
      mkPlayer.setVolume(volume * 100);

  @override
  double get volume => mkPlayer.state.volume / 100;

  @override
  Stream<double> get volumeStream => mkPlayer.stream.volume;

  @override
  Future<void> setSpeed(double speed) async => mkPlayer.setRate(speed);
  @override
  Future<void> seekTo(Duration position) async => mkPlayer.seek(position);

  @override
  Future<void> setSize(Size size) {
    return ensureVideoControllerInitialized((controller) async {
      await controller.setSize(
        width: size.width.toInt(),
        height: size.height.toInt(),
      );
    });
  }

  @override
  Future<void> start() {
    return ensureVideoControllerInitialized((controller) async {
      mkPlayer.play();
    });
  }

  @override
  Future<void> pause() async => mkPlayer.pause();
  @override
  Future<void> release() async {}
  @override
  Future<void> reset() async {
    await pause();
    await seekTo(Duration.zero);
  }

  @override
  Future<void> dispose() async {
    await super.dispose();
    if (mkPlayer.platform is NativePlayer) {
      final platform = mkPlayer.platform as NativePlayer;

      await platform.unobserveProperty('estimated-vf-fps');
    }
    await errorStream.cancel();
    await mkPlayer.dispose();
    _fpsStreamController.close();
    UnityVideoPlayerInterface.unregisterPlayer(this);
  }
}
