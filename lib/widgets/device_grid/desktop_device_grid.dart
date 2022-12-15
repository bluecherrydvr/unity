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
          color: theme.canvasColor,
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

                        return DesktopDeviceSelectorTile(
                          device: device,
                          selected: selected,
                        );
                      },
                    );
                  } else {
                    return Center(
                      child: Container(
                        alignment: AlignmentDirectional.center,
                        height: 156.0,
                        child: const CircularProgressIndicator.adaptive(),
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
        child: Material(
          color: Colors.black,
          child: SizedBox.expand(
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

              if (view.layoutType == DesktopLayoutType.compactView && dl > 4) {
                return ReorderableGridView.builder(
                  physics: const NeverScrollableScrollPhysics(),
                  shrinkWrap: true,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    mainAxisSpacing: 4.0,
                    crossAxisSpacing: 4.0,
                    childAspectRatio: 16 / 9,
                  ),
                  onReorder: view.reorder,
                  itemCount: 4,
                  itemBuilder: (context, index) {
                    final device = view.devices[index];

                    if (index == 3) {
                      final devices = view.devices.sublist(3);
                      return DesktopCompactTile(
                        key: ValueKey('$devices.${devices.length}'),
                        devices: devices,
                      );
                    }

                    return DesktopDeviceTile(
                      key: ValueKey('$device.${device.server.serverUUID}'),
                      device: device,
                    );
                  },
                );
              }

              final crossAxisCount = dl == 1
                  ? 1
                  : dl <= 4
                      ? 2
                      : 3;

              return ReorderableGridView.builder(
                physics: const NeverScrollableScrollPhysics(),
                shrinkWrap: true,
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: crossAxisCount.clamp(1, 50),
                  mainAxisSpacing: 4.0,
                  crossAxisSpacing: 4.0,
                  childAspectRatio: 16 / 9,
                ),
                onReorder: view.reorder,
                itemCount: view.devices.length,
                itemBuilder: (context, index) {
                  final device = view.devices[index];

                  return DesktopDeviceTile(
                    key: ValueKey('$device.${device.server.serverUUID}'),
                    device: device,
                  );
                },
              );
            }(),
          ),
        ),
      ),
    ];

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

class DesktopCompactTile extends StatelessWidget {
  const DesktopCompactTile({
    Key? key,
    required this.devices,
  })  : assert(devices.length >= 2 && devices.length <= 4),
        super(key: key);

  final List<Device> devices;

  @override
  Widget build(BuildContext context) {
    if (devices.isEmpty) return const SizedBox.shrink();

    final Device device1 = devices[0];
    final Device device2 = devices[1];

    return Column(children: [
      Expanded(
        child: Row(children: [
          Expanded(child: DesktopDeviceTile(device: device1)),
          Expanded(child: DesktopDeviceTile(device: device2)),
        ]),
      ),
      Expanded(
        child: Row(children: [
          Expanded(
            child: devices.length >= 3
                ? DesktopDeviceTile(device: devices[2])
                : const SizedBox.shrink(),
          ),
          Expanded(
            child: devices.length == 4
                ? DesktopDeviceTile(device: devices[3])
                : const SizedBox.shrink(),
          ),
        ]),
      ),
    ]);
  }
}

class DesktopDeviceSelectorTile extends StatelessWidget {
  const DesktopDeviceSelectorTile({
    Key? key,
    required this.device,
    required this.selected,
  }) : super(key: key);

  final Device device;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    MediaQuery.of(context);
    final view = context.watch<DesktopViewProvider>();

    return GestureDetector(
      onSecondaryTap: () {
        if (!device.status) return;

        final renderBox = context.findRenderObject() as RenderBox;
        final offset = renderBox.localToGlobal(const Offset(8, 0));
        final size = renderBox.size;

        showMenu(
          context: context,
          elevation: 4.0,
          items: [
            if (selected)
              PopupMenuItem(
                child: const Text('Remove from view'),
                onTap: () {
                  view.remove(device);
                },
              )
            else
              PopupMenuItem(
                child: const Text('Add to view'),
                onTap: () {
                  view.add(device);
                },
              ),
            PopupMenuItem(
              child: const Text('Open in full screen'),
              onTap: () {
                print(Navigator.of(context));
                // Navigator.pop(context);
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (context) {
                    final player = view.players[device] ??
                        getVideoPlayerControllerForDevice(device);

                    return DeviceFullscreenViewer(
                      device: device,
                      videoPlayerController: player,
                      restoreStatusBarStyleOnDispose: true,
                    );
                  }),
                );
              },
            ),
          ],
          position: RelativeRect.fromLTRB(
            offset.dx,
            offset.dy,
            offset.dx + size.width,
            offset.dy + size.height,
          ),
        );
      },
      child: ListTile(
        enabled: device.status,
        selected: selected,
        title: Row(children: [
          Container(
            height: 6.0,
            width: 6.0,
            margin: const EdgeInsetsDirectional.only(end: 8.0),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: device.status ? Colors.green.shade100 : Colors.red,
            ),
          ),
          Flexible(
            child: Text(
              device.name
                  .split(' ')
                  .map((e) => e[0].toUpperCase() + e.substring(1))
                  .join(' '),
            ),
          ),
        ]),
        onTap: () {
          if (selected) {
            DesktopViewProvider.instance.remove(device);
          } else {
            DesktopViewProvider.instance.add(device);
          }
        },
      ),
    );
  }
}
