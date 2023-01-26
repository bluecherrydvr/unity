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

import 'package:bluecherry_client/main.dart';
import 'package:bluecherry_client/models/device.dart';
import 'package:bluecherry_client/models/event.dart';
import 'package:bluecherry_client/providers/home_provider.dart';
import 'package:bluecherry_client/widgets/home.dart';
import 'package:bluecherry_client/widgets/misc.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:window_manager/window_manager.dart';

final navigationStream = StreamController.broadcast();

class NObserver extends NavigatorObserver {
  void update(Route route) {
    // do not update if it's a popup
    if (route is PopupRoute) return;
    if (route is DialogRoute) return;

    navigationStream.add(route.settings.arguments);
  }

  @override
  void didPop(Route route, Route? previousRoute) {
    update(previousRoute ?? route);
    super.didPop(route, previousRoute);
  }

  @override
  void didPush(Route route, Route? previousRoute) {
    update(route);
    super.didPush(route, previousRoute);
  }

  @override
  void didRemove(Route route, Route? previousRoute) {
    update(route);
    super.didRemove(route, previousRoute);
  }
}

class WindowButtons extends StatefulWidget {
  const WindowButtons({
    Key? key,
    this.title,
    this.showNavigator = true,
  }) : super(key: key);

  /// The current window title.
  ///
  /// If not provided, the title if fetched from the data of the current
  /// route
  final String? title;

  /// Whether the navigator will be show.
  ///
  /// Usually disabled on sub windows.
  ///
  /// Defaults to true.
  final bool showNavigator;

  @override
  State<WindowButtons> createState() => _WindowButtonsState();
}

class _WindowButtonsState extends State<WindowButtons> with WindowListener {
  @override
  Widget build(BuildContext context) {
    if (!isDesktop) return const SizedBox.shrink();

    final theme = Theme.of(context);

    final home = context.watch<HomeProvider>();
    final tab = home.tab;

    return StreamBuilder(
      stream: navigationStream.stream,
      builder: (context, arguments) {
        final canPop = navigatorKey.currentState?.canPop() ?? false;

        // final divider = SizedBox(
        //   height: 16.0,
        //   child: VerticalDivider(
        //     color: theme.brightness == Brightness.dark
        //         ? Colors.white
        //         : Colors.black,
        //   ),
        // );

        return Material(
          color: theme.appBarTheme.backgroundColor,
          child: Stack(children: [
            DragToMoveArea(
              child: Row(children: [
                if (canPop)
                  IconButton(
                    icon: const Icon(Icons.arrow_back),
                    iconSize: 20.0,
                    color: theme.hintColor,
                    onPressed: () async {
                      await navigatorKey.currentState?.maybePop();
                      setState(() {});
                    },
                  )
                else
                  Padding(
                    padding: const EdgeInsetsDirectional.only(start: 8.0),
                    child: Image.asset(
                      'assets/images/icon.png',
                      height: 16.0,
                      width: 16.0,
                    ),
                  ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsetsDirectional.only(start: 10.0),
                    child: Text(
                      () {
                        if (widget.title != null) return widget.title!;

                        if (arguments.data != null) {
                          if (arguments.data is Event) {
                            final event = arguments.data as Event;
                            return event.deviceName;
                          }

                          if (arguments.data is Device) {
                            final device = arguments.data as Device;
                            return device.fullName;
                          }
                        }

                        final names = navigatorData(context).values;

                        if (tab >= names.length) {
                          return widget.title ?? 'Bluecherry';
                        }

                        return names.elementAt(tab);
                      }(),
                      style: TextStyle(
                        color: theme.brightness == Brightness.light
                            ? Colors.black
                            : Colors.white,
                        fontSize: 12.0,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
                // if (!canPop && widget.showNavigator) ...[
                //   ...navigatorData(context).entries.map((entry) {
                //     final icon = entry.key;
                //     final text = entry.value;
                //     final index =
                //         navigatorData(context).keys.toList().indexOf(icon);

                //     return IconButton(
                //       icon: Icon(
                //         icon,
                //         color: home.tab == index
                //             ? theme.colorScheme.primary
                //             : theme.hintColor,
                //       ),
                //       iconSize: 22.0,
                //       tooltip: text,
                //       onPressed: () => home.setTab(index),
                //     );
                //   }),
                //   divider,
                // ],
                SizedBox(
                  width: 138,
                  height: 40,
                  child: WindowCaption(
                    brightness: theme.brightness,
                    backgroundColor: Colors.transparent,
                  ),
                ),
              ]),
            ),
            if (!canPop && widget.showNavigator)
              Padding(
                padding: const EdgeInsets.only(top: 4.0),
                child:
                    Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                  ...navigatorData(context).entries.map((entry) {
                    final icon = entry.key;
                    final text = entry.value;
                    final index =
                        navigatorData(context).keys.toList().indexOf(icon);

                    return IconButton(
                      icon: Icon(
                        icon,
                        color: home.tab == index
                            ? theme.colorScheme.primary
                            : theme.hintColor,
                      ),
                      iconSize: 22.0,
                      tooltip: text,
                      onPressed: () => home.setTab(index),
                    );
                  }),
                ]),
              ),
          ]),
        );
      },
    );
  }
}
