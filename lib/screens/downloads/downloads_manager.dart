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

import 'package:bluecherry_client/l10n/generated/app_localizations.dart';
import 'package:bluecherry_client/providers/downloads_provider.dart';
import 'package:bluecherry_client/providers/home_provider.dart';
import 'package:bluecherry_client/screens/downloads/download_tile.dart';
import 'package:bluecherry_client/widgets/drawer_button.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

const kDownloadsManagerPadding = 14.0;

class DownloadsManagerScreen extends StatelessWidget {
  final int? initiallyExpandedEventId;

  const DownloadsManagerScreen({super.key, this.initiallyExpandedEventId});

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final downloads = context.watch<DownloadsManager>();

    return Column(
      children: [
        if (Scaffold.hasDrawer(context))
          AppBar(
            leading: MaybeUnityDrawerButton(context),
            title: Text(loc.downloads),
          )
        else
          const SafeArea(child: SizedBox.shrink()),
        Expanded(
          child: LayoutBuilder(
            builder: (context, consts) {
              if (downloads.isEmpty) return const _NoDownloads();

              final size = consts.biggest;
              return CustomScrollView(
                slivers: [
                  SliverPadding(
                    padding: const EdgeInsetsDirectional.only(
                      top: kDownloadsManagerPadding / 2,
                      bottom: kDownloadsManagerPadding / 2,
                    ),
                    sliver: SliverList.builder(
                      itemCount: downloads.downloading.length,
                      itemBuilder: (context, index) {
                        final entry = downloads.downloading.entries.elementAt(
                          index,
                        );
                        final event = entry.key;
                        final (progress, _) = entry.value;

                        return DownloadTile(
                          key: ValueKey(event.id),
                          event: event,
                          upcomingEvents:
                              downloads.downloadedEvents
                                  .map((e) => e.event)
                                  .toList(),
                          size: size,
                          progress: progress,
                          initiallyExpanded:
                              initiallyExpandedEventId == event.id,
                        );
                      },
                    ),
                  ),
                  SliverList.builder(
                    itemCount: downloads.downloadedEvents.length,
                    itemBuilder: (context, index) {
                      final de = downloads.downloadedEvents.elementAt(index);

                      return DownloadTile(
                        key: ValueKey(de.event.id),
                        event: de.event,
                        upcomingEvents:
                            downloads.downloadedEvents
                                .map((e) => e.event)
                                .toList(),
                        size: size,
                        downloadPath: de.downloadPath,
                        initiallyExpanded:
                            initiallyExpandedEventId == de.event.id,
                      );
                    },
                  ),
                ],
              );
            },
          ),
        ),
      ],
    );
  }
}

class _NoDownloads extends StatelessWidget {
  const _NoDownloads();

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final home = context.watch<HomeProvider>();
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(Icons.folder_off, size: 48.0),
        const SizedBox(height: 6.0),
        Text(loc.noDownloads),
        Text.rich(
          TextSpan(
            text: loc.howToDownload,
            style: TextStyle(color: Theme.of(context).colorScheme.primary),
            recognizer:
                TapGestureRecognizer()
                  ..onTap = () => home.setTab(UnityTab.eventsHistory, context),
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}
