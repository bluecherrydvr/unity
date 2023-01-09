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

import 'package:bluecherry_client/models/event.dart';
import 'package:bluecherry_client/providers/settings_provider.dart';
import 'package:bluecherry_client/widgets/desktop_buttons.dart';
import 'package:bluecherry_client/widgets/error_warning.dart';
import 'package:bluecherry_client/widgets/misc.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:unity_video_player/unity_video_player.dart';

class EventPlayerDesktop extends StatefulWidget {
  final Event event;

  const EventPlayerDesktop({Key? key, required this.event}) : super(key: key);

  @override
  State<EventPlayerDesktop> createState() => _EventPlayerDesktopState();
}

class _EventPlayerDesktopState extends State<EventPlayerDesktop>
    with SingleTickerProviderStateMixin {
  final videoController = UnityVideoPlayer.create();
  late final StreamSubscription playingSubscription;
  late final playingAnimationController = AnimationController(
    vsync: this,
    duration: const Duration(microseconds: 500),
  );

  double speed = 1.0;
  double volume = 1.0;
  double? _position;

  @override
  void initState() {
    super.initState();
    debugPrint(widget.event.mediaURL.toString());
    videoController
      ..setDataSource(
        widget.event.mediaURL.toString(),
      )
      ..setVolume(volume)
      ..setSpeed(speed);

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
  void dispose() {
    videoController
      ..release()
      ..dispose();
    playingSubscription.cancel();
    playingAnimationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsProvider>();

    return SliderTheme(
      data: SliderThemeData(trackShape: _CustomTrackShape()),
      child: Material(
        color: Colors.grey.shade900,
        child: Column(children: [
          const WindowButtons(),
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
                  ),
                  Text(
                    settings.dateFormat.format(widget.event.published),
                    style: const TextStyle(fontSize: 12.0),
                  ),
                  Text(widget.event.title),
                  const Spacer(),
                  Row(children: [
                    const Expanded(
                      child: SubHeader(
                        'PLAYBACK OPTIONS',
                        padding: EdgeInsets.zero,
                      ),
                    ),
                    IconButton(
                      onPressed: () async {
                        if (videoController.isPlaying) {
                          await videoController.pause();
                        } else {
                          await videoController.start();
                        }
                        setState(() {});
                      },
                      tooltip: videoController.isPlaying ? 'Pause' : 'Play',
                      icon: AnimatedBuilder(
                        animation: playingAnimationController,
                        builder: (context, _) => AnimatedIcon(
                          icon: AnimatedIcons.play_pause,
                          progress: playingAnimationController,
                        ),
                      ),
                    ),
                  ]),
                  Align(
                    alignment: AlignmentDirectional.centerStart,
                    child: Text('Volume • ${volume.toStringAsFixed(1)}'),
                  ),
                  Slider(
                    value: volume,
                    onChanged: (v) {
                      setState(() => volume = v);
                    },
                    onChangeEnd: (v) {
                      videoController.setVolume(v);
                      setState(() => volume = v);
                    },
                  ),
                  Align(
                    alignment: AlignmentDirectional.centerStart,
                    child: Text('Speed • ${speed.toStringAsFixed(2)}'),
                  ),
                  Slider(
                    value: speed,
                    min: 0.25,
                    max: 2,
                    divisions: 7,
                    label: speed.toStringAsFixed(2),
                    onChanged: (v) => setState(() => speed = v),
                    onChangeEnd: (v) async {
                      await videoController.setSpeed(v);
                      setState(() => speed = v);
                    },
                  ),
                ]),
              ),
            ]),
          ),
          Row(children: [
            const SizedBox(width: 16.0),
            Text(settings.timeFormat.format(widget.event.published)),
            const SizedBox(width: 16.0),
            Expanded(
              child: StreamBuilder<Duration>(
                stream: videoController.onCurrentPosUpdate,
                builder: (context, snapshot) => Slider(
                  value: _position ??
                      (snapshot.data ?? videoController.currentPos)
                          .inMicroseconds
                          .toDouble(),
                  max: videoController.duration.inMicroseconds.toDouble(),
                  onChanged: (v) => setState(() => _position = v),
                  onChangeEnd: (v) {
                    videoController.seekTo(Duration(microseconds: v.toInt()));
                    setState(() => _position = null);
                  },
                ),
              ),
            ),
            const SizedBox(width: 16.0),
            Text(
              settings.timeFormat.format(
                widget.event.published.add(videoController.duration),
              ),
            ),
            const SizedBox(width: 16.0),
          ]),
        ]),
      ),
    );
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

  @override
  void paint(
    PaintingContext context,
    Offset offset, {
    required RenderBox parentBox,
    required SliderThemeData sliderTheme,
    required Animation<double> enableAnimation,
    required TextDirection textDirection,
    required Offset thumbCenter,
    bool isDiscrete = false,
    bool isEnabled = false,
    double additionalActiveTrackHeight = 0,
  }) {
    return super.paint(
      context,
      offset,
      parentBox: parentBox,
      sliderTheme: sliderTheme,
      enableAnimation: enableAnimation,
      textDirection: textDirection,
      thumbCenter: thumbCenter,
      isDiscrete: isDiscrete,
      isEnabled: isEnabled,
      additionalActiveTrackHeight: additionalActiveTrackHeight,
    );
  }
}
