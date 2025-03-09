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

import 'dart:io';

import 'package:bluecherry_client/models/event.dart';
import 'package:bluecherry_client/providers/downloads_provider.dart';
import 'package:bluecherry_client/providers/settings_provider.dart';
import 'package:bluecherry_client/screens/downloads/downloads_manager.dart';
import 'package:bluecherry_client/screens/downloads/indicators.dart';
import 'package:bluecherry_client/utils/date.dart';
import 'package:bluecherry_client/utils/extensions.dart';
import 'package:bluecherry_client/utils/methods.dart';
import 'package:bluecherry_client/utils/theme.dart';
import 'package:bluecherry_client/utils/window.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:provider/provider.dart';

class DownloadTile extends StatefulWidget {
  const DownloadTile({
    super.key,
    required this.size,
    required this.event,
    this.upcomingEvents = const [],
    this.progress = 1.0,
    this.downloadPath,
    this.initiallyExpanded = true,
  });

  final Size size;
  final Event event;
  final Iterable<Event> upcomingEvents;
  final double progress;
  final String? downloadPath;
  final bool initiallyExpanded;

  static const _breakpoint = 500.0;

  @override
  State<DownloadTile> createState() => _DownloadTileState();
}

class _DownloadTileState extends State<DownloadTile> {
  /// Whether the event is fully downloaded
  bool get isDownloaded =>
      widget.progress == 1.0 && widget.downloadPath != null;

  @override
  void initState() {
    super.initState();
    if (widget.initiallyExpanded) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!context.mounted) return;
        Scrollable.ensureVisible(context);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final loc = AppLocalizations.of(context);
    final settings = context.watch<SettingsProvider>();

    final eventType = widget.event.type.locale(context).uppercaseFirst;
    final at = settings.formatRawDateAndTime(widget.event.publishedRaw);

    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(8.0),
    );

    return Padding(
      padding: const EdgeInsetsDirectional.only(
        start: kDownloadsManagerPadding,
        end: kDownloadsManagerPadding,
        bottom: kDownloadsManagerPadding / 2,
      ),
      child: ClipPath.shape(
        shape: shape,
        child: Card(
          margin: EdgeInsetsDirectional.zero,
          shape: shape,
          child: ExpansionTile(
            clipBehavior: Clip.hardEdge,
            shape: shape,
            collapsedShape: shape,
            initiallyExpanded: widget.initiallyExpanded,
            title: Row(
              children: [
                SizedBox(
                  width: 40.0,
                  height: 40.0,
                  child: () {
                    if (isDownloaded) {
                      return Padding(
                        padding: const EdgeInsetsDirectional.only(end: 12.0),
                        child: Icon(
                          Icons.download_done,
                          color: theme.extension<UnityColors>()!.successColor,
                        ),
                      );
                    }

                    return DownloadProgressIndicator(progress: widget.progress);
                  }(),
                ),
                Expanded(
                  child: Text(
                    loc.downloadTitle(
                      eventType,
                      widget.event.deviceName,
                      widget.event.server.name,
                      at,
                    ),
                  ),
                ),
              ],
            ),
            childrenPadding: const EdgeInsetsDirectional.symmetric(
              vertical: 12.0,
              horizontal: 16.0,
            ),
            expandedCrossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: double.infinity,
                child: Flex(
                  direction:
                      widget.size.width >= DownloadTile._breakpoint
                          ? Axis.horizontal
                          : Axis.vertical,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    wrapExpandedIf(
                      widget.size.width >= DownloadTile._breakpoint,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          DefaultTextStyle.merge(
                            style: const TextStyle(fontWeight: FontWeight.bold),
                            maxLines: 1,
                            overflow: TextOverflow.fade,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(loc.eventType),
                                Text(loc.device),
                                Text(loc.server),
                                Text(loc.duration),
                                Text(loc.date),
                              ],
                            ),
                          ),
                          const SizedBox(width: 6.0),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(eventType),
                                Text(widget.event.deviceName),
                                Text(widget.event.server.name),
                                Text(() {
                                  var fileSize = '';
                                  if (isDownloaded) {
                                    final size =
                                        File(widget.downloadPath!).mbSize;
                                    fileSize =
                                        ' (${size.toStringAsFixed(2)} MB)';
                                  }

                                  return widget.event.duration.humanReadable(
                                        context,
                                      ) +
                                      fileSize;
                                }()),
                                Text(at),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12.0),
                    Center(
                      child: Flex(
                        direction:
                            widget.size.width >= DownloadTile._breakpoint
                                ? Axis.vertical
                                : Axis.horizontal,
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          wrapTooltipIf(
                            isDownloaded &&
                                widget.size.width < DownloadTile._breakpoint,
                            preferBelow: false,
                            message: loc.play,
                            child: TextButton(
                              onPressed:
                                  isDownloaded
                                      ? () {
                                        Navigator.of(context).pushNamed(
                                          '/events',
                                          arguments: {
                                            'event': widget.event,
                                            'upcoming': widget.upcomingEvents,
                                          },
                                        );
                                      }
                                      : null,
                              child: Row(
                                children: [
                                  const Icon(Icons.play_arrow, size: 20.0),
                                  if (widget.size.width >=
                                      DownloadTile._breakpoint) ...[
                                    const SizedBox(width: 8.0),
                                    Text(loc.play),
                                  ],
                                ],
                              ),
                            ),
                          ),
                          if (isDownloaded)
                            TextButton.icon(
                              onPressed: () {
                                context.read<DownloadsManager>().delete(
                                  widget.downloadPath!,
                                );
                              },
                              icon: const Icon(Icons.delete, size: 20.0),
                              label: Text(loc.delete),
                            )
                          else
                            TextButton.icon(
                              onPressed: () {
                                context
                                    .read<DownloadsManager>()
                                    .cancelEventDownload(widget.event);
                              },
                              icon: const Icon(Icons.cancel, size: 20.0),
                              label: Text(loc.cancel),
                            ),
                          if (isDesktop)
                            TextButton.icon(
                              onPressed:
                                  isDownloaded
                                      ? () {
                                        launchFileExplorer(
                                          File(
                                            widget.downloadPath!,
                                          ).parent.path,
                                        );
                                      }
                                      : null,
                              icon: const Icon(Icons.folder, size: 20.0),
                              label: Text(loc.showInFiles),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
