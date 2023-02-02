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

import 'package:bluecherry_client/models/event.dart';
import 'package:bluecherry_client/providers/downloads.dart';
import 'package:bluecherry_client/providers/settings_provider.dart';
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

  const EventPlayerDesktop({Key? key, required this.event}) : super(key: key);

  @override
  State<EventPlayerDesktop> createState() => _EventPlayerDesktopState();
}

class _EventPlayerDesktopState extends State<EventPlayerDesktop>
    with SingleTickerProviderStateMixin {
  final focusNode = FocusNode();

  final videoController = UnityVideoPlayer.create(
    width: 640,
    height: 360,
  );
  late final StreamSubscription playingSubscription;
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

  @override
  void initState() {
    super.initState();
    playingSubscription =
        videoController.onPlayingStateUpdate.listen((isPlaying) {
      setState(() {});
      if (isPlaying) {
        playingAnimationController.forward();
      } else {
        playingAnimationController.reverse();
      }
    });
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

    if (mediaUrl != videoController.dataSource) {
      videoController
        ..setDataSource(mediaUrl)
        ..setVolume(volume)
        ..setSpeed(speed);
    }

    super.didChangeDependencies();
  }

  @override
  void dispose() {
    videoController
      ..release()
      ..dispose();
    playingSubscription.cancel();
    playingAnimationController.dispose();
    focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
          child: Column(children: [
            WindowButtons(
              title: '${widget.event.deviceName} (${widget.event.server.name})',
            ),
            Expanded(
              child: Row(children: [
                Expanded(
                  child: UnityVideoView(
                    player: videoController,
                    paneBuilder: (context, controller) {
                      if (controller.error != null) {
                        return ErrorWarning(message: controller.error!);
                      } else if (!controller.isSeekable) {
                        return const Center(
                          child: CircularProgressIndicator(
                            color: Colors.white,
                          ),
                        );
                      }

                      return const SizedBox.shrink();
                    },
                  ),
                ),
                Container(
                  width: 200,
                  margin: const EdgeInsets.symmetric(
                    vertical: 12.0,
                    horizontal: 16.0,
                  ),
                  child: Column(children: [
                    Text(
                      '${widget.event.deviceName} (${widget.event.server.name})',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                    ),
                    Text(
                      settings.formatDate(widget.event.published),
                      style: const TextStyle(fontSize: 12.0),
                    ),
                    Text(widget.event.title),
                  ]),
                ),
              ]),
            ),
            Row(children: [
              padd,
              Expanded(
                child: StreamBuilder<Duration>(
                  stream: videoController.onCurrentPosUpdate,
                  builder: (context, snapshot) {
                    final pos = snapshot.data ?? videoController.currentPos;
                    return Row(children: [
                      Text(
                        DateFormat.Hms().format(
                          widget.event.published.add(pos).toLocal(),
                        ),
                      ),
                      padd,
                      Expanded(
                        child: Slider(
                          value: _position ?? pos.inMilliseconds.toDouble(),
                          max: videoController.duration.inMilliseconds
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
                              videoController
                                  .seekTo(Duration(milliseconds: v.toInt()));
                            }
                            setState(() => _position = v);
                          },
                          onChangeEnd: (v) async {
                            await videoController
                                .seekTo(Duration(milliseconds: v.toInt()));

                            if (shouldAutoplay) await videoController.start();

                            setState(() {
                              _position = null;
                              shouldAutoplay = false;
                            });
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
                  widget.event.published
                      .add(videoController.duration)
                      .toLocal(),
                ),
              ),
              padd,
            ]),
            Row(children: [
              padd,
              IconButton(
                onPressed: _playPause,
                tooltip: videoController.isPlaying ? loc.pause : loc.play,
                iconSize: 22.0,
                icon: AnimatedBuilder(
                  animation: playingAnimationController,
                  builder: (context, _) => AnimatedIcon(
                    icon: AnimatedIcons.play_pause,
                    progress: playingAnimationController,
                  ),
                ),
              ),
              Consumer<DownloadsManager>(builder: (context, downloads, child) {
                return DownloadIndicator(event: widget.event);
              }),
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
                    print(v);
                    await videoController.setSpeed(v);
                    setState(() => speed = v);
                  },
                ),
              ),
              padd,
            ]),
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
    setState(() {});
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
