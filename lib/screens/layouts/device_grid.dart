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
import 'dart:math';

import 'package:animations/animations.dart';
import 'package:auto_size_text/auto_size_text.dart';
import 'package:bluecherry_client/models/device.dart';
import 'package:bluecherry_client/models/layout.dart';
import 'package:bluecherry_client/models/server.dart';
import 'package:bluecherry_client/providers/home_provider.dart';
import 'package:bluecherry_client/providers/layouts_provider.dart';
import 'package:bluecherry_client/providers/mobile_view_provider.dart';
import 'package:bluecherry_client/providers/server_provider.dart';
import 'package:bluecherry_client/providers/settings_provider.dart';
import 'package:bluecherry_client/screens/layouts/desktop/device_info_dialog.dart';
import 'package:bluecherry_client/screens/layouts/desktop/external_stream.dart';
import 'package:bluecherry_client/screens/layouts/desktop/layout_manager.dart';
import 'package:bluecherry_client/screens/layouts/desktop/viewport.dart';
import 'package:bluecherry_client/screens/layouts/mobile/device_view.dart';
import 'package:bluecherry_client/screens/multi_window/window.dart';
import 'package:bluecherry_client/utils/app_links/app_links.dart' as app_links;
import 'package:bluecherry_client/utils/constants.dart';
import 'package:bluecherry_client/utils/extensions.dart';
import 'package:bluecherry_client/utils/keyboard.dart';
import 'package:bluecherry_client/utils/methods.dart';
import 'package:bluecherry_client/utils/theme.dart';
import 'package:bluecherry_client/utils/video_player.dart';
import 'package:bluecherry_client/utils/window.dart';
import 'package:bluecherry_client/widgets/collapsable_sidebar.dart';
import 'package:bluecherry_client/widgets/drawer_button.dart';
import 'package:bluecherry_client/widgets/misc.dart';
import 'package:bluecherry_client/widgets/reorderable_static_grid.dart';
import 'package:bluecherry_client/widgets/squared_icon_button.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:provider/provider.dart';
import 'package:sliver_tools/sliver_tools.dart';

part 'desktop/layout_view.dart';
part 'desktop/sidebar.dart';
part 'mobile/mobile_device_grid.dart';

const double kMobileBottomBarHeight = 48.0;

class DeviceGrid extends StatelessWidget {
  const DeviceGrid({super.key});

  @override
  Widget build(BuildContext context) {
    final hasDrawer = Scaffold.hasDrawer(context);

    return Material(
      type: MaterialType.transparency,
      child: LayoutBuilder(builder: (context, consts) {
        final width = consts.biggest.width;

        if (hasDrawer || width < kMobileBreakpoint.width) {
          return const SmallDeviceGrid();
        } else {
          return LargeDeviceGrid(width: width);
        }
      }),
    );
  }
}
