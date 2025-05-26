import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';
import 'package:unity_video_player_platform_interface/unity_video_player_platform_interface.dart';

class UnityVideoPlayerMediaKitInterface extends UnityVideoPlayerInterface {
  /// Registers this class as the default instance of [UnityVideoPlayerInterface].
  static void registerWith([registrar]) {
    UnityVideoPlayerInterface.instance = UnityVideoPlayerMediaKitInterface();
  }

  @override
  Future<void> initialize([dynamic arguments]) async {
    MediaKit.ensureInitialized();
    if (!kIsWeb && (Platform.isMacOS || Platform.isLinux)) {
      await Future.delayed(const Duration(seconds: 1));
    }
  }

  @override
  UnityVideoPlayer createPlayer({
    int? width,
    int? height,
    bool enableCache = false,
    RTSPProtocol? rtspProtocol,
    VoidCallback? onReload,
    MatrixType matrixType = MatrixType.t16,
    bool softwareZoom = false,
  }) {
    final player = UnityVideoPlayerMediaKit(
      width: width,
      height: height,
      enableCache: enableCache,
      rtspProtocol: rtspProtocol,
    )
      ..zoom.matrixType = matrixType
      ..zoom.softwareZoom = softwareZoom
      ..onReload = onReload;
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
    final mkPlayer = (player as UnityVideoPlayerMediaKit);

    return Builder(builder: (context) {
      return Stack(children: [
        Positioned.fill(
          child: videoBuilder!(
            context,
            _MKVideo(
              key: ValueKey(player),
              player: mkPlayer.mkPlayer,
              videoController: player.mkVideoController,
              mkPlayer: mkPlayer,
              color: color,
              fit: fit.boxFit,
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

  @override
  bool get supportsFPS => !kIsWasm && !kIsWeb;

  @override
  bool get supportsHardwareZoom {
    return !kIsWeb && !Platform.isMacOS;
  }
}

class _MKVideo extends StatefulWidget {
  const _MKVideo({
    super.key,
    required this.player,
    required this.videoController,
    required this.mkPlayer,
    required this.fit,
    required this.color,
  });

  final Player player;
  final VideoController videoController;
  final UnityVideoPlayerMediaKit mkPlayer;
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
    if (oldWidget.fit != widget.fit || oldWidget.color != widget.color) {
      videoKey.currentState?.update(fit: widget.fit, fill: widget.color);
    }
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
  get platform => (mkPlayer.platform as dynamic);
  late VideoController mkVideoController;

  double _fps = 0;
  @override
  double get fps => _fps;
  final _fpsStreamController = StreamController<double>.broadcast();
  @override
  Stream<double> get fpsStream => _fpsStreamController.stream;

  Size maxSize = Size.zero;
  final bool enableCache;

  UnityVideoPlayerMediaKit({
    super.width,
    super.height,
    this.enableCache = false,
    RTSPProtocol? rtspProtocol,
  }) {
    mkPlayer = Player(
      configuration: PlayerConfiguration(
        logLevel: MPVLogLevel.v,
        title: title,
        ready: onReady,
      ),
    );
    final pixelRatio = PlatformDispatcher.instance.views.first.devicePixelRatio;
    if (width != null) width = (width! * pixelRatio).toInt();
    if (height != null) height = (height! * pixelRatio).toInt();

    mkVideoController = VideoController(
      mkPlayer,
      configuration: VideoControllerConfiguration(
        width: width,
        height: height,
      ),
    );

    onLog?.call(
        'Initialized player $title with width=$width and height=$height');

    // Check type. Only true for libmpv based platforms. Currently Windows & Linux.
    if (!kIsWeb && platform is NativePlayer) {
      platform
        ..observeProperty('estimated-vf-fps', (fps) async {
          _fps = double.parse(fps);
          _fpsStreamController.add(_fps);
        })
        ..observeProperty('width', (width) async {
          debugPrint('$title: display width: $width/${this.width}');
          this.width = int.tryParse(width);
          if (this.width != null && this.width! > maxSize.width) {
            maxSize = Size(this.width!.toDouble(), maxSize.height);
          }
        })
        ..observeProperty('height', (height) async {
          debugPrint('$title: display height: $height/${this.height}');
          this.height = int.tryParse(height);
          if (this.height != null && this.height! > maxSize.height) {
            maxSize = Size(maxSize.width, this.height!.toDouble());
          }
        });

      mkPlayer.stream.log.listen((event) {
        final logMessage = '${event.level} | ${event.prefix}: ${event.text}';
        if (event.level != 'v') debugPrint(logMessage);
        if (event.level == 'fatal') {
          // ignore: invalid_use_of_protected_member
          platform.errorController.add(event.text);
        }
        onLog?.call(logMessage);
      });

      // Some servers use self-signed certificates. This is necessary to allow
      // the connection to these servers.
      platform.setProperty('tls-verify', 'no');
      platform.setProperty('insecure', 'yes');

      // Defines the protocol to be used in the RTSP connection.
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

      // Ensures the stream can be seekable. We use seekable streams to dismiss
      // late streams.
      // platform.setProperty('force-seekable', 'yes');
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

  /// Gets a property from the media kit player.
  ///
  /// Do not use this to get the properties of already observed properties.
  @override
  Future<String> getProperty(String propertyName) {
    // return (mkPlayer.platform as dynamic).getProperty(propertyName);

    final propertyCompleter = Completer<String>();
    try {
      (mkPlayer.platform as dynamic).observeProperty(propertyName,
          (value) async {
        propertyCompleter.complete(value);
        (mkPlayer.platform as dynamic).unobserveProperty(propertyName);
      });
    } catch (e) {
      propertyCompleter.completeError(e);
    }
    return propertyCompleter.future;
  }

  @override
  Future<void> setDataSource(
    String url, {
    bool autoPlay = true,
    Map<String, String>? headers,
  }) {
    if (url == dataSource) return Future.value();
    debugPrint('Playing $url');
    return ensureVideoControllerInitialized((controller) async {
      await mkPlayer.setPlaylistMode(PlaylistMode.loop);
      // do not use mkPlayer.add because it doesn't support auto play
      await mkPlayer.open(
        Playlist([Media(url, httpHeaders: headers)]),
        play: autoPlay,
      );
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
  Stream<double> get volumeStream => mkPlayer.stream.volume.map((volume) {
        return volume / 100;
      });

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

  /// Crops the current video into a box at the given row and column
  @override
  Future<void> crop(int row, int col) async {
    super.crop(row, col);
    if (kIsWeb ||
        // On macOS, the mpv options don't seem to work properly. Because of this,
        // software zoom is used instead.
        Platform.isMacOS ||
        zoom.softwareZoom) {
      return;
    }

    final reset = zoom.zoomAxis == (-1, -1);
    // final player = mkPlayer.platform as dynamic;

    final Future<void> Function(Rect rect) crop;
    if (Platform.isLinux) {
      // On linux, the mpv binaries used come from the distros (sudo apt install mpv ...)
      // As of now (18 nov 2023), the "video-crop" parameter is not supported on
      // most distros. In this case, there is the "vf=crop" parameter that does
      // the same thing. "video-crop" is preferred on the other platforms because
      // of its performance.
      crop = _cropWithFilter;
    } else {
      crop = _cropWithoutFilter;
    }

    if (reset) {
      await crop(Rect.zero);
    } else if (width != null && height != null) {
      final tileWidth = maxSize.width / zoom.matrixType.size;
      final tileHeight = maxSize.height / zoom.matrixType.size;

      zoom.zoomRect = Rect.fromLTWH(
        col * tileWidth,
        row * tileHeight,
        tileWidth,
        tileHeight,
      );

      debugPrint(
        'Cropping ${zoom.softwareZoom} | row=$row | col=$col | size=$maxSize | viewport=${zoom.zoomRect}',
      );

      await crop(zoom.zoomRect);
    }
  }

  Future<void> _cropWithFilter(Rect viewportRect) async {
    // Usage as dynamic is necessary because the property is not available on the
    // web platform, and the compiler will complain about it.
    final player = mkPlayer.platform as dynamic;
    if (viewportRect.isEmpty) {
      await player.setProperty('vf', 'crop=');
    } else {
      await player.setProperty(
        'vf',
        'crop='
            '${viewportRect.width.toInt()}:'
            '${viewportRect.height.toInt()}:'
            '${viewportRect.left.toInt()}:'
            '${viewportRect.top.toInt()}',
      );
    }
  }

  Future<void> _cropWithoutFilter(Rect viewportRect) async {
    // Usage as dynamic is necessary because the property is not available on the
    // web platform, and the compiler will complain about it.
    final player = mkPlayer.platform as dynamic;
    if (viewportRect.isEmpty) {
      await player.setProperty('video-crop', '0x0+0+0');
    } else {
      await player.setProperty(
        'video-crop',
        '${viewportRect.width.toInt()}x'
            '${viewportRect.height.toInt()}+'
            '${viewportRect.left.toInt()}+'
            '${viewportRect.top.toInt()}',
      );
    }
  }

  @override
  Future<void> dispose() async {
    await release();
    await super.dispose();
    if (!kIsWeb && mkPlayer.platform is NativePlayer) {
      final platform = mkPlayer.platform as dynamic;

      await platform.unobserveProperty('estimated-vf-fps');
      await platform.unobserveProperty('width');
      await platform.unobserveProperty('height');
    }
    await _fpsStreamController.close();
    await mkPlayer.dispose();
    UnityVideoPlayerInterface.unregisterPlayer(this);
  }
}
