/*
 * This file is a part of Bluecherry Client (https://github.com/bluecherrydvr/unity).
 *
 * Copyright 2022 Bluecherry, LLC
 *
 * This program is free software; you can redistribute it and/or
 * modify it under the terms of the GNU General Public License as
 * published by the Free Software Foundation; either version 3 of
 * the License, or (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program. If not, see <http://www.gnu.org/licenses/>.
 */

part of 'events_screen.dart';

class EventPlayerScreen extends StatelessWidget {
  final Event event;
  final Iterable<Event> upcomingEvents;

  const EventPlayerScreen({
    super.key,
    required this.event,
    required this.upcomingEvents,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      if (constraints.maxWidth < kMobileBreakpoint.width) {
        return _EventPlayerMobile(event: event);
      }
      return EventPlayerDesktop(event: event, upcomingEvents: upcomingEvents);
    });
  }
}

class _EventPlayerMobile extends StatefulWidget {
  final Event event;

  const _EventPlayerMobile({required this.event});

  @override
  State<_EventPlayerMobile> createState() => __EventPlayerMobileState();
}

class __EventPlayerMobileState extends State<_EventPlayerMobile> {
  final videoController = UnityVideoPlayer.create();

  @override
  void initState() {
    super.initState();
    DeviceOrientations.instance.set([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    HomeProvider.setDefaultStatusBarStyle();
  }

  @override
  void didChangeDependencies() {
    final downloads = context.read<DownloadsManager>();

    final mediaUrl = downloads.isEventDownloaded(widget.event.id)
        ? Uri.file(
            downloads.getDownloadedPathForEvent(widget.event.id),
            windows: Platform.isWindows,
          ).toString()
        : widget.event.mediaURL.toString();

    debugPrint(mediaUrl);
    videoController.setDataSource(mediaUrl);

    super.didChangeDependencies();
  }

  @override
  void dispose() {
    videoController
      ..release()
      ..dispose();

    DeviceOrientations.instance.set(DeviceOrientation.values);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(children: [
        const WindowButtons(showNavigator: false),
        Expanded(
          child: SafeArea(
            child: UnityVideoView(
              player: videoController,
              videoBuilder: (context, video) {
                return InteractiveViewer(
                  minScale: 1.0,
                  maxScale: 4.0,
                  child: video,
                );
              },
              paneBuilder: (context, videoController) {
                if (isDesktop) {
                  return _DesktopVideoViewport(
                    event: widget.event,
                    player: videoController,
                  );
                } else {
                  return VideoViewport(
                    event: widget.event,
                    player: videoController,
                  );
                }
              },
            ),
          ),
        ),
      ]),
    );
  }
}

class VideoViewport extends StatefulWidget {
  final UnityVideoPlayer player;
  final Event event;

  const VideoViewport({super.key, required this.player, required this.event});

  @override
  State<VideoViewport> createState() => _VideoViewportState();
}

class _VideoViewportState extends State<VideoViewport> {
  UnityVideoPlayer get player => widget.player;

  String? error;
  Duration position = Duration.zero;
  bool visible = true;
  Timer timer = Timer(Duration.zero, () {});
  bool isSliding = false;

  late StreamSubscription positionStream;
  late StreamSubscription bufferStream;

  @override
  void initState() {
    super.initState();
    // Set class attributes to match the current [FijkPlayer]'s state.
    position = widget.player.currentPos;
    positionStream =
        widget.player.onCurrentPosUpdate.listen(currentPosListener);
    bufferStream = widget.player.onBufferUpdate.listen(bufferListener);

    startTimer();
  }

  void currentPosListener(Duration event) {
    if (mounted) {
      setState(() {
        position = event;
      });
    }
  }

  void bufferListener(Duration buffer) {
    if (mounted) setState(() {});
  }

  void errorListener(String error) {
    if (mounted) setState(() => this.error = error);
  }

  void startTimer() {
    if (timer.isActive) timer.cancel();
    timer = Timer(const Duration(seconds: 5), () {
      if (mounted && !isSliding) {
        setState(() {
          visible = false;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Stack(children: [
      Positioned.fill(
        child: GestureDetector(
          behavior: HitTestBehavior.translucent,
          onTap: () {
            if (!visible) {
              setState(() => visible = true);
              startTimer();
            } else {
              setState(() => visible = false);
            }
          },
          child: IgnorePointer(
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
      ),
      if (visible || player.isBuffering) ...[
        Positioned(
          height: kToolbarHeight,
          left: 0,
          right: 0,
          top: MediaQuery.paddingOf(context).top,
          child: SafeArea(
            child: Row(children: [
              const BackButton(),
              Expanded(
                child: Text(
                  '${widget.event.deviceName} (${widget.event.server.name})',
                ),
              ),
              DownloadIndicator(event: widget.event),
            ]),
          ),
        ),
        Positioned.fill(
          child: () {
            if (error != null) {
              return ErrorWarning(message: error!);
            } else if (player.isBuffering) {
              return const Center(
                child: CircularProgressIndicator.adaptive(
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  strokeWidth: 2.0,
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
            child: Row(children: [
              const SizedBox(width: 16.0),
              Container(
                alignment: AlignmentDirectional.centerEnd,
                height: 36.0,
                child: Text(
                  player.currentPos.label,
                  style: theme.textTheme.headlineMedium
                      ?.copyWith(color: Colors.white),
                ),
              ),
              const SizedBox(width: 8.0),
              Expanded(
                child: SliderTheme(
                  data: SliderThemeData(
                    overlayShape:
                        const RoundSliderOverlayShape(overlayRadius: 12.0),
                    overlayColor: theme.colorScheme.primary.withOpacity(0.4),
                    thumbColor: theme.colorScheme.primary,
                    activeTrackColor: theme.colorScheme.primary,
                    inactiveTrackColor:
                        theme.colorScheme.primary.withOpacity(0.5),
                    trackHeight: 2.0,
                    thumbShape: const RoundSliderThumbShape(
                      enabledThumbRadius: 6.0,
                    ),
                  ),
                  child: Transform.translate(
                    offset: const Offset(0, 0.8),
                    child: Slider(
                      divisions: player.duration.inMilliseconds,
                      label: position.humanReadableCompact(context),
                      value: position.inMilliseconds.toDouble(),
                      max: player.duration.inMilliseconds.toDouble(),
                      secondaryTrackValue:
                          player.currentBuffer.inMilliseconds.toDouble(),
                      onChangeStart: (_) => isSliding = true,
                      onChanged: (value) async {
                        position = Duration(milliseconds: value.toInt());
                        await player.seekTo(position);
                        await player.start();
                      },
                      onChangeEnd: (_) {
                        isSliding = false;
                        if (!timer.isActive) setState(() => visible = false);
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
                  style: theme.textTheme.headlineMedium
                      ?.copyWith(color: Colors.white),
                ),
              ),
              const SizedBox(width: 8.0),
            ]),
          ),
      ],
    ]);
  }

  @override
  void dispose() {
    // player.removeListener(listener);

    super.dispose();
  }
}

class _DesktopVideoViewport extends StatefulWidget {
  final Event event;
  final UnityVideoPlayer player;

  const _DesktopVideoViewport({
    required this.event,
    required this.player,
  });

  @override
  State<_DesktopVideoViewport> createState() => __DesktopVideoViewportState();
}

class __DesktopVideoViewportState extends State<_DesktopVideoViewport> {
  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsProvider>();

    return Stack(children: [
      PositionedDirectional(
        bottom: 0,
        start: 12.0,
        end: 12.0,
        child: Row(children: [
          Text(settings.formatTime(widget.event.published)),
          Expanded(
            child: Slider(
              value: widget.player.currentPos.inMilliseconds.toDouble(),
              max: widget.player.duration.inMilliseconds.toDouble(),
              secondaryTrackValue:
                  widget.player.currentBuffer.inMilliseconds.toDouble(),
              onChanged: (v) {
                widget.player.seekTo(Duration(milliseconds: v.toInt()));
              },
            ),
          ),
          Text(
            settings.formatTime(
              widget.event.published.add(widget.event.duration),
            ),
          ),
        ]),
      ),
    ]);
  }
}
