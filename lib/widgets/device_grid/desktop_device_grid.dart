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

part of 'device_grid.dart';

class DesktopDeviceGrid extends StatefulWidget {
  const DesktopDeviceGrid({Key? key, required this.width}) : super(key: key);

  final double width;

  @override
  State<DesktopDeviceGrid> createState() => _DesktopDeviceGridState();
}

class _DesktopDeviceGridState extends State<DesktopDeviceGrid> {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final mq = MediaQuery.of(context);

    final view = context.watch<DesktopViewProvider>();

    final children = [
      SizedBox(
        width: 180.0,
        child: Material(
          color: theme.appBarTheme.backgroundColor,
          child: ListView.builder(
            itemCount: ServersProvider.instance.servers.length,
            itemBuilder: (context, i) {
              final server = ServersProvider.instance.servers[i];
              return FutureBuilder(
                future: (() async => server.devices.isEmpty
                    ? API.instance.getDevices(
                        await API.instance.checkServerCredentials(server))
                    : true)(),
                builder: (context, snapshot) {
                  if (snapshot.hasData) {
                    return ListView.builder(
                      padding: const EdgeInsets.symmetric(vertical: 10.0) +
                          mq.viewPadding,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: server.devices.length + 1,
                      itemBuilder: (context, index) {
                        if (index == 0) return SubHeader(server.name);

                        index--;
                        final device = server.devices[index];
                        final selected = view.devices.contains(device);

                        return ListTile(
                          enabled: device.status,
                          selected: selected,
                          title: Row(children: [
                            Container(
                              height: 6.0,
                              width: 6.0,
                              margin:
                                  const EdgeInsetsDirectional.only(end: 8.0),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: device.status
                                    ? Colors.green.shade100
                                    : Colors.red,
                              ),
                            ),
                            Flexible(
                              child: Text(
                                device.name
                                    .split(' ')
                                    .map((e) =>
                                        e[0].toUpperCase() + e.substring(1))
                                    .join(' '),
                              ),
                            ),
                          ]),
                          // subtitle: Text(
                          //   '${device.resolutionX}x${device.resolutionY}',
                          // ),
                          onTap: () {
                            if (selected) {
                              DesktopViewProvider.instance.remove(device);
                            } else {
                              DesktopViewProvider.instance.add(device);
                            }
                          },
                        );
                      },
                    );
                  } else {
                    return Center(
                      child: Container(
                        alignment: AlignmentDirectional.center,
                        height: 156.0,
                        child: const CircularProgressIndicator(),
                      ),
                    );
                  }
                },
              );
            },
          ),
        ),
      ),
      Expanded(
        child: () {
          if (view.devices.isEmpty) {
            return const Center(
              child: Text(
                'Select a camera',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 12.0,
                ),
              ),
            );
          }

          final dl = view.devices.length;
          final crossAxisCount = dl == 1
              ? 1
              : dl <= 4
                  ? 2
                  : 3;

          return ReorderableGridView.count(
            physics: const NeverScrollableScrollPhysics(),
            shrinkWrap: true,
            crossAxisCount: crossAxisCount.clamp(1, 50),
            mainAxisSpacing: 4.0,
            crossAxisSpacing: 4.0,
            childAspectRatio: 16 / 9,
            padding: EdgeInsets.zero,
            onReorder: view.reorder,
            children: view.devices.asMap().entries.map((e) {
              final device = e.value;
              return DesktopDeviceTile(
                key: ValueKey('${e.value}.${e.value.server.serverUUID}'),
                device: device,
              );
            }).toList(),
            dragStartBehavior: DragStartBehavior.start,
          );
        }(),
      ),
    ];

    print(widget.width);

    if (widget.width <= 900) {
      return Row(children: children.reversed.toList());
    }

    return Row(children: children);
  }
}

class DesktopDeviceTile extends StatefulWidget {
  const DesktopDeviceTile({Key? key, required this.device}) : super(key: key);

  final Device device;

  @override
  State<DesktopDeviceTile> createState() => _DesktopDeviceTileState();
}

class _DesktopDeviceTileState extends State<DesktopDeviceTile> {
  BluecherryVideoPlayerController? videoPlayer;

  @override
  void initState() {
    super.initState();
    videoPlayer = DesktopViewProvider.instance.players[widget.device];
  }

  @override
  Widget build(BuildContext context) {
    if (videoPlayer == null) {
      return const Center(child: CircularProgressIndicator());
    }

    final mq = MediaQuery.of(context);

    return SizedBox(
      height: mq.size.height,
      child: BluecherryVideoPlayer(
        controller: videoPlayer!,
        paneBuilder: (context, controller, states) {
          if (controller.error != null) {
            return ErrorWarning(message: controller.error!);
          } else if ([
            FijkState.idle,
            FijkState.asyncPreparing,
          ].contains(controller.ijkPlayer?.state)) {
            return const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation(Colors.white),
                strokeWidth: 4.4,
              ),
            );
          } else {
            return ClipRect(
              child: Stack(children: [
                PositionedDirectional(
                  top: 0,
                  start: 0,
                  end: 0,
                  child: AnimatedSlide(
                    offset: Offset(0, !states.isHovering ? -1 : 0.0),
                    duration: const Duration(milliseconds: 200),
                    curve: Curves.easeInOut,
                    child: Container(
                      height: 48.0,
                      color: Colors.black26,
                      padding: const EdgeInsets.symmetric(horizontal: 10.0),
                      child: Row(children: [
                        const Spacer(),
                        IconButton(
                          onPressed: () {
                            DesktopViewProvider.instance.remove(widget.device);
                          },
                          tooltip: AppLocalizations.of(context).removeCamera,
                          icon: const Icon(Icons.close_outlined),
                          color: Colors.white,
                        ),
                        IconButton(
                          onPressed: () {
                            DesktopViewProvider.instance.reload(widget.device);
                          },
                          tooltip: AppLocalizations.of(context).reloadCamera,
                          icon: const Icon(Icons.replay_outlined),
                          color: Colors.white,
                        ),
                      ]),
                    ),
                  ),
                ),
                Container(
                  height: 48.0,
                  padding: const EdgeInsets.symmetric(horizontal: 10.0),
                  alignment: AlignmentDirectional.centerStart,
                  child: Text(
                    widget.device.name,
                    style: const TextStyle(
                      shadows: [
                        Shadow(
                          blurRadius: 2,
                          color: Colors.black,
                          offset: Offset(1, 1),
                        ),
                      ],
                    ),
                  ),
                ),
              ]),
            );
          }
        },
      ),
    );
  }
}
