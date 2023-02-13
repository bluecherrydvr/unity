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

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

const double kDesktopAppBarHeight = 64.0;
bool get isDesktop {
  if (kIsWeb) return false;
  return [
    TargetPlatform.windows,
    TargetPlatform.linux,
    TargetPlatform.macOS,
  ].contains(defaultTargetPlatform);
}

final moreIconData = isDesktop ? Icons.more_horiz : Icons.more_vert;

final isMobile = Platform.isAndroid || Platform.isIOS;
final desktopTitleBarHeight = Platform.isWindows ? 0.0 : 0.0;

class NavigatorPopButton extends StatelessWidget {
  final Color? color;
  final void Function()? onTap;
  const NavigatorPopButton({Key? key, this.onTap, this.color})
      : super(key: key);

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
    Key? key,
    required this.child,
    required this.onTap,
    required this.onDoubleTap,
    this.doubleTapTime = const Duration(milliseconds: 200),
  }) : super(key: key);

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
    Key? key,
    required this.iconData,
    required this.title,
    this.subtitle,
    this.onTap,
    this.height,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        height: height ?? 88.0,
        width: MediaQuery.sizeOf(context).width,
        padding: const EdgeInsetsDirectional.only(start: 16.0),
        child: Row(
          children: [
            Container(
              margin: const EdgeInsetsDirectional.only(end: 16.0),
              alignment: AlignmentDirectional.center,
              width: 40.0,
              height: 40.0,
              child: Icon(iconData),
            ),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  if (subtitle != null) const SizedBox(height: 4.0),
                  if (subtitle != null)
                    Text(
                      subtitle!,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Theme.of(context).textTheme.bodySmall?.color,
                          ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                ],
              ),
            ),
            const SizedBox(width: 16.0),
          ],
        ),
      ),
    );
  }
}

class SubHeader extends StatelessWidget {
  final String text;
  final String? subtext;
  final EdgeInsetsGeometry padding;

  const SubHeader(
    this.text, {
    this.subtext,
    Key? key,
    this.padding = const EdgeInsets.symmetric(horizontal: 16.0),
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 56.0,
      alignment: AlignmentDirectional.centerStart,
      padding: padding,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            text.toUpperCase(),
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: Theme.of(context).textTheme.displaySmall?.color,
                  fontSize: 12.0,
                  fontWeight: FontWeight.w600,
                ),
          ),
          if (subtext != null)
            Text(
              subtext!.toUpperCase(),
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: Theme.of(context).hintColor,
                    fontSize: 10.0,
                    fontWeight: FontWeight.w600,
                  ),
            )
        ],
      ),
    );
  }
}

class CustomFutureBuilder<T> extends StatefulWidget {
  final Future<T>? future;
  final Widget Function(BuildContext) loadingBuilder;
  final Widget Function(BuildContext, T?) builder;
  const CustomFutureBuilder({
    Key? key,
    required this.future,
    required this.loadingBuilder,
    required this.builder,
  }) : super(key: key);

  @override
  State<CustomFutureBuilder<T>> createState() => _CustomFutureBuilderState();
}

class _CustomFutureBuilderState<T> extends State<CustomFutureBuilder<T>> {
  T? data;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      widget.future?.then((value) {
        data = value;
        if (mounted) setState(() {});
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return data == null
        ? widget.loadingBuilder(context)
        : widget.builder(context, data);
  }
}
