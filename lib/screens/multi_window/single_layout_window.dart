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

import 'package:bluecherry_client/models/layout.dart';
import 'package:bluecherry_client/screens/layouts/device_grid.dart';
import 'package:bluecherry_client/widgets/desktop_buttons.dart';
import 'package:flutter/material.dart';

class AlternativeLayoutView extends StatelessWidget {
  const AlternativeLayoutView({super.key, required this.layout});

  final Layout layout;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.black,
      child: SafeArea(
        child: Column(
          children: [
            WindowButtons(title: layout.name, showNavigator: false),
            Expanded(child: LayoutView(layout: layout)),
          ],
        ),
      ),
    );
  }
}
