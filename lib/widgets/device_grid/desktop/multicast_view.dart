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

import 'dart:async';
import 'dart:math';

import 'package:bluecherry_client/models/device.dart';
import 'package:bluecherry_client/providers/settings_provider.dart';
import 'package:bluecherry_client/utils/config.dart';
import 'package:bluecherry_client/widgets/misc.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:unity_video_player/unity_video_player.dart';

class MulticastViewport extends StatefulWidget {
  final List<VideoOverlay> overlays;

  final Device device;

  const MulticastViewport({
    super.key,
    this.overlays = const [],
    required this.device,
  });

  @override
  State<MulticastViewport> createState() => _MulticastViewportState();
}

class _MulticastViewportState extends State<MulticastViewport> {
  Timer? _gap;

  (int row, int column)? currentZoom;

  /// Returns the next zoom position.
  ///
  /// [size] is the size of the matrix. For example, 4x4 matrix has a size of 4.
  (int row, int column) nextZoom((int row, int column) current, int size) {
    var row = current.$1;
    var column = current.$2;

    if (row == size - 1 && column == size - 1) {
      row = 0;
      column = 0;
    } else if (column == size - 1) {
      row++;
      column = 0;
    } else {
      column++;
    }

    return (row, column);
  }

  /// Returns the previous zoom position.
  ///
  /// [size] is the size of the matrix. For example, 4x4 matrix has a size of 4.
  (int row, int column) previousZoom((int row, int column) current, int size) {
    var row = current.$1;
    var column = current.$2;

    if (row == 0 && column == 0) {
      row = size - 1;
      column = size - 1;
    } else if (column == 0) {
      row--;
      column = size - 1;
    } else {
      column--;
    }

    return (row, column);
  }

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsProvider>();
    final view = UnityVideoView.maybeOf(context);
    final theme = Theme.of(context);

    if (view == null || !settings.betaMatrixedZoomEnabled) {
      return const SizedBox.shrink();
    }

    final size = widget.device.matrixType.size;
    if (view.player.isCropped) {
      return Listener(
        onPointerSignal: (event) async {
          if (_gap != null && _gap!.isActive || currentZoom == null) return;

          if (event is PointerScrollEvent) {
            if (event.scrollDelta.dy == 0.0) return;

            final scaleChange = exp(event.scrollDelta.dy / 200).toInt();
            _gap = Timer(const Duration(milliseconds: 1100), () {
              _gap?.cancel();
              _gap = null;
            });

            (int row, int column) next;

            if (scaleChange == 1.0) {
              next = nextZoom(currentZoom!, size);
            } else {
              next = previousZoom(currentZoom!, size);
            }

            view.player.crop(next.$1, next.$2, size);
            debugPrint('next: $next');
            currentZoom = next;
          }
        },
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () {
            view.player.resetCrop();
            currentZoom = null;
          },
          child: const SizedBox.expand(),
        ),
      );
    }

    return LayoutBuilder(builder: (context, constraints) {
      return Stack(children: [
        if (size > 1)
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
                    currentZoom = (row, col);
                  },
                  child: const SizedBox.expand(
                    child: IgnorePointer(
                      child: kDebugMode ? Placeholder() : null,
                    ),
                  ),
                );
              }),
            ),
          ),
        for (final overlay in widget.overlays)
          Positioned(
            left: constraints.maxWidth * (overlay.position.dx / 100),
            top: constraints.maxHeight * (overlay.position.dy / 100),
            right: 0,
            bottom: 0,
            child: IgnorePointer(
              child: Text(
                overlay.text,
                style: theme.textTheme.labelLarge!
                    .copyWith(shadows: outlinedText())
                    .merge(overlay.textStyle),
              ),
            ),
          ),
      ]);
    });
  }
}
