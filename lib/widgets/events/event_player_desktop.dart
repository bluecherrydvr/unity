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

import 'dart:async';
import 'dart:io';

import 'package:auto_size_text/auto_size_text.dart';
import 'package:bluecherry_client/models/event.dart';
import 'package:bluecherry_client/providers/downloads_provider.dart';
import 'package:bluecherry_client/providers/settings_provider.dart';
import 'package:bluecherry_client/utils/extensions.dart';
import 'package:bluecherry_client/widgets/collapsable_sidebar.dart';
import 'package:bluecherry_client/widgets/desktop_buttons.dart';
import 'package:bluecherry_client/widgets/downloads_manager.dart';
import 'package:bluecherry_client/widgets/error_warning.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:unity_video_player/unity_video_player.dart';

const kSliderControlerWidth = 100.0;

class EventPlayerDesktop extends StatefulWidget {
  final Event event;

  final List<Event> upcomingEvents;

  const EventPlayerDesktop({
    super.key,
    required this.event,
    this.upcomingEvents = const [],
  });

  @override
  State<EventPlayerDesktop> createState() => _EventPlayerDesktopState();
}

class _EventPlayerDesktopState extends State<EventPlayerDesktop>
    with SingleTickerProviderStateMixin {
  late Event currentEvent;
  final focusNode = FocusNode();

  final videoController = UnityVideoPlayer.create(
    width: 640,
    height: 360,
  );
  late final StreamSubscription playingSubscription;
  late final StreamSubscription durationSubscription;
  late final playingAnimationController = AnimationController(
    vsync: this,
    duration: const Duration(microseconds: 500),
  );

  double speed = 1.0;
  double volume = 1.0;
  double? _position;

  /// Whether the video should automatically play after seeking
  ///
  /// This is true if the video was playing when the user started seeking
  bool shouldAutoplay = false;

  Duration get duration {
    if (widget.event.duration > videoController.duration) {
      return widget.event.duration;
    }
    return videoController.duration;
  }

  @override
  void initState() {
    super.initState();
    currentEvent = widget.event;
    playingSubscription =
        videoController.onPlayingStateUpdate.listen((isPlaying) {
      if (!mounted) return;

      setState(() {});
      if (isPlaying) {
        playingAnimationController.forward();
      } else {
        playingAnimationController.reverse();
      }
    });
    durationSubscription = videoController.onDurationUpdate.listen((_) {
      if (mounted) setState(() {});
    });
    setEvent(currentEvent);
  }

  @override
  void dispose() {
    videoController
      ..release()
      ..dispose();
    playingSubscription.cancel();
    durationSubscription.cancel();
    playingAnimationController.dispose();
    focusNode.dispose();
    super.dispose();
  }

  void setEvent(Event event) {
    currentEvent = event;

    final downloads = context.read<DownloadsManager>();
    final mediaUrl = downloads.isEventDownloaded(event.id)
        ? Uri.file(
            downloads.getDownloadedPathForEvent(event.id),
            windows: Platform.isWindows,
          ).toString()
        : event.mediaURL.toString();

    debugPrint(mediaUrl);

    if (mediaUrl != videoController.dataSource) {
      videoController
        ..setDataSource(mediaUrl)
        ..setVolume(volume)
        ..setSpeed(speed);
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);

    const padd = SizedBox(width: 16.0);

    return KeyboardListener(
      focusNode: focusNode,
      autofocus: true,
      onKeyEvent: (event) {
        if (event is KeyDownEvent) {
          if (event.logicalKey == LogicalKeyboardKey.space) {
            _playPause();
          }
        }
      },
      child: SliderTheme(
        data: SliderThemeData(trackShape: _CustomTrackShape()),
        child: Material(
          child: Column(children: [
            WindowButtons(
              title: '${currentEvent.deviceName} (${currentEvent.server.name})',
            ),
            Expanded(
              child: Row(children: [
                Expanded(
                  child: Column(children: [
                    Expanded(
                      child: InteractiveViewer(
                        child: UnityVideoView(
                          player: videoController,
                          paneBuilder: (context, controller) {
                            if (controller.error != null) {
                              return ErrorWarning(message: controller.error!);
                            } else if (!controller.isSeekable) {
                              return const Center(
                                child: CircularProgressIndicator.adaptive(
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    Colors.white,
                                  ),
                                ),
                              );
                            }

                            return const SizedBox.shrink();
                          },
                        ),
                      ),
                    ),
                    Row(children: [
                      padd,
                      Expanded(
                        child: StreamBuilder<Duration>(
                          stream: videoController.onCurrentPosUpdate,
                          builder: (context, snapshot) {
                            final pos =
                                snapshot.data ?? videoController.currentPos;
                            return Row(children: [
                              Text(
                                DateFormat.Hms().format(
                                  currentEvent.published.add(pos).toLocal(),
                                ),
                              ),
                              padd,
                              Expanded(
                                child: Slider(
                                  value: (_position ?? pos.inMilliseconds)
                                      .clamp(0.0, duration.inMilliseconds)
                                      .toDouble(),
                                  max: duration.inMilliseconds.toDouble(),
                                  secondaryTrackValue: videoController
                                      .currentBuffer.inMilliseconds
                                      .toDouble(),
                                  onChangeStart: (v) {
                                    shouldAutoplay = videoController.isPlaying;
                                    videoController.pause();
                                  },
                                  onChanged: (v) async {
                                    /// Since it's just a preview, we don't need to show every
                                    /// millisecond of the video on seek. This, in theory, should
                                    /// improve performance by 50%
                                    if (v.toInt().isEven) {
                                      videoController.seekTo(
                                          Duration(milliseconds: v.toInt()));
                                    }
                                    setState(() => _position = v);
                                  },
                                  onChangeEnd: (v) async {
                                    await videoController.seekTo(
                                        Duration(milliseconds: v.toInt()));

                                    if (shouldAutoplay) {
                                      await videoController.start();
                                    }

                                    if (mounted) {
                                      setState(() {
                                        _position = null;
                                        shouldAutoplay = false;
                                      });
                                    }
                                  },
                                ),
                              ),
                            ]);
                          },
                        ),
                      ),
                      padd,
                      Text(
                        DateFormat.Hms().format(
                          currentEvent.published.add(duration).toLocal(),
                        ),
                      ),
                      padd,
                    ]),
                    Row(children: [
                      padd,
                      IconButton(
                        onPressed: _playPause,
                        tooltip:
                            videoController.isPlaying ? loc.pause : loc.play,
                        iconSize: 22.0,
                        icon: AnimatedBuilder(
                          animation: playingAnimationController,
                          builder: (context, _) => AnimatedIcon(
                            icon: AnimatedIcons.play_pause,
                            progress: playingAnimationController,
                          ),
                        ),
                      ),
                      Consumer<DownloadsManager>(
                        builder: (context, downloads, child) {
                          return DownloadIndicator(event: currentEvent);
                        },
                      ),
                      padd,
                      Text(loc.volume(volume.toStringAsFixed(1))),
                      const SizedBox(width: 6.0),
                      SizedBox(
                        width: kSliderControlerWidth,
                        child: Slider(
                          value: volume,
                          onChanged: (v) {
                            setState(() => volume = v);
                          },
                          onChangeEnd: (v) {
                            videoController.setVolume(v);
                            setState(() => volume = v);
                          },
                        ),
                      ),
                      padd,
                      padd,
                      padd,
                      Text(loc.speed(speed.toStringAsFixed(2))),
                      SizedBox(
                        width: kSliderControlerWidth,
                        child: Slider(
                          value: speed,
                          min: 0.25,
                          max: 2,
                          divisions: 7,
                          label: speed.toStringAsFixed(2),
                          onChanged: (v) => setState(() => speed = v),
                          onChangeEnd: (v) async {
                            videoController.setSpeed(v);
                            setState(() => speed = v);
                          },
                        ),
                      ),
                      padd,
                    ]),
                  ]),
                ),
                CollapsableSidebar(
                  left: false,
                  builder: (context, collapsableButton) {
                    return Column(children: [
                      Align(
                        alignment: AlignmentDirectional.topEnd,
                        child: collapsableButton,
                      ),
                      Expanded(
                        child: ListView(
                          padding: const EdgeInsetsDirectional.only(
                            end: 16.0,
                            start: 16.0,
                            bottom: 12.0,
                          ),
                          children: [
                            // Text(
                            //   '${currentEvent.deviceName} (${currentEvent.server.name})',
                            //   style: const TextStyle(
                            //     fontWeight: FontWeight.bold,
                            //   ),
                            //   maxLines: 1,
                            // ),
                            // Text(
                            //   settings.formatDate(currentEvent.published),
                            //   style: const TextStyle(fontSize: 12.0),
                            // ),
                            // Text(
                            //   '(${currentEvent.priority.locale(context)})'
                            //   ' ${currentEvent.type.locale(context)}',
                            // ),
                            EventTile(
                              key: ValueKey(currentEvent),
                              event: currentEvent,
                            ),
                            ...widget.upcomingEvents.map((event) {
                              if (event == currentEvent) {
                                return const SizedBox.shrink();
                              }
                              return Padding(
                                padding:
                                    const EdgeInsetsDirectional.only(top: 6.0),
                                child: EventTile(
                                  event: event,
                                  onPlay: () => setEvent(event),
                                ),
                              );
                            }),
                          ],
                        ),
                      ),
                    ]);
                  },
                ),
              ]),
            ),
          ]),
        ),
      ),
    );
  }

  Future<void> _playPause() async {
    if (videoController.isPlaying) {
      await videoController.pause();
    } else {
      if (videoController.currentPos.inSeconds ==
          videoController.duration.inSeconds) {
        await videoController.seekTo(Duration.zero);
      }
      await videoController.start();
    }

    if (mounted) setState(() {});
  }
}

/// This is used to remove the padding the Material Slider adds automatically
class _CustomTrackShape extends RoundedRectSliderTrackShape {
  @override
  Rect getPreferredRect({
    required RenderBox parentBox,
    Offset offset = Offset.zero,
    required SliderThemeData sliderTheme,
    bool isEnabled = false,
    bool isDiscrete = false,
  }) {
    final trackHeight = sliderTheme.trackHeight!;
    final trackLeft = offset.dx + 10.0;
    final trackTop = offset.dy + (parentBox.size.height - trackHeight) / 2;
    final trackWidth = parentBox.size.width - 10.0;
    return Rect.fromLTWH(trackLeft, trackTop, trackWidth, trackHeight);
  }
}

class EventTile extends StatelessWidget {
  final Event event;
  final VoidCallback? onPlay;

  const EventTile({
    super.key,
    required this.event,
    this.onPlay,
  });

  static Widget buildContent(BuildContext context, Event event) {
    final settings = context.watch<SettingsProvider>();
    final loc = AppLocalizations.of(context);

    final eventType = event.type.locale(context).uppercaseFirst();
    final at = settings.formatDate(event.published);

    return SizedBox(
      width: double.infinity,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          DefaultTextStyle.merge(
            style: const TextStyle(
              fontWeight: FontWeight.bold,
            ),
            maxLines: 1,
            overflow: TextOverflow.fade,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(loc.eventType),
                Text(loc.device),
                Text(loc.server),
                Text(loc.duration),
                Text(loc.date),
              ],
            ),
          ),
          const SizedBox(width: 6.0),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AutoSizeText(eventType, maxLines: 1),
                AutoSizeText(event.deviceName, maxLines: 1),
                AutoSizeText(event.server.name, maxLines: 1),
                AutoSizeText(
                  event.duration.humanReadableCompact(context),
                  maxLines: 1,
                ),
                AutoSizeText(at),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);

    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(8.0),
    );

    return ClipPath.shape(
      shape: shape,
      child: Card(
        margin: EdgeInsets.zero,
        shape: shape,
        child: ExpansionTile(
          clipBehavior: Clip.hardEdge,
          shape: shape,
          collapsedShape: shape,
          tilePadding: const EdgeInsetsDirectional.only(start: 12.0, end: 10.0),
          initiallyExpanded: key != null,
          title: Row(children: [
            Expanded(
              child: Text(
                '${event.deviceName} (${event.server.name})',
              ),
            ),
          ]),
          childrenPadding: const EdgeInsets.symmetric(
            vertical: 12.0,
            horizontal: 16.0,
          ),
          expandedCrossAxisAlignment: CrossAxisAlignment.end,
          children: [
            buildContent(context, event),
            if (onPlay != null)
              TextButton(
                onPressed: onPlay,
                child: Text(loc.play),
              ),
          ],
        ),
      ),
    );
  }
}
