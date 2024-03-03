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

import 'package:bluecherry_client/screens/settings/settings_desktop.dart';
import 'package:bluecherry_client/screens/settings/settings_mobile.dart';
import 'package:bluecherry_client/utils/constants.dart';
import 'package:flutter/material.dart';

class Settings extends StatelessWidget {
  const Settings({super.key});

  @override
  Widget build(BuildContext context) {
    final hasDrawer = Scaffold.hasDrawer(context);

    return Material(
      type: MaterialType.transparency,
      child: LayoutBuilder(builder: (context, consts) {
        final width = consts.biggest.width;

        if (hasDrawer || width < kMobileBreakpoint.width) {
          return const MobileSettings();
        } else {
          return const DesktopSettings();
        }
      }),
    );
  }
}
