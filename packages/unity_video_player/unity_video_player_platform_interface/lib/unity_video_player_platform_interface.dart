library unity_video_player_platform_interface;

import 'package:flutter/widgets.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

typedef UnityVideoPaneBuilder = Widget Function(
  BuildContext context,
  UnityVideoPlayer controller,
)?;

typedef UnityVideoBuilder = Widget Function(
  BuildContext context,
  Widget video,
)?;

enum UnityVideoFit {
  contain,
  fill,
  cover,
}

abstract class UnityVideoPlayerInterface extends PlatformInterface {
  UnityVideoPlayerInterface() : super(token: _token);

  static late UnityVideoPlayerInterface _instance;

  static final Object _token = Object();

  static UnityVideoPlayerInterface get instance => _instance;

  /// Platform-specific plugins should set this with their own platform-specific
  /// class that extends [UnityVideoPlayer] when they register themselves.
  static set instance(UnityVideoPlayerInterface instance) {
    PlatformInterface.verify(instance, _token);
    _instance = instance;
  }

  /// Called to initialize any resources before using it
  Future<void> initialize();

  /// Creates a player
  UnityVideoPlayer createPlayer({int? width, int? height});

  /// Creates a video view
  Widget createVideoView({
    required UnityVideoPlayer player,
    UnityVideoFit fit = UnityVideoFit.contain,
    UnityVideoPaneBuilder? paneBuilder,
    UnityVideoBuilder? videoBuilder,
    Color color = const Color(0xFF000000),
  });

  static final _appPlayers = <UnityVideoPlayer>[];
  static List<UnityVideoPlayer> get players => _appPlayers;

  static void registerPlayer(UnityVideoPlayer player) {
    _appPlayers.add(player);
  }

  static void unregisterPlayer(UnityVideoPlayer player) {
    _appPlayers.remove(player);
  }
}

// ignore: non_constant_identifier_names
Widget UnityVideoView({
  required UnityVideoPlayer player,
  UnityVideoFit fit = UnityVideoFit.contain,
  UnityVideoPaneBuilder? paneBuilder,
  UnityVideoBuilder? videoBuilder,
  Color color = const Color(0xFF000000),
}) {
  return UnityVideoPlayerInterface.instance.createVideoView(
    player: player,
    color: color,
    fit: fit,
    videoBuilder: videoBuilder,
    paneBuilder: paneBuilder,
  );
}

/// The size of a view with 1080p resolution
const p1080Resolution = Size(1920, 1080);

/// The size of a view with 720p resolution
const p720Resolution = Size(1280, 720);

/// The size of a view with 480p resolution
const p480Resolution = Size(852, 480);

/// The size of a view with 360p resolution
const p360Resolution = Size(640, 360);

/// The size of a view with 240p resolution
const p240Resolution = Size(426, 240);

enum UnityVideoQuality {
  p1080._(resolution: p1080Resolution, isHD: true),
  p720._(resolution: p720Resolution, isHD: true),
  p480._(resolution: p480Resolution),
  p360._(resolution: p360Resolution),
  p240._(resolution: p240Resolution);

  final Size resolution;
  final bool isHD;

  const UnityVideoQuality._({required this.resolution, this.isHD = false});

  /// Returns the video quality for the video height
  static UnityVideoQuality qualityForResolutionY(int? height) {
    return {
          1080: p1080,
          720: p720,
          480: p480,
          360: p360,
          240: p240,
        }[height] ??
        UnityVideoQuality.p480;
  }
}

abstract class UnityVideoPlayer {
  static UnityVideoPlayer create({
    UnityVideoQuality quality = UnityVideoQuality.p360,
  }) {
    return UnityVideoPlayerInterface.instance.createPlayer(
      width: quality.resolution.width.toInt(),
      height: quality.resolution.height.toInt(),
    )..quality = quality;
  }

  UnityVideoQuality? quality;

  /// The current data source url
  String? get dataSource;

  /// The current error, if any
  String? get error;

  /// The duration of the current media.
  ///
  /// May be 0
  Duration get duration;
  Stream<Duration> get onDurationUpdate;

  /// The current position of the current media.
  Duration get currentPos;
  Stream<Duration> get onCurrentPosUpdate;

  /// Whether the media is buffering
  bool get isBuffering;
  Stream<bool> get onBufferStateUpdate;

  /// The current buffer position
  Duration get currentBuffer;
  Stream<Duration> get onBufferUpdate;

  /// Whether the media is playing
  bool get isPlaying;
  Stream<bool> get onPlayingStateUpdate;

  /// Whether the media is seekable
  bool get isSeekable;

  Future<void> setDataSource(String url, {bool autoPlay = true});
  Future<void> setMultipleDataSource(
    List<String> url, {
    bool autoPlay = true,
  });
  Future<void> setVolume(double volume);

  /// The current media volume
  Future<double> get volume;

  Future<void> setSpeed(double speed);
  Future<void> seekTo(Duration position);

  Future<void> setSize(Size size);

  Future<void> setResolution(UnityVideoQuality quality) {
    this.quality = quality;
    return setSize(quality.resolution);
  }

  Future<void> start();
  Future<void> pause();
  Future<void> release();
  Future<void> reset();

  void dispose();
}
