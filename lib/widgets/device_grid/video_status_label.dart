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

class VideoStatusLabel extends StatelessWidget {
  final bool isImageOld;

  const VideoStatusLabel({super.key, required this.isImageOld});

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final color = isImageOld ? Colors.amber.shade600 : Colors.red.shade600;
    final text = isImageOld ? loc.timedOut : loc.live;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 500),
      padding: const EdgeInsetsDirectional.symmetric(
        horizontal: 4.0,
        vertical: 2.0,
      ),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(4.0),
      ),
      child: Text(
        text,
        style: theme.textTheme.labelSmall?.copyWith(
          color: color.computeLuminance() > 0.5 ? Colors.black : Colors.white,
        ),
      ),
    );
  }
}
