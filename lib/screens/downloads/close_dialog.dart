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

import 'package:bluecherry_client/providers/downloads_provider.dart';
import 'package:bluecherry_client/screens/downloads/indicators.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:provider/provider.dart';

Future<bool?> showCloseDownloadsDialog(BuildContext context) async {
  return showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (context) => const CloseDownloadsDialog(),
  );
}

/// The dialog that appears when the user tries to close the app when there are
/// downloads in progress.
class CloseDownloadsDialog extends StatefulWidget {
  const CloseDownloadsDialog({super.key});

  @override
  State<CloseDownloadsDialog> createState() => _CloseDownloadsDialogState();
}

class _CloseDownloadsDialogState extends State<CloseDownloadsDialog> {
  bool _closeWhenDone = false;

  @override
  Widget build(BuildContext context) {
    final downloadsManager = context.watch<DownloadsManager>();
    final loc = AppLocalizations.of(context);
    final navigator = Navigator.of(context);

    return AlertDialog(
      title: Text(loc.nDownloadsProgress(downloadsManager.downloading.length)),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (final entry in downloadsManager.downloading.entries)
            ListTile(
              dense: true,
              contentPadding: EdgeInsets.zero,
              trailing: SizedBox.fromSize(
                size: const Size(40.0, 40.0),
                child: DownloadProgressIndicator(progress: entry.value),
              ),
              title: Text(entry.key.deviceName),
              subtitle: Text(entry.key.server.name),
            )
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => navigator.pop<bool>(false),
          child: Text(loc.cancel),
        ),
        OutlinedButton(
          onPressed: _closeWhenDone ? null : () => navigator.pop<bool>(true),
          child: Text(loc.closeAnyway),
        ),
        FilledButton(
          onPressed: _closeWhenDone
              ? null
              : () async {
                  setState(() => _closeWhenDone = true);
                  await downloadsManager.downloadsCompleter?.future;
                  navigator.pop<bool>(true);
                },
          child: Text(loc.closeWhenDone),
        ),
      ],
    );
  }
}
