library unity_video_player_media_kit;

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';
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
  UnityVideoPlayer createPlayer({int? width, int? height}) {
    final player = UnityVideoPlayerMediaKit(width: width, height: height);
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
              fit: {
                UnityVideoFit.contain: BoxFit.contain,
                UnityVideoFit.cover: BoxFit.cover,
                UnityVideoFit.fill: BoxFit.fill,
              }[fit]!,
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
    );
  }
}

class UnityVideoPlayerMediaKit extends UnityVideoPlayer {
  Player mkPlayer = Player();
  late VideoController mkVideoController;
  late StreamSubscription errorStream;

  UnityVideoPlayerMediaKit({int? width, int? height}) {
    final pixelRatio = PlatformDispatcher.instance.views.first.devicePixelRatio;
    if (width != null) width = (width * pixelRatio).toInt();
    if (height != null) height = (height * pixelRatio).toInt();

    debugPrint('Pixel ratio: $pixelRatio');

    mkVideoController = VideoController(
      mkPlayer,
      configuration: VideoControllerConfiguration(width: width, height: height),
    );

    // Check type. Only true for libmpv based platforms. Currently Windows & Linux.
    if (mkPlayer.platform is libmpvPlayer) {
      final platform = (mkPlayer.platform as libmpvPlayer?);
      // https://mpv.io/manual/stable/#options-cache
      platform?.setProperty("cache", "yes");
      // https://mpv.io/manual/stable/#options-cache-pause-initial
      platform?.setProperty("cache-pause-initial", "yes");
      // https://mpv.io/manual/stable/#options-cache-pause-wait
      platform?.setProperty("cache-pause-wait", "3");

      platform?.setProperty("profile", "low-latency");
      // platform?.setProperty("untimed", "");
    }

    errorStream = mkPlayer.streams.error.listen((event) {
      debugPrint('==== VIDEO ERROR HAPPENED with $dataSource');
      debugPrint('==== with code ${event.code}');
      debugPrint('==== ${event.message}');
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
  String? get error {
    // if (mkPlayer.error.isEmpty) return null;
    // return mkPlayer.error;

    return null;
  }

  @override
  Duration get duration => mkPlayer.state.duration;

  @override
  Stream<Duration> get onDurationUpdate => mkPlayer.streams.duration;

  @override
  Duration get currentPos => mkPlayer.state.position;

  @override
  Stream<Duration> get onCurrentPosUpdate => mkPlayer.streams.position;

  @override
  bool get isBuffering => mkPlayer.state.buffering;

  @override
  Duration get currentBuffer => mkPlayer.state.buffer;

  @override
  Stream<Duration> get onBufferUpdate => mkPlayer.streams.buffer;

  @override
  bool get isSeekable => true;

  @override
  Stream<bool> get onBufferStateUpdate => mkPlayer.streams.buffering;

  @override
  bool get isPlaying => mkPlayer.state.playing;

  @override
  Stream<bool> get onPlayingStateUpdate => mkPlayer.streams.playing;

  @override
  Future<void> setDataSource(String url, {bool autoPlay = true}) {
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
        Playlist(url.map((source) => Media(source)).toList()),
        play: autoPlay,
      );
    });
  }

  // Volume in media kit goes from 0 to 100
  @override
  Future<void> setVolume(double volume) async =>
      mkPlayer.setVolume(volume * 100);

  @override
  Future<double> get volume async => mkPlayer.state.volume / 100;

  @override
  Future<void> setSpeed(double speed) async => mkPlayer.setRate(speed);
  @override
  Future<void> seekTo(Duration position) async => await mkPlayer.seek(position);

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
  void dispose() async {
    errorStream.cancel();
    mkPlayer.dispose();
    UnityVideoPlayerInterface.unregisterPlayer(this);
  }
}
