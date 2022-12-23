library unity_video_player_platform_interface;

import 'package:plugin_platform_interface/plugin_platform_interface.dart';

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
  UnityVideoPlayer createPlayer();
}

abstract class UnityVideoPlayer {
  /// The current data source url
  String? get dataSource;

  /// The current error, if any
  String? get error;

  /// The duration of the current media.
  ///
  /// May be 0
  Duration get duration;

  /// The current position of the current media.
  Duration get currentPos;

  /// Whether the media is buffering
  bool get isBuffering;
  Stream<Duration> get onCurrentPosUpdate;
  Stream<bool> get onBufferStateUpdate;

  /// Whether the media is playing
  bool get isPlaying;

  Future<void> setDataSource(String url, {bool autoPlay = true});
  Future<void> setVolume(double volume);
  Future<void> setSpeed(double speed);
  Future<void> seekTo(int msec);

  Future<void> start();
  Future<void> pause();
  Future<void> release();
  Future<void> reset();

  void dispose();
}
