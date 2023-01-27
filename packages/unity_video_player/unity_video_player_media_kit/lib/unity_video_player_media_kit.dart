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
      setState(() => videoController = value);
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    if (!widget.player.state.isPlaying) widget.player.play();
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
    mkVideoController = VideoController.create(
      mkPlayer.handle,
      height: height,
      width: width,
    );
  }

  void ensureVideoControllerInitialized(VoidCallback cb) {
    mkVideoController.then((_) {
      cb();
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
  Duration get currentPos => mkPlayer.state.position;

  @override
  bool get isBuffering => mkPlayer.state.isBuffering;

  @override
  bool get isSeekable => true;

  @override
  Stream<Duration> get onCurrentPosUpdate => mkPlayer.streams.position;
  @override
  Stream<bool> get onBufferStateUpdate => mkPlayer.streams.isBuffering;

  @override
  bool get isPlaying => mkPlayer.state.isPlaying;

  @override
  Stream<bool> get onPlayingStateUpdate => mkPlayer.streams.isPlaying;

  @override
  Future<void> setDataSource(String url, {bool autoPlay = true}) async {
    ensureVideoControllerInitialized(() {
      // do not use mkPlayer.add because it doesn't support auto play
      mkPlayer.open(Playlist([Media(url)]), play: autoPlay);
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
  Future<void> seekTo(Duration position) async => mkPlayer.seek(position);

  @override
  Future<void> start() async => mkPlayer.play();
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
