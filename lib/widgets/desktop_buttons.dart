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

import 'package:bluecherry_client/providers/desktop_view_provider.dart';
import 'package:bluecherry_client/providers/home_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:window_manager/window_manager.dart';

class WindowButtons extends StatelessWidget {
  const WindowButtons({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final tab = context.watch<HomeProvider>().tab;

    return Material(
      elevation: 0.0,
      color: theme.appBarTheme.backgroundColor,
      child: Row(children: [
        const Expanded(
          child: DragToMoveArea(
            child: Padding(
              padding: EdgeInsetsDirectional.only(start: 16.0),
              child: Text('Bluecherry'),
            ),
          ),
        ),

        // if it's the grid tab
        if (tab == 0)
          const Padding(
            padding: EdgeInsetsDirectional.only(end: 8.0),
            child: _GridLayout(),
          ),
        SizedBox(
          width: 138,
          height: 30,
          child: WindowCaption(
            brightness: theme.brightness,
            backgroundColor: Colors.transparent,
          ),
        ),
      ]),
    );
  }
}

class _GridLayout extends StatelessWidget {
  const _GridLayout({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final desktop = context.watch<DesktopViewProvider>();

    return Row(
      children: DesktopLayoutType.values.map((type) {
        final selected = desktop.layoutType == type;

        return IconButton(
          icon: Icon(iconForLayout(type)),
          iconSize: 18.0,
          color: selected ? theme.primaryColor : null,
          onPressed: () async {
            desktop.setLayoutType(type);
          },
        );
      }).toList(),
    );
  }

  IconData iconForLayout(DesktopLayoutType type) {
    switch (type) {
      case DesktopLayoutType.singleView:
        return Icons.square;
      case DesktopLayoutType.multipleView:
        return Icons.view_comfy_outlined;
      case DesktopLayoutType.compactView:
        return Icons.view_compact;
    }
  }
}
