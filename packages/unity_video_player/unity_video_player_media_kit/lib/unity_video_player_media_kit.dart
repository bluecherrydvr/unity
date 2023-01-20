library unity_video_player_media_kit;

import 'package:flutter/material.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_core_video/media_kit_core_video.dart';
import 'package:unity_video_player_platform_interface/unity_video_player_platform_interface.dart';

class UnityVideoPlayerMediaKitInterface extends UnityVideoPlayerInterface {
  /// Registers this class as the default instance of [UnityVideoPlayerInterface].
  static void registerWith() {
    UnityVideoPlayerInterface.instance = UnityVideoPlayerMediaKitInterface();
  }

  @override
  Future<void> initialize() async {}

  @override
  UnityVideoPlayer createPlayer() {
    return UnityVideoPlayerMediaKit();
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
    required this.fit,
    required this.color,
  }) : super(key: key);

  final Player player;
  final BoxFit fit;
  final Color color;

  @override
  State<_MKVideo> createState() => __MKVideoState();
}

class __MKVideoState extends State<_MKVideo> {
  // Reference to the [VideoController] instance from `package:media_kit_core_video`.
  VideoController? controller;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      // Create a [VideoController] instance from `package:media_kit_core_video`.
      // Pass the [handle] of the [Player] from `package:media_kit` to the [VideoController] constructor.
      controller = await VideoController.create(widget.player.handle);
      setState(() {});
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    if (!widget.player.state.isPlaying) widget.player.play();
  }

  @override
  void dispose() {
    controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Video(
      controller: controller,
      fill: widget.color,
      fit: widget.fit,
    );
  }
}

class UnityVideoPlayerMediaKit extends UnityVideoPlayer {
  Player mkPlayer = Player();

  @override
  String? get dataSource =>
      mkPlayer.state.playlist.medias[mkPlayer.state.playlist.index].uri;

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
    // do not use mkPlayer.add because it doesn't support auto play
    mkPlayer.open(Playlist([Media(url)]), play: autoPlay);
  }

  @override
  Future<void> setMultipleDataSource(
    List<UnityVideoPlayerSource> url, {
    bool autoPlay = true,
  }) async {
    mkPlayer.open(
      Playlist(url.map((source) {
        if (source is UnityVideoPlayerUrlSource) {
          return Media((source as UnityVideoPlayerUrlSource).url);
        } else if (source is UnityVideoPlayerSilenceSource) {
          // TODO(bdlukaa): silence source
        } else if (source is UnityVideoPlayerAssetSource) {
          // TODO(bdlukaa): asset source
        }

        throw UnsupportedError('${source.runtimeType} is not a supported type');
      }).toList()),
      play: autoPlay,
    );
  }

  @override
  Future<void> setVolume(double volume) async => mkPlayer.volume = volume;

  @override
  Future<double> get volume => mkPlayer.streams.volume.last;

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
    await mkPlayer.dispose();
  }
}
