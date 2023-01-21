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
import 'package:bluecherry_client/providers/home_provider.dart';
import 'package:bluecherry_client/providers/server_provider.dart';
import 'package:bluecherry_client/providers/settings_provider.dart';
import 'package:bluecherry_client/utils/extensions.dart';
import 'package:bluecherry_client/widgets/device_grid/device_grid.dart';
import 'package:bluecherry_client/widgets/error_warning.dart';
import 'package:bluecherry_client/widgets/events_playback/events_playback.dart';
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
const kPeriodWidth = 3.0;

class TimelineItem {
  final String deviceId;
  final List<Event> events;
  final UnityVideoPlayer player;

  const TimelineItem({
    required this.deviceId,
    required this.events,
    required this.player,
  });
}

class TimelineController extends ChangeNotifier {
  AnimationController? controller;
  DateTime get currentPeriod => periods.first.add(duration * controller!.value);
  Duration? _duration;
  Duration get duration {
    return Duration(milliseconds: _duration!.inMilliseconds ~/ _speed);
  }

  double _speed = 2;
  double get speed => _speed;
  set speed(double v) {
    _speed = v;

    controller?.duration = duration;

    notifyListeners();
  }

  List<TimelineItem> items = [];
  List<DateTime> periods = [];

  TimelineController();

  /// [events] all the events split by device
  ///
  /// [allEvents] all events in the history
  Future<void> initialize(
    EventsData events,
    List<Event> allEvents,
    TickerProvider vsync,
  ) async {
    HomeProvider.instance.loading(
      UnityLoadingReason.fetchingEventsPlaybackPeriods,
      notify: false,
    );
    await clear();
    notifyListeners();

    periods = await compute(_generatePeriods, [
      allEvents.oldest.published,
      allEvents.newest.published,
      allEvents.map((e) => e.published),
    ]);

    _duration = periods.last.difference(periods.first);
    notifyListeners();

    controller?.dispose();
    controller = null;
    controller = AnimationController(
      vsync: vsync,
      duration: duration,
    )..addListener(() {
        if (!controller!.isAnimating) {
          for (final item in items) {
            item.player.pause();
          }
          notifyListeners();
          return;
        }

        if (controller!.isCompleted) {
          controller!.value = 0.0;
          return;
        }

        var shouldNotify = false;

        for (final item in items) {
          if (item.events.hasForDate(currentPeriod)) {
            // print('${item.deviceId} has');
            if (!item.player.isPlaying) {
              shouldNotify = true;
              item.player.start();
            }
          } else {
            if (item.player.isPlaying) {
              shouldNotify = true;
              item.player.pause();
            }
          }
        }

        if (shouldNotify) notifyListeners();
      });

    for (final event in events.entries) {
      final id = event.key;
      final ev = event.value;

      final item = TimelineItem(
        deviceId: id,
        events: ev,
        player: UnityVideoPlayer.create(),
      );

      item.player
        ..setMultipleDataSource(
          // we can ensure the url is not null because we filter for alarms above
          ev.where((event) => event.mediaURL != null).map((event) {
            return event.mediaURL!.toString();
          }).toList(),
          autoPlay: false,
        )
        ..onPlayingStateUpdate.listen((playing) {
          if (playing) controller?.forward();
          notifyListeners();
        });

      controller?.forward();

      items.add(item);
    }

    HomeProvider.instance.notLoading(
      UnityLoadingReason.fetchingEventsPlaybackPeriods,
    );

    notifyListeners();
  }

  static List<DateTime> _generatePeriods(List data) {
    final oldest = data[0] as DateTime;
    final newest = data[1] as DateTime;
    final allDates = data[2] as Iterable<DateTime>;

    debugPrint('oldest $oldest / newest $newest - ${allDates.length}');

    var periods = <DateTime>[];

    var placeholder = oldest;

    while (placeholder.year != newest.year ||
        placeholder.month != newest.month ||
        placeholder.day != newest.day ||
        placeholder.hour != newest.hour ||
        placeholder.minute != newest.minute) {
      placeholder = placeholder.add(const Duration(minutes: 1));

      if (allDates.hasForDate(placeholder)) periods.add(placeholder);
    }

    return periods;
  }

  /// Starts all players
  Future<void> play() async {
    controller?.forward();

    notifyListeners();
  }

  /// Checks if the current player state is paused
  ///
  /// If a single player is paused, all players will be paused.
  bool get isPaused {
    return controller == null || !controller!.isAnimating;
  }

  /// Pauses all players
  Future<void> pause() async {
    await Future.wait(items.map((i) => i.player.pause()));
    controller?.stop();

    notifyListeners();
  }

  Future<void> clear() async {
    for (final item in items) {
      await item.player.release();
      item.player.dispose();
    }

    items.clear();
    periods.clear();
  }

  @override
  Future<void> dispose() async {
    super.dispose();
    clear();

    controller?.dispose();
  }
}

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

class _EventsPlaybackDesktopState extends State<EventsPlaybackDesktop>
    with TickerProviderStateMixin {
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
      final allEvents = widget.events.isEmpty
          ? <Event>[]
          : widget.events.values.reduce((value, element) => value + element);

      timelineController.initialize(widget.events, allEvents, this);
    }
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
              child: events.selectedIds.isEmpty
                  ? const Text('Select a device')
                  : GridView.count(
                      crossAxisCount: calculateCrossAxisCount(
                        timelineController.items.length,
                      ),
                      childAspectRatio: 16 / 9,
                      padding: kGridPadding,
                      mainAxisSpacing: kGridInnerPadding,
                      crossAxisSpacing: kGridInnerPadding,
                      children: timelineController.items.map((i) {
                        return UnityVideoView(
                          player: i.player,
                          paneBuilder: (context, player) {
                            final has = i.events
                                .hasForDate(timelineController.currentPeriod);

                            if (!has) {
                              return const Center(
                                child: Text(
                                  'The camera has no records in current period',
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
                      if (timelineController.controller != null)
                        AnimatedBuilder(
                          animation: timelineController.controller!,
                          builder: (context, child) {
                            return Text(
                              timelineController.currentPeriod.toString(),
                            );
                          },
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

class TimelineView extends StatelessWidget {
  final TimelineController timelineController;

  const TimelineView({
    Key? key,
    required this.timelineController,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final maxHeight = timelineController.items.length * kTimelineTileHeight;
    final maxWidth = timelineController.periods.length * kPeriodWidth;

    final servers = context.read<ServersProvider>().servers;

    return SizedBox(
      height: maxHeight,
      child: Row(children: [
        Column(
            children: timelineController.items.map((i) {
          final device = servers.findDevice(i.deviceId)!;
          final server = servers.firstWhere((s) => s.ip == device.server.ip);

          return SizedBox(
            height: kTimelineTileHeight,
            width: kDeviceNameWidth,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              child: AutoSizeText(
                '${server.name}/${device.name}',
                maxLines: 1,
                overflow: TextOverflow.fade,
              ),
            ),
          );
        }).toList()),
        const VerticalDivider(width: 2.0),
        Expanded(
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: SizedBox(
              width: maxWidth,
              height: maxHeight,
              child: Stack(children: [
                Positioned.fill(
                  child: Column(
                      children: timelineController.items.map((item) {
                    return Row(
                      children: timelineController.periods.map((period) {
                        final has = item.events.hasForDate(period);

                        return Container(
                          height: kTimelineTileHeight,
                          decoration: BoxDecoration(
                            color: has
                                ? item.events.forDate(period).isAlarm
                                    ? Colors.red
                                    : Colors.green.shade700
                                : Colors.grey.shade400,
                            border: Border(
                              bottom: BorderSide(
                                color: Theme.of(context).canvasColor,
                              ),
                            ),
                          ),
                          width: kPeriodWidth,
                        );
                      }).toList(),
                    );
                  }).toList()),
                ),
                if (timelineController.controller != null)
                  AnimatedBuilder(
                    animation: timelineController.controller!,
                    builder: (context, child) {
                      final left = Tween<double>(
                        begin: 0,
                        end: maxWidth,
                      ).evaluate(timelineController.controller!);

                      return Positioned(
                        top: 0,
                        bottom: 0,
                        left: left,
                        child: child!,
                      );
                    },
                    child: GestureDetector(
                      onHorizontalDragStart: (_) {
                        timelineController.controller!.stop();
                      },
                      onHorizontalDragUpdate: (d) {
                        // if lower than 0 or greater than 1, it means it's off the
                        // bounds of the scroller
                        final pos =
                            (d.localPosition.dx / maxWidth).clamp(0.0, 1.0);
                        debugPrint('${d.localPosition.dx}/$maxWidth $pos');

                        timelineController.controller!.value = pos;

                        // print(timelineController.controller!.value);

                        // Tween<double>(
                        //   begin: 0,
                        //   end: maxWidth,
                        // );
                      },
                      onHorizontalDragEnd: (_) {
                        timelineController.controller!.forward();
                      },
                      child: Container(
                        height: double.infinity,
                        width: kPeriodWidth,
                        color: Colors.black.withOpacity(0.6),
                      ),
                    ),
                  ),
              ]),
            ),
          ),
        ),
      ]),
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

  @override
  Widget build(BuildContext context) {
    return Row(children: [
      Text(title),
      const SizedBox(width: 4.0),
      Expanded(
        child: Material(
          child: InkWell(
            onTap: onTap,
            child: AutoSizeText(
              trailing,
              maxLines: 1,
              textAlign: TextAlign.end,
            ),
          ),
        ),
      ),
    ]);
  }
}
