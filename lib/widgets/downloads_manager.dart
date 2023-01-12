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
import 'package:bluecherry_client/providers/downloads.dart';
import 'package:bluecherry_client/providers/home_provider.dart';
import 'package:bluecherry_client/providers/settings_provider.dart';
import 'package:bluecherry_client/utils/extensions.dart';
import 'package:bluecherry_client/utils/methods.dart';
import 'package:bluecherry_client/utils/window.dart';
import 'package:bluecherry_client/widgets/misc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:provider/provider.dart';

const _kDownloadsManagerPadding = 14.0;

class DownloadsManagerScreen extends StatelessWidget {
  const DownloadsManagerScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final downloads = context.watch<DownloadsManager>();
    return Scaffold(
      appBar: showIf(
        isMobile,
        child: AppBar(
          leading: Scaffold.of(context).hasDrawer
              ? IconButton(
                  icon: const Icon(Icons.menu),
                  splashRadius: 20.0,
                  onPressed: Scaffold.of(context).openDrawer,
                )
              : null,
          title: Text(AppLocalizations.of(context).downloads),
        ),
      ),
      body: LayoutBuilder(builder: (context, consts) {
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
                  final entry = downloads.downloading.entries.elementAt(index);
                  final event = entry.key;
                  final progress = entry.value;

                  return DownloadTile(
                    key: ValueKey(event.id),
                    event: event,
                    size: size,
                    progress: progress,
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
                  size: size,
                  downloadPath: de.downloadPath,
                );
              },
            ),
          ],
        );
      }),
    );
  }
}

class DownloadTile extends StatelessWidget {
  const DownloadTile({
    Key? key,
    required this.event,
    required this.size,
    this.progress = 1.0,
    this.downloadPath,
  }) : super(key: key);

  final Size size;
  final Event event;
  final double progress;
  final String? downloadPath;

  /// Whether the event is fully downloaded
  bool get isDownloaded => progress == 1.0 && downloadPath != null;

  static const _breakpoint = 500.0;

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);

    final parsedCategory = event.category?.split('/');
    final eventType = (parsedCategory?.last ?? '').uppercaseFirst();
    final at = SettingsProvider.instance.dateFormat.format(event.published);

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
            title: Row(children: [
              SizedBox(
                width: 40.0,
                height: 40.0,
                child: () {
                  if (isDownloaded) {
                    return const Padding(
                      padding: EdgeInsetsDirectional.only(end: 12.0),
                      child: Icon(
                        Icons.download_done,
                        color: Colors.green,
                      ),
                    );
                  }

                  return DownloadProgressIndicator(progress: progress);
                }(),
              ),
              Expanded(
                child: Text(
                  loc.downloadTitle(
                    eventType,
                    event.deviceName,
                    event.server.name,
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
                  direction: size.width >= _breakpoint
                      ? Axis.horizontal
                      : Axis.vertical,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    wrapExpandedIf(
                      size.width >= _breakpoint,
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
                                Text(event.deviceName),
                                Text(event.server.name),
                                Text(event.mediaDuration
                                        ?.humanReadable(context) ??
                                    '--'),
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
                        direction: size.width >= _breakpoint
                            ? Axis.vertical
                            : Axis.horizontal,
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          wrapTooltipIf(
                            isDownloaded && size.width < _breakpoint,
                            preferBelow: false,
                            message: loc.play,
                            child: TextButton(
                              onPressed: isDownloaded
                                  ? () {
                                      Navigator.of(context).pushNamed(
                                        '/events',
                                        arguments: event,
                                      );
                                    }
                                  : null,
                              child: Row(
                                children: [
                                  const Icon(Icons.play_arrow, size: 20.0),
                                  if (size.width >= _breakpoint) ...[
                                    const SizedBox(width: 8.0),
                                    Text(loc.play),
                                  ],
                                ],
                              ),
                            ),
                          ),
                          TextButton(
                            onPressed: isDownloaded
                                ? () {
                                    context
                                        .read<DownloadsManager>()
                                        .delete(downloadPath!);
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
                                        File(downloadPath!).parent.path,
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
    Key? key,
    required this.progress,
  }) : super(key: key);

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

  const DownloadIndicator({
    Key? key,
    required this.event,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 40.0,
      width: 40.0,
      child: () {
        if (event.isAlarm) {
          return const Icon(
            Icons.warning,
            color: Colors.amber,
          );
        }

        final downloads = context.watch<DownloadsManager>();

        if (downloads.isEventDownloaded(event.id)) {
          return IconButton(
            onPressed: () {
              context.read<HomeProvider>().setTab(UnityTab.downloads.index);
            },
            tooltip: AppLocalizations.of(context).seeInDownloads,
            icon: const Icon(
              Icons.download_done,
              color: Colors.green,
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
            tooltip: AppLocalizations.of(context).download,
            onPressed: () => downloads.download(event),
            icon: const Icon(Icons.download),
          );
        }
      }(),
    );
  }
}
