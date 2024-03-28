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

import 'package:bluecherry_client/models/event.dart';
import 'package:bluecherry_client/providers/downloads_provider.dart';
import 'package:bluecherry_client/providers/home_provider.dart';
import 'package:bluecherry_client/utils/methods.dart';
import 'package:bluecherry_client/utils/theme.dart';
import 'package:bluecherry_client/widgets/misc.dart';
import 'package:bluecherry_client/widgets/squared_icon_button.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:provider/provider.dart';

class DownloadProgressIndicator extends StatelessWidget {
  const DownloadProgressIndicator({
    super.key,
    required this.progress,
    this.color,
  });

  final DownloadProgress progress;

  /// The color of the indicator.
  ///
  /// If not provided, the primary color is used instead.
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (isCupertino) {
      return CupertinoActivityIndicator.partiallyRevealed(
        progress: progress,
      );
    }

    return Stack(children: [
      Padding(
        padding: const EdgeInsetsDirectional.all(8.0),
        child: CircularProgressIndicator(
          value: progress,
          strokeWidth: 2.0,
          color: color,
        ),
      ),
      Center(
        child: Icon(
          Icons.download,
          size: 14.0,
          color: color ?? theme.colorScheme.primary,
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

  /// Whether to highlight the indicator with a white color and an outline border
  final bool highlight;

  /// Whether the indicator is small
  final bool small;

  const DownloadIndicator({
    super.key,
    required this.event,
    this.highlight = false,
    this.small = false,
  });

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
            size: small ? 18.0 : null,
          );
        }

        final downloads = context.watch<DownloadsManager>();

        if (downloads.isEventDownloaded(event.id)) {
          return SquaredIconButton(
            onPressed: () {
              context.read<HomeProvider>().toDownloads(event.id, context);
            },
            tooltip: loc.seeInDownloads,
            icon: Icon(
              Icons.download_done,
              size: small ? 18.0 : null,
              color: theme.extension<UnityColors>()!.successColor,
            ),
          );
        }

        if (downloads.isEventDownloading(event.id)) {
          return DownloadProgressIndicator(
            progress: downloads
                .downloading[downloads.downloading.keys
                    .firstWhere((e) => e.id == event.id)]!
                .$1,
            color: highlight ? Colors.amber : null,
          );
        }

        if (event.mediaURL != null) {
          return SquaredIconButton(
            tooltip: loc.download,
            onPressed: () => downloads.download(event),
            icon: Icon(
              Icons.download,
              size: small ? 18.0 : 22.0,
              color: highlight ? Colors.white : null,
              shadows: highlight ? outlinedText() : null,
            ),
          );
        }
      }(),
    );
  }
}
