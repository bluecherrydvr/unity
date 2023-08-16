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

import 'package:bluecherry_client/models/device.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:intl/intl.dart';
import 'package:unity_video_player/unity_video_player.dart';

class VideoStatusLabel extends StatefulWidget {
  final VideoViewInheritance video;
  final Device device;

  const VideoStatusLabel({
    super.key,
    required this.video,
    required this.device,
  });

  @override
  State<VideoStatusLabel> createState() => _VideoStatusLabelState();
}

class _VideoStatusLabelState extends State<VideoStatusLabel> {
  final overlayKey = GlobalKey(debugLabel: 'Label Overlay');

  bool _openWithTap = false;
  OverlayEntry? entry;
  bool get isOverlayOpen => entry != null;
  void showOverlay({bool force = false}) {
    if (entry != null && !force) return;

    final box = context.findRenderObject() as RenderBox;
    final boxSize = box.size;
    final position = box.localToGlobal(Offset.zero);

    entry = OverlayEntry(builder: (context) {
      return LayoutBuilder(builder: (context, constraints) {
        return Stack(children: [
          if (position.dy > DeviceVideoInfo.constraints.minHeight + 8.0)
            Positioned(
              bottom: constraints.maxHeight - position.dy + 8.0,
              right: constraints.maxWidth - position.dx - boxSize.width,
              child:
                  DeviceVideoInfo(device: widget.device, video: widget.video),
            )
          else
            Positioned(
              top: position.dy + boxSize.height + 8.0,
              left: position.dx,
              child:
                  DeviceVideoInfo(device: widget.device, video: widget.video),
            ),
        ]);
      });
    });
    Overlay.of(context).insert(entry!);
  }

  void dismissOverlay() {
    entry?.remove();
    entry = null;
  }

  @override
  void dispose() {
    dismissOverlay();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final color =
        widget.video.isImageOld ? Colors.amber.shade600 : Colors.red.shade600;
    final text = widget.video.isImageOld ? loc.timedOut : loc.live;

    // This opens the overlay when a property is updated. This is a frame late
    if (isOverlayOpen) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        dismissOverlay();
        showOverlay(force: true);
      });
    }

    return MouseRegion(
      onEnter: _openWithTap ? null : (_) => showOverlay(),
      onExit: _openWithTap ? null : (_) => dismissOverlay(),
      child: GestureDetector(
        onTap: () {
          if (_openWithTap) {
            dismissOverlay();
            _openWithTap = false;
          } else {
            _openWithTap = true;
            showOverlay();
          }
        },
        child: AnimatedContainer(
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
              color:
                  color.computeLuminance() > 0.5 ? Colors.black : Colors.white,
            ),
          ),
        ),
      ),
    );
  }
}

class DeviceVideoInfo extends StatelessWidget {
  final Device device;
  final VideoViewInheritance video;

  const DeviceVideoInfo({super.key, required this.device, required this.video});

  static const constraints = BoxConstraints(
    minWidth: 211.0,
    minHeight: 124.0,
  );

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final theme = Theme.of(context);
    return Container(
      constraints: constraints,
      decoration: BoxDecoration(
        color: theme.colorScheme.secondaryContainer,
        borderRadius: BorderRadius.circular(6.0),
      ),
      padding: const EdgeInsetsDirectional.symmetric(
        vertical: 12.0,
        horizontal: 12.0,
      ),
      child: RichText(
        text: TextSpan(
          children: [
            _buildTextSpan(context, title: loc.device, data: device.name),
            _buildTextSpan(
              context,
              title: loc.server,
              data: '${device.server.name} (${device.id})',
            ),
            _buildTextSpan(
              context,
              title: loc.ptzSupported,
              data: device.hasPTZ ? loc.yes : loc.no,
            ),
            _buildTextSpan(
              context,
              title: loc.resolution,
              data: '${device.resolutionX}x${device.resolutionY}',
            ),
            _buildTextSpan(
              context,
              title: loc.lastImageUpdate,
              data: video.lastImageUpdate == null
                  ? loc.unknown
                  : DateFormat.Hms().format(video.lastImageUpdate!),
              last: true,
            ),
          ],
        ),
      ),
    );
  }

  TextSpan _buildTextSpan(
    BuildContext context, {
    required String title,
    required String data,
    bool last = false,
  }) {
    final theme = Theme.of(context);
    return TextSpan(children: [
      TextSpan(
        text: '$title: ',
        style: theme.textTheme.labelLarge?.copyWith(
          fontWeight: FontWeight.bold,
          color: theme.colorScheme.onSecondaryContainer,
        ),
      ),
      TextSpan(
        text: data,
        style: theme.textTheme.labelLarge,
      ),
      if (!last) const TextSpan(text: '\n'),
    ]);
  }
}
