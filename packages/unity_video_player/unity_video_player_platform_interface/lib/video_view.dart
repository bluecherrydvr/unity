import 'package:flutter/widgets.dart';

import 'unity_video_player_platform_interface.dart';

class VideoViewInheritance extends InheritedWidget {
  const VideoViewInheritance({
    super.key,
    required super.child,
    required this.error,
    required this.position,
    required this.duration,
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

  /// The matrix type to use for the video view.
  ///
  /// Defaults to [MatrixType.t16].
  final MatrixType matrixType;

  /// Whether to use software zoom.
  ///
  /// Defaults to `false`.
  final bool softwareZoom;

  /// Creates a new video view.
  const UnityVideoView({
    super.key,
    required this.player,
    this.fit = UnityVideoFit.contain,
    this.paneBuilder,
    this.videoBuilder,
    this.color = const Color(0xFF000000),
    this.heroTag,
    this.matrixType = MatrixType.t16,
    this.softwareZoom = false,
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
      fps: widget.player.fps.toInt(),
      lastImageUpdate: widget.player.lastImageUpdate,
      child: UnityVideoPlayerInterface.instance.createVideoView(
        player: widget.player,
        color: widget.color,
        fit: widget.fit,
        videoBuilder: (context, video) {
          Widget output = video;

          final zoom = widget.player.zoom;
          if (zoom.softwareZoom && zoom.zoomAxis != (-1, -1)) {
            output = LayoutBuilder(builder: (context, constraints) {
              final tileWidth = constraints.maxWidth / zoom.matrixType.size;
              final tileHeight = constraints.maxHeight / zoom.matrixType.size;

              final x = zoom.zoomAxis.$2 * tileWidth;
              final y = zoom.zoomAxis.$1 * tileHeight;

              return Stack(children: [
                Positioned(
                  left: -x * zoom.matrixType.size,
                  top: -y * zoom.matrixType.size,
                  width: constraints.maxWidth * zoom.matrixType.size,
                  height: constraints.maxHeight * zoom.matrixType.size,
                  child: video,
                ),
              ]);
            });
          }

          return widget.videoBuilder?.call(context, output) ?? output;
        },
        paneBuilder: widget.paneBuilder,
      ),
    );

    if (widget.heroTag != null) {
      return Hero(tag: widget.heroTag, child: videoView);
    }

    return videoView;
  }
}
