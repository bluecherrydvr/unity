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
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:unity_video_player/unity_video_player.dart';

typedef FutureValueChanged<T> = Future<void> Function(T data);

class EventsPlaybackDesktop extends StatefulWidget {
  final EventsData events;
  final FilterData? filter;
  final FutureValueChanged<FilterData> onFilter;

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
    final selectedIds = context.read<EventsProvider>().selectedIds;

    final realEvents = ({...widget.events}
      ..removeWhere((key, value) => !selectedIds.contains(key)));

    final allEvents = widget.events.isEmpty
        ? <Event>[]
        : realEvents.values.reduce((value, element) => value + element);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      timelineController.initialize(context, realEvents, allEvents);
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
    final settings = context.watch<SettingsProvider>();

    return Row(children: [
      Expanded(
        child: Column(children: [
          Expanded(
            child: () {
              if (!timelineController.initialized) {
                return const SizedBox.shrink();
              } else if (timelineController.tiles.isEmpty) {
                return Center(
                  child: Text(AppLocalizations.of(context).selectACamera),
                );
              } else {
                return _StaticGrid(
                  crossAxisCount: calculateCrossAxisCount(
                    timelineController.tiles.length,
                  ),
                  childAspectRatio: 16 / 9,
                  mainAxisSpacing: kGridInnerPadding,
                  crossAxisSpacing: kGridInnerPadding,
                  children: timelineController.tiles.map((i) {
                    final has =
                        i.events.hasForDate(timelineController.currentDate);

                    if (!has) {
                      return Container(
                        color: Colors.black,
                        alignment: Alignment.center,
                        padding: const EdgeInsets.all(6.0),
                        child: AutoSizeText(
                          AppLocalizations.of(context).noRecords,
                          maxLines: 1,
                        ),
                      );
                    }

                    return UnityVideoView(
                      player: i.player,
                      paneBuilder: (context, player) {
                        if (player.dataSource == null) {
                          return const ErrorWarning(message: '');
                        } else {
                          debugPrint('${player.dataSource}');
                        }

                        return const SizedBox.shrink();
                      },
                    );
                  }).toList(),
                );
              }
            }(),
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
                              return AutoSizeText(
                                '${settings.dateFormat.format(timelineController.currentDate)}'
                                ' '
                                '${DateFormat.Hms().format(timelineController.currentDate)}',
                                minFontSize: 8.0,
                                maxFontSize: 13.0,
                              );
                            },
                          ),
                        ),
                      const Spacer(),
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
                              onUpdate: () async {
                                initialize();
                              },
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
                      SubHeader(
                        AppLocalizations.of(context).filter,
                        padding: const EdgeInsets.only(bottom: 6.0),
                        height: null,
                      ),
                      FilterTile(
                        title: AppLocalizations.of(context).fromDate,
                        trailing: widget.filter == null
                            ? '--'
                            : settings.dateFormat.format(widget.filter!.from),
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
                        title: AppLocalizations.of(context).toDate,
                        trailing: widget.filter == null
                            ? '--'
                            : settings.dateFormat.format(widget.filter!.to),
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
                        onChanged: widget.filter == null
                            ? null
                            : (v) {
                                widget.onFilter(
                                  widget.filter!.copyWith(
                                    allowAlarms: !widget.filter!.allowAlarms,
                                  ),
                                );
                              },
                        title: Text(AppLocalizations.of(context).allowAlarms),
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
    final events = context.read<EventsProvider>();

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
    required ValueChanged<bool?>? onChanged,
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
              padding: const EdgeInsets.symmetric(horizontal: 4.0),
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

/// A non-scrollable grid view
class _StaticGrid extends StatelessWidget {
  final int crossAxisCount;
  final List<Widget> children;

  final double childAspectRatio;

  final double mainAxisSpacing;
  final double crossAxisSpacing;

  const _StaticGrid({
    Key? key,
    required this.crossAxisCount,
    required this.children,
    this.childAspectRatio = 1.0,
    this.mainAxisSpacing = 0.0,
    this.crossAxisSpacing = 0.0,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final realChildren =
        children.fold<List<List<Widget>>>([[]], (lists, child) {
      if (lists.last.length == crossAxisCount) lists.add([]);

      lists.last.add(AspectRatio(
        aspectRatio: childAspectRatio,
        child: child,
      ));

      return lists;
    });

    return Padding(
      padding: kGridPadding.add(EdgeInsetsDirectional.only(
        start: crossAxisSpacing,
        top: mainAxisSpacing,
      )),
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        ...List.generate(realChildren.length, (index) {
          return Flexible(
            child: Padding(
              padding: EdgeInsetsDirectional.only(
                bottom: mainAxisSpacing,
              ),
              child: buildRow(realChildren[index]),
            ),
          );
        }),
      ]),
    );
  }

  Widget buildRow(List<Widget> children) {
    assert(children.length <= crossAxisCount);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: List.generate(
        crossAxisCount,
        (index) {
          if (children.length < index + 1) {
            return const Expanded(child: SizedBox.shrink());
          }

          return Expanded(
            child: Padding(
              padding: EdgeInsetsDirectional.only(
                end: crossAxisSpacing,
              ),
              child: children[index],
            ),
          );
        },
      ),
    );
  }
}
