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

const kGridInnerPadding = 8.0;

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
      ConstrainedBox(
        constraints: const BoxConstraints(
          maxWidth: 220.0,
        ),
        child: Material(
          color: theme.canvasColor,
          child: Column(children: [
            const LayoutManager(),
            Expanded(
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
                            final selected =
                                view.currentLayout.devices.contains(device);

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
          ]),
        ),
      ),
      Expanded(
        child: Material(
          color: Colors.black,
          child: SizedBox.expand(
            child: () {
              if (view.currentLayout.devices.isEmpty) {
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

              final dl = view.currentLayout.devices.length;

              if (view.currentLayout.layoutType ==
                      DesktopLayoutType.compactView &&
                  dl > 4) {
                return ReorderableGridView.builder(
                  physics: const NeverScrollableScrollPhysics(),
                  shrinkWrap: true,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    mainAxisSpacing: kGridInnerPadding,
                    crossAxisSpacing: kGridInnerPadding,
                    childAspectRatio: 16 / 9,
                  ),
                  padding: const EdgeInsets.all(10.0),
                  onReorder: view.reorder,
                  itemCount: 4,
                  itemBuilder: (context, index) {
                    final device = view.currentLayout.devices[index];

                    if (index == 3) {
                      final devices = view.currentLayout.devices.sublist(3);

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
                  mainAxisSpacing: kGridInnerPadding,
                  crossAxisSpacing: kGridInnerPadding,
                  childAspectRatio: 16 / 9,
                ),
                padding: const EdgeInsets.all(10.0),
                onReorder: view.reorder,
                itemCount: view.currentLayout.devices.length,
                itemBuilder: (context, index) {
                  final device = view.currentLayout.devices[index];

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
    final view = context.watch<DesktopViewProvider>();

    return SizedBox(
      height: mq.size.height,
      child: BluecherryVideoPlayer(
        controller: videoPlayer!,
        color: Colors.grey.shade900,
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
          }

          const shadows = [
            Shadow(
              blurRadius: 10,
              color: Colors.black,
              offset: Offset(-4, -4),
            ),
            Shadow(
              blurRadius: 10,
              color: Colors.black,
              offset: Offset(4, 4),
            ),
            Shadow(
              blurRadius: 10,
              color: Colors.black,
              offset: Offset(-4, 4),
            ),
            Shadow(
              blurRadius: 10,
              color: Colors.black,
              offset: Offset(4, -4),
            ),
          ];
          return Column(children: [
            Container(
              height: 48.0,
              padding: const EdgeInsets.symmetric(horizontal: 12.0),
              alignment: AlignmentDirectional.centerStart,
              child: Text(
                '${widget.device.server.name} / ${widget.device.name}',
                style: const TextStyle(
                  color: Colors.white,
                  shadows: shadows,
                ),
              ),
            ),
            const Spacer(),
            AnimatedOpacity(
              opacity: !states.isHovering ? 0 : 1,
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeInOut,
              child: Container(
                height: 48.0,
                padding: const EdgeInsets.symmetric(horizontal: 12.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    IconButton(
                      icon: const Icon(
                        Icons.replay_outlined,
                        shadows: shadows,
                      ),
                      tooltip: AppLocalizations.of(context).reloadCamera,
                      color: Colors.white,
                      iconSize: 20.0,
                      onPressed: () {
                        DesktopViewProvider.instance.reload(widget.device);
                      },
                    ),
                    IconButton(
                      icon: const Icon(
                        Icons.fullscreen_rounded,
                        shadows: shadows,
                      ),
                      tooltip:
                          AppLocalizations.of(context).showFullscreenCamera,
                      color: Colors.white,
                      iconSize: 22.0,
                      onPressed: () async {
                        var player = view.players[widget.device];
                        bool isLocalController = false;
                        if (player == null) {
                          player =
                              getVideoPlayerControllerForDevice(widget.device);
                          isLocalController = true;
                        }

                        await Navigator.of(context).pushNamed(
                          '/fullscreen',
                          arguments: {
                            'device': widget.device,
                            'player': player,
                          },
                        );
                        if (isLocalController) await player.release();
                      },
                    ),
                    const VerticalDivider(
                      color: Colors.white,
                      indent: 10,
                      endIndent: 10,
                    ),
                    IconButton(
                      icon: const Icon(
                        Icons.close_outlined,
                        shadows: shadows,
                      ),
                      color: Colors.white,
                      tooltip: AppLocalizations.of(context).removeCamera,
                      iconSize: 20.0,
                      onPressed: () {
                        DesktopViewProvider.instance.remove(widget.device);
                      },
                    ),
                  ],
                ),
              ),
            ),
          ]);
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
          const SizedBox(width: kGridInnerPadding),
          Expanded(child: DesktopDeviceTile(device: device2)),
        ]),
      ),
      const SizedBox(height: kGridInnerPadding),
      Expanded(
        child: Row(children: [
          Expanded(
            child: devices.length >= 3
                ? DesktopDeviceTile(device: devices[2])
                : const SizedBox.shrink(),
          ),
          const SizedBox(width: kGridInnerPadding),
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

        const EdgeInsets padding = EdgeInsets.symmetric(horizontal: 16.0);

        final renderBox = context.findRenderObject() as RenderBox;
        final offset = renderBox.localToGlobal(Offset(
          padding.left,
          padding.top,
        ));
        final size = Size(
          renderBox.size.width - padding.right * 2,
          renderBox.size.height - padding.bottom,
        );

        showMenu(
          context: context,
          elevation: 4.0,
          position: RelativeRect.fromLTRB(
            offset.dx,
            offset.dy,
            offset.dx + size.width,
            offset.dy + size.height,
          ),
          constraints: BoxConstraints(
            maxWidth: size.width,
            minWidth: size.width,
          ),
          items: <PopupMenuEntry>[
            PopupMenuItem(
              // TODO: localization
              child: Text(selected ? 'Remove from view' : 'Add to view'),
              onTap: () {
                if (selected) {
                  view.remove(device);
                } else {
                  view.add(device);
                }
              },
            ),
            const PopupMenuDivider(height: 8),
            PopupMenuItem(
              child: const Text(
                // TODO: localization
                // AppLocalizations.of(context).showFullscreenCamera,
                'Show in full screen',
              ),
              onTap: () async {
                WidgetsBinding.instance.addPostFrameCallback((timeStamp) async {
                  var player = view.players[device];
                  bool isLocalController = false;
                  if (player == null) {
                    player = getVideoPlayerControllerForDevice(device);
                    isLocalController = true;
                  }

                  await Navigator.of(context).pushNamed(
                    '/fullscreen',
                    arguments: {
                      'device': device,
                      'player': player,
                    },
                  );
                  if (isLocalController) await player.release();
                });
              },
            ),
          ],
        );
      },
      child: ListTile(
        enabled: device.status,
        selected: selected,
        dense: true,
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
                  // uppercase all first
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
