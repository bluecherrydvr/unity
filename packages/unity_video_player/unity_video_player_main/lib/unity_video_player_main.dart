library unity_video_player_main;

import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';
import 'package:path_provider/path_provider.dart';
import 'package:unity_video_player_platform_interface/unity_video_player_platform_interface.dart';

class UnityVideoPlayerMediaKitInterface extends UnityVideoPlayerInterface {
  /// Registers this class as the default instance of [UnityVideoPlayerInterface].
  static void registerWith([registrar]) {
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
    RTSPProtocol? rtspProtocol,
    VoidCallback? onReload,
    String? title,
  }) {
    final player = UnityVideoPlayerMediaKit(
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

class _MKVideo extends StatefulWidget {
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
  State<_MKVideo> createState() => _MKVideoState();
}

class _MKVideoState extends State<_MKVideo> {
  final videoKey = GlobalKey<VideoState>();

  @override
  void didUpdateWidget(covariant _MKVideo oldWidget) {
    super.didUpdateWidget(oldWidget);
    videoKey.currentState?.update(
      fit: widget.fit,
      fill: widget.color,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Video(
      key: videoKey,
      controller: widget.videoController,
      fill: widget.color,
      fit: widget.fit,
      controls: NoVideoControls,
      wakelock: UnityVideoPlayerInterface.wakelockEnabled,
    );
  }
}

class UnityVideoPlayerMediaKit extends UnityVideoPlayer {
  late final Player mkPlayer;
  late VideoController mkVideoController;

  double _fps = 0;
  @override
  double get fps => _fps;
  final _fpsStreamController = StreamController<double>.broadcast();
  @override
  Stream<double> get fpsStream => _fpsStreamController.stream;

  bool _isCropped = false;

  Size maxSize = Size.zero;

  UnityVideoPlayerMediaKit({
    super.width,
    super.height,
    bool enableCache = false,
    RTSPProtocol? rtspProtocol,
    String? title,
  }) {
    mkPlayer = Player(
      configuration: PlayerConfiguration(
        bufferSize: 5 * 1024,
        logLevel: MPVLogLevel.warn,
        title: title ?? 'Bluecherry',
        ready: onReady,
      ),
    );
    final pixelRatio = PlatformDispatcher.instance.views.first.devicePixelRatio;
    if (width != null) width = (width! * pixelRatio).toInt();
    if (height != null) height = (height! * pixelRatio).toInt();

    debugPrint('Pixel ratio: $pixelRatio');

    mkVideoController = VideoController(
      mkPlayer,
      configuration: VideoControllerConfiguration(
        width: width,
        height: height,
      ),
    );

    // Check type. Only true for libmpv based platforms. Currently Windows & Linux.
    if (!kIsWeb && mkPlayer.platform is NativePlayer) {
      final platform = (mkPlayer.platform as dynamic)
        ..observeProperty('estimated-vf-fps', (fps) async {
          _fps = double.parse(fps);
          _fpsStreamController.add(_fps);
        })
        ..observeProperty('width', (width) async {
          debugPrint('display width: $width');
          this.width = int.tryParse(width);
          if (this.width != null && this.width! > maxSize.width) {
            maxSize = Size(this.width!.toDouble(), maxSize.height);
          }
        })
        ..observeProperty('height', (height) async {
          debugPrint('display height: $height');
          this.height = int.tryParse(height);
          if (this.height != null && this.height! > maxSize.height) {
            maxSize = Size(maxSize.width, this.height!.toDouble());
          }
        });
      platform.setProperty('msg-level', 'all=v');

      mkPlayer.stream.log.listen((event) {
        // debugPrint('${event.level} / ${event.prefix}: ${event.text}');
        if (event.level == 'fatal') {
          // ignore: invalid_use_of_protected_member
          platform.errorController.add(event.text);
        }
      });

      platform.setProperty('tls-verify', 'no');
      platform.setProperty('insecure', 'yes');

      if (rtspProtocol != null) {
        platform.setProperty(
          'rtsp-transport',
          switch (rtspProtocol) {
            RTSPProtocol.tcp => 'tcp',
            RTSPProtocol.udp => 'udp',
            // _ => 'udp_multicast'
          },
        );
      }

      platform.setProperty('force-seekable', 'yes');

      if (enableCache) {
        debugPrint('Cache is enabled');
        // https://mpv.io/manual/stable/#options-cache
        platform
          ..setProperty('cache', 'yes')
          // https://mpv.io/manual/stable/#options-cache-pause-initial
          ..setProperty('cache-pause-initial', 'yes')
          // https://mpv.io/manual/stable/#options-cache-pause-wait
          ..setProperty('cache-pause-wait', '1')
          ..setProperty('cache-pause', 'no')
          // https://mpv.io/manual/stable/#options-cache-secs
          ..setProperty('cache-secs', '13');
        getTemporaryDirectory().then((value) {
          platform
            ..setProperty('cache-on-disk', 'yes')
            ..setProperty('cache-dir', value.path);
        });

        platform
          // https://mpv.io/manual/master/#options-gapless-audio
          ..setProperty('gapless-audio', 'yes')
          // https://mpv.io/manual/master/#options-prefetch-playlist
          ..setProperty('prefetch-playlist', 'yes');
      } else {
        platform
          ..setProperty('cache', 'no')
          ..setProperty('cache-on-disk', 'no')
          ..setProperty('video-sync', 'audio');
        // these two properties reduce latency, but it causes problems with FPS
        // platform.setProperty("profile", "low-latency");
        // platform.setProperty("untimed", "");
      }
    }
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
  Stream<String> get onError => mkPlayer.stream.error;

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
    debugPrint('Playing $url');
    return ensureVideoControllerInitialized((controller) async {
      await mkPlayer.setPlaylistMode(PlaylistMode.loop);
      // do not use mkPlayer.add because it doesn't support auto play
      await mkPlayer.open(Playlist([Media(url)]), play: autoPlay);
    });
  }

  @override
  Future<void> setMultipleDataSource(
    Iterable<String> url, {
    bool autoPlay = true,
  }) {
    return ensureVideoControllerInitialized((controller) async {
      await mkPlayer.open(
        Playlist(url.map(Media.new).toList()),
        play: autoPlay,
      );
    });
  }

  @override
  Future<void> jumpToIndex(int index) {
    return ensureVideoControllerInitialized((controller) async {
      await mkPlayer.jump(index);
    });
  }

  // Volume in media kit goes from 0 to 100
  @override
  Future<void> setVolume(double volume) => mkPlayer.setVolume(volume * 100);

  @override
  double get volume => mkPlayer.state.volume / 100;

  @override
  Stream<double> get volumeStream => mkPlayer.stream.volume;

  @override
  Future<void> setSpeed(double speed) => mkPlayer.setRate(speed);
  @override
  Future<void> seekTo(Duration position) => mkPlayer.seek(position);

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
  double get aspectRatio => maxSize.aspectRatio;

  @override
  Future<void> start() {
    return ensureVideoControllerInitialized((controller) async {
      await mkPlayer.play();
    });
  }

  @override
  Future<void> pause() => mkPlayer.pause();

  @override
  Future<void> release() async {
    if (!kIsWeb && Platform.isLinux) {
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
  Future<void> resetCrop() => crop(-1, -1, -1);

  /// Crops the current video into a box at the given row and column
  @override
  Future<void> crop(int row, int col, int size) async {
    if (kIsWeb) return;
    // Usage as dynamic is necessary because the property is not available on the
    // web platform, and the compiler will complain about it.
    final player = mkPlayer.platform as dynamic;
    // On linux, the mpv binaries used come from the distros (sudo apt install mpv ...)
    // As of now (18 nov 2023), the "video-crop" parameter is not supported on
    // most distros. In this case, there is the "vf=crop" parameter that does
    // the same thing. "video-crop" is preferred on the other platforms because
    // of its performance.

    final useVideoFilter = Platform.isLinux || Platform.isMacOS;

    if (row == -1 || col == -1 || size == -1) {
      if (useVideoFilter) {
        await player.setProperty('vf', 'crop=');
      } else {
        await player.setProperty('video-crop', '0x0+0+0');
      }
      _isCropped = false;
    } else if (width != null && height != null) {
      final tileWidth = maxSize.width / size;
      final tileHeight = maxSize.height / size;

      final viewportRect = Rect.fromLTWH(
        col * tileWidth,
        row * tileHeight,
        tileWidth,
        tileHeight,
      );

      debugPrint(
        'Cropping | row=$row | col=$col | size=$maxSize | viewport=$viewportRect',
      );

      if (useVideoFilter) {
        await player.setProperty(
          'vf',
          'crop='
              '${viewportRect.width.toInt()}:'
              '${viewportRect.height.toInt()}:'
              '${viewportRect.left.toInt()}:'
              '${viewportRect.top.toInt()}',
        );
      } else {
        await player.setProperty(
          'video-crop',
          '${viewportRect.width.toInt()}x'
              '${viewportRect.height.toInt()}+'
              '${viewportRect.left.toInt()}+'
              '${viewportRect.top.toInt()}',
        );
      }
      _isCropped = true;
    }
  }

  @override
  bool get isCropped => _isCropped;

  @override
  Future<void> dispose() async {
    await release();
    await super.dispose();
    if (!kIsWeb && mkPlayer.platform is NativePlayer) {
      final platform = mkPlayer.platform as dynamic;

      await platform.unobserveProperty('estimated-vf-fps');
      await platform.unobserveProperty('dwidth');
      await platform.unobserveProperty('dheight');
    }
    await _fpsStreamController.close();
    await mkPlayer.dispose();
    UnityVideoPlayerInterface.unregisterPlayer(this);
  }
}
