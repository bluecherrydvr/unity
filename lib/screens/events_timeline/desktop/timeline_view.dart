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

import 'package:bluecherry_client/providers/downloads_provider.dart';
import 'package:bluecherry_client/providers/home_provider.dart';
import 'package:bluecherry_client/providers/settings_provider.dart';
import 'package:bluecherry_client/screens/downloads/indicators.dart';
import 'package:bluecherry_client/screens/events_browser/events_screen.dart';
import 'package:bluecherry_client/screens/events_timeline/desktop/timeline.dart';
import 'package:bluecherry_client/screens/events_timeline/desktop/timeline_card.dart';
import 'package:bluecherry_client/screens/events_timeline/desktop/timeline_tiles.dart';
import 'package:bluecherry_client/screens/layouts/device_grid.dart'
    show calculateCrossAxisCount;
import 'package:bluecherry_client/utils/constants.dart';
import 'package:bluecherry_client/widgets/collapsable_sidebar.dart';
import 'package:bluecherry_client/widgets/misc.dart';
import 'package:bluecherry_client/widgets/reorderable_static_grid.dart';
import 'package:bluecherry_client/widgets/squared_icon_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:provider/provider.dart';

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

  var _isCollapsed = false;

  var selectedEvents = <TimelineEvent>[];

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
    final loc = AppLocalizations.of(context);
    final settings = context.watch<SettingsProvider>();
    final home = context.watch<HomeProvider>();

    return Column(
      children: [
        Expanded(
          child: Row(
            children: [
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
                        text:
                            '${loc.noEventsLoadedTips}'
                            '\n'
                            '\n${loc.timelineKeyboardShortcutsTips}',
                      ),
                      children:
                          timeline.tiles.map((tile) {
                            return TimelineCard(tile: tile, timeline: timeline);
                          }).toList(),
                    ),
                  ),
                ),
              ),
              widget.sidebar,
            ],
          ),
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
          child: Column(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Padding(
                padding: const EdgeInsetsDirectional.only(
                  bottom: 4.0,
                  top: 2.0,
                  start: 8.0,
                  end: 8.0,
                ),
                child: Row(
                  children: [
                    SquaredIconButton(
                      icon: Icon(
                        _isCollapsed ? Icons.expand_less : Icons.expand_more,
                      ),
                      onPressed:
                          () => setState(() => _isCollapsed = !_isCollapsed),
                      tooltip: _isCollapsed ? loc.expand : loc.collapse,
                    ),
                    if (selectedEvents.isNotEmpty)
                      TimelineSelectionOptions(selectedEvents: selectedEvents),
                    Expanded(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          if (timeline.pausedToBuffer.isNotEmpty)
                            Container(
                              height: 22.0,
                              width: 22.0,
                              margin: const EdgeInsetsDirectional.only(
                                end: 8.0,
                              ),
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
                        ],
                      ),
                    ),
                    const SizedBox(width: 20.0),
                    SquaredIconButton(
                      tooltip: loc.previous,
                      icon: const Icon(Icons.skip_previous),
                      onPressed: () {
                        timeline.seekToPreviousEvent();
                      },
                    ),
                    SquaredIconButton(
                      tooltip: timeline.isPlaying ? loc.pause : loc.play,
                      icon: PlayPauseIcon(
                        isPlaying: timeline.isPlaying,
                        size: 24.0,
                      ),
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
                    SquaredIconButton(
                      tooltip: loc.next,
                      icon: const Icon(Icons.skip_next),
                      onPressed: () {
                        timeline.seekToNextEvent();
                      },
                    ),
                    const SizedBox(width: 20.0),
                    Expanded(
                      child: Row(
                        children: [
                          ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 120.0),
                            child: Slider.adaptive(
                              value:
                                  _volume ??
                                  (timeline.isMuted ? 0.0 : timeline.volume),
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
                                    onPressed:
                                        home.isLoadingFor(
                                              UnityLoadingReason
                                                  .fetchingEventsHistory,
                                            )
                                            ? null
                                            : widget.onFetch,
                                    child: Text(loc.filter),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                '${settings.kDateFormat.value.format(timeline.currentDate)} '
                '${settings.extendedTimeFormat.format(timeline.currentDate)}',
              ),
              AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                constraints: BoxConstraints(
                  maxHeight: _isCollapsed ? 0.0 : kTimelineTileHeight * 5.0,
                ),
                child: TimelineTiles(
                  timeline: timeline,
                  onSelectionChanged: (events) {
                    setState(() => selectedEvents = events);
                  },
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class TimelineSelectionOptions extends StatelessWidget {
  final List<TimelineEvent> selectedEvents;

  const TimelineSelectionOptions({super.key, required this.selectedEvents});

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final downloads = context.watch<DownloadsManager>();
    final events = selectedEvents.where(
      (e) => !downloads.isEventDownloaded(e.event.id),
    );
    final downloading = events.where(
      (e) => downloads.isEventDownloading(e.event.id),
    );
    return Row(
      children: [
        if (downloading.length != events.length)
          SquaredIconButton(
            tooltip: loc.downloadN(events.length),
            onPressed: () {
              for (final event in events) {
                downloads.download(event.event);
              }
            },
            icon: Icon(Icons.download),
          ),
        if (downloading.isNotEmpty)
          SizedBox.square(
            dimension: 40.0,
            child: DownloadProgressIndicator(
              progress: downloading
                  .map((e) => downloads.downloading[e.event]!.$1)
                  .reduce((a, b) => a + b),
            ),
          ),
      ],
    );
  }
}
