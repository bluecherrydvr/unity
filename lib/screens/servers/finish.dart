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

import 'package:bluecherry_client/l10n/generated/app_localizations.dart';
import 'package:bluecherry_client/models/server.dart';
import 'package:bluecherry_client/screens/layouts/device_grid.dart';
import 'package:bluecherry_client/utils/constants.dart';
import 'package:bluecherry_client/utils/extensions.dart';
import 'package:flutter/material.dart';

class LetsGoScreen extends StatelessWidget {
  final VoidCallback onBack;
  final Server? server;
  final VoidCallback onFinish;

  const LetsGoScreen({
    super.key,
    required this.onBack,
    required this.server,
    required this.onFinish,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final loc = AppLocalizations.of(context);

    final addedCard = Card(
      elevation: 4.0,
      margin: const EdgeInsetsDirectional.only(bottom: 8.0),
      color: Color.alphaBlend(
        Colors.green.withValues(alpha: 0.2),
        theme.cardColor,
      ),
      child: Padding(
        padding: const EdgeInsetsDirectional.all(16.0),
        child: Row(
          children: [
            Icon(Icons.check, color: Colors.green.shade400),
            const SizedBox(width: 16.0),
            Expanded(child: Text(loc.serverAdded)),
          ],
        ),
      ),
    );

    final tipsCard = Card(
      elevation: 4.0,
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsetsDirectional.all(16.0),
        child: SelectionArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                loc.letsGoDescription,
                style: theme.textTheme.headlineMedium,
              ),
              ...[loc.tip0, loc.tip1, loc.tip2, loc.tip3].map((tip) {
                return Padding(
                  padding: const EdgeInsetsDirectional.only(top: 8.0),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(' • '),
                      const SizedBox(width: 4.0),
                      Expanded(child: Text(tip)),
                    ],
                  ),
                );
              }),
            ],
          ),
        ),
      ),
    );

    final finishButton = Align(
      alignment: AlignmentDirectional.centerEnd,
      child: FloatingActionButton.extended(
        onPressed: onFinish,
        label: Text(loc.finish.toUpperCase()),
        icon: const Icon(Icons.check),
      ),
    );

    return LayoutBuilder(
      builder: (context, consts) {
        if (consts.maxWidth < kMobileBreakpoint.width) {
          return PopScope(
            canPop: false,
            child: ListView(
              padding: const EdgeInsetsDirectional.all(24.0),
              children: [
                SizedBox(
                  height: consts.maxHeight * 0.875,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (server != null) addedCard,
                      tipsCard,
                      const SizedBox(height: 8.0),
                      finishButton,
                      const SizedBox(height: 12.0),
                    ],
                  ),
                ),
                Card(
                  child: Padding(
                    padding: const EdgeInsetsDirectional.symmetric(vertical: 8),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children:
                          server!.devices.sorted().map((device) {
                            return DeviceSelectorTile(
                              device: device,
                              selected: false,
                              selectable: false,
                            );
                          }).toList(),
                    ),
                  ),
                ),
              ],
            ),
          );
        } else {
          return PopScope(
            canPop: false,
            child: IntrinsicWidth(
              child: Container(
                margin: const EdgeInsetsDirectional.all(16.0),
                constraints: BoxConstraints(
                  minWidth: MediaQuery.sizeOf(context).width / 2.5,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          if (server != null) addedCard,
                          tipsCard,
                          const SizedBox(height: 8.0),
                          finishButton,
                        ],
                      ),
                    ),
                    if (server != null && server!.devices.isNotEmpty) ...[
                      const SizedBox(width: 16.0),
                      SizedBox(
                        width: kSidebarConstraints.maxWidth,
                        child: Card(
                          child: SingleChildScrollView(
                            padding: const EdgeInsetsDirectional.symmetric(
                              vertical: 8,
                            ),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children:
                                  server!.devices.sorted().map((device) {
                                    return DeviceSelectorTile(
                                      device: device,
                                      selected: false,
                                      selectable: false,
                                    );
                                  }).toList(),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          );
        }
      },
    );
  }
}
