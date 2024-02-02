library unity_video_player_platform_interface;

import 'dart:async';

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
  cover;

  UnityVideoFit get next {
    return switch (this) {
      UnityVideoFit.contain => UnityVideoFit.fill,
      UnityVideoFit.fill => UnityVideoFit.cover,
      UnityVideoFit.cover => UnityVideoFit.contain
    };
  }
}

enum RTSPProtocol { tcp, udp }

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

  /// Whether the app should be kept awake while playing videos.
  static bool wakelockEnabled = true;

  /// Called to initialize any resources before using it
  Future<void> initialize();

  /// Creates a player
  UnityVideoPlayer createPlayer({
    int? width,
    int? height,
    bool enableCache = false,
    RTSPProtocol? rtspProtocol,
    String? title,
  });

  /// Creates a video view
  Widget createVideoView({
    Key? key,
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

  /// Diposes all the player instances
  static Future<void> dispose() {
    return Future.microtask(() async {
      for (final player in UnityVideoPlayerInterface.players.toList()) {
        debugPrint('Disposing player ${player.hashCode}');
        await player.dispose();
      }
    });
  }
}

class VideoViewInheritance extends InheritedWidget {
  const VideoViewInheritance({
    super.key,
    required super.child,
    required this.error,
    required this.position,
    required this.duration,
    required this.isImageOld,
    required this.lastImageUpdate,
    required this.fps,
    required this.player,
  });

  /// When the video is in an error state, this will be set with a description
  final String? error;

  /// The current position of the video. This is updated as the video plays.
  final Duration position;

  /// The duration of the video. This is updated when the video is ready to play
  /// or when it's buffering.
  final Duration duration;

  /// Whether the frame is old.
  ///
  /// This can be used to warn the user the image is stuck at some point and
  /// some action is required to continue playing, such as reconnecting to the
  /// internet or reloading the camera.
  ///
  /// This is usually used when the video is unpauseable and unseekable.
  final bool isImageOld;

  /// The last time the image was updated.
  final DateTime? lastImageUpdate;

  /// The FPS of the video.
  final int fps;

  /// The player that is currently being used by the video.
  final UnityVideoPlayer player;

  bool get isLoading => !player.isSeekable && error == null;

  static VideoViewInheritance? maybeOf(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<VideoViewInheritance>();
  }

  @override
  bool updateShouldNotify(VideoViewInheritance oldWidget) {
    return error != oldWidget.error ||
        position != oldWidget.position ||
        duration != oldWidget.duration;
  }
}

/// A widget that displays a video from a [UnityVideoPlayer].
class UnityVideoView extends StatefulWidget {
  /// The player that is currently being used by the video.
  final UnityVideoPlayer player;

  /// The image fit. Defaults to [UnityVideoFit.contain].
  final UnityVideoFit fit;

  /// Builds the foreground of the video view.
  final UnityVideoPaneBuilder? paneBuilder;

  /// Builds the video view itself. Can be used to wrap the video with some
  /// widget.
  final UnityVideoBuilder? videoBuilder;

  /// The background color of the view when nothing is painted. Defaults to
  /// black.
  final Color color;

  /// The hero tag for the video view.
  ///
  /// See also:
  ///
  ///   * [Hero.tag], the identifier for this particular hero.
  final dynamic heroTag;

  /// Creates a new video view.
  const UnityVideoView({
    super.key,
    required this.player,
    this.fit = UnityVideoFit.contain,
    this.paneBuilder,
    this.videoBuilder,
    this.color = const Color(0xFF000000),
    this.heroTag,
  });

  static VideoViewInheritance of(BuildContext context) {
    return VideoViewInheritance.maybeOf(context)!;
  }

  static VideoViewInheritance? maybeOf(BuildContext context) {
    return VideoViewInheritance.maybeOf(context);
  }

  @override
  State<UnityVideoView> createState() => UnityVideoViewState();
}

class UnityVideoViewState extends State<UnityVideoView> {
  @override
  void initState() {
    super.initState();
    widget.player.addListener(_onPlayerUpdate);
  }

  @override
  void didUpdateWidget(covariant UnityVideoView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.player != widget.player) {
      oldWidget.player.removeListener(_onPlayerUpdate);
      widget.player.addListener(_onPlayerUpdate);
    }
  }

  void _onPlayerUpdate() {
    setState(() {});
  }

  @override
  void dispose() {
    widget.player.removeListener(_onPlayerUpdate);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final videoView = VideoViewInheritance(
      player: widget.player,
      error: widget.player.error,
      position: widget.player.currentPos,
      duration: widget.player.duration,
      isImageOld: widget.player.isImageOld,
      fps: widget.player.fps.toInt(),
      lastImageUpdate: widget.player.lastImageUpdate,
      child: UnityVideoPlayerInterface.instance.createVideoView(
        player: widget.player,
        color: widget.color,
        fit: widget.fit,
        videoBuilder: widget.videoBuilder,
        paneBuilder: widget.paneBuilder,
      ),
    );

    if (widget.heroTag != null) {
      return Hero(tag: widget.heroTag, child: videoView);
    }

    return videoView;
  }
}

/// The size of a view with 4K resolution
const p4kResolution = Size(3840, 2160);

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
  p4k._(resolution: p4kResolution, isHD: true),
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
    return switch (height) {
      1080 => p1080,
      720 => p720,
      480 => p480,
      360 => p360,
      240 => p240,
      _ => p480,
    };
  }
}

abstract class UnityVideoPlayer with ChangeNotifier {
  Future<String>? fallbackUrl;
  VoidCallback? onReload;

  /// Creates a new [UnityVideoPlayer] instance.
  ///
  /// The [quality] parameter is used to set the rendering resolution of the
  /// video. It defaults to [UnityVideoQuality.p360].
  ///
  /// The [enableCache] parameter is used to enable or disable the cache for the
  /// video. It defaults to `false`. It is usually true when vieweing recorded
  /// videos, not streams.
  ///
  /// The [rtspProtocol] parameter is used to set the rtsp protocol for the
  /// video. It is only applied on rtsp streams.
  ///
  /// The [fallbackUrl] parameter is used to set the fallback url for the
  /// video. It is only used if the initial source fails to load.
  ///
  /// The [onReload] parameter is called when the video needs to be reloaded.
  /// It is usually used when the image has been old for a while.
  static UnityVideoPlayer create({
    UnityVideoQuality quality = UnityVideoQuality.p360,
    bool enableCache = false,
    RTSPProtocol? rtspProtocol,
    Future<String>? fallbackUrl,
    VoidCallback? onReload,
    String? title,
  }) {
    return UnityVideoPlayerInterface.instance.createPlayer(
      width: quality.resolution.width.toInt(),
      height: quality.resolution.height.toInt(),
      enableCache: enableCache,
      rtspProtocol: rtspProtocol,
      title: title,
    )
      ..quality = quality
      ..fallbackUrl = fallbackUrl
      ..onReload = onReload;
  }

  static const timerInterval = Duration(seconds: 6);
  Timer? _oldImageTimer;
  bool _isImageOld = false;
  bool get isImageOld => _isImageOld;
  DateTime? _lastImageTime;
  DateTime? get lastImageUpdate => _lastImageTime;

  late StreamSubscription<Duration> _onDurationUpdateSubscription;
  late StreamSubscription<String> _onErrorSubscription;
  late StreamSubscription<Duration> _onPositionUpdateSubscription;
  late StreamSubscription<double> _fpsSubscription;

  int? width;
  int? height;
  String? error;

  UnityVideoQuality? quality;

  late final VoidCallback onReady;

  UnityVideoPlayer({this.width, this.height}) {
    onReady = () {
      _onErrorSubscription = onError.listen(_onError);
      _onDurationUpdateSubscription =
          onDurationUpdate.listen(_onDurationUpdate);
      _onPositionUpdateSubscription =
          onCurrentPosUpdate.listen(_onPositionUpdate);
      _fpsSubscription = fpsStream.listen(_onFpsUpdate);
    };
  }

  void _onDurationUpdate(Duration duration) {
    if (duration > Duration.zero) {
      _lastImageTime = DateTime.now();
      _isImageOld = false;
      error = null;
      _oldImageTimer?.cancel();
      _oldImageTimer = Timer(timerInterval, () {
        // If the image is still the same after the interval, then it's old.
        _isImageOld = true;

        if (lastImageUpdate != null) {
          final difference = lastImageUpdate!.difference(DateTime.now());
          if (difference > timerInterval * 2) {
            // If the image is still the same after twice the interval, then
            // it's probably stuck and we should reload the video.
            onReload?.call();
          }
        }
      });
      notifyListeners();
    }
  }

  void _onError(String error) async {
    this.error = error;
    notifyListeners();

    debugPrint('==== VIDEO ERROR HAPPENED with $dataSource');
    debugPrint('==== $error');

    // If the video is not supported, try to play the fallback url
    if (error == 'Failed to recognize file format.' &&
        fallbackUrl != null &&
        lastImageUpdate != null) {
      setDataSource(await fallbackUrl!);
    }
  }

  void _onPositionUpdate(Duration duration) {
    error = null;
    notifyListeners();
  }

  void _onFpsUpdate(double fps) {
    notifyListeners();
  }

  /// Whether the current position of the video is not the same or near the
  /// last image update.
  ///
  /// The video is considered late if the current position is more than 1.5
  /// seconds after the last image update.
  bool get isLate {
    if (lastImageUpdate == null) return false;
    final now = DateTime.now();
    final diff = now.difference(lastImageUpdate!);
    return diff.inMilliseconds > 1500;
  }

  /// The current data source url
  String? get dataSource;

  /// The current error, if any
  Stream<String> get onError;

  /// The duration of the current media.
  ///
  /// May be [Duration.zero]
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

  double get fps;
  Stream<double> get fpsStream;

  /// Whether the media is seekable
  bool get isSeekable;

  Future<void> setDataSource(String url, {bool autoPlay = true});
  Future<void> setMultipleDataSource(
    List<String> url, {
    bool autoPlay = true,
  });

  Future<void> setVolume(double volume);
  double get volume;
  Stream<double> get volumeStream;

  Future<void> setSpeed(double speed);
  Future<void> seekTo(Duration position);

  Future<void> setSize(Size size);
  double get aspectRatio;

  Future<void> setResolution(UnityVideoQuality quality) {
    this.quality = quality;
    return setSize(quality.resolution);
  }

  Future<void> start();
  Future<void> pause();
  Future<void> release();
  Future<void> reset();

  Future<void> resetCrop();
  Future<void> crop(int row, int col, int size);
  bool get isCropped;

  @mustCallSuper
  @override
  Future<void> dispose() async {
    _onDurationUpdateSubscription.cancel();
    _onErrorSubscription.cancel();
    _onPositionUpdateSubscription.cancel();
    _fpsSubscription.cancel();
    _oldImageTimer?.cancel();
    _lastImageTime = null;
    _isImageOld = false;

    super.dispose();
  }
}
