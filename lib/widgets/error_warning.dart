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
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class ErrorWarning extends StatelessWidget {
  const ErrorWarning({super.key, required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    return GestureDetector(
      onLongPress: () {
        Clipboard.setData(ClipboardData(text: message));
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(loc.copiedToClipboard(message)),
            behavior: SnackBarBehavior.floating,
          ),
        );
      },
      child: Container(
        margin: const EdgeInsetsDirectional.all(6.0),
        color: Colors.black38,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.warning, color: Colors.white, size: 32.0),
            AutoSizeText(
              loc.videoError,
              style: const TextStyle(color: Colors.white),
              maxLines: 1,
              minFontSize: 6.0,
            ),
            if (message.isNotEmpty) ...[
              const FractionallySizedBox(
                widthFactor: 0.5,
                child: Divider(color: Colors.white),
              ),
              const SizedBox(height: 8.0),
              Flexible(
                child: Text(
                  message,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.white, fontSize: 12.0),
                  overflow: TextOverflow.fade,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class NoServerWarning extends StatelessWidget {
  const NoServerWarning({super.key});

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final theme = Theme.of(context);

    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.dns,
            size: 72.0,
            color: theme.iconTheme.color?.withValues(alpha: 0.8),
          ),
          const SizedBox(height: 8.0),
          Text(
            loc.noServersAdded,
            style: theme.textTheme.headlineSmall?.copyWith(fontSize: 16.0),
          ),
        ],
      ),
    );
  }
}
