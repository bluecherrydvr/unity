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
import 'package:bluecherry_client/providers/mobile_view_provider.dart';
import 'package:bluecherry_client/providers/server_provider.dart';
import 'package:flutter/material.dart';
import 'package:fijkplayer/fijkplayer.dart';

import 'package:bluecherry_client/models/device.dart';
import 'package:bluecherry_client/widgets/device_selector_screen.dart';
import 'package:bluecherry_client/widgets/device_tile.dart';

class DeviceTileSelector extends StatefulWidget {
  final int tab;
  final int index;
  final Map<Device, FijkPlayer> players;
  const DeviceTileSelector({
    Key? key,
    required this.tab,
    required this.index,
    required this.players,
  }) : super(key: key);

  @override
  State<DeviceTileSelector> createState() => _DeviceTileSelectorState();
}

class _DeviceTileSelectorState extends State<DeviceTileSelector>
    with AutomaticKeepAliveClientMixin {
  Device? device;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    device ??= MobileViewProvider.instance.devices[widget.tab]![widget.index];
    return device != null
        ? DeviceTile(
            device: device!,
            ijkPlayer: widget.players[device],
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
                    debugPrint(result.toString());
                    debugPrint(result
                        .streamURL(ServersProvider.instance.servers.first));
                    widget.players[result] = FijkPlayer()
                      ..setDataSource(
                        result.streamURL(
                          /// TODO: Currently only single server is implemented.
                          ServersProvider.instance.servers.first,
                        ),
                        autoPlay: true,
                      )
                      ..setVolume(0.0)
                      ..setSpeed(1.0);
                    MobileViewProvider.instance
                        .edit(widget.tab, widget.index, result);
                    setState(() {
                      device = result;
                    });
                  }
                },
                child: Container(
                  alignment: Alignment.center,
                  child: const Icon(
                    Icons.add,
                    size: 36.0,
                  ),
                ),
              ),
            ),
          );
  }

  @override
  bool get wantKeepAlive => true;
}
