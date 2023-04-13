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

import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class ErrorWarning extends StatelessWidget {
  const ErrorWarning({super.key, required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.warning,
            color: Colors.white70,
            size: 32.0,
          ),
          if (message.isNotEmpty) ...[
            const SizedBox(height: 8.0),
            Text(
              message.toUpperCase(),
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 12.0,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class NoServerWarning extends StatelessWidget {
  const NoServerWarning({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.dns,
            size: 72.0,
            color: Theme.of(context).iconTheme.color?.withOpacity(0.8),
          ),
          const SizedBox(height: 8.0),
          Text(
            AppLocalizations.of(context).noServersAdded,
            style: Theme.of(context)
                .textTheme
                .headlineSmall
                ?.copyWith(fontSize: 16.0),
          ),
        ],
      ),
    );
  }
}
