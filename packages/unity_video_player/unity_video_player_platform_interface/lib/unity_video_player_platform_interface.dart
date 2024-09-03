library unity_video_player_platform_interface;

import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import 'video_zoom.dart';

export 'video_zoom.dart';
export 'video_view.dart';

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

enum RTSPProtocol {
  tcp,
  udp;
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
}

/// How to handle late video streams.
enum LateVideoBehavior {
  /// Automatically jump to the current time.
  automatic,

  /// Show an option to jump to the current time.
  manual,

  /// Do nothing.
  never;
}

const kDefaultVideoPlayerName = 'Bluecherry';

abstract class UnityVideoPlayer with ChangeNotifier {
  Future<String>? fallbackUrl;
  VoidCallback? onReload;
  ValueChanged<String>? onLog;
  late LateVideoBehavior lateVideoBehavior;

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
    UnityVideoQuality? quality,
    bool enableCache = false,
    RTSPProtocol? rtspProtocol,
    Future<String>? fallbackUrl,
    VoidCallback? onReload,
    String? title,
    LateVideoBehavior lateVideoBehavior = LateVideoBehavior.automatic,
    MatrixType matrixType = MatrixType.t1,
    bool softwareZoom = false,
    ValueChanged<String>? onLog,
  }) {
    return UnityVideoPlayerInterface.instance.createPlayer(
      width: quality?.resolution.width.toInt(),
      height: quality?.resolution.height.toInt(),
      enableCache: enableCache,
      rtspProtocol: rtspProtocol,
    )
      ..quality = quality
      ..fallbackUrl = fallbackUrl
      ..onReload = onReload
      ..lateVideoBehavior = lateVideoBehavior
      ..zoom.matrixType = matrixType
      ..zoom.softwareZoom = softwareZoom
      ..title = title ?? kDefaultVideoPlayerName
      ..onLog = onLog;
  }

  static const timerInterval = Duration(seconds: 14);
  Timer? _oldImageTimer;
  bool _isImageOld = false;

  /// Whether the frame is old.
  ///
  /// This can be used to warn the user the image is stuck at some point and
  /// some action is required to continue playing, such as reconnecting to the
  /// internet or reloading the camera.
  ///
  /// This is usually used when the video is unpauseable and unseekable.
  bool get isImageOld => _isImageOld;
  DateTime? _lastImageTime;
  DateTime? get lastImageUpdate => _lastImageTime;

  late StreamSubscription<Duration> _onDurationUpdateSubscription;
  late StreamSubscription<String> _onErrorSubscription;
  late StreamSubscription<Duration> _onPositionUpdateSubscription;
  late StreamSubscription<double> _fpsSubscription;

  String title = 'Bluecherry';

  int? width;
  int? height;
  Size? get resolution => width != null && height != null
      ? Size(width!.toDouble(), height!.toDouble())
      : null;
  String? error;

  UnityVideoQuality? quality;
  VideoZoom zoom = VideoZoom();

  /// Called when the video source is ready to be listened to.
  ///
  /// Implementations must call this when the video source is ready to be
  /// listened to.
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
      _oldImageTimer = Timer.periodic(timerInterval, (timer) {
        // If the image is still the same after the interval, then it's old.
        _isImageOld = true;

        if (lastImageUpdate != null) {
          final difference = lastImageUpdate!.difference(DateTime.now());
          if (difference > timerInterval * 3) {
            // If the image is still the same after twice the interval, then
            // it's probably stuck and we should reload the video.
            onReload?.call();
            timer.cancel();
            notifyListeners();
          }
        }
        notifyListeners();
      });
      _handleLateVideo();
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

  void _onPositionUpdate(Duration position) {
    error = null;
    _handleLateVideo();
    notifyListeners();
  }

  void _onFpsUpdate(double fps) {
    notifyListeners();
  }

  static const kLateStreamThreshold = Duration(milliseconds: 1500);

  /// Whether the current position of the video is not the same or near the
  /// last image update.
  ///
  /// The video is considered late if the current position is greater than
  /// [kLateStreamThreshold] after the last image update
  ///
  /// OR
  ///
  /// if the difference between the last image update and the current position
  /// is greater than [kLateStreamThreshold].
  bool get isLate {
    if (dataSource == null || lastImageUpdate == null || !isLive) return false;
    final lastImageDiff = DateTime.now().difference(lastImageUpdate!);
    if (lastImageDiff > kLateStreamThreshold) return true;

    // final positionDiff = (duration - currentPos).abs();
    // if (positionDiff > kLateStreamThreshold) return true;

    return false;
  }

  /// Whether the video is a live stream.
  ///
  /// A live stream is considered any url which protocol is either RTSP or RTMP.
  /// MJPEG and HLS are also considered live streams in a Bluecherry Server.
  bool get isLive {
    if (dataSource == null) return false;

    final source = dataSource!.toLowerCase().trim();
    for (var protocol in ['rtsp', 'rtmp']) {
      if (source.startsWith(protocol)) return true;
    }

    // HLS and MJPEG are also considered live streams in a Bluecherry Server.
    return source.contains('media/mjpeg') || source.contains('.m3u8');
  }

  bool get isRecorded => !isLive;

  void _handleLateVideo() {
    switch (lateVideoBehavior) {
      case LateVideoBehavior.automatic:
        dismissLateVideo();
        break;
      case LateVideoBehavior.never:
      case LateVideoBehavior.manual:
        break;
    }
  }

  void dismissLateVideo() {
    if (isLate) {
      // debugPrint('Dismissing late video');
      // seekTo(duration);
      // start();
    }
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

  Future<String> getProperty(String propertyName);

  /// Whether the media is seekable
  bool get isSeekable;

  Future<void> setDataSource(String url, {bool autoPlay = true});
  Future<void> setMultipleDataSource(
    Iterable<String> url, {
    bool autoPlay = true,
  });
  Future<void> jumpToIndex(int index);

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

  @mustCallSuper
  Future<void> resetCrop() => crop(-1, -1);

  @mustCallSuper
  Future<void> crop(int row, int col) async {
    zoom.zoomAxis = (row, col);
  }

  @mustCallSuper
  bool get isCropped {
    return zoom.zoomAxis != (-1, -1);
  }

  @mustCallSuper
  @override
  Future<void> dispose() async {
    try {
      _onDurationUpdateSubscription.cancel();
      _onErrorSubscription.cancel();
      _onPositionUpdateSubscription.cancel();
      _fpsSubscription.cancel();
      _oldImageTimer?.cancel();
    } catch (error, stack) {
      debugPrint('Tried to cancel subscriptions but failed: $error, $stack');
    }
    _lastImageTime = null;
    _isImageOld = false;

    super.dispose();
  }
}
