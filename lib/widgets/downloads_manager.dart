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
import 'package:bluecherry_client/providers/home_provider.dart';
import 'package:bluecherry_client/providers/settings_provider.dart';
import 'package:bluecherry_client/utils/extensions.dart';
import 'package:bluecherry_client/utils/methods.dart';
import 'package:bluecherry_client/utils/theme.dart';
import 'package:bluecherry_client/utils/window.dart';
import 'package:bluecherry_client/widgets/misc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:provider/provider.dart';

const _kDownloadsManagerPadding = 14.0;

class DownloadsManagerScreen extends StatelessWidget {
  final int? initiallyExpandedEventId;

  const DownloadsManagerScreen({super.key, this.initiallyExpandedEventId});

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final downloads = context.watch<DownloadsManager>();

    return Column(children: [
      showIf(
            Scaffold.hasDrawer(context),
            child: AppBar(
              leading: MaybeUnityDrawerButton(context),
              title: Text(loc.downloads),
            ),
          ) ??
          const SizedBox.shrink(),
      Expanded(
        child: LayoutBuilder(builder: (context, consts) {
          if (downloads.isEmpty) {
            return Center(
              child: Text(loc.noDownloads),
            );
          }

          final size = consts.biggest;
          return CustomScrollView(
            slivers: [
              SliverPadding(
                padding: const EdgeInsetsDirectional.only(
                  top: _kDownloadsManagerPadding / 2,
                  bottom: _kDownloadsManagerPadding / 2,
                ),
                sliver: SliverList.builder(
                  itemCount: downloads.downloading.length,
                  itemBuilder: (context, index) {
                    final entry =
                        downloads.downloading.entries.elementAt(index);
                    final event = entry.key;
                    final progress = entry.value;

                    return DownloadTile(
                      key: ValueKey(event.id),
                      event: event,
                      upcomingEvents: downloads.downloadedEvents
                          .map((e) => e.event)
                          .toList(),
                      size: size,
                      progress: progress,
                      initiallyExpanded: initiallyExpandedEventId == event.id,
                    );
                  },
                ),
              ),
              SliverList.builder(
                itemCount: downloads.downloadedEvents.length,
                itemBuilder: (context, index) {
                  final de = downloads.downloadedEvents[index];

                  return DownloadTile(
                    key: ValueKey(de.event.id),
                    event: de.event,
                    upcomingEvents:
                        downloads.downloadedEvents.map((e) => e.event).toList(),
                    size: size,
                    downloadPath: de.downloadPath,
                    initiallyExpanded: initiallyExpandedEventId == de.event.id,
                  );
                },
              ),
            ],
          );
        }),
      ),
    ]);
  }
}

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
  final List<Event> upcomingEvents;
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
        if (!mounted) return;

        Scrollable.ensureVisible(context);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final loc = AppLocalizations.of(context);
    final settings = context.watch<SettingsProvider>();

    final eventType = widget.event.type.locale(context).uppercaseFirst();
    final at = settings.formatDate(widget.event.published);

    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(8.0),
    );

    return Padding(
      padding: const EdgeInsetsDirectional.only(
        start: _kDownloadsManagerPadding,
        end: _kDownloadsManagerPadding,
        bottom: _kDownloadsManagerPadding / 2,
      ),
      child: ClipPath.shape(
        shape: shape,
        child: Card(
          margin: EdgeInsets.zero,
          shape: shape,
          child: ExpansionTile(
            clipBehavior: Clip.hardEdge,
            shape: shape,
            collapsedShape: shape,
            initiallyExpanded: widget.initiallyExpanded,
            title: Row(children: [
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
            ]),
            childrenPadding: const EdgeInsets.symmetric(
              vertical: 12.0,
              horizontal: 16.0,
            ),
            expandedCrossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: double.infinity,
                child: Flex(
                  direction: widget.size.width >= DownloadTile._breakpoint
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
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                            ),
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
                                Text(widget.event.duration
                                    .humanReadable(context)),
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
                        direction: widget.size.width >= DownloadTile._breakpoint
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
                              onPressed: isDownloaded
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
                              child: Row(children: [
                                const Icon(Icons.play_arrow, size: 20.0),
                                if (widget.size.width >=
                                    DownloadTile._breakpoint) ...[
                                  const SizedBox(width: 8.0),
                                  Text(loc.play),
                                ],
                              ]),
                            ),
                          ),
                          TextButton(
                            onPressed: isDownloaded
                                ? () {
                                    context
                                        .read<DownloadsManager>()
                                        .delete(widget.downloadPath!);
                                  }
                                : null,
                            child: Row(children: [
                              const Icon(Icons.delete, size: 20.0),
                              const SizedBox(width: 8.0),
                              Text(loc.delete),
                            ]),
                          ),
                          if (isDesktop)
                            TextButton(
                              onPressed: isDownloaded
                                  ? () {
                                      launchFileExplorer(
                                        File(widget.downloadPath!).parent.path,
                                      );
                                    }
                                  : null,
                              child: Row(children: [
                                const Icon(Icons.folder, size: 20.0),
                                const SizedBox(width: 8.0),
                                Text(loc.showInFiles), // show in explorer
                              ]),
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

class DownloadProgressIndicator extends StatelessWidget {
  const DownloadProgressIndicator({
    super.key,
    required this.progress,
  });

  final DownloadProgress progress;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Stack(children: [
      Padding(
        padding: const EdgeInsets.all(8.0),
        child: CircularProgressIndicator(
          value: progress,
          strokeWidth: 2.0,
        ),
      ),
      Center(
        child: Icon(
          Icons.download,
          size: 14.0,
          color: theme.colorScheme.primary,
        ),
      ),
    ]);
  }
}

/// The download indicator for the given event
///
/// See also:
///  * [EventsScreenDesktop], which uses this to display the download status
class DownloadIndicator extends StatelessWidget {
  final Event event;

  const DownloadIndicator({super.key, required this.event});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final loc = AppLocalizations.of(context);

    return SizedBox(
      height: 40.0,
      width: 40.0,
      child: () {
        if (event.isAlarm) {
          return Icon(
            Icons.warning,
            color: theme.extension<UnityColors>()!.warningColor,
          );
        }

        final downloads = context.watch<DownloadsManager>();

        if (downloads.isEventDownloaded(event.id)) {
          return IconButton(
            onPressed: () {
              context.read<HomeProvider>().toDownloads(event.id, context);
            },
            tooltip: loc.seeInDownloads,
            icon: Icon(
              Icons.download_done,
              color: theme.extension<UnityColors>()!.successColor,
            ),
          );
        }

        if (downloads.isEventDownloading(event.id)) {
          return DownloadProgressIndicator(
            progress: downloads.downloading[downloads.downloading.keys
                .firstWhere((e) => e.id == event.id)]!,
          );
        }

        if (event.mediaURL != null) {
          return IconButton(
            padding: EdgeInsets.zero,
            tooltip: loc.download,
            onPressed: () => downloads.download(event),
            icon: const Icon(Icons.download),
          );
        }
      }(),
    );
  }
}
