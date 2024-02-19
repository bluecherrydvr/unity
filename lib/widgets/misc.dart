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

import 'package:bluecherry_client/screens/settings/settings_desktop.dart';
import 'package:bluecherry_client/utils/extensions.dart';
import 'package:bluecherry_client/utils/methods.dart';
import 'package:bluecherry_client/widgets/squared_icon_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:unity_video_player/unity_video_player.dart';

const double kDesktopAppBarHeight = 64.0;

final moreIconData = isDesktop ? Icons.more_horiz : Icons.more_vert;

// ignore: must_be_immutable
class GestureDetectorWithReducedDoubleTapTime extends StatelessWidget {
  GestureDetectorWithReducedDoubleTapTime({
    super.key,
    required this.child,
    required this.onTap,
    required this.onDoubleTap,
    this.doubleTapTime = const Duration(milliseconds: 200),
  });

  final Widget child;
  final GestureTapCallback onTap;
  final GestureTapCallback onDoubleTap;
  final Duration doubleTapTime;

  Timer doubleTapTimer = Timer(const Duration(milliseconds: 200), () {});
  bool isPressed = false;
  bool isSingleTap = false;
  bool isDoubleTap = false;

  void _doubleTapTimerElapsed() {
    if (isPressed) {
      isSingleTap = true;
    } else {
      onTap();
    }
  }

  void _onTap() {
    isPressed = false;
    if (isSingleTap) {
      isSingleTap = false;
      onTap();
    }
    if (isDoubleTap) {
      isDoubleTap = false;
      onDoubleTap();
    }
  }

  void _onTapDown(TapDownDetails details) {
    isPressed = true;
    if (doubleTapTimer.isActive) {
      isDoubleTap = true;
      doubleTapTimer.cancel();
    } else {
      doubleTapTimer = Timer(doubleTapTime, _doubleTapTimerElapsed);
    }
  }

  void _onTapCancel() {
    isPressed = isSingleTap = isDoubleTap = false;
    if (doubleTapTimer.isActive) {
      doubleTapTimer.cancel();
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      key: key,
      onTap: _onTap,
      onTapDown: _onTapDown,
      onTapCancel: _onTapCancel,
      child: child,
    );
  }
}

class CorrectedListTile extends StatelessWidget {
  final VoidCallback? onTap;
  final IconData iconData;
  final String title;
  final String? subtitle;
  final double? height;
  final IconData? trailing;
  final Widget? trailingWidget;

  const CorrectedListTile({
    super.key,
    required this.iconData,
    required this.title,
    this.subtitle,
    this.onTap,
    this.height,
    this.trailing,
    this.trailingWidget,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return InkWell(
      onTap: onTap,
      child: Container(
        constraints: BoxConstraints(
          minHeight: height ?? 88.0,
          minWidth: MediaQuery.sizeOf(context).width,
          maxWidth: MediaQuery.sizeOf(context).width,
        ),
        padding: DesktopSettings.horizontalPadding,
        child: Row(children: [
          Container(
            margin: const EdgeInsetsDirectional.only(end: 12.0),
            alignment: AlignmentDirectional.center,
            width: 40.0,
            height: 40.0,
            child: Icon(iconData),
          ),
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: theme.textTheme.bodyLarge),
                if (subtitle != null) const SizedBox(height: 4.0),
                if (subtitle != null)
                  Text(
                    subtitle!,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.textTheme.bodySmall?.color,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
              ],
            ),
          ),
          if (trailingWidget != null)
            Padding(
              padding: const EdgeInsetsDirectional.only(start: 12.0),
              child: trailingWidget!,
            )
          else if (trailing != null)
            Container(
              margin: const EdgeInsetsDirectional.only(start: 12.0),
              alignment: AlignmentDirectional.center,
              width: 40.0,
              height: 40.0,
              child: Icon(trailing, color: theme.colorScheme.primary),
            ),
          const SizedBox(width: 16.0),
        ]),
      ),
    );
  }
}

class SubHeader extends StatelessWidget {
  final String text;
  final String? subtext;
  final TextStyle? subtextStyle;
  final EdgeInsetsGeometry padding;
  final double? height;
  final MaterialType materialType;
  final Widget? trailing;
  final TextAlign? textAlign;

  const SubHeader(
    this.text, {
    this.subtext,
    this.subtextStyle,
    this.trailing,
    super.key,
    this.padding = const EdgeInsetsDirectional.symmetric(horizontal: 16.0),
    this.height = 56.0,
    this.materialType = MaterialType.transparency,
    this.textAlign,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Material(
      type: materialType,
      child: Container(
        height: height,
        alignment: AlignmentDirectional.centerStart,
        padding: padding,
        child: Row(children: [
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  text.toUpperCase(),
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.textTheme.displaySmall?.color,
                    fontSize: 12.0,
                    fontWeight: FontWeight.w600,
                  ),
                  textAlign: textAlign,
                ),
                if (subtext != null)
                  Text(
                    subtext!.toUpperCase(),
                    style: theme.textTheme.labelSmall
                        ?.copyWith(
                          color: theme.hintColor,
                          fontSize: 10.0,
                          fontWeight: FontWeight.w600,
                        )
                        .merge(subtextStyle),
                  )
              ],
            ),
          ),
          if (trailing != null)
            DefaultTextStyle(
              style: theme.textTheme.labelSmall ?? const TextStyle(),
              child: trailing!,
            ),
        ]),
      ),
    );
  }
}

/// Outlines any text with the given color and stroke width making use of
/// [TextStyle.shadows]
///
///   * <https://stackoverflow.com/a/61292438/11622876>
List<Shadow> outlinedText({
  double strokeWidth = 1,
  Color strokeColor = Colors.black,
  int precision = 5,
}) {
  var result = <Shadow>{};
  for (var x = 1; x < strokeWidth + precision; x++) {
    for (var y = 1; y < strokeWidth + precision; y++) {
      var offsetX = x.toDouble();
      var offsetY = y.toDouble();
      result
        ..add(Shadow(
          offset: Offset(-strokeWidth / offsetX, -strokeWidth / offsetY),
          color: strokeColor,
        ))
        ..add(Shadow(
          offset: Offset(-strokeWidth / offsetX, strokeWidth / offsetY),
          color: strokeColor,
        ))
        ..add(Shadow(
          offset: Offset(strokeWidth / offsetX, -strokeWidth / offsetY),
          color: strokeColor,
        ))
        ..add(Shadow(
          offset: Offset(strokeWidth / offsetX, strokeWidth / offsetY),
          color: strokeColor,
        ));
    }
  }
  return result.toList();
}

List<Shadow> outlinedIcon() {
  return outlinedText(
    strokeWidth: 0.75,
    strokeColor: Colors.black.withOpacity(0.75),
  );
}

class PopupMenuLabel extends PopupMenuEntry<Never> {
  const PopupMenuLabel({super.key, required this.label, this.height = 42.0});

  @override
  final double height;

  final Widget label;

  @override
  bool represents(void value) => false;

  @override
  State<PopupMenuLabel> createState() => _PopupMenuLabelState();
}

class _PopupMenuLabelState extends State<PopupMenuLabel> {
  @override
  Widget build(BuildContext context) => widget.label;
}

class PlayPauseIcon extends StatefulWidget {
  final bool isPlaying;
  final Color? color;
  final List<Shadow>? shadows;
  final double? size;

  const PlayPauseIcon({
    super.key,
    required this.isPlaying,
    this.color,
    this.shadows,
    this.size,
  });

  @override
  State<PlayPauseIcon> createState() => _PlayPauseIconState();
}

class _PlayPauseIconState extends State<PlayPauseIcon>
    with SingleTickerProviderStateMixin {
  late final playPauseController = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 250),
    value: widget.isPlaying ? 1.0 : 0.0,
  );

  @override
  void didUpdateWidget(covariant PlayPauseIcon oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isPlaying) {
      playPauseController.forward();
    } else {
      playPauseController.reverse();
    }
  }

  @override
  void dispose() {
    playPauseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedIcon(
      icon: AnimatedIcons.play_pause,
      progress: CurvedAnimation(
        curve: Curves.ease,
        parent: playPauseController,
      ),
      color: widget.color,
      size: widget.size,
    );
  }
}

class InvertedTriangleClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    return Path()
      ..moveTo(0, 0)
      ..lineTo(size.width, 0)
      ..lineTo(size.width / 2, size.height)
      ..close();
  }

  @override
  bool shouldReclip(covariant InvertedTriangleClipper oldClipper) {
    return false;
  }
}

class EnforceScrollbarScroll extends StatefulWidget {
  final ScrollController controller;
  final PointerSignalEventListener? onPointerSignal;
  final Widget child;

  const EnforceScrollbarScroll({
    super.key,
    required this.controller,
    required this.child,
    this.onPointerSignal,
  });

  @override
  State<EnforceScrollbarScroll> createState() => _EnforceScrollbarScrollState();
}

class _EnforceScrollbarScrollState extends State<EnforceScrollbarScroll> {
  bool isScrolling = false;
  bool isHovered = false;

  @override
  Widget build(BuildContext context) {
    return Listener(
      onPointerDown: (_) => setState(() => isScrolling = true),
      onPointerUp: (_) => setState(() => isScrolling = false),
      onPointerSignal: widget.onPointerSignal,
      child: ScrollConfiguration(
        behavior: ScrollConfiguration.of(context).copyWith(
          physics: isHovered && !isScrolling
              ? const NeverScrollableScrollPhysics()
              : null,
        ),
        child: MouseRegion(
          onEnter: (v) => setState(() => isHovered = true),
          onExit: (v) => setState(() => isHovered = false),
          child: widget.child,
        ),
      ),
    );
  }
}

class CameraViewFitButton extends StatelessWidget {
  final UnityVideoFit fit;
  final ValueChanged<UnityVideoFit> onChanged;

  const CameraViewFitButton({
    super.key,
    required this.fit,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return SquaredIconButton(
      tooltip: fit.locale(context),
      onPressed: () => onChanged(fit.next),
      icon: Icon(
        fit.icon,
        size: 18.0,
        shadows: outlinedText(),
        color: Colors.white,
      ),
    );
  }
}
