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

import 'package:bluecherry_client/providers/settings_provider.dart';
import 'package:bluecherry_client/widgets/misc.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:unity_video_player/unity_video_player.dart';

class MulticastViewport extends StatelessWidget {
  final String? overlayText;
  final TextStyle? overlayStyle;
  final Offset? overlayPosition;

  const MulticastViewport({
    super.key,
    this.overlayText,
    this.overlayStyle = const TextStyle(
      color: Colors.green,
      fontSize: 32,
    ),
    this.overlayPosition = const Offset(250, 250),
  });

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsProvider>();
    final view = UnityVideoView.maybeOf(context);

    if (view == null || !settings.betaMatrixedZoomEnabled) {
      return const SizedBox.shrink();
    }

    if (view.player.isCropped) {
      return GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: view.player.resetCrop,
        child: const SizedBox.expand(),
      );
    }

    const size = 4;
    return Stack(children: [
      if (overlayText != null)
        Positioned(
          left: overlayPosition?.dx,
          top: overlayPosition?.dy,
          child: IgnorePointer(
            child: Text(
              overlayText!,
              style: TextStyle(
                shadows: outlinedText(),
              ).merge(overlayStyle),
            ),
          ),
        ),
      Positioned.fill(
        child: GridView.count(
          crossAxisCount: size,
          childAspectRatio: 16 / 9,
          physics: const NeverScrollableScrollPhysics(),
          children: List.generate(size * size, (index) {
            final row = index ~/ size;
            final col = index % size;

            return GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () {
                view.player.crop(row, col, size);
              },
              child: const SizedBox.expand(
                  // child: Placeholder(),
                  ),
            );
          }),
        ),
      ),
    ]);
  }
}
