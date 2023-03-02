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
import 'package:bluecherry_client/api/api.dart';
import 'package:bluecherry_client/models/device.dart';
import 'package:bluecherry_client/providers/events_playback_provider.dart';
import 'package:bluecherry_client/providers/server_provider.dart';
import 'package:bluecherry_client/providers/settings_provider.dart';
import 'package:bluecherry_client/utils/extensions.dart';
import 'package:bluecherry_client/utils/theme.dart';
import 'package:bluecherry_client/widgets/collapsable_sidebar.dart';
import 'package:bluecherry_client/widgets/device_grid/device_grid.dart';
import 'package:bluecherry_client/widgets/error_warning.dart';
import 'package:bluecherry_client/widgets/events/event_player_desktop.dart';
import 'package:bluecherry_client/widgets/events_playback/events_playback.dart';
import 'package:bluecherry_client/widgets/events_playback/timeline_controller.dart';
import 'package:bluecherry_client/widgets/misc.dart';
import 'package:bluecherry_client/widgets/reorderable_static_grid.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:unity_video_player/unity_video_player.dart';

typedef FutureValueChanged<T> = Future<void> Function(T data);

class EventsPlaybackDesktop extends EventsPlaybackWidget {
  const EventsPlaybackDesktop({
    super.key,
    required super.events,
    required super.filter,
    required super.onFilter,
  });

  @override
  State<EventsPlaybackWidget> createState() => _EventsPlaybackDesktopState();
}

class _EventsPlaybackDesktopState extends EventsPlaybackState {
  final sidebarKey = GlobalKey();

  double? _volume;
  double? _speed;

  @override
  Widget buildChild(BuildContext context) {
    final settings = context.watch<SettingsProvider>();
    final eventsProvider = context.watch<EventsProvider>();

    final minTimelineHeight = kTimelineTileHeight *
        // at least the height of 4
        timelineController.tiles.length.clamp(
          4,
          double.infinity,
        );
    final maxTimelineHeight =
        (kTimelineTileHeight * timelineController.tiles.length)
                .clamp(minTimelineHeight, double.infinity) +
            70.0; // 70 is the height of the controls bar

    final page = Column(children: [
      Expanded(
        child: Row(children: [
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
                        crossAxisCount: calculateCrossAxisCount(
                          timelineController.tiles.length,
                        ),
                        childAspectRatio: 16 / 9,
                        onReorder: eventsProvider.onReorder,
                        children: timelineController.tiles.map((tile) {
                          final has = timelineController.currentItem
                                  is! TimelineGap &&
                              tile.events
                                  .hasForDate(timelineController.currentDate);

                          final color = createTheme(themeMode: ThemeMode.dark)
                              .canvasColor;

                          return IndexedStack(
                            key: ValueKey(tile),
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
          CollapsableSidebar(
            left: false,
            onCollapseStateChange: (v) {
              setState(() {});
            },
            builder: (context, collapseButton) {
              return Sidebar(
                key: sidebarKey,
                collapseButton: collapseButton,
                events: widget.events,
                onUpdate: initialize,
              );
            },
          ),
        ]),
      ),
      PhysicalModel(
        color: Colors.transparent,
        elevation: 4.0,
        child: ConstrainedBox(
          constraints: BoxConstraints(
            minHeight: minTimelineHeight,
            maxHeight: maxTimelineHeight,
            minWidth: double.infinity,
          ),
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Expanded(
              child: Card(
                margin: EdgeInsets.zero,
                shape: const RoundedRectangleBorder(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(children: [
                      const Icon(null),
                      const Spacer(),
                      Text(
                        '${(_speed ?? timelineController.speed) == 1.0 ? '1' : (_speed ?? timelineController.speed).toStringAsFixed(1)}x',
                      ),
                      ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 120.0),
                        child: Slider(
                          value: _speed ?? timelineController.speed,
                          min: 0.5,
                          max: 2.0,
                          onChanged: (s) => setState(() => _speed = s),
                          onChangeEnd: (s) {
                            _speed = null;
                            timelineController.speed = s;
                          },
                        ),
                      ),
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
                      const SizedBox(width: 20.0),
                      Icon(() {
                        final volume = _volume ?? timelineController.volume;
                        if ((_volume == null || _volume == 0.0) &&
                            (timelineController.isMuted || volume == 0.0)) {
                          return Icons.volume_off;
                        } else if (volume < 0.5) {
                          return Icons.volume_down;
                        } else {
                          return Icons.volume_up;
                        }
                      }()),
                      ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 120.0),
                        child: Slider(
                          value: _volume ??
                              (timelineController.isMuted
                                  ? 0.0
                                  : timelineController.volume),
                          onChanged: (v) => setState(() => _volume = v),
                          onChangeEnd: (v) {
                            _volume = null;
                            timelineController.volume = v;
                          },
                        ),
                      ),
                      ConstrainedBox(
                        constraints: const BoxConstraints(minWidth: 26.0),
                        child: Text(
                          timelineController.isMuted
                              ? '0'
                              : ((_volume ?? timelineController.volume) * 100)
                                  .toStringAsFixed(0),
                        ),
                      ),
                      const Spacer(),
                      IconButton(
                        icon: const Icon(Icons.filter_list),
                        tooltip: AppLocalizations.of(context).filter,
                        onPressed: () => showFilter(context),
                      ),
                    ]),
                    Row(children: [
                      const SizedBox(width: 8.0),
                      SizedBox(
                        width: kDeviceNameWidth,
                        child: Text(AppLocalizations.of(context).device),
                      ),
                      const Spacer(),
                      if (timelineController.initialized)
                        RepaintBoundary(
                          child: AnimatedBuilder(
                            animation: timelineController.positionNotifier,
                            builder: (context, child) {
                              final date =
                                  timelineController.currentItem!.start;

                              return AutoSizeText(
                                '${settings.dateFormat.format(date)}'
                                ' '
                                '${DateFormat.Hms().format(date.add(timelineController.thumbPrecision))}',
                                minFontSize: 8.0,
                                maxFontSize: 13.0,
                              );
                            },
                          ),
                        ),
                      const Spacer(),
                    ]),
                    Expanded(
                      child: Material(
                        child: TimelineView(
                          timelineController: timelineController,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(
              width: 220.0,
              child: Card(
                margin: EdgeInsets.zero,
                shape: const RoundedRectangleBorder(),
                child: Container(
                  alignment: AlignmentDirectional.center,
                  padding: const EdgeInsets.all(14.0),
                  child: timelineController.currentEvent == null
                      ? const Center(child: Text('No events'))
                      : EventTile.buildContent(
                          context,
                          timelineController.currentEvent!,
                        ),
                ),
              ),
            ),
          ]),
        ),
      ),
    ]);

    return page;
  }
}

class Sidebar extends StatelessWidget {
  final EventsData events;
  final Widget collapseButton;
  final VoidCallback onUpdate;

  const Sidebar({
    Key? key,
    required this.events,
    required this.collapseButton,
    required this.onUpdate,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final events = context.watch<EventsProvider>();

    final servers = ServersProvider.instance.servers.where((server) => server
        .devices
        .any((d) => this.events.keys.contains(EventsProvider.idForDevice(d))));

    return Material(
      child: Column(children: [
        Expanded(
          child: ListView.builder(
            padding: EdgeInsets.only(
              bottom: MediaQuery.viewPaddingOf(context).bottom,
            ),
            itemCount: servers.length,
            itemBuilder: (context, i) {
              final server = servers.elementAt(i);
              return FutureBuilder(
                future: (() async => server.devices.isEmpty
                    ? await API.instance.getDevices(
                        await API.instance.checkServerCredentials(server))
                    : true)(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return Center(
                      child: Container(
                        alignment: AlignmentDirectional.center,
                        height: 156.0,
                        child: const LinearProgressIndicator(),
                      ),
                    );
                  }

                  final devices = server.devices.sorted();

                  return ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: devices.length + 1,
                    itemBuilder: (context, index) {
                      if (index == 0) {
                        return SubHeader(
                          server.name,
                          subtext: AppLocalizations.of(context).nDevices(
                            devices.length,
                          ),
                          padding: const EdgeInsetsDirectional.only(
                            start: 16.0,
                            end: 6.0,
                          ),
                          trailing: i == 0 ? collapseButton : null,
                        );
                      }

                      index--;
                      final device = devices[index];
                      if (!this
                          .events
                          .keys
                          .contains(EventsProvider.idForDevice(device))) {
                        return const SizedBox.shrink();
                      }

                      final selected = events.selectedIds
                          .contains(EventsProvider.idForDevice(device));

                      return _DeviceTile(
                        device: device,
                        selected: selected,
                        onUpdate: () async {
                          onUpdate();
                        },
                      );
                    },
                  );
                },
              );
            },
          ),
        ),
      ]),
    );
  }
}

class _DeviceTile extends StatefulWidget {
  const _DeviceTile({
    Key? key,
    required this.device,
    required this.selected,
    required this.onUpdate,
  }) : super(key: key);

  final Device device;
  final bool selected;
  final VoidCallback onUpdate;

  @override
  State<_DeviceTile> createState() => _DesktopDeviceSelectorTileState();
}

class _DesktopDeviceSelectorTileState extends State<_DeviceTile> {
  PointerDeviceKind? currentLongPressDeviceKind;

  @override
  Widget build(BuildContext context) {
    // subscribe to media query updates
    MediaQuery.of(context);
    final theme = Theme.of(context);
    final events = context.watch<EventsProvider>();

    return InkWell(
      onTap: !widget.device.status
          ? null
          : () async {
              if (widget.selected) {
                await events.remove(widget.device);
              } else {
                await events.add(widget.device);
              }
              widget.onUpdate();
            },
      child: SizedBox(
        height: 30.0,
        child: Row(children: [
          const SizedBox(width: 16.0),
          Container(
            height: 6.0,
            width: 6.0,
            margin: const EdgeInsetsDirectional.only(end: 8.0),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: widget.device.status ? Colors.green.shade100 : Colors.red,
            ),
          ),
          Expanded(
            child: Text(
              widget.device.name.uppercaseFirst(),
              style: theme.textTheme.titleMedium!.copyWith(
                color: widget.selected
                    ? theme.colorScheme.primary
                    : !widget.device.status
                        ? theme.disabledColor
                        : null,
              ),
            ),
          ),
          const SizedBox(width: 16.0),
        ]),
      ),
    );
  }
}

class FilterDialog extends StatelessWidget {
  final FilterData? filter;
  final FutureValueChanged<FilterData> onFilter;

  const FilterDialog({
    Key? key,
    required this.filter,
    required this.onFilter,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final settings = SettingsProvider.instance;

    return SizedBox(
      width: 280.0,
      child: AlertDialog(
        title: Text(AppLocalizations.of(context).filter),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            FilterTile(
              title: AppLocalizations.of(context).fromDate,
              trailing: filter == null
                  ? '--'
                  : settings.dateFormat.format(filter!.from),
              onTap: filter == null
                  ? null
                  : () async {
                      final date = await showDatePicker(
                        context: context,
                        initialDate: filter!.from,
                        firstDate: filter!.fromLimit,
                        lastDate: filter!.to,
                      );

                      if (date != null) {
                        onFilter(filter!.copyWith(
                          from: date,
                        ));
                      }
                    },
            ),
            FilterTile(
              title: AppLocalizations.of(context).toDate,
              trailing: filter == null
                  ? '--'
                  : settings.dateFormat.format(filter!.to),
              onTap: filter == null
                  ? null
                  : () async {
                      final date = await showDatePicker(
                        context: context,
                        initialDate: filter!.to,
                        firstDate: filter!.from,
                        lastDate: filter!.toLimit,
                      );

                      if (date != null) {
                        onFilter(filter!.copyWith(
                          to: date,
                        ));
                      }
                    },
            ),
            FilterTile.checkbox(
              checked: filter?.allowAlarms,
              onChanged: filter == null
                  ? null
                  : (v) {
                      onFilter(
                        filter!.copyWith(
                          allowAlarms: !filter!.allowAlarms,
                        ),
                      );
                    },
              title: Text(AppLocalizations.of(context).allowAlarms),
            ),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: Navigator.of(context).pop,
            child: Text(AppLocalizations.of(context).finish),
          ),
        ],
      ),
    );
  }
}

class FilterTile extends StatelessWidget {
  final String title;
  final String trailing;
  final VoidCallback? onTap;

  const FilterTile({
    Key? key,
    required this.title,
    required this.trailing,
    required this.onTap,
  }) : super(key: key);

  static Widget checkbox({
    required bool? checked,
    required ValueChanged<bool?>? onChanged,
    required Widget title,
  }) {
    return Row(children: [
      Expanded(child: title),
      Checkbox(
        value: checked,
        onChanged: onChanged,
        tristate: true,
        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    return Row(mainAxisSize: MainAxisSize.min, children: [
      SizedBox(
        width: 40.0,
        child: Text(
          title,
          maxLines: 1,
        ),
      ),
      const SizedBox(width: 4.0),
      Expanded(
        child: Material(
          child: InkWell(
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4.0),
              child: Text(
                trailing,
                maxLines: 1,
                textAlign: TextAlign.end,
              ),
            ),
          ),
        ),
      ),
    ]);
  }
}
