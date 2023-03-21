library unity_video_player_media_kit;

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
  Future<void> initialize() async {}

  @override
  UnityVideoPlayer createPlayer({int? width, int? height}) {
    final player = UnityVideoPlayerMediaKit(width: width, height: height);
    UnityVideoPlayerInterface.registerPlayer(player);
    return player;
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
          child: _MKVideo(
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

class _MKVideo extends StatefulWidget {
  const _MKVideo({
    Key? key,
    required this.player,
    required this.videoController,
    required this.fit,
    required this.color,
  }) : super(key: key);

  final Player player;
  final Future<VideoController> videoController;
  final BoxFit fit;
  final Color color;

  @override
  State<_MKVideo> createState() => __MKVideoState();
}

class __MKVideoState extends State<_MKVideo> {
  VideoController? videoController;

  @override
  void initState() {
    super.initState();

    widget.videoController.then((value) {
      videoController = value;
      if (mounted) setState(() {});
    });
  }

  @override
  Widget build(BuildContext context) {
    return Video(
      controller: videoController,
      fill: widget.color,
      fit: widget.fit,
    );
  }
}

class UnityVideoPlayerMediaKit extends UnityVideoPlayer {
  Player mkPlayer = Player();
  late Future<VideoController> mkVideoController;

  UnityVideoPlayerMediaKit({int? width, int? height}) {
    // final finalSize = width == null || height == null
    //     ? const Size(640, 360)
    //     : Size(
    //         width.toDouble(),
    //         width * (9 / 16),
    // );

    mkVideoController = VideoController.create(
      mkPlayer.handle,
      // height: finalSize.height.toInt(),
      // width: finalSize.width.toInt(),
      // width: width,
      // height: height,
      width: 640,
      height: 360,
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
    }
  }

  Future<void> ensureVideoControllerInitialized(
    Future<void> Function() cb,
  ) async {
    await mkVideoController.then((_) async {
      return await cb();
    });
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
  bool get isBuffering => mkPlayer.state.isBuffering;

  @override
  bool get isSeekable => true;

  @override
  Stream<bool> get onBufferStateUpdate => mkPlayer.streams.isBuffering;

  @override
  bool get isPlaying => mkPlayer.state.isPlaying;

  @override
  Stream<bool> get onPlayingStateUpdate => mkPlayer.streams.isPlaying;

  @override
  Future<void> setDataSource(String url, {bool autoPlay = true}) {
    return ensureVideoControllerInitialized(() async {
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
    return ensureVideoControllerInitialized(() async {
      await mkPlayer.open(
        Playlist(url.map((source) => Media(source)).toList()),
        play: autoPlay,
      );
    });
  }

  // Volume in media kit goes from 0 to 100
  @override
  Future<void> setVolume(double volume) async => mkPlayer.volume = volume * 100;

  @override
  Future<double> get volume async => mkPlayer.state.volume / 100;

  @override
  Future<void> setSpeed(double speed) async => mkPlayer.rate = speed;
  @override
  Future<void> seekTo(Duration position) async => await mkPlayer.seek(position);

  @override
  Future<void> start() {
    return ensureVideoControllerInitialized(() async {
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
    await (await mkVideoController).dispose();
    await mkPlayer.dispose();
    UnityVideoPlayerInterface.unregisterPlayer(this);
  }
}
