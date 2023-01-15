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
import 'dart:math';

import 'package:animations/animations.dart';
import 'package:bluecherry_client/api/api.dart';
import 'package:bluecherry_client/models/device.dart';
import 'package:bluecherry_client/models/layout.dart';
import 'package:bluecherry_client/providers/desktop_view_provider.dart';
import 'package:bluecherry_client/providers/mobile_view_provider.dart';
import 'package:bluecherry_client/providers/server_provider.dart';
import 'package:bluecherry_client/utils/extensions.dart';
import 'package:bluecherry_client/utils/methods.dart';
import 'package:bluecherry_client/utils/theme.dart';
import 'package:bluecherry_client/utils/window.dart';
import 'package:bluecherry_client/widgets/device_grid/layout_manager.dart';
import 'package:bluecherry_client/widgets/device_tile_selector.dart';
import 'package:bluecherry_client/widgets/error_warning.dart';
import 'package:bluecherry_client/widgets/hover_button.dart';
import 'package:bluecherry_client/widgets/misc.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:provider/provider.dart';
import 'package:reorderable_grid_view/reorderable_grid_view.dart';
import 'package:unity_video_player/unity_video_player.dart';

part 'desktop_device_grid.dart';
part 'desktop_sidebar.dart';
part 'mobile_device_grid.dart';

const double kMobileBottomBarHeight = 48.0;

class DeviceGrid extends StatelessWidget {
  const DeviceGrid({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Material(
      type: MaterialType.transparency,
      child: LayoutBuilder(builder: (context, consts) {
        final width = consts.biggest.width;

        if (width >= 800) {
          return DesktopDeviceGrid(width: width);
        } else {
          return const MobileDeviceGrid();
        }
      }),
    );
  }
}
