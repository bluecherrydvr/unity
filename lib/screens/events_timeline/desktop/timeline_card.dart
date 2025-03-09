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
import 'package:bluecherry_client/providers/downloads_provider.dart';
import 'package:bluecherry_client/providers/settings_provider.dart';
import 'package:bluecherry_client/screens/downloads/indicators.dart';
import 'package:bluecherry_client/screens/events_timeline/desktop/timeline.dart';
import 'package:bluecherry_client/screens/layouts/desktop/multicast_view.dart';
import 'package:bluecherry_client/screens/layouts/video_status_label.dart';
import 'package:bluecherry_client/utils/extensions.dart';
import 'package:bluecherry_client/widgets/hover_button.dart';
import 'package:bluecherry_client/widgets/misc.dart';
import 'package:bluecherry_client/widgets/squared_icon_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:provider/provider.dart';
import 'package:unity_video_player/unity_video_player.dart';

class TimelineCard extends StatefulWidget {
  const TimelineCard({super.key, required this.tile, required this.timeline});

  final Timeline timeline;
  final TimelineTile tile;

  @override
  State<TimelineCard> createState() => _TimelineCardState();
}

class _TimelineCardState extends State<TimelineCard> {
  UnityVideoFit? _fit;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final loc = AppLocalizations.of(context);
    final settings = context.watch<SettingsProvider>();
    final downloadsManager = context.watch<DownloadsManager>();

    final device = widget.tile.device;
    final events = widget.tile.events;

    final currentEvent = events.firstWhereOrNull((event) {
      return event.isPlaying(widget.timeline.currentDate);
    });

    return Card(
      key: ValueKey(device),
      clipBehavior: Clip.antiAliasWithSaveLayer,
      color: Colors.transparent,
      surfaceTintColor: Colors.transparent,
      child: UnityVideoView(
        // heroTag: device.streamURL,
        player: widget.tile.videoController,
        color: Colors.transparent,
        fit:
            _fit ??
            device.server.additionalSettings.videoFit ??
            settings.kVideoFit.value,
        // videoBuilder: (context, video) {
        //   return AspectRatio(
        //     aspectRatio: 16 / 9,
        //     child: video,
        //   );
        // },
        paneBuilder: (context, controller) {
          if (currentEvent == null) {
            return RepaintBoundary(
              child: Material(
                type: MaterialType.card,
                color: theme.colorScheme.surface,
                surfaceTintColor: theme.colorScheme.surfaceTint,
                elevation: 1.0,
                child: Padding(
                  padding: const EdgeInsetsDirectional.all(16.0),
                  child: Column(
                    children: [
                      Text(device.name, style: theme.textTheme.titleMedium),
                      Expanded(
                        child: Center(
                          child: AutoSizeText(
                            loc.noRecords,
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }

          final isDownloaded = downloadsManager.isEventDownloaded(
            currentEvent.event.id,
          );
          final isDownloading = downloadsManager.isEventDownloading(
            currentEvent.event.id,
          );

          final video = UnityVideoView.of(context);

          const paddingSize = 12.0;

          return HoverButton(
            forceEnabled: true,
            builder:
                (_, states) => Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Padding(
                      padding: const EdgeInsetsDirectional.all(paddingSize),
                      child: RichText(
                        text: TextSpan(
                          text: '',
                          style: theme.textTheme.labelLarge!.copyWith(
                            color: Colors.white,
                            shadows: outlinedText(strokeWidth: 0.75),
                          ),
                          children: [
                            TextSpan(
                              text: device.name,
                              style: theme.textTheme.titleMedium!.copyWith(
                                color: Colors.white,
                                shadows: outlinedText(strokeWidth: 0.75),
                              ),
                            ),
                            const TextSpan(text: '\n'),
                            if (states.isHovering)
                              TextSpan(
                                text:
                                    settings.kShowDebugInfo.value
                                        ? currentEvent
                                            .position(
                                              widget.timeline.currentDate,
                                            )
                                            .toString()
                                        : currentEvent
                                            .position(
                                              widget.timeline.currentDate,
                                            )
                                            .humanReadableCompact(context),
                              ),
                            if (settings.kShowDebugInfo.value) ...[
                              const TextSpan(text: '\ndebug: '),
                              TextSpan(text: controller.currentPos.toString()),
                              TextSpan(
                                text:
                                    '\ndiff: ${currentEvent.position(widget.timeline.currentDate) - controller.currentPos}',
                              ),
                              TextSpan(
                                text:
                                    '\nindex: ${events.indexOf(currentEvent)}',
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                    if (settings.kShowDebugInfo.value)
                      Positioned(
                        top: 36.0,
                        right: paddingSize,
                        child: Text(
                          'buffer: '
                          '${(widget.tile.videoController.currentBuffer.inMilliseconds / widget.tile.videoController.duration.inMilliseconds).toStringAsPrecision(2)}'
                          '\n${widget.tile.videoController.currentBuffer.humanReadableCompact(context)}',
                          style: theme.textTheme.labelLarge!.copyWith(
                            color: Colors.white,
                            shadows: outlinedText(strokeWidth: 0.75),
                          ),
                          textAlign: TextAlign.end,
                        ),
                      ),
                    const Positioned.fill(child: MulticastViewport()),
                    PositionedDirectional(
                      end: paddingSize,
                      top: paddingSize,
                      height: 24.0,
                      width: 24.0,
                      child: () {
                        if (controller.isBuffering) {
                          return const CircularProgressIndicator.adaptive(
                            strokeWidth: 1.5,
                          );
                        }
                        if (isDownloaded ||
                            isDownloading ||
                            states.isHovering) {
                          DownloadIndicator(
                            event: currentEvent.event,
                            highlight: true,
                            small: true,
                          );
                        }
                        return const SizedBox.shrink();
                      }(),
                    ),
                    if (states.isHovering)
                      Container(
                        margin: const EdgeInsetsDirectional.all(paddingSize),
                        alignment: AlignmentDirectional.bottomStart,
                        child: RichText(
                          text: TextSpan(
                            style: theme.textTheme.labelLarge!.copyWith(
                              color: Colors.white,
                              shadows: outlinedText(strokeWidth: 0.75),
                            ),
                            children: [
                              TextSpan(text: '${loc.duration}: '),
                              TextSpan(
                                text: currentEvent.duration
                                    .humanReadableCompact(context),
                              ),
                              const TextSpan(text: '\n'),
                              TextSpan(text: '${loc.eventType}: '),
                              TextSpan(
                                text: currentEvent.event.type.locale(context),
                              ),
                            ],
                          ),
                        ),
                      ),
                    Container(
                      margin: const EdgeInsetsDirectional.all(paddingSize),
                      alignment: AlignmentDirectional.bottomEnd,
                      child: SizedBox(
                        height: 24.0,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            if (states.isHovering) ...[
                              CameraViewFitButton(
                                fit:
                                    _fit ??
                                    device.server.additionalSettings.videoFit ??
                                    settings.kVideoFit.value,
                                onChanged: (fit) => setState(() => _fit = fit),
                              ),
                              SquaredIconButton(
                                tooltip: loc.showFullscreenCamera,
                                onPressed: () async {
                                  final isPlaying = widget.timeline.isPlaying;
                                  if (isPlaying) widget.timeline.stop();

                                  await Navigator.of(context).pushNamed(
                                    '/events',
                                    arguments: {
                                      'event': currentEvent.event,
                                      // Do not pass the video controller to the fullscreen
                                      // view because we don't want to desync the video
                                      // from the Timeline. https://github.com/bluecherrydvr/unity/issues/306
                                      // 'videoPlayer': widget.tile.videoController,
                                    },
                                  );

                                  if (isPlaying) widget.timeline.play();
                                },
                                icon: Icon(
                                  Icons.fullscreen,
                                  color: Colors.white,
                                  shadows: outlinedText(),
                                ),
                              ),
                            ],
                            VideoStatusLabel(
                              video: video,
                              device: widget.tile.device,
                              event: currentEvent.event,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
          );
        },
      ),
    );
  }
}
