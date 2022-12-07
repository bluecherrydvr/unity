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

import 'package:flutter/material.dart';
import 'package:window_manager/window_manager.dart';

class WindowButtons extends StatelessWidget {
  const WindowButtons({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    print(theme.appBarTheme.backgroundColor);

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
        SizedBox(
          width: 138,
          height: 30,
          child: WindowCaption(
            brightness: theme.brightness,
            backgroundColor: Colors.transparent,
          ),
        ),
      ]),
      // child: DragToMoveArea(
      // ),
    );
  }
}
