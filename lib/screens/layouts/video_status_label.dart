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
import 'package:bluecherry_client/utils/date.dart';
import 'package:bluecherry_client/utils/extensions.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:intl/intl.dart' show DateFormat;
import 'package:provider/provider.dart';
import 'package:unity_video_player/unity_video_player.dart';

/// The position of the [VideoStatusLabel].
enum VideoStatusLabelPosition {
  /// The label will be displayed at the bottom of the video.
  ///
  /// This is the default position.
  bottom,
  top,
}

class VideoStatusLabel extends StatefulWidget {
  final VideoViewInheritance video;
  final Device device;
  final Event? event;
  final VideoStatusLabelPosition position;

  const VideoStatusLabel({
    super.key,
    required this.video,
    required this.device,
    this.event,
    this.position = VideoStatusLabelPosition.bottom,
  });

  @override
  State<VideoStatusLabel> createState() => _VideoStatusLabelState();
}

enum VideoLabel {
  /// When the video hasn't loaded any frame yet.
  loading,

  /// When the video is live and playing
  live,

  /// When the video has loaded but isn't receiving any new frames in a specified
  /// amount of time.
  timedOut,

  /// When the video is a recording, such as events.
  recorded,

  /// When an error happened while loading the video.
  error,

  /// When the video is live, receiving frames, but the current position does
  /// not match the current time - with an offset of 1.5 seconds.
  late,
}

class _VideoStatusLabelState extends State<VideoStatusLabel> {
  final overlayKey = GlobalKey(debugLabel: 'Label Overlay');

  bool get isLoading => widget.video.lastImageUpdate == null;

  VideoLabel get status =>
      widget.video.error != null
          ? VideoLabel.error
          : isLoading
          ? VideoLabel.loading
          : widget.video.player.isRecorded
          ? VideoLabel.recorded
          : widget.video.player.isImageOld
          ? VideoLabel.timedOut
          : widget.video.player.isLate
          ? VideoLabel.late
          : VideoLabel.live;

  bool _openWithTap = false;
  OverlayEntry? entry;
  bool get isOverlayOpen => entry != null;
  void showOverlay({bool force = false}) {
    if ((entry != null && !force) || !context.mounted) return;

    final box = context.findRenderObject() as RenderBox;
    final boxSize = box.size;
    final position = box.localToGlobal(Offset.zero);

    entry = OverlayEntry(
      builder: (context) {
        return LayoutBuilder(
          builder: (context, constraints) {
            final label = _DeviceVideoInfo(
              device: widget.device,
              video: widget.video,
              label: status,
              event: widget.event,
            );
            final (height, width) = label.textSize(context);
            const padding = 8.0;

            final left =
                widget.position == VideoStatusLabelPosition.bottom
                    ? position.dx - width + boxSize.width
                    : position.dx;
            final top =
                widget.position == VideoStatusLabelPosition.bottom
                    ? position.dy - height - padding
                    : position.dy + boxSize.height + padding;

            final overflowsRight = left + width > constraints.maxWidth;
            final right = constraints.maxWidth - position.dx - boxSize.width;

            return Stack(
              children: [
                Positioned(
                  left: overflowsRight ? null : left,
                  right: overflowsRight ? right : null,
                  top: top,
                  height: height,
                  width: width,
                  child: label,
                ),
              ],
            );
          },
        );
      },
    );
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
    final settings = context.watch<SettingsProvider>();

    // This opens the overlay when a property is updated. This is a frame late
    if (isOverlayOpen) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        dismissOverlay();
        showOverlay(force: true);
      });
    }

    final isLateDismissal =
        status == VideoLabel.late &&
        settings.kLateStreamBehavior.value == LateVideoBehavior.manual;

    return MouseRegion(
      onEnter: _openWithTap ? null : (_) => showOverlay(),
      onExit: _openWithTap ? null : (_) => dismissOverlay(),
      child: GestureDetector(
        onTap: () {
          if (isLateDismissal) {
            widget.video.player.dismissLateVideo();
            return;
          }
          if (_openWithTap) {
            dismissOverlay();
            _openWithTap = false;
          } else {
            _openWithTap = true;
            showOverlay();
          }
        },
        child: VideoStatusLabelIndicator(status: status),
      ),
    );
  }
}

class VideoStatusLabelIndicator extends StatelessWidget {
  final VideoLabel status;

  const VideoStatusLabelIndicator({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final loc = AppLocalizations.of(context);
    final text = switch (status) {
      VideoLabel.live => loc.live,
      VideoLabel.loading => loc.loading,
      VideoLabel.recorded => loc.recorded,
      VideoLabel.timedOut => loc.timedOut,
      VideoLabel.error => loc.error,
      VideoLabel.late => loc.late,
    };

    final color = switch (status) {
      VideoLabel.live => Colors.red.shade600,
      VideoLabel.loading => Colors.blue,
      VideoLabel.recorded => Colors.green,
      VideoLabel.timedOut => Colors.amber.shade600,
      VideoLabel.error => Colors.grey,
      VideoLabel.late => Colors.purple,
    };

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
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (status == VideoLabel.loading)
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
              color:
                  color.computeLuminance() > 0.5 ? Colors.black : Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}

class _DeviceVideoInfo extends StatelessWidget {
  final Device device;
  final VideoViewInheritance video;
  final VideoLabel label;

  final Event? event;

  const _DeviceVideoInfo({
    required this.device,
    required this.video,
    required this.label,
    required this.event,
  });

  List<TextSpan> _buildTextSpans(BuildContext context) {
    final loc = AppLocalizations.of(context);

    final name = _buildTextSpan(context, title: loc.device, data: device.name);
    final server = _buildTextSpan(
      context,
      title: loc.server,
      data: '${device.server.name} (${device.id})',
    );
    if (video.player.isLive) {
      return [
        name,
        server,
        _buildTextSpan(
          context,
          title: loc.isPtzSupported,
          data: device.hasPTZ ? loc.yes : loc.no,
        ),
        _buildTextSpan(
          context,
          title: loc.resolution,
          data:
              '${video.player.width ?? device.resolutionX}'
              'x'
              '${video.player.height ?? device.resolutionY}',
        ),
        if (UnityVideoPlayerInterface.instance.supportsFPS)
          _buildTextSpan(context, title: loc.fps, data: '${video.fps}'),
        _buildTextSpan(
          context,
          title: loc.lastImageUpdate,
          data:
              video.lastImageUpdate == null
                  ? loc.unknown
                  : DateFormat.Hms().format(video.lastImageUpdate!),
        ),
        _buildTextSpan(
          context,
          title: loc.status,
          data: video.player.isPlaying ? loc.playing : loc.paused,
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
          title: loc.time,
          data: SettingsProvider.instance.formatTimeRaw(event!.publishedRaw),
        ),
        _buildTextSpan(
          context,
          title: loc.eventType,
          data: event!.type.locale(context),
        ),
        _buildTextSpan(
          context,
          title: loc.status,
          data: video.player.isPlaying ? loc.playing : loc.paused,
          last: true,
        ),
      ];
    } else {
      return [name, server];
    }
  }

  (double height, double width) textSize(BuildContext context) {
    final spans = _buildTextSpans(context);
    const padding = 12.0 * 2.0;
    var height = 0.0;
    var width = 0.0;
    for (final span in spans) {
      final painter = TextPainter(
        maxLines: 1,
        text: span,
        textDirection: TextDirection.ltr,
      )..layout(maxWidth: MediaQuery.of(context).size.width);
      height += painter.height;
      if (painter.width > width) width = painter.width;
    }

    return (height + padding, width + padding);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.secondaryContainer,
        borderRadius: BorderRadius.circular(6.0),
      ),
      padding: const EdgeInsetsDirectional.symmetric(
        vertical: 12.0,
        horizontal: 12.0,
      ),
      alignment: AlignmentDirectional.center,
      child: RichText(text: TextSpan(children: _buildTextSpans(context))),
    );
  }

  TextSpan _buildTextSpan(
    BuildContext context, {
    required String title,
    required String data,
    bool last = false,
  }) {
    final theme = Theme.of(context);
    return TextSpan(
      children: [
        TextSpan(
          text: '$title: ',
          style: theme.textTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.bold,
            color: theme.colorScheme.onSecondaryContainer,
          ),
        ),
        TextSpan(text: data, style: theme.textTheme.labelLarge),
        if (!last) const TextSpan(text: '\n'),
      ],
    );
  }
}
