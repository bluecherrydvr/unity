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

import 'dart:math';

import 'package:bluecherry_client/models/event.dart';
import 'package:bluecherry_client/providers/home_provider.dart';
import 'package:bluecherry_client/providers/settings_provider.dart';
import 'package:bluecherry_client/screens/events_browser/events_screen.dart';
import 'package:bluecherry_client/screens/events_timeline/desktop/timeline.dart';
import 'package:bluecherry_client/screens/events_timeline/desktop/timeline_card.dart';
import 'package:bluecherry_client/screens/layouts/device_grid.dart'
    show calculateCrossAxisCount;
import 'package:bluecherry_client/utils/constants.dart';
import 'package:bluecherry_client/utils/methods.dart';
import 'package:bluecherry_client/widgets/collapsable_sidebar.dart';
import 'package:bluecherry_client/widgets/misc.dart';
import 'package:bluecherry_client/widgets/reorderable_static_grid.dart';
import 'package:bluecherry_client/widgets/squared_icon_button.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:provider/provider.dart';

const _kDeviceNameWidth = 100.0;
const _kTimelineTileHeight = 30.0;

class TimelineEventsView extends StatefulWidget {
  final Timeline? timeline;

  final VoidCallback onFetch;
  final Widget sidebar;

  const TimelineEventsView({
    super.key,
    required this.timeline,
    required this.onFetch,
    required this.sidebar,
  });

  @override
  State<TimelineEventsView> createState() => _TimelineEventsViewState();
}

class _TimelineEventsViewState extends State<TimelineEventsView> {
  double? _speed;
  double? _volume;

  final verticalScrollController = ScrollController();

  bool _isCollapsed = false;

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
  void dispose() {
    verticalScrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final settings = context.watch<SettingsProvider>();
    final home = context.watch<HomeProvider>();

    return Column(children: [
      Expanded(
        child: Row(children: [
          Expanded(
            child: AspectRatio(
              aspectRatio: kHorizontalAspectRatio,
              child: Center(
                child: StaticGrid(
                  padding: EdgeInsetsDirectional.zero,
                  reorderable: false,
                  crossAxisCount: calculateCrossAxisCount(
                    timeline.tiles.length,
                  ),
                  onReorder: (a, b) {},
                  childAspectRatio: kHorizontalAspectRatio,
                  emptyChild: NoEventsLoaded(
                    isLoading: context.watch<HomeProvider>().isLoadingFor(
                          UnityLoadingReason.fetchingEventsHistory,
                        ),
                  ),
                  children: timeline.tiles.map((tile) {
                    return TimelineCard(tile: tile, timeline: timeline);
                  }).toList(),
                ),
              ),
            ),
          ),
          widget.sidebar,
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
              SquaredIconButton(
                icon:
                    Icon(_isCollapsed ? Icons.expand_more : Icons.expand_less),
                onPressed: () {
                  setState(() {
                    _isCollapsed = !_isCollapsed;
                  });
                },
                tooltip: _isCollapsed ? loc.expand : loc.collapse,
              ),
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
                    child: Slider.adaptive(
                      value: _speed ?? timeline.speed,
                      min: settings.kEventsSpeed.min!,
                      max: settings.kEventsSpeed.max!,
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
              SquaredIconButton(
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
                    child: Slider.adaptive(
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
                  const Spacer(),
                  Expanded(
                    child: Align(
                      alignment: AlignmentDirectional.centerEnd,
                      child: SizedBox(
                        width: kSidebarConstraints.maxWidth,
                        child: Center(
                          child: FilledButton(
                            onPressed: home.isLoadingFor(
                              UnityLoadingReason.fetchingEventsHistory,
                            )
                                ? null
                                : widget.onFetch,
                            child: Text(loc.filter),
                          ),
                        ),
                      ),
                    ),
                  ),
                ]),
              ),
            ]),
          ),
          Text(
            '${settings.kDateFormat.value.format(timeline.currentDate)} '
            '${settings.extendedTimeFormat.format(timeline.currentDate)}',
          ),
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            constraints: BoxConstraints(
              maxHeight: _isCollapsed ? 0.0 : _kTimelineTileHeight * 5.0,
            ),
            child: LayoutBuilder(builder: (context, constraints) {
              if (constraints.maxHeight < _kTimelineTileHeight / 1.9) {
                return const SizedBox.shrink();
              }

              final tileWidth =
                  (constraints.maxWidth - _kDeviceNameWidth) * timeline.zoom;
              final hourWidth = tileWidth / 24;
              final secondsWidth = tileWidth / secondsInADay;

              return Stack(
                fit: StackFit.passthrough,
                alignment: AlignmentDirectional.bottomCenter,
                children: [
                  Column(mainAxisSize: MainAxisSize.min, children: [
                    Padding(
                      padding: const EdgeInsetsDirectional.only(
                        start: _kDeviceNameWidth,
                      ),
                      // a hacky workaround to make the hours to follow the zoom
                      // controller.
                      child: AnimatedBuilder(
                        animation: Listenable.merge([timeline.zoomController]),
                        builder: (context, _) {
                          final offset = timeline.zoomController.hasClients
                              ? timeline.zoomController.offset
                              : 0.0;
                          return SingleChildScrollView(
                            key: ValueKey(offset),
                            scrollDirection: Axis.horizontal,
                            controller: ScrollController(
                              initialScrollOffset: offset,
                              debugLabel: 'Timeline Hours Scroll Controller',
                            ),
                            child: _TimelineHours(hourWidth: hourWidth),
                          );
                        },
                      ),
                    ),
                    Flexible(
                      child: EnforceScrollbarScroll(
                        controller: verticalScrollController,
                        onPointerSignal: _receivedPointerSignal,
                        child: SingleChildScrollView(
                          controller: verticalScrollController,
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              SizedBox(
                                width: _kDeviceNameWidth,
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: [
                                    ...timeline.tiles.map((tile) {
                                      return _TimelineTile.name(tile: tile);
                                    }),
                                  ],
                                ),
                              ),
                              Expanded(
                                child: GestureDetector(
                                  behavior: HitTestBehavior.opaque,
                                  onTapUp: (details) {
                                    _onMove(
                                      details.localPosition,
                                      constraints,
                                      tileWidth,
                                    );
                                  },
                                  onHorizontalDragUpdate: (details) {
                                    _onMove(
                                      details.localPosition,
                                      constraints,
                                      tileWidth,
                                    );
                                  },
                                  child: Builder(builder: (context) {
                                    return ScrollConfiguration(
                                      behavior: ScrollConfiguration.of(context)
                                          .copyWith(
                                        physics:
                                            const AlwaysScrollableScrollPhysics(),
                                      ),
                                      child: Scrollbar(
                                        controller: timeline.zoomController,
                                        thumbVisibility:
                                            isMobilePlatform || kIsWeb,
                                        child: SingleChildScrollView(
                                          controller: timeline.zoomController,
                                          scrollDirection: Axis.horizontal,
                                          child: SizedBox(
                                            width: tileWidth,
                                            child: Column(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                ...timeline.tiles.map((tile) {
                                                  return _TimelineTile(
                                                    key: ValueKey(tile),
                                                    tile: tile,
                                                  );
                                                }),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ),
                                    );
                                  }),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ]),
                  if (timeline.zoomController.hasClients)
                    Builder(builder: (context) {
                      final left =
                          (timeline.currentPosition.inSeconds * secondsWidth) -
                              timeline.zoomController.offset -
                              (/* the width of half of the triangle */
                                  8 / 2);
                      if (left < -8.0) return const SizedBox.shrink();
                      return Positioned(
                        key: timeline.indicatorKey,
                        left: _kDeviceNameWidth + left,
                        width: 8,
                        top: 12.0,
                        bottom: 0.0,
                        child: IgnorePointer(
                          child: Column(children: [
                            ClipPath(
                              clipper: InvertedTriangleClipper(),
                              child: Container(
                                width: 8,
                                height: 4,
                                // color: theme.colorScheme.onSurface,
                                color: Colors.black,
                              ),
                            ),
                            Expanded(
                              child: Container(
                                // color: theme.colorScheme.onSurface,
                                width: 1.8,
                                color: Colors.black,
                              ),
                            ),
                          ]),
                        ),
                      );
                    }),
                ],
              );
            }),
          ),
        ]),
      ),
    ]);
  }

  // Handle mousewheel and web trackpad scroll events.
  void _receivedPointerSignal(PointerSignalEvent event) {
    if (widget.timeline == null || widget.timeline!.tiles.isEmpty) return;
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

  void _onMove(
    Offset localPosition,
    BoxConstraints constraints,
    double tileWidth,
  ) {
    if (!timeline.zoomController.hasClients ||
        localPosition.dx >= (constraints.maxWidth - _kDeviceNameWidth)) {
      return;
    }
    final pointerPosition =
        (localPosition.dx + timeline.zoomController.offset) / tileWidth;
    if (pointerPosition < 0 || pointerPosition > 1) {
      return;
    }

    final seconds = (secondsInADay * pointerPosition).round();
    final position = Duration(seconds: seconds);
    timeline.seekTo(position);

    if (timeline.zoom > 1.0) {
      // the position that the seeker will start moving
      // 100. removes it from the border
      final endPosition = constraints.maxWidth - _kDeviceNameWidth - 100.0;
      if (localPosition.dx >= endPosition) {
        timeline.scrollTo(
          timeline.zoomController.offset + 25.0,
        );
      } else if (localPosition.dx <= 100.0) {
        timeline.scrollTo(
          timeline.zoomController.offset - 25.0,
        );
      }
    }
  }
}

class _TimelineTile extends StatefulWidget {
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
          padding: const EdgeInsetsDirectional.symmetric(horizontal: 5.0),
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
  State<_TimelineTile> createState() => _TimelineTileState();
}

class _TimelineTileState extends State<_TimelineTile> {
  late final Map<Event, Color> colors;

  @override
  void initState() {
    super.initState();
    colors = Map.fromIterables(
      widget.tile.events.map((e) => e.event),
      widget.tile.events.indexed.map((e) {
        final index = e.$1;
        return [
          ...Colors.primaries,
          ...Colors.accents,
        ][index % [...Colors.primaries, ...Colors.accents].length];
      }),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final settings = context.watch<SettingsProvider>();

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
              if (!widget.tile.events
                  .any((event) => event.startTime.hour == hour)) {
                return const SizedBox.shrink();
              }

              final secondWidth = constraints.maxWidth / 60 / 60;

              return Stack(clipBehavior: Clip.none, children: [
                for (final event in widget.tile.events
                    .where((event) => event.startTime.hour == hour))
                  PositionedDirectional(
                    // the minute (in seconds) + the start second * the width of
                    // a second
                    start: ((event.startTime.minute * 60) +
                            event.startTime.second) *
                        secondWidth,
                    width: event.duration.inSeconds * secondWidth,
                    height: _kTimelineTileHeight,
                    child: ColoredBox(
                      color: settings.kShowDebugInfo.value ||
                              settings.kShowDifferentColorsForEvents.value
                          ? colors[event.event] ?? theme.colorScheme.primary
                          : switch (event.event.type) {
                              EventType.motion => theme.colorScheme.secondary,
                              _ => theme.colorScheme.primary,
                            },
                      // color: theme.colorScheme.primary,
                      child: settings.kShowDebugInfo.value
                          ? Align(
                              alignment: AlignmentDirectional.centerStart,
                              child: Text(
                                '${widget.tile.events.indexOf(event)}',
                                style: TextStyle(
                                  color: theme.colorScheme.onPrimary,
                                  fontSize: 10.0,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            )
                          : null,
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

    final decWidth = hourWidth / 6;
    return Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
      ...List.generate(24, (index) {
        final hour = index + 1;
        final shouldDisplayHour = hour < 24;

        final hourWidget = shouldDisplayHour
            ? Transform.translate(
                offset: Offset(
                  hour.toString().length * 4,
                  0.0,
                ),
                child: Text(
                  '$hour',
                  style: theme.textTheme.labelMedium,
                  textAlign: TextAlign.end,
                ),
              )
            : const SizedBox.shrink();

        if (decWidth > 25.0) {
          return SizedBox(
            width: hourWidth,
            child: Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
              ...List.generate(5, (index) {
                return SizedBox(
                  width: decWidth,
                  child: Align(
                    alignment: AlignmentDirectional.centerEnd,
                    child: Container(
                      height: 6.5,
                      width: 2,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
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
