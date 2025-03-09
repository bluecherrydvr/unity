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

part of '../events_browser/events_screen.dart';

class EventPlayerScreen extends StatelessWidget {
  final Event event;
  final Iterable<Event> upcomingEvents;
  final UnityVideoPlayer? player;

  const EventPlayerScreen({
    super.key,
    required this.event,
    required this.upcomingEvents,
    this.player,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (isMobile || constraints.maxWidth < kMobileBreakpoint.width) {
          return _EventPlayerMobile(event: event, player: player);
        }
        return EventPlayerDesktop(
          event: event,
          upcomingEvents: upcomingEvents,
          player: player,
        );
      },
    );
  }
}

class _EventPlayerMobile extends StatefulWidget {
  final Event event;
  final UnityVideoPlayer? player;

  const _EventPlayerMobile({required this.event, this.player});

  @override
  State<_EventPlayerMobile> createState() => __EventPlayerMobileState();
}

class __EventPlayerMobileState extends State<_EventPlayerMobile> {
  late final videoController =
      widget.player ??
      UnityVideoPlayer.create(
        enableCache: true,
        quality:
            SettingsProvider.instance.kRenderingQuality.value.playerQuality,
      );

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

    final mediaUrl =
        downloads.isEventDownloaded(widget.event.id)
            ? Uri.file(
              downloads.getDownloadedPathForEvent(widget.event.id),
              windows: Platform.isWindows,
            ).toString()
            : widget.event.mediaPath;

    debugPrint(mediaUrl);
    if (videoController.dataSource != mediaUrl) {
      debugPrint(
        'Setting data source from ${videoController.dataSource} to $mediaUrl',
      );
      videoController
        ..setDataSource(mediaUrl)
        ..setSpeed(1.0);
    } else {
      videoController.setSpeed(1.0);
    }

    super.didChangeDependencies();
  }

  @override
  void dispose() {
    if (widget.player == null) videoController.dispose();

    DeviceOrientations.instance.set(DeviceOrientation.values);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsProvider>();
    return Scaffold(
      body: Column(
        children: [
          const WindowButtons(showNavigator: false),
          Expanded(
            child: SafeArea(
              child: UnityVideoView(
                heroTag: widget.event.mediaPath,
                player: videoController,
                fit: settings.kVideoFit.value,
                videoBuilder: (context, video) {
                  return InteractiveViewer(
                    minScale: 1.0,
                    maxScale: 4.0,
                    child: video,
                  );
                },
                paneBuilder: (context, videoController) {
                  return VideoViewport(
                    event: widget.event,
                    player: videoController,
                  );
                },
              ),
            ),
          ),
        ],
      ),
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
  bool visible = true;
  Timer timer = Timer(Duration.zero, () {});
  bool isSliding = false;

  @override
  void initState() {
    super.initState();
    startTimer();
  }

  void startTimer() {
    if (timer.isActive) timer.cancel();
    timer = Timer(const Duration(seconds: 5), () {
      if (mounted && !isSliding) {
        setState(() {
          visible = false;
          Tooltip.dismissAllToolTips();
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final settings = context.watch<SettingsProvider>();
    final player = UnityVideoView.of(context);
    final error = player.error;
    final loc = AppLocalizations.of(context);

    return DefaultTextStyle(
      style: const TextStyle(color: Colors.white),
      child: IconTheme.merge(
        data: const IconThemeData(color: Colors.white),
        child: Stack(
          children: [
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
                      gradient:
                          visible
                              ? const LinearGradient(
                                stops: [1.0, 0.8, 0.0, 0.8, 1.0],
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
            Positioned.fill(
              child: () {
                if (error != null) {
                  return ErrorWarning(message: error);
                } else if (player.player.isBuffering) {
                  return const Center(
                    child: CircularProgressIndicator.adaptive(
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      strokeWidth: 2.0,
                    ),
                  );
                } else {
                  return Center(
                    child: GestureDetector(
                      child: PlayPauseIcon(
                        isPlaying: player.player.isPlaying,
                        color: Colors.white,
                        size: 56.0,
                      ),
                      onTap: () {
                        if (player.player.isPlaying) {
                          widget.player.pause();
                        } else {
                          widget.player.start();
                        }
                      },
                    ),
                  );
                }
              }(),
            ),
            if (visible || player.player.isBuffering) ...[
              PositionedDirectional(
                start: 8.0,
                end: 8.0,
                top: MediaQuery.paddingOf(context).top,
                child: SafeArea(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox(
                        height: kToolbarHeight,
                        child: Row(
                          children: [
                            // const BackButton(),
                            Padding(
                              padding: const EdgeInsetsDirectional.only(
                                start: 8.0,
                              ),
                              child: SquaredIconButton(
                                onPressed: Navigator.of(context).pop,
                                icon: Container(
                                  padding: const EdgeInsetsDirectional.all(4.0),
                                  child: Icon(
                                    Icons.adaptive.arrow_back,
                                    size: 20.0,
                                    color: theme.hintColor,
                                  ),
                                ),
                              ),
                            ),
                            Expanded(
                              child: Text(
                                '${widget.event.deviceName} (${widget.event.server.name})',
                              ),
                            ),
                            DownloadIndicator(event: widget.event),
                          ],
                        ),
                      ),
                      if (settings.kShowDebugInfo.value)
                        Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Text(
                            'source: ${player.player.dataSource ?? loc.unknown}'
                            '\nposition: ${player.player.currentPos}'
                            '\nduration ${player.player.duration}'
                            '\nbuffer ${player.player.currentBuffer}',
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: Colors.white,
                              shadows: outlinedText(),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              if (player.duration != Duration.zero)
                PositionedDirectional(
                  bottom: 0.0,
                  start: 0.0,
                  end: 0.0,
                  child: Row(
                    children: [
                      const SizedBox(width: 16.0),
                      Container(
                        alignment: AlignmentDirectional.centerEnd,
                        height: 36.0,
                        child: Text(
                          player.position.label,
                          style: theme.textTheme.bodyMedium!.copyWith(
                            color: Colors.white,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8.0),
                      Expanded(
                        child: SliderTheme(
                          data: SliderThemeData(
                            overlayShape: const RoundSliderOverlayShape(
                              overlayRadius: 12.0,
                            ),
                            overlayColor: theme.colorScheme.primary.withValues(
                              alpha: 0.4,
                            ),
                            thumbColor: theme.colorScheme.primary,
                            trackHeight: 2.0,
                            thumbShape: const RoundSliderThumbShape(
                              enabledThumbRadius: 6.0,
                            ),
                          ),
                          child: Slider.adaptive(
                            label: player.position.humanReadableCompact(
                              context,
                            ),
                            value: player.position.inMilliseconds.toDouble(),
                            max: player.duration.inMilliseconds.toDouble(),
                            secondaryTrackValue:
                                player.player.currentBuffer.inMilliseconds
                                    .toDouble(),
                            onChangeStart: (_) => isSliding = true,
                            onChanged: (value) async {
                              player.player.pause();
                              final position = Duration(
                                milliseconds: value.toInt(),
                              );
                              await player.player.seekTo(position);
                            },
                            onChangeEnd: (_) {
                              player.player.start();
                              isSliding = false;
                              if (!timer.isActive) {
                                setState(() => visible = false);
                              }
                            },
                          ),
                        ),
                      ),
                      const SizedBox(width: 8.0),
                      Container(
                        alignment: AlignmentDirectional.centerStart,
                        height: 36.0,
                        child: Text(
                          player.duration.label,
                          style: theme.textTheme.bodyMedium!.copyWith(
                            color: Colors.white,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8.0),
                    ],
                  ),
                ),
            ],
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    // player.removeListener(listener);

    super.dispose();
  }
}
