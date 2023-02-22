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

import 'package:auto_size_text/auto_size_text.dart';
import 'package:bluecherry_client/models/device.dart';
import 'package:bluecherry_client/models/event.dart';
import 'package:bluecherry_client/providers/events_playback_provider.dart';
import 'package:bluecherry_client/utils/extensions.dart';
import 'package:bluecherry_client/utils/theme.dart';
import 'package:bluecherry_client/widgets/device_grid/device_grid.dart';
import 'package:bluecherry_client/widgets/device_selector_screen.dart';
import 'package:bluecherry_client/widgets/error_warning.dart';
import 'package:bluecherry_client/widgets/events_playback/events_playback.dart';
import 'package:bluecherry_client/widgets/events_playback/events_playback_desktop.dart';
import 'package:bluecherry_client/widgets/events_playback/timeline_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:provider/provider.dart';
import 'package:unity_video_player/unity_video_player.dart';

class EventsPlaybackMobile extends EventsPlaybackWidget {
  const EventsPlaybackMobile({
    super.key,
    required super.events,
    required super.filter,
    required super.onFilter,
  });

  @override
  State<EventsPlaybackWidget> createState() => _EventsPlaybackMobileState();
}

class _EventsPlaybackMobileState extends EventsPlaybackState {
  @override
  Widget buildChild(BuildContext context) {
    final eventsProvider = context.watch<EventsProvider>();

    final minTimelineHeight = kTimelineTileHeight *
        // at least the height of 2
        timelineController.tiles.length.clamp(
          2,
          double.infinity,
        );
    final maxTimelineHeight =
        (kTimelineTileHeight * timelineController.tiles.length)
                .clamp(minTimelineHeight, double.infinity) +
            70.0; // 70 is the height of the controls bar

    return Column(children: [
      Expanded(
        child: ColoredBox(
          color: Colors.black,
          child: () {
            if (!timelineController.initialized) {
              return const SizedBox.expand();
            } else if (timelineController.tiles.isEmpty) {
              return Center(
                child: Text(
                  AppLocalizations.of(context).selectACamera,
                  style: const TextStyle(color: Colors.white),
                ),
              );
            } else {
              return Center(
                child: AspectRatio(
                  aspectRatio: 16 / 9,
                  child: StaticGrid(
                    reorderable: false,
                    crossAxisCount: calculateCrossAxisCount(
                      timelineController.tiles.length,
                    ),
                    childAspectRatio: 16 / 9,
                    mainAxisSpacing: kGridInnerPadding,
                    crossAxisSpacing: kGridInnerPadding,
                    onReorder: eventsProvider.onReorder,
                    children: timelineController.tiles.map((tile) {
                      final has =
                          timelineController.currentItem is! TimelineGap &&
                              tile.events
                                  .hasForDate(timelineController.currentDate);

                      final color =
                          createTheme(themeMode: ThemeMode.dark).canvasColor;

                      return IndexedStack(
                        index: !has ? 0 : 1,
                        children: [
                          Container(
                            color: color,
                            alignment: Alignment.center,
                            padding: const EdgeInsets.all(12.0),
                            child: AutoSizeText(
                              AppLocalizations.of(context).noRecords,
                              textAlign: TextAlign.center,
                              style: const TextStyle(color: Colors.white),
                            ),
                          ),

                          /// This ensures a faster initialization of the video view
                          /// providing a smoother experience. This isn't a good solution,
                          /// just a workaround for now
                          UnityVideoView(
                            player: tile.player,
                            color: color,
                            paneBuilder: (context, player) {
                              if (player.dataSource == null) {
                                return const ErrorWarning(message: '');
                              } else {
                                // debugPrint('${player.dataSource}');
                              }

                              return const SizedBox.shrink();
                            },
                          ),
                        ],
                      );
                    }).toList(),
                  ),
                ),
              );
            }
          }(),
        ),
      ),
      const SizedBox(height: 8.0),
      Row(children: [
        const SizedBox(width: 8.0),
        IconButton(
          icon: const Icon(Icons.device_hub),
          onPressed: () async {
            final device = await Navigator.of(context).push<Device>(
              MaterialPageRoute(
                builder: (context) => const DeviceSelectorScreen(),
              ),
            );
            if (device is Device && !eventsProvider.contains(device)) {
              eventsProvider
                ..clear()
                ..add(device);
              initialize();
            }
          },
        ),
        const Spacer(),
        Tooltip(
          message: timelineController.isPaused
              ? AppLocalizations.of(context).play
              : AppLocalizations.of(context).pause,
          child: CircleAvatar(
            child: Material(
              type: MaterialType.transparency,
              child: InkWell(
                borderRadius: BorderRadius.circular(100.0),
                onTap: () {
                  if (timelineController.isPaused) {
                    timelineController.play(context);
                  } else {
                    timelineController.pause();
                  }
                },
                child: Center(
                  child: Icon(
                    timelineController.isPaused
                        ? Icons.play_arrow
                        : Icons.pause,
                  ),
                ),
              ),
            ),
          ),
        ),
        const Spacer(),
        IconButton(
          icon: const Icon(Icons.filter_list),
          tooltip: AppLocalizations.of(context).filter,
          onPressed: () => showFilter(context),
        ),
        const SizedBox(width: 8.0),
      ]),
      const SizedBox(height: 6.0),
      PhysicalModel(
        color: Colors.transparent,
        elevation: 4.0,
        child: ConstrainedBox(
          constraints: BoxConstraints(
            minHeight: minTimelineHeight,
            maxHeight: maxTimelineHeight,
            minWidth: double.infinity,
          ),
          child: Material(
            child: TimelineView(
              timelineController: timelineController,
              showDevicesName: false,
            ),
          ),
        ),
      ),
    ]);
  }
}
