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

import 'package:bluecherry_client/l10n/generated/app_localizations.dart';
import 'package:bluecherry_client/models/device.dart';
import 'package:bluecherry_client/models/event.dart';
import 'package:bluecherry_client/providers/downloads_provider.dart';
import 'package:bluecherry_client/providers/home_provider.dart';
import 'package:bluecherry_client/providers/settings_provider.dart';
import 'package:bluecherry_client/screens/downloads/indicators.dart';
import 'package:bluecherry_client/screens/events_timeline/desktop/timeline.dart';
import 'package:bluecherry_client/screens/events_timeline/events_playback.dart';
import 'package:bluecherry_client/utils/constants.dart';
import 'package:bluecherry_client/utils/date.dart';
import 'package:bluecherry_client/utils/extensions.dart';
import 'package:bluecherry_client/utils/theme.dart';
import 'package:bluecherry_client/widgets/device_selector.dart';
import 'package:bluecherry_client/widgets/misc.dart';
import 'package:bluecherry_client/widgets/squared_icon_button.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:unity_video_player/unity_video_player.dart';

const _kEventSeparatorWidth = 8.0;

class TimelineDeviceView extends StatefulWidget {
  const TimelineDeviceView({
    super.key,
    required this.timeline,
    required this.onDateChanged,
  });

  final Timeline timeline;
  final ValueChanged<DateTime> onDateChanged;

  @override
  State<TimelineDeviceView> createState() => _TimelineDeviceViewState();
}

class _TimelineDeviceViewState extends State<TimelineDeviceView> {
  Device? device;
  TimelineTile? get tile {
    if (device == null) return null;
    return widget.timeline.tiles.firstWhereOrNull((t) => t.device == device);
  }

  DateTime? currentDate;
  TimelineEvent? get currentEvent {
    if (tile == null) return null;

    assert(currentDate != null, 'There must be a date');
    return tile?.events.firstWhereOrNull((event) {
      return event.isPlaying(currentDate!);
    });
  }

  int lastEventIndex = -1;
  bool get isFirstEvent => lastEventIndex <= 0;
  bool get isLastEvent =>
      lastEventIndex.isNegative || lastEventIndex == tile!.events.length - 1;

  Iterable<TimelineEvent> get eventsBefore => tile!.events.whereIndexed(
    (index, _) => index < tile!.events.indexOf(currentEvent!),
  );

  /// Whether the user is scrolling the timeline. If true, [ensureScrollPosition]
  /// will not execute to avoid conflicts
  bool isScrolling = false;
  final controller = ScrollController();

  /// Select a device to show on the timeline
  Future<void> selectDevice(BuildContext context) async {
    device = await showDeviceSelector(
      context,
      available: widget.timeline.tiles.map((tile) => tile.device),
      selected: [if (tile != null) tile!.device],
      eventsPerDevice: widget.timeline.tiles.fold<Map<Device, int>>({}, (
        map,
        tile,
      ) {
        map[tile.device] = tile.events.length;
        return map;
      }),
    );
    if (device != null && mounted) {
      // If there is already a selected device, dispose it
      setState(() {
        positionSubscription = tile!.videoController.onCurrentPosUpdate.listen(
          _tilePositionListener,
        );
        bufferingSubscription = tile!.videoController.onBufferStateUpdate
            .listen((v) {
              if (mounted) setState(() => isBuffering = v);
            });
        tile!.videoController.onBufferUpdate.listen((_) => _updateScreen());
        tile!.videoController.setDataSource(currentEvent!.videoUrl);
        tile!.videoController.onPlayingStateUpdate.listen(
          (_) => _updateScreen(),
        );

        currentDate = tile!.events.first.event.published;

        ensureScrollPosition();
        setEvent(tile!.events.first);
      });
    }
  }

  /// Make [event] the current event and seek to [position]
  void setEvent(TimelineEvent event, [Duration? position]) {
    Future<void> seek() async {
      if (position != null && position != tile!.videoController.currentPos) {
        tile!.videoController.seekTo(position);
      }
    }

    if (currentEvent == event) {
      seek();
    } else {
      currentDate = event.event.published;
      seek();
      ensureScrollPosition(const Duration(milliseconds: 650), Curves.ease);
    }

    if (currentEvent != null) {
      /// Ensure the data source is correct. If the data source is the same
      /// nothing is done.
      tile!.videoController.setDataSource(currentEvent!.videoUrl);
      lastEventIndex = tile!.events.indexOf(currentEvent!);
    }
  }

  StreamSubscription<Duration>? positionSubscription;
  StreamSubscription<bool>? bufferingSubscription;
  bool isBuffering = false;
  Duration _lastPosition = Duration.zero;
  void _tilePositionListener(Duration position) {
    if (mounted) {
      setState(() {
        if (tile!.videoController.currentPos ==
                tile!.videoController.duration &&
            tile!.videoController.duration > Duration.zero) {
          // If it's the last event, return
          if (lastEventIndex == tile!.events.length - 1) {
            return;
          }
          setEvent(tile!.events.elementAt(lastEventIndex + 1));
        } else if (currentEvent != null) {
          currentDate = currentEvent!.startTime.add(
            tile!.videoController.currentPos,
          );
          ensureScrollPosition(position - _lastPosition);

          _lastPosition = position;
        }
      });
    }
  }

  void _updateScreen() {
    if (mounted) setState(() {});
  }

  /// Ensure the scroll position is correct
  Future<void> ensureScrollPosition([
    Duration duration = const Duration(milliseconds: 100),
    Curve curve = Curves.linear,
  ]) async {
    // If the event is null it means that there is no position to scroll to
    //
    // If the user is scrolling, don't scroll to the event
    if (currentEvent == null ||
        isScrolling ||
        !controller.hasClients ||
        scrolledManually) {
      return;
    }
    final eventsFactor =
        eventsBefore.isEmpty
            ? Duration.zero
            : eventsBefore
                .map((event) => event.duration)
                .reduce((a, b) => a + b);

    scrolledManually = true;
    await controller.animateTo(
      // The scroll position is:
      //   + the position of the event
      //   + the position of the events before the current event
      //   + the width of the separators
      eventsFactor.inDoubleSeconds +
          currentEvent!.position(currentDate!).inDoubleSeconds +
          eventsBefore.length * _kEventSeparatorWidth,
      duration:
          duration > Duration.zero
              ? duration
              : const Duration(milliseconds: 100),
      curve: curve,
    );
    scrolledManually = false;
  }

  /// Whether the video was playing when the user started scrolling
  bool wasPlayingOnScroll = false;

  /// Whether the scroll view was scrolled programatically by [ensureScrollPosition]
  bool scrolledManually = false;
  void _onScrollStart(ScrollStartNotification notification) {
    if (scrolledManually) return;

    isScrolling = true;
    wasPlayingOnScroll = widget.timeline.isPlaying;
    if (wasPlayingOnScroll) {
      widget.timeline.play(currentEvent);
    }
  }

  void _onScrollUpdate(ScrollUpdateNotification notification) {
    if (scrolledManually) return;
    // _onScrollEnd(ScrollEndNotification(
    //   context: notification.context!,
    //   metrics: notification.metrics,
    // ));
  }

  void _onScrollEnd(ScrollEndNotification notification) {
    if (scrolledManually) return;

    final scrollPosition = controller.position.pixels;

    for (final event in tile!.events) {
      Duration eventsBeforeDuration() =>
          eventsBefore.map((event) => event.duration).reduce((a, b) => a + b);

      final especulatedStartPosition =
          eventsBefore.isEmpty
              ? 0
              : (eventsBeforeDuration().inSeconds +
                      eventsBefore.length * _kEventSeparatorWidth)
                  .toInt();

      final especulatedEndPosition =
          eventsBefore.isEmpty
              ? event.duration.inSeconds
              : (eventsBeforeDuration().inSeconds +
                  (eventsBefore.length * _kEventSeparatorWidth) +
                  event.duration.inSeconds);

      if (scrollPosition >= especulatedStartPosition &&
          scrollPosition <= especulatedEndPosition) {
        final position = Duration(
          seconds: scrollPosition.toInt() - especulatedStartPosition,
        );
        setEvent(event, position);
        debugPrint(
          'User scrolled to event #${tile!.events.indexOf(event)} at $position',
        );
        break;
      }
    }

    isScrolling = false;
    if (wasPlayingOnScroll) {
      widget.timeline.play(currentEvent);
    }
  }

  /// Enter the fullscreen mode
  Future<void> enterFullscreen(BuildContext context) async {
    assert(currentEvent != null);

    if (tile != null) {
      final isPlaying = widget.timeline.isPlaying;
      if (isPlaying) widget.timeline.stop();
      await Navigator.of(context).pushNamed(
        '/events',
        arguments: {
          'event': currentEvent!.event,
          'upcoming': tile?.events.map((timelineEvent) => timelineEvent.event),
          'videoPlayer': tile?.videoController,
        },
      );
      if (isPlaying) widget.timeline.play(currentEvent);
    }
  }

  @override
  void dispose() {
    tile?.videoController.dispose();
    positionSubscription?.cancel();
    bufferingSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final loc = AppLocalizations.of(context);
    final settings = context.watch<SettingsProvider>();

    final tile = this.tile;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsetsDirectional.all(8.0),
          child: AspectRatio(
            aspectRatio: kHorizontalAspectRatio,
            child: () {
              if (tile == null) {
                return Card(
                  margin: EdgeInsetsDirectional.zero,
                  clipBehavior: Clip.hardEdge,
                  child: InkWell(
                    onTap: () => selectDevice(context),
                    child: const Center(child: Icon(Icons.add, size: 42.0)),
                  ),
                );
              }

              return UnityVideoView(
                heroTag: currentEvent?.videoUrl,
                player: tile.videoController,
                fit:
                    device?.server.additionalSettings.videoFit ??
                    settings.kVideoFit.value,
                paneBuilder:
                    !settings.kShowDebugInfo.value
                        ? null
                        : (context, controller) {
                          return Padding(
                            padding: const EdgeInsetsDirectional.all(8.0),
                            child: Stack(
                              children: [
                                RichText(
                                  text: TextSpan(
                                    style: theme.textTheme.labelMedium
                                        ?.copyWith(
                                          shadows: outlinedText(),
                                          color: Colors.white,
                                        ),
                                    children: [
                                      TextSpan(
                                        text: currentEvent
                                            ?.position(currentDate!)
                                            .humanReadableCompact(context),
                                      ),
                                      const TextSpan(text: '\ndebug: '),
                                      TextSpan(
                                        text: tile.videoController.currentPos
                                            .humanReadableCompact(context),
                                      ),
                                      const TextSpan(text: '\nindex: '),
                                      TextSpan(
                                        text:
                                            currentEvent == null
                                                ? (-1).toString()
                                                : tile.events
                                                    .indexOf(currentEvent!)
                                                    .toString(),
                                      ),
                                      const TextSpan(text: '\nscroll: '),
                                      if (this.controller.hasClients)
                                        TextSpan(
                                          text:
                                              this.controller.position.pixels
                                                  .toString(),
                                        ),
                                      TextSpan(
                                        text:
                                            '\nt: ${tile.videoController.dataSource}',
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
              );
            }(),
          ),
        ),
        Center(
          child: Container(
            margin: const EdgeInsetsDirectional.only(top: 8.0, bottom: 14.0),
            padding: const EdgeInsetsDirectional.symmetric(
              horizontal: 8.0,
              vertical: 4.0,
            ),
            color: theme.colorScheme.secondaryContainer,
            child:
                currentDate == null
                    ? const Text(' ■■■■■ • ■■■■■ ')
                    : Text(
                      '${settings.kDateFormat.value.format(currentDate!)}'
                      ' '
                      '${settings.extendedTimeFormat.format(currentDate!)}',
                      style: theme.textTheme.labelMedium,
                    ),
          ),
        ),
        Container(
          height: 48.0,
          color: theme.colorScheme.secondaryContainer,
          child:
              tile == null
                  ? Center(child: Text(loc.selectACamera))
                  : Stack(
                    children: [
                      Positioned.fill(
                        child: NotificationListener(
                          onNotification: (Notification notification) {
                            if (notification is! ScrollNotification) {
                              return false;
                            }

                            if (notification is ScrollStartNotification) {
                              _onScrollStart(notification);
                            } else if (notification
                                is ScrollUpdateNotification) {
                              _onScrollUpdate(notification);
                            } else if (notification is ScrollEndNotification) {
                              _onScrollEnd(notification);
                              return true;
                            }

                            return false;
                          },
                          child: ListView.separated(
                            controller: controller,
                            padding: const EdgeInsetsDirectional.symmetric(
                              horizontal: 8.0,
                              vertical: 6.0,
                            ),
                            separatorBuilder:
                                (_, __) => const SizedBox(
                                  width: _kEventSeparatorWidth,
                                ),
                            scrollDirection: Axis.horizontal,
                            itemCount: tile.events.length,
                            itemBuilder: (context, index) {
                              final event = tile.events.elementAt(index);

                              return _TimelineTile(
                                key: ValueKey(event.event.id),
                                event: event,
                                index: index,
                                isCurrentEvent: event == currentEvent,
                                onPressed: () => setEvent(event),
                                tile: tile,
                              );
                            },
                          ),
                        ),
                      ),
                      PositionedDirectional(
                        start: 8.0,
                        top: 0,
                        bottom: 0,
                        child: Container(
                          width: 3,
                          color: theme.colorScheme.onInverseSurface,
                        ),
                      ),
                    ],
                  ),
        ),
        const SizedBox(height: 14.0),
        Row(
          children: [
            Expanded(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  if (tile != null) ...[
                    const Spacer(),
                    Container(
                      margin: const EdgeInsetsDirectional.only(start: 8.0),
                      padding: const EdgeInsetsDirectional.symmetric(
                        horizontal: 6.0,
                        vertical: 4.0,
                      ),
                      color: theme.colorScheme.secondaryContainer,
                      child: Text(
                        loc.nEvents(tile.events.length),
                        style: theme.textTheme.labelSmall,
                      ),
                    ),
                    const Spacer(),
                  ],
                  SquaredIconButton(
                    icon: const Icon(Icons.fullscreen),
                    tooltip:
                        currentEvent == null ? null : loc.showFullscreenCamera,
                    onPressed:
                        currentEvent == null
                            ? null
                            : () => enterFullscreen(context),
                  ),
                ],
              ),
            ),
            SquaredIconButton(
              icon: const Icon(Icons.skip_previous),
              tooltip: isFirstEvent ? null : loc.previous,
              onPressed:
                  isFirstEvent
                      ? null
                      : () {
                        setEvent(tile!.events.elementAt(lastEventIndex - 1));
                      },
            ),
            const SizedBox(width: 6.0),
            IconButton.filled(
              icon: PlayPauseIcon(
                isPlaying: tile?.videoController.isPlaying ?? false,
                color: theme.colorScheme.surface,
              ),
              tooltip:
                  tile == null
                      ? null
                      : tile.videoController.isPlaying
                      ? loc.pause
                      : loc.play,
              iconSize: 32,
              onPressed:
                  tile == null
                      ? null
                      : () {
                        setState(() {
                          if (widget.timeline.isPlaying) {
                            widget.timeline.stop();
                          } else {
                            widget.timeline.play(currentEvent);
                          }
                        });
                      },
            ),
            const SizedBox(width: 6.0),
            SquaredIconButton(
              icon: const Icon(Icons.skip_next),
              tooltip: isLastEvent ? null : loc.next,
              onPressed:
                  isLastEvent
                      ? null
                      : () {
                        setEvent(tile!.events.elementAt(lastEventIndex + 1));
                      },
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsetsDirectional.only(end: 12.0),
                child: Row(
                  children: [
                    SquaredIconButton(
                      icon: const Icon(Icons.event),
                      tooltip: loc.timeFilter,
                      onPressed: () async {
                        final result = await showDatePicker(
                          context: context,
                          initialDate: widget.timeline.currentDate,
                          firstDate: DateTime.utc(1970),
                          lastDate: DateTimeExtension.now(),
                          initialEntryMode: DatePickerEntryMode.calendarOnly,
                        );
                        if (result != null) {
                          widget.onDateChanged(result);
                        }
                      },
                    ),
                    const Spacer(),
                    if (tile != null &&
                        (isBuffering ||
                            tile.videoController.currentPos ==
                                tile.videoController.duration ||
                            tile.videoController.currentBuffer ==
                                Duration.zero ||
                            widget.timeline.pausedToBuffer.isNotEmpty))
                      const SizedBox(
                        width: 24.0,
                        height: 24.0,
                        child: CircularProgressIndicator.adaptive(
                          strokeWidth: 2.5,
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
        const Spacer(),
        Padding(
          padding: const EdgeInsetsDirectional.all(8.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              if (Scaffold.hasDrawer(context))
                _buildIconButton(
                  icon: const DrawerButtonIcon(),
                  text: MaterialLocalizations.of(context).moreButtonTooltip,
                  onPressed: () => Scaffold.of(context).openDrawer(),
                ),
              _buildIconButton(
                icon: const Icon(Icons.refresh),
                text: loc.refresh,
                onPressed: () {
                  eventsPlaybackScreenKey.currentState?.fetch();
                },
              ),
              if (tile != null) ...[
                _buildIconButton(
                  icon: const Icon(Icons.cameraswitch),
                  text: loc.switchCamera,
                  onPressed: () {
                    selectDevice(context);
                  },
                ),
                Builder(
                  builder: (context) {
                    final downloads = context.watch<DownloadsManager>();
                    final event = currentEvent?.event;

                    final isDownloaded =
                        event == null
                            ? false
                            : downloads.isEventDownloaded(event.id);
                    final isDownloading =
                        event == null
                            ? false
                            : downloads.isEventDownloading(event.id);

                    return _buildIconButton(
                      icon:
                          isDownloaded
                              ? Icon(
                                Icons.download_done,
                                color:
                                    theme
                                        .extension<UnityColors>()!
                                        .successColor,
                              )
                              : isDownloading
                              ? DownloadProgressIndicator(
                                progress:
                                    downloads
                                        .downloading[downloads.downloading.keys
                                            .firstWhere(
                                              (e) => e.id == event.id,
                                            )]!
                                        .$1,
                              )
                              : const Icon(Icons.download),
                      text:
                          isDownloaded
                              ? loc.downloaded
                              : isDownloading
                              ? loc.downloading
                              : loc.download,
                      onPressed:
                          event == null
                              ? null
                              : () {
                                if (isDownloaded || isDownloading) {
                                  context.read<HomeProvider>().toDownloads(
                                    event.id,
                                    context,
                                  );
                                } else {
                                  downloads.download(event);
                                }
                              },
                    );
                  },
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildIconButton({
    required Widget icon,
    String? text,
    VoidCallback? onPressed,
  }) {
    return Material(
      child: InkWell(
        borderRadius: BorderRadius.circular(10.0),
        onTap: onPressed,
        child: Padding(
          padding: const EdgeInsetsDirectional.all(8.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(height: 38.0, width: 38.0, child: icon),
              if (text != null) Text(text),
            ],
          ),
        ),
      ),
    );
  }
}

class _TimelineTile extends StatelessWidget {
  const _TimelineTile({
    super.key,
    required this.event,
    required this.isCurrentEvent,
    required this.tile,
    required this.onPressed,
    required this.index,
  });

  final TimelineEvent event;
  final bool isCurrentEvent;
  final TimelineTile tile;
  final VoidCallback onPressed;
  final int index;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return GestureDetector(
      onTap: onPressed,
      child: SizedBox(
        width: event.duration.inDoubleSeconds,
        child: Stack(
          alignment: AlignmentDirectional.centerStart,
          children: [
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  color: theme.colorScheme.onSecondaryContainer,
                  borderRadius: BorderRadius.circular(25.0),
                ),
              ),
            ),
            if (isCurrentEvent &&
                tile.videoController.dataSource == event.videoUrl)
              Positioned.fill(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(25.0),
                  child: Align(
                    alignment: AlignmentDirectional.centerStart,
                    child: Container(
                      width: tile.videoController.currentBuffer.inDoubleSeconds,
                      color: theme.colorScheme.tertiary,
                      padding: const EdgeInsetsDirectional.symmetric(
                        horizontal: 12.0,
                      ),
                      alignment: AlignmentDirectional.centerStart,
                    ),
                  ),
                ),
              ),
            Padding(
              padding: const EdgeInsetsDirectional.symmetric(horizontal: 12.0),
              child: Row(
                children: [
                  Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: theme.colorScheme.tertiaryContainer,
                    ),
                    padding: const EdgeInsetsDirectional.all(5.5),
                    margin: const EdgeInsetsDirectional.only(end: 4.0),
                    child: Text(
                      '${index + 1}',
                      style: TextStyle(
                        fontSize: 11.0,
                        fontWeight: FontWeight.w500,
                        color: theme.colorScheme.onTertiaryContainer,
                      ),
                    ),
                  ),
                  Icon(() {
                    switch (event.event.type) {
                      case EventType.motion:
                        return Icons.directions_run;
                      case EventType.continuous:
                        return Icons.horizontal_rule;
                      default:
                        return Icons.event_note;
                    }
                  }(), color: theme.colorScheme.surface),
                  const SizedBox(width: 4.0),
                  Expanded(
                    child: Text(
                      event.event.type.locale(context),
                      style: theme.textTheme.labelLarge?.copyWith(
                        color: theme.colorScheme.surface,
                      ),
                      maxLines: 1,
                    ),
                  ),
                  const SizedBox(width: 6.0),
                  Icon(
                    Icons.timer,
                    size: 16.0,
                    color: theme.colorScheme.surface,
                  ),
                  const SizedBox(width: 4.0),
                  Text(
                    event.event.duration.humanReadableCompact(context),
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.surface,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
