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
import 'dart:io';

import 'package:bluecherry_client/utils/methods.dart';
import 'package:flutter/material.dart';

const double kDesktopAppBarHeight = 64.0;

final moreIconData = isDesktop ? Icons.more_horiz : Icons.more_vert;

class NavigatorPopButton extends StatelessWidget {
  final Color? color;
  final VoidCallback? onTap;

  const NavigatorPopButton({super.key, this.onTap, this.color});

  @override
  Widget build(BuildContext context) {
    return IconButton(
      splashRadius: 22.0,
      onPressed: onTap ?? Navigator.of(context).pop,
      icon: Icon(
        Platform.isIOS ? Icons.arrow_back_ios : Icons.arrow_back,
        color: color,
      ),
    );
  }
}

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

// I'm tired of buggy implementation in
class CorrectedListTile extends StatelessWidget {
  final VoidCallback? onTap;
  final IconData iconData;
  final String title;
  final String? subtitle;
  final double? height;

  const CorrectedListTile({
    super.key,
    required this.iconData,
    required this.title,
    this.subtitle,
    this.onTap,
    this.height,
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
        padding: const EdgeInsetsDirectional.only(start: 16.0),
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

  final Widget? trailing;

  const SubHeader(
    this.text, {
    this.subtext,
    this.subtextStyle,
    this.trailing,
    super.key,
    this.padding = const EdgeInsets.symmetric(horizontal: 16.0),
    this.height = 56.0,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final isInCard = context.findAncestorWidgetOfExactType<Card>() != null ||
        context.findAncestorWidgetOfExactType<AlertDialog>() != null;

    return Material(
      type: isInCard ? MaterialType.transparency : MaterialType.canvas,
      child: Container(
        height: height,
        alignment: AlignmentDirectional.centerStart,
        padding: padding,
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
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
          if (trailing != null) trailing!,
        ]),
      ),
    );
  }
}

// ignore: non_constant_identifier_names
Widget? MaybeUnityDrawerButton(
  BuildContext context, {
  EdgeInsetsGeometry padding = EdgeInsets.zero,
}) {
  if (Scaffold.hasDrawer(context)) {
    return Padding(
      padding: padding,
      child: const UnityDrawerButton(),
    );
  }

  return null;
}

/// A button that listen to updates to the parent [Scaffold] and display the
/// drawer button accordingly
class UnityDrawerButton extends StatelessWidget {
  final Color? iconColor;
  final double? iconSize;
  final double splashRadius;

  const UnityDrawerButton({
    super.key,
    this.iconColor,
    this.iconSize = 22.0,
    this.splashRadius = 20.0,
  });

  @override
  Widget build(BuildContext context) {
    if (Scaffold.hasDrawer(context)) {
      return Tooltip(
        message: MaterialLocalizations.of(context).openAppDrawerTooltip,
        child: Center(
          child: SizedBox(
            height: 44.0,
            width: 44.0,
            child: InkWell(
              onTap: () => Scaffold.of(context).openDrawer(),
              radius: 10.0,
              borderRadius: BorderRadius.circular(100.0),
              child: Icon(Icons.menu, color: iconColor, size: iconSize),
            ),
          ),
        ),
      );
    }
    return const SizedBox.shrink();
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

class PopupLabel extends PopupMenuEntry<Never> {
  const PopupLabel({
    super.key,
    required this.label,
    this.height = 42.0,
  });

  @override
  final double height;

  final Widget label;

  @override
  bool represents(void value) => false;

  @override
  State<PopupLabel> createState() => _PopupLabelState();
}

class _PopupLabelState extends State<PopupLabel> {
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
