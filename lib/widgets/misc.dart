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
import 'dart:io';
import 'dart:async';

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

class DesktopAppBar extends StatelessWidget {
  final String? title;
  final Widget? child;
  final Color? color;
  final Widget? leading;
  final double? height;
  final double? elevation;

  const DesktopAppBar({
    Key? key,
    this.title,
    this.child,
    this.color,
    this.leading,
    this.height,
    this.elevation,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (isMobile) return const SizedBox.shrink();
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        DesktopTitleBar(
          color: color,
        ),
        ClipRect(
          child: ClipRect(
            clipBehavior: Clip.antiAlias,
            child: Container(
              height: (height ?? kDesktopAppBarHeight) + 8.0,
              alignment: Alignment.topLeft,
              padding: const EdgeInsets.only(bottom: 8.0),
              child: Material(
                animationDuration: Duration.zero,
                elevation: elevation ?? 4.0,
                color: color ?? Theme.of(context).appBarTheme.backgroundColor,
                child: Container(
                  height: double.infinity,
                  alignment: Alignment.topLeft,
                  child: SizedBox(
                    height: kDesktopAppBarHeight,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.start,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        leading ??
                            NavigatorPopButton(
                              color: color != null
                                  ? isDark
                                      ? Colors.white
                                      : Colors.black
                                  : null,
                            ),
                        const SizedBox(
                          width: 16.0,
                        ),
                        if (title != null)
                          Text(
                            title!,
                            style:
                                Theme.of(context).textTheme.headline1?.copyWith(
                                    color: color != null
                                        ? isDark
                                            ? Colors.white
                                            : Colors.black
                                        : null),
                          ),
                        if (child != null)
                          SizedBox(
                            width: MediaQuery.of(context).size.width - 72.0,
                            child: child!,
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  bool get isDark =>
      (0.299 * (color?.red ?? 256.0)) +
          (0.587 * (color?.green ?? 256.0)) +
          (0.114 * (color?.blue ?? 256.0)) <
      128.0;
}

class DesktopTitleBar extends StatelessWidget {
  final Color? color;
  const DesktopTitleBar({Key? key, this.color}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (Platform.isAndroid || Platform.isIOS) {
      return Container(
        height: MediaQuery.of(context).padding.top,
        color: color ?? Theme.of(context).appBarTheme.backgroundColor,
      );
    }
    return
        // return Platform.isWindows
        //     ? Container(
        //         width: MediaQuery.of(context).size.width,
        //         height: desktopTitleBarHeight,
        //         color: color ?? Theme.of(context).appBarTheme.backgroundColor,
        //         child: Row(
        //           children: [
        //             Expanded(
        //               child: MoveWindow(
        //                 child: Row(
        //                   crossAxisAlignment: CrossAxisAlignment.center,
        //                   children: [
        //                     SizedBox(
        //                       width: 14.0,
        //                     ),
        //                     Text(
        //                       'Harmonoid Music',
        //                       style: TextStyle(
        //                         color: (color == null
        //                                 ? Theme.of(context).brightness ==
        //                                     Brightness.dark
        //                                 : isDark)
        //                             ? Colors.white
        //                             : Colors.black,
        //                         fontSize: 12.0,
        //                       ),
        //                     ),
        //                   ],
        //                 ),
        //               ),
        //             ),
        //             MinimizeWindowButton(
        //               colors: windowButtonColors(context),
        //             ),
        //             appWindow.isMaximized
        //                 ? RestoreWindowButton(
        //                     colors: windowButtonColors(context),
        //                   )
        //                 : MaximizeWindowButton(
        //                     colors: windowButtonColors(context),
        //                   ),
        //             CloseWindowButton(
        //               onPressed: () async {
        //                 if (!CollectionRefresh.instance.isCompleted) {
        //                   await showDialog(
        //                     context: context,
        //                     builder: (subContext) => AlertDialog(
        //                       title: Text(
        //                         Language.instance.WARNING,
        //                         style: Theme.of(subContext).textTheme.headline1,
        //                       ),
        //                       content: Text(
        //                         Language.instance.COLLECTION_INDEXING_LABEL,
        //                         style: Theme.of(subContext).textTheme.headline3,
        //                       ),
        //                       actions: [
        //                         MaterialButton(
        //                           textColor: Theme.of(context).primaryColor,
        //                           onPressed: Navigator.of(subContext).pop,
        //                           child: Text(Language.instance.OK),
        //                         ),
        //                       ],
        //                     ),
        //                   );
        //                 } else {
        //                   await Playback.instance.saveAppState();
        //                   if (Platform.isWindows) {
        //                     smtc.clear();
        //                     smtc.dispose();
        //                   }
        //                   appWindow.close();
        //                 }
        //               },
        //               colors: windowButtonColors(context),
        //             ),
        //           ],
        //         ),
        //       )
        //     :
        Container();
  }

  bool get isDark =>
      (0.299 * (color?.red ?? 256.0)) +
          (0.587 * (color?.green ?? 256.0)) +
          (0.114 * (color?.blue ?? 256.0)) <
      128.0;

  // WindowButtonColors windowButtonColors(BuildContext context) =>
  //     WindowButtonColors(
  //       iconNormal: (color == null
  //               ? Theme.of(context).brightness == Brightness.dark
  //               : isDark)
  //           ? Colors.white
  //           : Colors.black,
  //       iconMouseDown: (color == null
  //               ? Theme.of(context).brightness == Brightness.dark
  //               : isDark)
  //           ? Colors.white
  //           : Colors.black,
  //       iconMouseOver: (color == null
  //               ? Theme.of(context).brightness == Brightness.dark
  //               : isDark)
  //           ? Colors.white
  //           : Colors.black,
  //       normal: Colors.transparent,
  //       mouseOver: (color == null
  //               ? Theme.of(context).brightness == Brightness.dark
  //               : isDark)
  //           ? Colors.white.withOpacity(0.04)
  //           : Colors.black.withOpacity(0.04),
  //       mouseDown: (color == null
  //               ? Theme.of(context).brightness == Brightness.dark
  //               : isDark)
  //           ? Colors.white.withOpacity(0.04)
  //           : Colors.black.withOpacity(0.04),
  //     );
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
      child: child,
      onTap: _onTap,
      onTapDown: _onTapDown,
      onTapCancel: _onTapCancel,
    );
  }
}

// I'm tired of buggy implementation in
class CorrectedListTile extends StatelessWidget {
  final void Function()? onTap;
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
        width: MediaQuery.of(context).size.width,
        padding: const EdgeInsets.only(left: 16.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              margin: const EdgeInsets.only(right: 16.0),
              alignment: Alignment.center,
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
                    style: Theme.of(context).textTheme.subtitle1,
                  ),
                  if (subtitle != null) const SizedBox(height: 4.0),
                  if (subtitle != null)
                    Text(
                      subtitle!,
                      style: Theme.of(context).textTheme.bodyText2?.copyWith(
                            color: Theme.of(context).textTheme.caption?.color,
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
  const SubHeader(this.text, {Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 56.0,
      alignment: Alignment.centerLeft,
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Text(
        text.toUpperCase(),
        style: Theme.of(context).textTheme.overline?.copyWith(
              color: Theme.of(context).textTheme.headline3?.color,
              fontSize: 12.0,
              fontWeight: FontWeight.w600,
            ),
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
        setState(() {
          data = value;
        });
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
