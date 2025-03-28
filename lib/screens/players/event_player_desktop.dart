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
import 'package:bluecherry_client/l10n/generated/app_localizations.dart';
import 'package:bluecherry_client/models/device.dart';
import 'package:bluecherry_client/models/event.dart';
import 'package:bluecherry_client/providers/downloads_provider.dart';
import 'package:bluecherry_client/providers/settings_provider.dart';
import 'package:bluecherry_client/screens/downloads/indicators.dart';
import 'package:bluecherry_client/screens/layouts/desktop/multicast_view.dart';
import 'package:bluecherry_client/screens/layouts/video_status_label.dart';
import 'package:bluecherry_client/utils/date.dart';
import 'package:bluecherry_client/utils/extensions.dart';
import 'package:bluecherry_client/utils/video_player.dart';
import 'package:bluecherry_client/widgets/collapsable_sidebar.dart';
import 'package:bluecherry_client/widgets/desktop_buttons.dart';
import 'package:bluecherry_client/widgets/error_warning.dart';
import 'package:bluecherry_client/widgets/misc.dart';
import 'package:bluecherry_client/widgets/squared_icon_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:unity_video_player/unity_video_player.dart';

const kSliderControlerWidth = 100.0;

class EventPlayerDesktop extends StatefulWidget {
  final Event event;

  final Iterable<Event> upcomingEvents;
  final UnityVideoPlayer? player;

  const EventPlayerDesktop({
    super.key,
    required this.event,
    this.upcomingEvents = const [],
    this.player,
  });

  @override
  State<EventPlayerDesktop> createState() => _EventPlayerDesktopState();
}

class _EventPlayerDesktopState extends State<EventPlayerDesktop> {
  late Event currentEvent;
  final focusNode = FocusNode();

  late UnityVideoFit fit;

  late final UnityVideoPlayer videoController;
  late final StreamSubscription playingSubscription;
  late final StreamSubscription bufferSubscription;

  late double speed = SettingsProvider.instance.kEventsSpeed.value;
  late double volume = SettingsProvider.instance.kEventsVolume.value;
  double? _position;

  /// Whether the video should automatically play after seeking
  ///
  /// This is true if the video was playing when the user started seeking
  bool shouldAutoplay = false;

  Duration get duration {
    if (widget.event.duration < videoController.duration) {
      return videoController.duration;
    }
    return widget.event.duration;
  }

  Device? get device => currentEvent.server.devices.firstWhereOrNull(
    (d) => d.id == currentEvent.deviceID,
  );
  String get title =>
      '${currentEvent.deviceName} (${currentEvent.server.name})';

  /// All the events but the current one.
  Iterable<Event> get upcomingEvents {
    return widget.upcomingEvents.where((ue) => ue != widget.event);
  }

  @override
  void initState() {
    super.initState();
    currentEvent = widget.event;
    videoController = widget.player ?? UnityPlayers.forEvent(widget.event);
    fit =
        device?.server.additionalSettings.videoFit ??
        SettingsProvider.instance.kVideoFit.value;
    playingSubscription = videoController.onPlayingStateUpdate.listen((
      isPlaying,
    ) {
      if (!mounted) return;
      setState(() {});
    });
    bufferSubscription = videoController.onBufferUpdate.listen((buffer) {
      if (!mounted) return;

      setState(() {});
    });
    if (widget.player == null) {
      setEvent(currentEvent);
    } else {
      videoController.start();
    }
  }

  @override
  void dispose() {
    playingSubscription.cancel();
    bufferSubscription.cancel();
    focusNode.dispose();
    if (widget.player == null) videoController.dispose();
    super.dispose();
  }

  Future<void> setEvent(Event event) async {
    currentEvent = event;

    final downloads = context.read<DownloadsManager>();
    final mediaUrl =
        downloads.isEventDownloaded(event.id)
            ? await () async {
              if (await downloads.doesEventFileExist(event.id)) {
                return Uri.file(
                  downloads.getDownloadedPathForEvent(event.id),
                  windows: Platform.isWindows,
                ).toString();
              }
              return event.mediaPath;
            }()
            : event.mediaPath;

    if (mediaUrl != videoController.dataSource) {
      debugPrint(
        'Setting data source from ${videoController.dataSource} to $mediaUrl',
      );
      videoController.setDataSource(mediaUrl, headers: event.server.headers);
    } else {
      debugPrint(mediaUrl);
    }
    videoController
      ..setVolume(volume)
      ..setSpeed(speed)
      ..start();
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final loc = AppLocalizations.of(context);
    final settings = context.watch<SettingsProvider>();

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
          child: Column(
            children: [
              WindowButtons(title: title, showNavigator: false),
              Expanded(
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        children: [
                          Expanded(
                            child: InteractiveViewer(
                              child: UnityVideoView(
                                heroTag: currentEvent.mediaPath,
                                player: videoController,
                                fit: fit,
                                paneBuilder: (context, player) {
                                  final video = UnityVideoView.of(context);

                                  return Stack(
                                    clipBehavior: Clip.none,
                                    children: [
                                      if (video.error != null)
                                        Center(
                                          child: ErrorWarning(
                                            message: video.error!,
                                          ),
                                        ),
                                      if (settings.kShowDebugInfo.value)
                                        Padding(
                                          padding: const EdgeInsets.all(8.0),
                                          child: Text(
                                            'source: ${player.dataSource ?? loc.unknown}'
                                            '\nposition: ${player.currentPos}'
                                            '\nduration ${player.duration}'
                                            '\nbuffer ${player.currentBuffer}',
                                            style: theme.textTheme.labelSmall
                                                ?.copyWith(
                                                  color: Colors.white,
                                                  shadows: outlinedText(),
                                                ),
                                          ),
                                        ),
                                      const Positioned.fill(
                                        child: MulticastViewport(),
                                      ),
                                      PositionedDirectional(
                                        bottom: 8.0,
                                        end: 8.0,
                                        child: Row(
                                          children: [
                                            CameraViewFitButton(
                                              fit: fit,
                                              onChanged:
                                                  (value) => setState(
                                                    () => fit = value,
                                                  ),
                                            ),
                                            if (device != null)
                                              Padding(
                                                padding:
                                                    const EdgeInsetsDirectional.only(
                                                      start: 8.0,
                                                    ),
                                                child: VideoStatusLabel(
                                                  device: device!,
                                                  video: video,
                                                  event: currentEvent,
                                                ),
                                              ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  );
                                },
                              ),
                            ),
                          ),
                          Row(
                            children: [
                              padd,
                              Expanded(
                                child: StreamBuilder<Duration>(
                                  stream: videoController.onCurrentPosUpdate,
                                  builder: (context, snapshot) {
                                    final pos =
                                        snapshot.data ??
                                        videoController.currentPos;
                                    return Row(
                                      children: [
                                        Text(
                                          settings.formatTimeRaw(
                                            currentEvent.publishedRaw,
                                            offset: pos,
                                            pattern: DateFormat.Hms(),
                                          ),
                                        ),
                                        padd,
                                        Expanded(
                                          child: Slider.adaptive(
                                            value:
                                                (_position ??
                                                        pos.inMilliseconds)
                                                    .clamp(
                                                      0.0,
                                                      duration.inMilliseconds,
                                                    )
                                                    .toDouble(),
                                            max:
                                                duration.inMilliseconds
                                                    .toDouble(),
                                            secondaryTrackValue:
                                                videoController
                                                    .currentBuffer
                                                    .inMilliseconds
                                                    .clamp(
                                                      0.0,
                                                      duration.inMilliseconds,
                                                    )
                                                    .toDouble(),
                                            onChangeStart: (v) {
                                              shouldAutoplay =
                                                  videoController.isPlaying;
                                              videoController.pause();
                                            },
                                            onChanged: (v) async {
                                              /// Since it's just a preview, we don't need to show every
                                              /// millisecond of the video on seek. This, in theory, should
                                              /// improve performance by 50%
                                              if (v.toInt().isEven) {
                                                videoController.seekTo(
                                                  Duration(
                                                    milliseconds: v.toInt(),
                                                  ),
                                                );
                                              }
                                              setState(() => _position = v);
                                            },
                                            onChangeEnd: (v) async {
                                              await videoController.seekTo(
                                                Duration(
                                                  milliseconds: v.toInt(),
                                                ),
                                              );

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
                                      ],
                                    );
                                  },
                                ),
                              ),
                              padd,
                              Text(
                                settings.formatTimeRaw(
                                  currentEvent.publishedRaw,
                                  offset: duration,
                                  pattern: DateFormat.Hms(),
                                ),
                              ),
                              padd,
                            ],
                          ),
                          Row(
                            children: [
                              padd,
                              SquaredIconButton(
                                onPressed: _playPause,
                                tooltip:
                                    videoController.isPlaying
                                        ? loc.pause
                                        : loc.play,
                                icon: PlayPauseIcon(
                                  isPlaying: videoController.isPlaying,
                                  size: 18.0,
                                ),
                              ),
                              Consumer<DownloadsManager>(
                                builder: (context, downloads, child) {
                                  return DownloadIndicator(
                                    event: currentEvent,
                                    small: true,
                                  );
                                },
                              ),
                              padd,
                              Text(loc.volume(volume.toStringAsFixed(1))),
                              const SizedBox(width: 6.0),
                              SizedBox(
                                width: kSliderControlerWidth,
                                child: Slider.adaptive(
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
                              Text(loc.speed(speed.toStringAsFixed(1))),
                              SizedBox(
                                width: kSliderControlerWidth,
                                child: Slider.adaptive(
                                  value: speed.clamp(
                                    settings.kEventsSpeed.min!,
                                    settings.kEventsSpeed.max!,
                                  ),
                                  min: settings.kEventsSpeed.min!,
                                  max: settings.kEventsSpeed.max!,
                                  onChanged: (v) => setState(() => speed = v),
                                  onChangeEnd: (v) async {
                                    videoController.setSpeed(v);
                                    setState(() => speed = v);
                                  },
                                ),
                              ),
                              padd,
                              if (videoController.isBuffering ||
                                  !videoController.isSeekable)
                                const SizedBox(
                                  height: 20.0,
                                  width: 20.0,
                                  child: CircularProgressIndicator.adaptive(
                                    strokeWidth: 2.0,
                                  ),
                                ),
                              padd,
                            ],
                          ),
                        ],
                      ),
                    ),
                    if (upcomingEvents.isNotEmpty)
                      CollapsableSidebar(
                        left: false,
                        builder: (context, collapsed, collapseButton) {
                          if (collapsed) {
                            return collapseButton;
                          }
                          return Column(
                            children: [
                              Row(
                                children: [
                                  const SizedBox(width: 16.0),
                                  Expanded(
                                    child: Text(
                                      loc.nextEvents,
                                      style: theme.textTheme.bodySmall,
                                    ),
                                  ),
                                  Align(
                                    alignment: AlignmentDirectional.topEnd,
                                    child: collapseButton,
                                  ),
                                ],
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
                                      highlight: true,
                                    ),
                                    ...upcomingEvents.map((event) {
                                      return Padding(
                                        padding:
                                            const EdgeInsetsDirectional.only(
                                              top: 6.0,
                                            ),
                                        child: EventTile(
                                          event: event,
                                          highlight:
                                              event.id == currentEvent.id,
                                          onPlay: () => setEvent(event),
                                        ),
                                      );
                                    }),
                                  ],
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                  ],
                ),
              ),
            ],
          ),
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
  final bool highlight;

  const EventTile({
    super.key,
    required this.event,
    this.onPlay,
    this.highlight = false,
  });

  static Widget buildContent(BuildContext context, Event event) {
    final settings = context.watch<SettingsProvider>();
    final loc = AppLocalizations.of(context);

    final eventType = event.type.locale(context).uppercaseFirst;
    final at = settings.formatRawDateAndTime(event.publishedRaw);

    return SizedBox(
      width: double.infinity,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          DefaultTextStyle.merge(
            style: const TextStyle(fontWeight: FontWeight.bold),
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
    final theme = Theme.of(context);
    final loc = AppLocalizations.of(context);

    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(8.0),
      side: BorderSide(
        color: highlight ? theme.colorScheme.primary : Colors.transparent,
        width: 2.0,
        style: highlight ? BorderStyle.solid : BorderStyle.none,
      ),
    );

    return Card(
      margin: EdgeInsetsDirectional.zero,
      shape: shape,
      clipBehavior: Clip.antiAliasWithSaveLayer,
      child: ExpansionTile(
        clipBehavior: Clip.hardEdge,
        tilePadding: const EdgeInsetsDirectional.only(start: 12.0, end: 10.0),
        initiallyExpanded: key != null,
        title: Row(
          children: [
            Expanded(child: Text('${event.deviceName} (${event.server.name})')),
          ],
        ),
        childrenPadding: const EdgeInsetsDirectional.symmetric(
          vertical: 12.0,
          horizontal: 16.0,
        ),
        expandedCrossAxisAlignment: CrossAxisAlignment.end,
        children: [
          buildContent(context, event),
          if (onPlay != null)
            TextButton(onPressed: onPlay, child: Text(loc.play)),
        ],
      ),
    );
  }
}
