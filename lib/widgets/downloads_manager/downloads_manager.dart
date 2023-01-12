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
import 'package:bluecherry_client/providers/settings_provider.dart';
import 'package:bluecherry_client/utils/extensions.dart';
import 'package:bluecherry_client/utils/window.dart';
import 'package:bluecherry_client/widgets/misc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:provider/provider.dart';

class DownloadsManagerScreen extends StatelessWidget {
  const DownloadsManagerScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final downloads = context.watch<DownloadsManager>();
    return Scaffold(
      body: LayoutBuilder(builder: (context, consts) {
        final size = consts.biggest;
        return CustomScrollView(
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.only(top: 8.0),
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

    return Padding(
      padding: const EdgeInsets.only(left: 8.0, right: 8.0, bottom: 8.0),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8.0),
        child: Material(
          child: ExpansionTile(
            shape: Border.all(style: BorderStyle.none),
            title: Row(children: [
              SizedBox(
                width: 40.0,
                height: 40.0,
                child: () {
                  if (isDownloaded) {
                    return const Padding(
                      padding: EdgeInsets.only(right: 12.0),
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
                    Expanded(
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          DefaultTextStyle(
                            style: const TextStyle(fontWeight: FontWeight.bold),
                            maxLines: 1,
                            overflow: TextOverflow.fade,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('Event type'),
                                Text(loc.device),
                                Text(loc.server),
                                Text(loc.duration),
                                Text(loc.date),
                              ],
                            ),
                          ),
                          const SizedBox(width: 6.0),
                          Expanded(
                            child: DefaultTextStyle(
                              style: const TextStyle(),
                              // maxLines: 1,
                              // overflow: TextOverflow.ellipsis,
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
                          if (isDownloaded)
                            Tooltip(
                              preferBelow: false,
                              message: loc.play,
                              child: TextButton(
                                child: Row(
                                  children: [
                                    const Icon(Icons.play_arrow, size: 20.0),
                                    if (size.width >= _breakpoint) ...[
                                      const SizedBox(width: 8.0),
                                      Text(loc.play),
                                    ],
                                  ],
                                ),
                                onPressed: () {
                                  launchFileExplorer(downloadPath!);
                                },
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
