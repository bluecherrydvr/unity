/*
 * This file is a part of Bluecherry Client (https://https://github.com/bluecherrydvr/bluecherry_client).
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
import 'package:easy_localization/easy_localization.dart';

import 'package:bluecherry_client/providers/mobile_view_provider.dart';
import 'package:bluecherry_client/models/device.dart';
import 'package:bluecherry_client/widgets/device_selector_screen.dart';
import 'package:bluecherry_client/widgets/device_tile.dart';

class DeviceTileSelector extends StatefulWidget {
  final int tab;
  final int index;

  const DeviceTileSelector({
    Key? key,
    required this.tab,
    required this.index,
  }) : super(key: key);

  @override
  State<DeviceTileSelector> createState() => _DeviceTileSelectorState();
}

class _DeviceTileSelectorState extends State<DeviceTileSelector> {
  Device? device;

  @override
  Widget build(BuildContext context) {
    final view = MobileViewProvider.instance;
    device ??= view.devices[widget.tab]![widget.index];
    return device != null
        ? Material(
            child: Stack(
              children: [
                DeviceTile(
                  device: device!,
                  ijkPlayer: view.players[device],
                ),
                Positioned(
                  top: 0.0,
                  right: 0.0,
                  child: Container(
                    height: 72.0,
                    width: 72.0,
                    decoration: const BoxDecoration(
                      color: Colors.black,
                      gradient: LinearGradient(
                        colors: [
                          Colors.black54,
                          Colors.transparent,
                        ],
                        begin: Alignment.topRight,
                        end: Alignment.bottomLeft,
                        stops: [
                          0.0,
                          0.6,
                        ],
                      ),
                    ),
                  ),
                ),
                PopupMenuButton<int>(
                  elevation: 4.0,
                  onSelected: (value) async {
                    switch (value) {
                      case 0:
                        {
                          view.remove(widget.tab, widget.index);
                          if (mounted) {
                            setState(() {
                              device = null;
                            });
                          }
                          break;
                        }
                      case 1:
                        {
                          final result = await Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) =>
                                  const DeviceSelectorScreen(),
                            ),
                          );
                          if (result is Device) {
                            view.replace(widget.tab, widget.index, result);
                            if (mounted) {
                              setState(() {
                                device = result;
                              });
                            }
                          }
                          break;
                        }
                    }
                  },
                  icon: const Icon(
                    Icons.more_vert,
                    color: Colors.white,
                  ),
                  itemBuilder: (_) => [
                    PopupMenuItem(
                      value: 0,
                      padding: EdgeInsets.zero,
                      child: ListTile(
                        leading: CircleAvatar(
                          child: const Icon(Icons.close),
                          backgroundColor: Colors.transparent,
                          foregroundColor: Theme.of(context).iconTheme.color,
                        ),
                        title: Text('remove_camera'.tr()),
                      ),
                    ),
                    PopupMenuItem(
                      value: 1,
                      padding: EdgeInsets.zero,
                      child: ListTile(
                        leading: CircleAvatar(
                          child: const Icon(Icons.replay),
                          backgroundColor: Colors.transparent,
                          foregroundColor: Theme.of(context).iconTheme.color,
                        ),
                        title: Text('replace_camera'.tr()),
                      ),
                    ),
                  ],
                ),
              ],
              alignment: Alignment.topRight,
            ),
          )
        : SizedBox(
            width: double.infinity,
            height: double.infinity,
            child: Material(
              elevation: 4.0,
              borderRadius: BorderRadius.zero,
              color: Colors.black,
              child: InkWell(
                onTap: () async {
                  final result = await Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => const DeviceSelectorScreen(),
                    ),
                  );
                  if (result is Device) {
                    view.add(widget.tab, widget.index, result);
                    if (mounted) {
                      setState(() {
                        device = result;
                      });
                    }
                  }
                },
                child: Container(
                  alignment: Alignment.center,
                  child: const Icon(
                    Icons.add,
                    size: 36.0,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          );
  }
}
