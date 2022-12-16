part of 'events_screen.dart';

class EventPlayerScreen extends StatefulWidget {
  final Event event;

  const EventPlayerScreen({Key? key, required this.event}) : super(key: key);

  @override
  State<EventPlayerScreen> createState() => _EventPlayerScreenState();
}

class _EventPlayerScreenState extends State<EventPlayerScreen> {
  final videoController = BluecherryVideoPlayerController();

  @override
  void initState() {
    super.initState();
    debugPrint(widget.event.mediaURL.toString());
    videoController.setDataSource(
      widget.event.mediaURL.toString(),
      autoPlay: true,
    );
  }

  @override
  void dispose() {
    videoController.release();
    videoController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.event.title
              .split('device')
              .last
              .trim()
              .split(' ')
              .map(
                (e) => e.isEmpty ? '' : e[0].toUpperCase() + e.substring(1),
              )
              .join(' '),
        ),
      ),
      body: InteractiveViewer(
        minScale: 1.0,
        maxScale: 4.0,
        child: BluecherryVideoPlayer(
          controller: videoController,
          fit: CameraViewFit.contain,
          paneBuilder: (context, controller, states) => VideoViewport(
            player: controller,
          ),
        ),
      ),
    );
  }
}

class VideoViewport extends StatefulWidget {
  final BluecherryVideoPlayerController player;

  const VideoViewport({
    Key? key,
    required this.player,
  }) : super(key: key);

  @override
  _VideoViewportState createState() => _VideoViewportState();
}

class _VideoViewportState extends State<VideoViewport> {
  BluecherryVideoPlayerController get player => widget.player;

  Duration position = Duration.zero;
  bool visible = true;
  Timer timer = Timer(Duration.zero, () {});

  @override
  void initState() {
    super.initState();
    // Set class attributes to match the current [FijkPlayer]'s state.
    position = widget.player.currentPos;
    widget.player.onCurrentPosUpdate.listen(currentPosListener);
    widget.player.onBufferStateUpdate.listen(bufferStateListener);
    timer = Timer(const Duration(seconds: 5), () {
      if (mounted) {
        setState(() {
          visible = false;
        });
      }
    });
  }

  void currentPosListener(Duration event) {
    if (mounted) {
      setState(() {
        position = event;
        // Deal with the [seekTo] condition inside the [Slider] [Widget] callback.
        // if (state == FijkState.idle) {
        //   state = FijkState.started;
        // }
      });
    }
  }

  void bufferStateListener(bool event) {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    // Rect rect = Rect.fromLTRB(
    //   max(0.0, widget.rect.left),
    //   max(0.0, widget.rect.top),
    //   min(widget.size.width, widget.rect.right),
    //   min(widget.size.height, widget.rect.bottom),
    // );

    return Material(
      color: Colors.transparent,
      child: SafeArea(
        child: Stack(children: [
          Positioned.fill(
            child: GestureDetector(
              onTap: () {
                if (!visible) {
                  setState(() {
                    visible = true;
                  });
                  if (timer.isActive) timer.cancel();
                  timer = Timer(const Duration(seconds: 5), () {
                    setState(() {
                      visible = false;
                    });
                  });
                } else {
                  setState(() {
                    visible = false;
                  });
                }
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 400),
                decoration: BoxDecoration(
                  gradient: visible
                      ? const LinearGradient(
                          stops: [
                            1.0,
                            0.8,
                            0.0,
                            0.8,
                            1.0,
                          ],
                          colors: [
                            Colors.black38,
                            Colors.transparent,
                            Colors.transparent,
                            Colors.transparent,
                            Colors.black38,
                          ],
                        )
                      : null,
                ),
              ),
            ),
          ),
          if (visible ||
              player.isBuffering ||
              player.ijkPlayer?.state == FijkState.asyncPreparing) ...[
            PositionedDirectional(
              top: 0.0,
              bottom: 0.0,
              start: 0.0,
              end: 0.0,
              child: () {
                if (player.error != null) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.warning,
                          color: Colors.white70,
                          size: 32.0,
                        ),
                        const SizedBox(height: 8.0),
                        Text(
                          player.error!.toUpperCase(),
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 12.0,
                          ),
                        ),
                      ],
                    ),
                  );
                } else if (player.isBuffering ||
                    player.ijkPlayer?.state == FijkState.asyncPreparing) {
                  return const Center(
                    child: CircularProgressIndicator(
                      color: Colors.white,
                    ),
                  );
                } else {
                  return GestureDetector(
                    child: Icon(
                      player.isPlaying ? Icons.pause : Icons.play_arrow,
                      color: Colors.white,
                      shadows: const <Shadow>[
                        BoxShadow(
                            color: Colors.black54,
                            blurRadius: 15.0,
                            offset: Offset(0.0, 0.75)),
                      ],
                      size: 56.0,
                    ),
                    onTap: () {
                      if (player.isPlaying) {
                        widget.player.pause();
                      } else {
                        widget.player.start();
                      }
                    },
                  );
                }
              }(),
            ),
            if (player.duration != Duration.zero)
              PositionedDirectional(
                bottom: 0.0,
                start: 0.0,
                end: 0.0,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const SizedBox(width: 16.0),
                    Container(
                      alignment: AlignmentDirectional.centerEnd,
                      height: 36.0,
                      child: Text(
                        player.currentPos.label,
                        style: Theme.of(context)
                            .textTheme
                            .headline4
                            ?.copyWith(color: Colors.white),
                      ),
                    ),
                    const SizedBox(width: 8.0),
                    Expanded(
                      child: SliderTheme(
                        data: SliderThemeData(
                          overlayShape: const RoundSliderOverlayShape(
                              overlayRadius: 12.0),
                          overlayColor:
                              Theme.of(context).primaryColor.withOpacity(0.4),
                          thumbColor: Theme.of(context).primaryColor,
                          activeTrackColor: Theme.of(context).primaryColor,
                          inactiveTrackColor:
                              Theme.of(context).primaryColor.withOpacity(0.5),
                          trackHeight: 2.0,
                          thumbShape: const RoundSliderThumbShape(
                            enabledThumbRadius: 6.0,
                          ),
                        ),
                        child: Transform.translate(
                          offset: const Offset(0, 0.8),
                          child: Slider(
                            value: position.inMilliseconds.toDouble(),
                            min: 0.0,
                            max: player.duration.inMilliseconds.toDouble(),
                            onChanged: (value) async {
                              // setState(() {
                              //   state = FijkState.idle;
                              // });
                              position = Duration(milliseconds: value.toInt());
                              await player.seekTo(value.toInt());
                              await player.start();
                            },
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8.0),
                    Container(
                      alignment: AlignmentDirectional.centerStart,
                      height: 36.0,
                      child: Text(
                        player.duration.label,
                        style: Theme.of(context)
                            .textTheme
                            .headline4
                            ?.copyWith(color: Colors.white),
                      ),
                    ),
                    const SizedBox(width: 8.0),
                    // TODO: fullscreen
                    IconButton(
                      padding: EdgeInsets.zero,
                      icon: Icon(
                        widget.player.isFullScreen
                            ? Icons.fullscreen_exit
                            : Icons.fullscreen,
                        color: Colors.white,
                      ),
                      onPressed: () {
                        // if (widget.player.value.fullScreen) {
                        //   player.exitFullScreen();
                        // } else {
                        //   player.enterFullScreen();
                        // }
                      },
                    ),
                    const SizedBox(width: 8.0),
                  ],
                ),
              ),
          ],
        ]),
      ),
    );
  }

  @override
  void dispose() {
    // player.removeListener(listener);

    super.dispose();
  }
}
