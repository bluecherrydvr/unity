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

import 'package:bluecherry_client/providers/downloads.dart';
import 'package:bluecherry_client/widgets/downloads_manager/desktop_downloads_manager.dart';
import 'package:bluecherry_client/widgets/downloads_manager/mobile_downloads_manager.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class DownloadsManagerScreen extends StatelessWidget {
  const DownloadsManagerScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final downloads = context.watch<DownloadsManager>();

    return Scaffold(
      body: LayoutBuilder(builder: (context, consts) {
        final width = consts.biggest.width;

        if (downloads.downloadedEvents.isEmpty &&
            downloads.downloading.isEmpty) {
          return const Center(
            child: Text('You have no downloads'),
          );
        }

        if (width >= 800) {
          return const DesktopDownloadsManager();
        } else {
          return const MobileDownloadsManager();
        }
      }),
    );
  }
}
