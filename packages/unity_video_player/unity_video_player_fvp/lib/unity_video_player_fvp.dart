library unity_video_player_fvp;

import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:unity_video_player_platform_interface/unity_video_player_platform_interface.dart';
import 'package:fvp/mdk.dart';
import 'package:fvp/fvp.dart' as fvp;

class UnityVideoPlayerFvpInterface extends UnityVideoPlayerInterface {
  /// Registers this class as the default instance of [UnityVideoPlayerInterface].
  static void registerWith([registrar]) {
    UnityVideoPlayerInterface.instance = UnityVideoPlayerFvpInterface();
  }

  @override
  Future<void> initialize() async {
    fvp.registerWith(options: {
      'player': {
        'avformat.analyzeduration': '10000',
        'avformat.probesize': '1000',
        'avformat.fpsprobesize': '0',
        'avformat.fflags': '+nobuffer',
        'avformat.avioflags': 'direct',
      }
    });
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
    final player = UnityVideoPlayerFvp(
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
    final mdkPlayer = (player as UnityVideoPlayerFvp);

    return Builder(builder: (context) {
      return Stack(children: [
        Positioned.fill(
          child: videoBuilder!(
            context,
            _MKVideo(
              key: ValueKey(player),
              mdkPlayer: mdkPlayer,
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
    required this.mdkPlayer,
    required this.fit,
    required this.color,
  });

  final UnityVideoPlayerFvp mdkPlayer;
  final BoxFit fit;
  final Color color;

  @override
  State<_MKVideo> createState() => _MKVideoState();
}

class _MKVideoState extends State<_MKVideo> {
  @override
  void didUpdateWidget(covariant _MKVideo oldWidget) {
    super.didUpdateWidget(oldWidget);
  }

  @override
  void initState() {
    super.initState();
    final player = widget.mdkPlayer.mdkPlayer;
    player.setProperty("avformat.fflags", "+nobuffer");
    player.setProperty("avformat.analyzeduration", "10000");
    player.setProperty("avformat.probesize", "1000");
    player.setProperty("avformat.fpsprobesize", "0");
    player.setProperty("avformat.avioflags", "direct");
    player.updateTexture();
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<int?>(
      valueListenable: widget.mdkPlayer.mdkPlayer.textureId,
      builder: (context, id, _) =>
          id == null ? const SizedBox.shrink() : Texture(textureId: id),
    );
  }
}

class UnityVideoPlayerFvp extends UnityVideoPlayer {
  late final Player mdkPlayer;

  double _fps = 0;
  @override
  double get fps => _fps;

  final _fpsStreamController = StreamController<double>.broadcast();
  @override
  Stream<double> get fpsStream => _fpsStreamController.stream;

  Size maxSize = Size.zero;
  final bool enableCache;

  UnityVideoPlayerFvp({
    super.width,
    super.height,
    this.enableCache = false,
    RTSPProtocol? rtspProtocol,
  }) {
    mdkPlayer = Player();
    final pixelRatio = PlatformDispatcher.instance.views.first.devicePixelRatio;
    if (width != null) width = (width! * pixelRatio).toInt();
    if (height != null) height = (height! * pixelRatio).toInt();

    onLog?.call(
        'Initialized player $title with width=$width and height=$height');

    // Check type. Only true for libmpv based platforms. Currently Windows & Linux.
    // if (!kIsWeb && platform is NativePlayer) {
    //   platform
    //     ..observeProperty('estimated-vf-fps', (fps) async {
    //       _fps = double.parse(fps);
    //       _fpsStreamController.add(_fps);
    //     })
    //     ..observeProperty('width', (width) async {
    //       debugPrint('$title: display width: $width/${this.width}');
    //       this.width = int.tryParse(width);
    //       if (this.width != null && this.width! > maxSize.width) {
    //         maxSize = Size(this.width!.toDouble(), maxSize.height);
    //       }
    //     })
    //     ..observeProperty('height', (height) async {
    //       debugPrint('$title: display height: $height/${this.height}');
    //       this.height = int.tryParse(height);
    //       if (this.height != null && this.height! > maxSize.height) {
    //         maxSize = Size(maxSize.width, this.height!.toDouble());
    //       }
    //     });

    //   mdkPlayer.stream.log.listen((event) {
    //     final logMessage = '${event.level} | ${event.prefix}: ${event.text}';
    //     if (event.level != 'v') debugPrint(logMessage);
    //     if (event.level == 'fatal') {
    //       // ignore: invalid_use_of_protected_member
    //       platform.errorController.add(event.text);
    //     }
    //     onLog?.call(logMessage);
    //   });

    //   // Some servers use self-signed certificates. This is necessary to allow
    //   // the connection to these servers.
    //   platform.setProperty('tls-verify', 'no');
    //   platform.setProperty('insecure', 'yes');

    //   // Defines the protocol to be used in the RTSP connection.
    //   if (rtspProtocol != null) {
    //     platform.setProperty(
    //       'rtsp-transport',
    //       switch (rtspProtocol) {
    //         RTSPProtocol.tcp => 'tcp',
    //         RTSPProtocol.udp => 'udp',
    //         // _ => 'udp_multicast'
    //       },
    //     );
    //   }

    // Ensures the stream can be seekable. We use seekable streams to dismiss
    // late streams.
    // platform.setProperty('force-seekable', 'yes');
    // }

    mdkPlayer
      ..onStateChanged((previous, state) {
        _playingStateStreamController.add(state == PlaybackState.playing);
      })
      ..onMediaStatus((previous, status) {
        _bufferStateStreamController.add(
          status.rawValue == MediaStatus.buffering,
        );

        return false;
      })
      ..onEvent((_) {
        // we will add the current value to the stream
        _positionStreamController.add(currentPos);
        _bufferStreamController.add(currentBuffer);
        _durationStreamController.add(duration);
        _fpsStreamController.add(fps);
        _playingStateStreamController.add(isPlaying);
        _bufferStateStreamController.add(isBuffering);
      });
  }

  @override
  String? get dataSource {
    final media = mdkPlayer.media;
    return media.isNotEmpty ? media : null;
  }

  @override
  Stream<String> get onError => const Stream.empty(broadcast: false);

  @override
  Duration get duration => Duration(milliseconds: mdkPlayer.mediaInfo.duration);

  final _durationStreamController = StreamController<Duration>.broadcast();
  @override
  Stream<Duration> get onDurationUpdate => _durationStreamController.stream;

  @override
  Duration get currentPos => Duration(milliseconds: mdkPlayer.position);

  final _positionStreamController = StreamController<Duration>.broadcast();
  @override
  Stream<Duration> get onCurrentPosUpdate => _positionStreamController.stream;

  @override
  bool get isBuffering =>
      mdkPlayer.mediaStatus.rawValue == MediaStatus.buffering;

  @override
  Duration get currentBuffer => Duration(milliseconds: mdkPlayer.buffered());

  final _bufferStreamController = StreamController<Duration>.broadcast();
  @override
  Stream<Duration> get onBufferUpdate => _bufferStreamController.stream;

  @override
  bool get isSeekable => duration > Duration.zero;

  final _bufferStateStreamController = StreamController<bool>.broadcast();
  @override
  Stream<bool> get onBufferStateUpdate => _bufferStateStreamController.stream;

  @override
  bool get isPlaying => mdkPlayer.state == PlaybackState.playing;

  final _playingStateStreamController = StreamController<bool>.broadcast();
  @override
  Stream<bool> get onPlayingStateUpdate => _playingStateStreamController.stream;

  /// Gets a property from the media kit player.
  ///
  /// Do not use this to get the properties of already observed properties.
  @override
  Future<String> getProperty(String propertyName) async {
    return '';
  }

  @override
  Future<void> setDataSource(String url, {bool autoPlay = true}) async {
    if (url == dataSource) return Future.value();
    debugPrint('Playing $url');
    mdkPlayer.setMedia(url, MediaType.video);
    if (autoPlay) start();
    // await mdkPlayer.setPlaylistMode(PlaylistMode.loop);
    // // do not use mdkPlayer.add because it doesn't support auto play
    // await mdkPlayer.open(Playlist([Media(url)]), play: autoPlay);
  }

  @override
  Future<void> setMultipleDataSource(
    Iterable<String> url, {
    bool autoPlay = true,
  }) async {
    // await mdkPlayer.open(
    //   Playlist(url.map(Media.new).toList()),
    //   play: autoPlay,
    // );
    setDataSource(url.first);
  }

  @override
  Future<void> jumpToIndex(int index) async {}

  @override
  Future<void> setVolume(double volume) async =>
      mdkPlayer.volume = volume / 100;

  @override
  double get volume => mdkPlayer.volume;

  @override
  Stream<double> get volumeStream => Stream.value(volume);

  @override
  Future<void> setSpeed(double speed) async => mdkPlayer.playbackRate = speed;
  @override
  Future<void> seekTo(Duration position) =>
      mdkPlayer.seek(position: position.inMilliseconds);

  @override
  Future<void> setSize(Size size) async {
    // return ensureVideoControllerInitialized((controller) async {
    //   await controller.setSize(
    //     width: size.width.toInt(),
    //     height: size.height.toInt(),
    //   );
    // });

    mdkPlayer.setVideoSurfaceSize(size.width.toInt(), size.height.toInt());
  }

  @override
  double get aspectRatio => maxSize.aspectRatio;

  @override
  Future<void> start() async {
    mdkPlayer.state = PlaybackState.playing;
  }

  @override
  Future<void> pause() async {
    mdkPlayer.state = PlaybackState.paused;
  }

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
        zoom.softwareZoom) return;

    final reset = zoom.zoomAxis == (-1, -1);
    // final player = mdkPlayer.platform as dynamic;

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
    // final player = mdkPlayer.platform as dynamic;
    // if (viewportRect.isEmpty) {
    //   await player.setProperty('vf', 'crop=');
    // } else {
    //   await player.setProperty(
    //     'vf',
    //     'crop='
    //         '${viewportRect.width.toInt()}:'
    //         '${viewportRect.height.toInt()}:'
    //         '${viewportRect.left.toInt()}:'
    //         '${viewportRect.top.toInt()}',
    //   );
    // }
  }

  Future<void> _cropWithoutFilter(Rect viewportRect) async {
    // Usage as dynamic is necessary because the property is not available on the
    // web platform, and the compiler will complain about it.
    // final player = mdkPlayer.platform as dynamic;
    // if (viewportRect.isEmpty) {
    //   await player.setProperty('video-crop', '0x0+0+0');
    // } else {
    //   await player.setProperty(
    //     'video-crop',
    //     '${viewportRect.width.toInt()}x'
    //         '${viewportRect.height.toInt()}+'
    //         '${viewportRect.left.toInt()}+'
    //         '${viewportRect.top.toInt()}',
    //   );
    // }
  }

  @override
  Future<void> dispose() async {
    await release();
    await super.dispose();
    // if (!kIsWeb && mdkPlayer.platform is NativePlayer) {
    //   final platform = mdkPlayer.platform as dynamic;

    //   await platform.unobserveProperty('estimated-vf-fps');
    //   await platform.unobserveProperty('width');
    //   await platform.unobserveProperty('height');
    // }
    await _fpsStreamController.close();
    mdkPlayer.dispose();
    UnityVideoPlayerInterface.unregisterPlayer(this);
  }
}
