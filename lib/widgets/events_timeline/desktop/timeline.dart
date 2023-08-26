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
import 'dart:math';

import 'package:bluecherry_client/models/device.dart';
import 'package:bluecherry_client/models/event.dart';
import 'package:bluecherry_client/providers/settings_provider.dart';
import 'package:bluecherry_client/utils/extensions.dart';
import 'package:bluecherry_client/widgets/device_grid/device_grid.dart'
    show calculateCrossAxisCount;
import 'package:bluecherry_client/widgets/events_timeline/desktop/timeline_card.dart';
import 'package:bluecherry_client/widgets/events_timeline/desktop/timeline_sidebar.dart';
import 'package:bluecherry_client/widgets/events_timeline/events_playback.dart';
import 'package:bluecherry_client/widgets/misc.dart';
import 'package:bluecherry_client/widgets/reorderable_static_grid.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:unity_video_player/unity_video_player.dart';

final timelineTimeFormat = DateFormat('hh:mm:ss a');

class TimelineTile {
  final Device device;
  final List<TimelineEvent> events;

  late final UnityVideoPlayer videoController;

  TimelineTile({
    required this.device,
    required this.events,
  }) {
    videoController = UnityVideoPlayer.create(
      quality: UnityVideoQuality.p480,
      enableCache: true,
    );
  }
}

class TimelineEvent {
  /// The duration of the event
  final Duration duration;

  /// When the event started
  final DateTime startTime;

  final String videoUrl;

  final Event event;

  TimelineEvent({
    required this.duration,
    required this.startTime,
    required this.event,
    this.videoUrl =
        'https://user-images.githubusercontent.com/28951144/229373695-22f88f13-d18f-4288-9bf1-c3e078d83722.mp4',
  });

  static List<TimelineEvent> get fakeData {
    return [
      TimelineEvent(
        duration: const Duration(minutes: 1),
        startTime: DateTime(2023).add(
          Duration(hours: Random().nextInt(4), minutes: Random().nextInt(60)),
        ),
        event: Event.dump(),
      ),
      TimelineEvent(
        duration: const Duration(hours: 1),
        startTime: DateTime(2023).add(Duration(hours: Random().nextInt(4) + 5)),
        event: Event.dump(),
      ),
      TimelineEvent(
        duration: const Duration(minutes: 1),
        startTime: DateTime(2023).add(Duration(hours: Random().nextInt(4) + 9)),
        event: Event.dump(),
      ),
      TimelineEvent(
        duration: const Duration(minutes: 1),
        startTime: DateTime(2023).add(
          Duration(
            hours: Random().nextInt(4) + 13,
            minutes: Random().nextInt(60),
          ),
        ),
        event: Event.dump(),
      ),
      TimelineEvent(
        duration: const Duration(minutes: 1),
        startTime: DateTime(2023).add(
          Duration(
            hours: Random().nextInt(4) + 14,
            minutes: Random().nextInt(60),
          ),
        ),
        event: Event.dump(),
      ),
      TimelineEvent(
        duration: const Duration(minutes: 1),
        startTime: DateTime(2023).add(
          Duration(
            hours: Random().nextInt(4) + 20,
            minutes: Random().nextInt(60),
          ),
        ),
        event: Event.dump(),
      ),
    ];
  }

  DateTime get endTime => startTime.add(duration);

  bool isPlaying(DateTime currentDate) {
    return currentDate.isInBetween(startTime, endTime);
  }

  /// The position of the video at the [currentDate]
  Duration position(DateTime currentDate) {
    return currentDate.difference(startTime);
  }
}

/// A timeline of events
///
/// Events are played as they happened in time. The timeline is limited to a
/// single day, so events are from hour 0 to 23.
class Timeline extends ChangeNotifier {
  /// Each tile of the timeline
  final List<TimelineTile> tiles = [];

  /// All the events must have happened in the same day
  final DateTime date;

  Timeline({required List<TimelineTile> tiles, required this.date}) {
    add(tiles.where((tile) => tile.events.isNotEmpty));

    for (final tile in this.tiles) {
      tile.videoController
        ..onBufferUpdate.listen((_) => _eventCallback(tile))
        ..onDurationUpdate.listen((_) => _eventCallback(tile))
        ..onPlayingStateUpdate.listen((_) => _eventCallback(tile))
        ..onCurrentPosUpdate.listen((_) => _eventCallback(tile, notify: false));
    }

    zoomController.addListener(notifyListeners);
  }

  void _eventCallback(TimelineTile tile, {bool notify = true}) {
    if (tile.videoController.duration <= Duration.zero) return;

    final index = tiles.indexOf(tile);

    final bufferFactor = tile.videoController.currentBuffer.inMilliseconds /
        tile.videoController.duration.inMilliseconds;

    // This only applies if the video is not buffered
    if (bufferFactor < 1.0) {
      if (tile.videoController.currentBuffer <
          tile.videoController.currentPos) {
        debugPrint('should pause for buffering');
        pausedToBuffer.add(index);
        stop();
      } else if (pausedToBuffer.contains(index)) {
        debugPrint('should play from buffering');
        pausedToBuffer.remove(index);

        if (pausedToBuffer.isEmpty) play();
      }
    } else if (pausedToBuffer.contains(index)) {
      debugPrint('should play from buffering');
      pausedToBuffer.remove(index);

      if (pausedToBuffer.isEmpty) play();
    }
    if (notify) notifyListeners();
  }

  Timeline.placeholder() : date = DateTime(2023);

  static Timeline get fakeTimeline {
    return Timeline(
      date: DateTime(2023),
      tiles: [
        TimelineTile(
          device: Device.dump(name: 'device1'),
          events: TimelineEvent.fakeData,
        ),
        TimelineTile(
          device: Device.dump(name: 'device2'),
          events: TimelineEvent.fakeData,
        ),
        TimelineTile(
          device: Device.dump(name: 'device3'),
          events: TimelineEvent.fakeData,
        ),
        TimelineTile(
          device: Device.dump(name: 'device4'),
          events: TimelineEvent.fakeData,
        ),
      ],
    );
  }

  void add(Iterable<TimelineTile> tiles) {
    assert(tiles.every((tile) {
      return tile.events.every((event) =>
          event.startTime.year == date.year &&
          event.startTime.month == date.month &&
          event.startTime.day == date.day);
    }), 'All events must have happened in the same day');
    this.tiles.addAll(tiles);
    assert(
      this.tiles.length <= kMaxDevicesOnScreen,
      'There must be at most $kMaxDevicesOnScreen devices on screen',
    );
    notifyListeners();
  }

  void removeTile(TimelineTile tile) {
    tiles.remove(tile);
    notifyListeners();
  }

  void forEachEvent(
      void Function(TimelineTile tile, TimelineEvent event) callback) {
    for (var tile in tiles) {
      for (var event in tile.events) {
        callback(tile, event);
      }
    }
  }

  /// The current position of the timeline
  var currentPosition = const Duration();

  DateTime get currentDate => date.add(currentPosition);

  void seekTo(Duration position) {
    currentPosition = position;
    notifyListeners();

    forEachEvent((tile, event) {
      if (!event.isPlaying(currentDate)) return;
      tile.videoController.setDataSource(event.videoUrl);

      final position = event.position(currentDate);
      tile.videoController.seekTo(position);
      if (!isPlaying) tile.videoController.pause();

      debugPrint('Seeking ${tile.device} to $position');
    });
  }

  /// Seeks forward by [duration]
  void seekForward([Duration duration = const Duration(seconds: 15)]) =>
      seekTo(currentPosition + duration);

  /// Seeks backward by [duration]
  void seekBackward([Duration duration = const Duration(seconds: 15)]) =>
      seekTo(currentPosition - duration);

  double _volume = 1.0;
  bool get isMuted => volume == 0;
  double get volume => _volume;
  set volume(double value) {
    _volume = value;
    notifyListeners();

    for (final tile in tiles) {
      tile.videoController.setVolume(volume);
    }
  }

  double _speed = 1.0;
  double get speed => _speed;
  set speed(double value) {
    _speed = value;
    stop();
    notifyListeners();

    for (final tile in tiles) {
      tile.videoController.setSpeed(speed);
    }

    play();
  }

  final indicatorKey = GlobalKey(debugLabel: 'Indicator key');
  final zoomController = ScrollController(
    debugLabel: 'Zoom Indicator Controller',
  );
  double _zoom = 1.0;
  double get zoom => _zoom;
  set zoom(double value) {
    if (value >= 1.0 && value <= maxZoom) {
      _zoom = value;
      notifyListeners();
    }
  }

  static const maxZoom = 10.0;

  Timer? timer;
  bool get isPlaying => timer != null && timer!.isActive;

  /// The indexes of the tiles that are paused to buffer
  Set<int> pausedToBuffer = {};
  void stop() {
    if (timer == null) return;

    timer?.cancel();
    timer = null;

    for (final tile in tiles) {
      tile.videoController.pause();
    }
    notifyListeners();
  }

  void play([TimelineEvent? event]) {
    timer ??= Timer.periodic(Duration(milliseconds: 1000 ~/ _speed), (timer) {
      if (event == null) currentPosition += const Duration(seconds: 1);
      notifyListeners();

      forEachEvent((tile, e) {
        if (tile.videoController.isPlaying) return;

        if ((event != null && event == e) || e.isPlaying(currentDate)) {
          if (event == null) {
            tile.videoController.seekTo(e.position(currentDate));
          }
          if (!tile.videoController.isPlaying) tile.videoController.start();
        } else {
          tile.videoController.pause();
        }
      });
    });
    notifyListeners();
  }

  @override
  void dispose() {
    stop();
    for (final tile in tiles) {
      tile.videoController.dispose();
    }
    zoomController.dispose();
    super.dispose();
  }
}

const _kDeviceNameWidth = 100.0;
const _kTimelineTileHeight = 30.0;
final _secondsInADay = const Duration(days: 1).inSeconds;

class TimelineEventsView extends StatefulWidget {
  final Timeline? timeline;

  const TimelineEventsView({super.key, required this.timeline});

  @override
  State<TimelineEventsView> createState() => _TimelineEventsViewState();
}

class _TimelineEventsViewState extends State<TimelineEventsView> {
  double? _speed;
  double? _volume;

  @override
  void initState() {
    super.initState();
    widget.timeline?.addListener(_updateCallback);
  }

  void _updateCallback() {
    if (mounted) setState(() {});
  }

  Timeline get timeline => widget.timeline ?? Timeline.placeholder();

  @override
  void didUpdateWidget(covariant TimelineEventsView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.timeline != oldWidget.timeline) {
      oldWidget.timeline?.removeListener(_updateCallback);
      widget.timeline?.addListener(_updateCallback);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final loc = AppLocalizations.of(context);
    final settings = context.watch<SettingsProvider>();

    final view = Column(children: [
      Expanded(
        child: Row(children: [
          Expanded(
            child: Center(
              child: AspectRatio(
                aspectRatio: 16 / 9,
                child: Center(
                  child: StaticGrid(
                    padding: EdgeInsets.zero,
                    reorderable: false,
                    crossAxisCount: calculateCrossAxisCount(
                      timeline.tiles.length,
                    ),
                    onReorder: (a, b) {},
                    childAspectRatio: 16 / 9,
                    emptyChild: Center(child: Text(loc.noEventsFound)),
                    children: timeline.tiles.map((tile) {
                      return TimelineCard(tile: tile, timeline: timeline);
                    }).toList(),
                  ),
                ),
              ),
            ),
          ),
          TimelineSidebar(timeline: timeline),
        ]),
      ),
      Card(
        margin: const EdgeInsetsDirectional.only(
          start: 4.0,
          end: 4.0,
          bottom: 4.0,
        ),
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadiusDirectional.only(
            topStart: Radius.circular(12.0),
            bottomStart: Radius.circular(12.0),
            bottomEnd: Radius.circular(12.0),
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(mainAxisAlignment: MainAxisAlignment.end, children: [
          Padding(
            padding: const EdgeInsetsDirectional.only(
              bottom: 4.0,
              top: 2.0,
              start: 8.0,
              end: 8.0,
            ),
            child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              Expanded(
                child: Row(mainAxisAlignment: MainAxisAlignment.end, children: [
                  if (timeline.pausedToBuffer.isNotEmpty)
                    Container(
                      height: 22.0,
                      width: 22.0,
                      margin: const EdgeInsetsDirectional.only(end: 8.0),
                      child: const CircularProgressIndicator.adaptive(
                        strokeWidth: 2,
                      ),
                    ),
                  Text(
                    '${(_speed ?? timeline.speed) == 1.0 ? '1' : (_speed ?? timeline.speed).toStringAsFixed(1)}'
                    'x',
                  ),
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 120.0),
                    child: Slider(
                      value: _speed ?? timeline.speed,
                      min: 0.5,
                      max: 2.0,
                      onChanged: (s) => setState(() => _speed = s),
                      onChangeEnd: (s) {
                        _speed = null;
                        timeline.speed = s;
                        FocusScope.of(context).unfocus();
                      },
                    ),
                  ),
                ]),
              ),
              const SizedBox(width: 20.0),
              IconButton(
                tooltip: timeline.isPlaying ? loc.pause : loc.play,
                icon: PlayPauseIcon(isPlaying: timeline.isPlaying),
                onPressed: () {
                  setState(() {
                    if (timeline.isPlaying) {
                      timeline.stop();
                    } else {
                      timeline.play();
                    }
                  });
                },
              ),
              const SizedBox(width: 20.0),
              Expanded(
                child: Row(children: [
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 120.0),
                    child: Slider(
                      value:
                          _volume ?? (timeline.isMuted ? 0.0 : timeline.volume),
                      onChanged: (v) => setState(() => _volume = v),
                      onChangeEnd: (v) {
                        _volume = null;
                        timeline.volume = v;
                        FocusScope.of(context).unfocus();
                      },
                    ),
                  ),
                  Icon(() {
                    final volume = _volume ?? timeline.volume;
                    if ((_volume == null || _volume == 0.0) &&
                        (timeline.isMuted || volume == 0.0)) {
                      return Icons.volume_off;
                    } else if (volume < 0.5) {
                      return Icons.volume_down;
                    } else {
                      return Icons.volume_up;
                    }
                  }()),
                ]),
              ),
            ]),
          ),
          Text(
            '${settings.dateFormat.format(timeline.currentDate)} '
            '${timelineTimeFormat.format(timeline.currentDate)}',
          ),
          LayoutBuilder(builder: (context, constraints) {
            final tileWidth =
                (constraints.maxWidth - _kDeviceNameWidth) * timeline.zoom;
            final hourWidth = tileWidth / 24;
            final secondsWidth = tileWidth / _secondsInADay;

            return Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
              SizedBox(
                width: _kDeviceNameWidth,
                child: Column(children: [
                  ...timeline.tiles.map((tile) {
                    return _TimelineTile.name(tile: tile);
                  }),
                ]),
              ),
              Expanded(
                child: Stack(children: [
                  GestureDetector(
                    onHorizontalDragUpdate: (details) {
                      if (!timeline.zoomController.hasClients) return;
                      final pointerPosition = (details.localPosition.dx +
                              timeline.zoomController.offset) /
                          tileWidth;
                      if (pointerPosition < 0 || pointerPosition > 1) return;

                      final seconds =
                          (_secondsInADay * pointerPosition).round();
                      final position = Duration(seconds: seconds);
                      timeline.seekTo(position);
                    },
                    child: SingleChildScrollView(
                      controller: timeline.zoomController,
                      scrollDirection: Axis.horizontal,
                      child: SizedBox(
                        width: tileWidth,
                        child: Column(children: [
                          _TimelineHours(hourWidth: hourWidth),
                          ...timeline.tiles.map((tile) {
                            return _TimelineTile(
                              key: ValueKey(tile),
                              tile: tile,
                            );
                          }),
                        ]),
                      ),
                    ),
                  ),
                  if (timeline.zoomController.hasClients)
                    Positioned(
                      key: timeline.indicatorKey,
                      left:
                          (timeline.currentPosition.inSeconds * secondsWidth) -
                              timeline.zoomController.offset,
                      width: 1.8,
                      top: 16.0,
                      height: _kTimelineTileHeight * timeline.tiles.length,
                      child: IgnorePointer(
                        child: ColoredBox(
                          color: theme.colorScheme.onBackground,
                        ),
                      ),
                    ),
                ]),
              ),
            ]);
          }),
        ]),
      ),
    ]);

    return Listener(
      onPointerSignal: _receivedPointerSignal,
      child: view,
    );
  }

  // Handle mousewheel and web trackpad scroll events.
  void _receivedPointerSignal(PointerSignalEvent event) {
    final double scaleChange;
    if (event is PointerScrollEvent) {
      if (event.kind == PointerDeviceKind.trackpad) {
        return;
      }
      // Ignore left and right mouse wheel scroll.
      if (event.scrollDelta.dy == 0.0) {
        return;
      }
      scaleChange = exp(event.scrollDelta.dy / 200);
    } else if (event is PointerScaleEvent) {
      scaleChange = event.scale;
    } else {
      return;
    }
    if (scaleChange < 1.0) {
      timeline.zoom -= 0.8;
    } else {
      timeline.zoom += 0.6;
    }
  }
}

class _TimelineTile extends StatelessWidget {
  final TimelineTile tile;

  const _TimelineTile({super.key, required this.tile});

  static Widget name({required TimelineTile tile}) {
    return Builder(builder: (context) {
      final theme = Theme.of(context);
      final border = Border(
        right: BorderSide(color: theme.disabledColor.withOpacity(0.5)),
        top: BorderSide(color: theme.dividerColor.withOpacity(0.5)),
      );

      return Tooltip(
        message:
            '${tile.device.server.name}/${tile.device.name} (${tile.events.length})',
        preferBelow: false,
        textStyle: theme.textTheme.labelMedium?.copyWith(
          color: theme.colorScheme.onInverseSurface,
        ),
        verticalOffset: 12.0,
        child: Container(
          width: _kDeviceNameWidth,
          height: _kTimelineTileHeight,
          padding: const EdgeInsets.symmetric(horizontal: 5.0),
          decoration: BoxDecoration(
            color: theme.dialogBackgroundColor,
            border: border,
          ),
          alignment: AlignmentDirectional.centerStart,
          child: DefaultTextStyle(
            style: theme.textTheme.labelMedium!,
            child: Row(children: [
              Flexible(child: Text(tile.device.name, maxLines: 1)),
              Text(
                ' (${tile.events.length})',
                style: const TextStyle(fontSize: 10),
              ),
            ]),
          ),
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final border = Border(
      right: BorderSide(color: theme.disabledColor.withOpacity(0.5)),
      top: BorderSide(color: theme.dividerColor.withOpacity(0.5)),
    );

    return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      ...List.generate(24, (index) {
        final hour = index;

        return Expanded(
          child: Container(
            height: _kTimelineTileHeight,
            decoration: BoxDecoration(border: border),
            child: LayoutBuilder(builder: (context, constraints) {
              if (!tile.events.any((event) => event.startTime.hour == hour)) {
                return const SizedBox.shrink();
              }

              final secondWidth = constraints.maxWidth / 60 / 60;

              return Stack(clipBehavior: Clip.none, children: [
                for (final event in tile.events
                    .where((event) => event.startTime.hour == hour))
                  Positioned(
                    // the minute (in seconds) + the start second * the width of
                    // a second
                    left: ((event.startTime.minute * 60) +
                            event.startTime.second) *
                        secondWidth,
                    width: event.duration.inSeconds * secondWidth,
                    height: _kTimelineTileHeight,
                    child: ColoredBox(
                      color: theme.colorScheme.primary,
                    ),
                  ),
              ]);
            }),
          ),
        );
      }),
    ]);
  }
}

class _TimelineHours extends StatelessWidget {
  /// The width of an hour
  final double hourWidth;
  const _TimelineHours({required this.hourWidth});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final decWidth = hourWidth / 10;
    return Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
      ...List.generate(24, (index) {
        final hour = index + 1;
        if (hour == 24) return SizedBox(width: hourWidth);

        final hourWidget = Transform.translate(
          offset: Offset(
            hour.toString().length * 4,
            0.0,
          ),
          child: Text(
            '$hour',
            style: theme.textTheme.labelMedium,
            textAlign: TextAlign.end,
          ),
        );

        if (decWidth > 25.0) {
          return SizedBox(
            width: hourWidth,
            child: Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
              ...List.generate(9, (index) {
                return Container(
                  margin: EdgeInsets.only(
                    left: decWidth,
                  ),
                  height: 6.5,
                  width: 1,
                  color: Colors.black,
                );
              }),
              const Spacer(),
              hourWidget,
            ]),
          );
        }

        return SizedBox(
          width: hourWidth,
          child: hourWidget,
        );
      }),
    ]);
  }
}
