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
import 'package:bluecherry_client/models/event.dart';
import 'package:bluecherry_client/providers/settings_provider.dart';
import 'package:bluecherry_client/utils/extensions.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:intl/intl.dart';
import 'package:unity_video_player/unity_video_player.dart';

class VideoStatusLabel extends StatefulWidget {
  final VideoViewInheritance video;
  final Device device;
  final Event? event;

  const VideoStatusLabel({
    super.key,
    required this.video,
    required this.device,
    this.event,
  });

  @override
  State<VideoStatusLabel> createState() => _VideoStatusLabelState();
}

enum _VideoLabel {
  loading,
  live,
  timedOut,
  recorded,
  error,
}

class _VideoStatusLabelState extends State<VideoStatusLabel> {
  final overlayKey = GlobalKey(debugLabel: 'Label Overlay');

  bool get isLoading => widget.video.lastImageUpdate == null;
  String get _source => widget.video.player.dataSource!;
  bool get isLive =>
      widget.video.player.dataSource != null &&
      // It is only LIVE if it starts with rtsp or is hls
      (_source.startsWith('rtsp') ||
          _source.contains('media/mjpeg') ||
          _source.contains('.m3u8') /* hls */);

  _VideoLabel get status => widget.video.error != null
      ? _VideoLabel.error
      : isLoading
          ? _VideoLabel.loading
          : !isLive
              ? _VideoLabel.recorded
              : widget.video.isImageOld
                  ? _VideoLabel.timedOut
                  : _VideoLabel.live;

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
        final label = _DeviceVideoInfo(
          device: widget.device,
          video: widget.video,
          label: status,
          isLive: isLive,
          event: widget.event,
        );
        final minHeight = label.buildTextSpans(context).length * 15;
        return Stack(children: [
          if (position.dy > minHeight + 8.0)
            Positioned(
              bottom: constraints.maxHeight - position.dy + 8.0,
              right: constraints.maxWidth - position.dx - boxSize.width,
              child: label,
            )
          else
            () {
              final willLeftOverflow = position.dx + _DeviceVideoInfo.minWidth >
                  constraints.maxWidth;
              return Positioned(
                top: position.dy + boxSize.height + 8.0,
                left: willLeftOverflow
                    ? (constraints.maxWidth - _DeviceVideoInfo.minWidth - 8.0)
                    : position.dx,
                child: label,
              );
            }(),
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

    final text = switch (status) {
      _VideoLabel.live => loc.live,
      _VideoLabel.loading => loc.loading,
      _VideoLabel.recorded => loc.recorded,
      _VideoLabel.timedOut => loc.timedOut,
      _VideoLabel.error => loc.error,
    };

    final color = switch (status) {
      _VideoLabel.live => Colors.red.shade600,
      _VideoLabel.loading => Colors.blue,
      _VideoLabel.recorded => Colors.green,
      _VideoLabel.timedOut => Colors.amber.shade600,
      _VideoLabel.error => Colors.grey,
    };

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
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            if (status == _VideoLabel.loading)
              const Padding(
                padding: EdgeInsetsDirectional.only(end: 8.0),
                child: SizedBox(
                  height: 12.0,
                  width: 12.0,
                  child: CircularProgressIndicator.adaptive(
                    strokeWidth: 1.5,
                    valueColor: AlwaysStoppedAnimation(Colors.white),
                  ),
                ),
              ),
            Text(
              text,
              style: theme.textTheme.labelSmall?.copyWith(
                color: color.computeLuminance() > 0.5
                    ? Colors.black
                    : Colors.white,
              ),
            ),
          ]),
        ),
      ),
    );
  }
}

class _DeviceVideoInfo extends StatelessWidget {
  final Device device;
  final VideoViewInheritance video;
  final _VideoLabel label;
  final bool isLive;

  final Event? event;

  const _DeviceVideoInfo({
    required this.device,
    required this.video,
    required this.label,
    required this.isLive,
    required this.event,
  });

  static const minWidth = 211.0;

  List<TextSpan> buildTextSpans(BuildContext context) {
    final loc = AppLocalizations.of(context);

    final name = _buildTextSpan(context, title: loc.device, data: device.name);
    final server = _buildTextSpan(
      context,
      title: loc.server,
      data: '${device.server.name} (${device.id})',
    );
    if (isLive) {
      return [
        name,
        server,
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
        _buildTextSpan(context, title: loc.fps, data: '${video.fps}'),
        _buildTextSpan(
          context,
          title: loc.lastImageUpdate,
          data: video.lastImageUpdate == null
              ? loc.unknown
              : DateFormat.Hms().format(video.lastImageUpdate!),
          last: true,
        ),
      ];
    } else if (event != null) {
      // If not live, it is a recorded footage
      return [
        name,
        server,
        _buildTextSpan(
          context,
          title: loc.duration,
          data: event!.duration.humanReadable(context),
        ),
        _buildTextSpan(
          context,
          title: loc.date,
          data: SettingsProvider.instance.formatDate(event!.published),
        ),
        _buildTextSpan(
          context,
          title: loc.eventType,
          data: event!.type.locale(context),
          last: true,
        ),
      ];
    } else {
      return [name, server];
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      constraints: const BoxConstraints(minWidth: minWidth),
      decoration: BoxDecoration(
        color: theme.colorScheme.secondaryContainer,
        borderRadius: BorderRadius.circular(6.0),
      ),
      padding: const EdgeInsetsDirectional.symmetric(
        vertical: 12.0,
        horizontal: 12.0,
      ),
      child: RichText(text: TextSpan(children: buildTextSpans(context))),
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
