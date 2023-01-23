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
import 'package:bluecherry_client/models/event.dart';
import 'package:bluecherry_client/providers/events_playback_provider.dart';
import 'package:bluecherry_client/providers/server_provider.dart';
import 'package:bluecherry_client/providers/settings_provider.dart';
import 'package:bluecherry_client/utils/extensions.dart';
import 'package:bluecherry_client/widgets/device_grid/device_grid.dart';
import 'package:bluecherry_client/widgets/error_warning.dart';
import 'package:bluecherry_client/widgets/events_playback/events_playback.dart';
import 'package:bluecherry_client/widgets/events_playback/timeline_controller.dart';
import 'package:bluecherry_client/widgets/misc.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:provider/provider.dart';
import 'package:unity_video_player/unity_video_player.dart';

const kDeviceNameWidth = 140.0;
const kTimelineViewHeight = 190.0;
const kTimelineTileHeight = 24.0;

/// The width of a second
const kPeriodWidth = 2.0;

class EventsPlaybackDesktop extends StatefulWidget {
  final EventsData events;
  final FilterData? filter;
  final ValueChanged<FilterData> onFilter;

  const EventsPlaybackDesktop({
    Key? key,
    required this.events,
    required this.filter,
    required this.onFilter,
  }) : super(key: key);

  @override
  State<EventsPlaybackDesktop> createState() => _EventsPlaybackDesktopState();
}

class _EventsPlaybackDesktopState extends State<EventsPlaybackDesktop> {
  late final timelineController = TimelineController();

  double _volume = 1;

  @override
  void initState() {
    super.initState();
    timelineController.addListener(() => setState(() {}));
  }

  @override
  void didUpdateWidget(covariant EventsPlaybackDesktop oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.filter != widget.filter) {
      initialize();
    }
  }

  void initialize() {
    final allEvents = widget.events.isEmpty
        ? <Event>[]
        : widget.events.values.reduce((value, element) => value + element);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      timelineController.initialize(widget.events, allEvents);
    });
  }

  @override
  void dispose() {
    timelineController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final events = context.watch<EventsProvider>();

    return Row(children: [
      Expanded(
        child: Column(children: [
          Expanded(
            child: Center(
              child: timelineController.tiles.isEmpty ||
                      !timelineController.initialized
                  ? const Text('Select a device')
                  : GridView.count(
                      crossAxisCount: calculateCrossAxisCount(
                        timelineController.tiles.length,
                      ),
                      childAspectRatio: 16 / 9,
                      padding: kGridPadding,
                      mainAxisSpacing: kGridInnerPadding,
                      crossAxisSpacing: kGridInnerPadding,
                      children: timelineController.tiles.map((i) {
                        final has =
                            i.events.hasForDate(timelineController.currentDate);

                        return UnityVideoView(
                          player: i.player,
                          paneBuilder: (context, player) {
                            if (!has) {
                              return const Center(
                                child: Padding(
                                  padding: EdgeInsets.all(6.0),
                                  child: AutoSizeText(
                                    'The camera has no records in current period',
                                    maxLines: 1,
                                  ),
                                ),
                              );
                            } else if (player.dataSource == null) {
                              return const ErrorWarning(
                                message: 'Error loading',
                              );
                            } else {
                              debugPrint('${player.dataSource}');
                            }

                            return const SizedBox.shrink();
                          },
                        );
                      }).toList(),
                    ),
            ),
          ),
          SizedBox(
            height: kTimelineViewHeight,
            child: Card(
              margin: EdgeInsets.zero,
              shape: const RoundedRectangleBorder(),
              child: Padding(
                padding: const EdgeInsets.only(
                  left: 16.0,
                  right: 16.0,
                  top: 6.0,
                  bottom: 4.0,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          '${timelineController.speed == 1.0 ? '1' : timelineController.speed.toStringAsFixed(1)}x',
                        ),
                        SizedBox(
                          width: 120.0,
                          child: Slider(
                            value: timelineController.speed,
                            max: 2,
                            onChanged: (v) => timelineController.speed = v,
                          ),
                        ),
                        Tooltip(
                          message:
                              timelineController.isPaused ? 'Play' : 'Pause',
                          child: CircleAvatar(
                            child: Material(
                              type: MaterialType.transparency,
                              child: InkWell(
                                borderRadius: BorderRadius.circular(100.0),
                                onTap: () {
                                  if (timelineController.isPaused) {
                                    timelineController.play();
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
                        SizedBox(
                          width: 120.0,
                          child: Slider(
                            value: _volume,
                            onChanged: (v) => setState(() => _volume = v),
                          ),
                        ),
                        Text(_volume.toStringAsFixed(1)),
                        if (kDebugMode)
                          IconButton(
                            icon: const Icon(Icons.refresh),
                            tooltip: 'Recompute',
                            onPressed: initialize,
                          ),
                      ],
                    ),
                    Row(children: [
                      const SizedBox(
                        width: kDeviceNameWidth,
                        child: Text('Device name'),
                      ),
                      Text(
                        widget.filter == null
                            ? '--'
                            : SettingsProvider.instance.dateFormat
                                .format(widget.filter!.from),
                      ),
                      const Spacer(),
                      if (timelineController.initialized)
                        RepaintBoundary(
                          child: AnimatedBuilder(
                            animation: timelineController.positionNotifier,
                            builder: (context, child) {
                              return Text(
                                timelineController.currentDate.toString(),
                              );
                            },
                          ),
                        ),
                      const Spacer(),
                      Text(
                        widget.filter == null
                            ? '--'
                            : SettingsProvider.instance.dateFormat
                                .format(widget.filter!.to),
                      ),
                    ]),
                    Expanded(
                      child: SingleChildScrollView(
                        child: Material(
                          child: TimelineView(
                            timelineController: timelineController,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ]),
      ),
      ConstrainedBox(
        constraints: kSidebarConstraints,
        child: Material(
          child: Column(children: [
            Expanded(
              child: ListView.builder(
                padding: EdgeInsets.only(
                  bottom: MediaQuery.viewPaddingOf(context).bottom,
                ),
                itemCount: ServersProvider.instance.servers.length,
                itemBuilder: (context, i) {
                  final server = ServersProvider.instance.servers[i];
                  return FutureBuilder(
                    future: (() async => server.devices.isEmpty
                        ? API.instance.getDevices(
                            await API.instance.checkServerCredentials(server))
                        : true)(),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData) {
                        return Center(
                          child: Container(
                            alignment: AlignmentDirectional.center,
                            height: 156.0,
                            child: const CircularProgressIndicator.adaptive(),
                          ),
                        );
                      }

                      if (server.devices.any((d) => widget.events.keys
                          .contains(EventsProvider.idForDevice(d)))) {
                        return ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: server.devices.length + 1,
                          itemBuilder: (context, index) {
                            if (index == 0) {
                              return SubHeader(
                                server.name,
                                subtext: AppLocalizations.of(context).nDevices(
                                  server.devices.length,
                                ),
                              );
                            }

                            index--;
                            final device = server.devices[index];
                            if (!widget.events.keys
                                .contains(EventsProvider.idForDevice(device))) {
                              return const SizedBox.shrink();
                            }

                            final selected = events.selectedIds
                                .contains(EventsProvider.idForDevice(device));

                            return _DeviceTile(
                              device: device,
                              selected: selected,
                            );
                          },
                        );
                      }

                      return const SizedBox.shrink();
                    },
                  );
                },
              ),
            ),
            SizedBox(
              height: kTimelineViewHeight,
              child: Card(
                margin: EdgeInsets.zero,
                shape: const RoundedRectangleBorder(),
                child: Padding(
                  padding: const EdgeInsets.only(
                    top: 8.0,
                    bottom: 8.0,
                    left: 8.0,
                    right: 16.0,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SubHeader(
                        'Filter',
                        padding: EdgeInsets.only(bottom: 6.0),
                        height: null,
                      ),
                      FilterTile(
                        title: 'From',
                        trailing: widget.filter == null
                            ? '--'
                            : SettingsProvider.instance.dateFormat
                                .format(widget.filter!.from),
                        onTap: widget.filter == null
                            ? null
                            : () async {
                                final date = await showDatePicker(
                                  context: context,
                                  initialDate: widget.filter!.from,
                                  firstDate: widget.filter!.fromLimit,
                                  lastDate: widget.filter!.to,
                                );

                                if (date != null) {
                                  widget.onFilter(widget.filter!.copyWith(
                                    from: date,
                                  ));
                                }
                              },
                      ),
                      FilterTile(
                        title: 'To',
                        trailing: widget.filter == null
                            ? '--'
                            : SettingsProvider.instance.dateFormat
                                .format(widget.filter!.to),
                        onTap: widget.filter == null
                            ? null
                            : () async {
                                final date = await showDatePicker(
                                  context: context,
                                  initialDate: widget.filter!.to,
                                  firstDate: widget.filter!.from,
                                  lastDate: widget.filter!.toLimit,
                                );

                                if (date != null) {
                                  widget.onFilter(widget.filter!.copyWith(
                                    to: date,
                                  ));
                                }
                              },
                      ),
                      const Divider(),
                      FilterTile.checkbox(
                        checked: widget.filter?.allowAlarms,
                        onChanged: (v) {
                          if (v == null) {
                            if (widget.filter != null) {
                              widget.onFilter(
                                widget.filter!.copyWith(allowAlarms: true),
                              );
                            }
                          } else {
                            widget.onFilter(
                              widget.filter!.copyWith(allowAlarms: v),
                            );
                          }
                        },
                        title: const Text('Allow alarms'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ]),
        ),
      ),
    ]);
  }
}

class _DeviceTile extends StatefulWidget {
  const _DeviceTile({
    Key? key,
    required this.device,
    required this.selected,
  }) : super(key: key);

  final Device device;
  final bool selected;

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
          : () {
              if (widget.selected) {
                events.remove(widget.device);
              } else {
                events.add(widget.device);
              }
            },
      child: SizedBox(
        height: 40.0,
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
    required ValueChanged<bool?> onChanged,
    required Widget title,
  }) {
    return Row(children: [
      title,
      const Spacer(),
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
    return Row(children: [
      SizedBox(
        width: 40.0,
        child: AutoSizeText(
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
              padding: const EdgeInsetsDirectional.only(start: 4.0),
              child: AutoSizeText(
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
