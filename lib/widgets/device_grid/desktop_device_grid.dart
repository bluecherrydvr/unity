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

typedef FoldedDevices = List<List<Device>>;

class DesktopDeviceGrid extends StatefulWidget {
  const DesktopDeviceGrid({Key? key, required this.width}) : super(key: key);

  final double width;

  @override
  State<DesktopDeviceGrid> createState() => _DesktopDeviceGridState();
}

class _DesktopDeviceGridState extends State<DesktopDeviceGrid> {
  int calculateCrossAxisCount(int deviceAmount) {
    if (deviceAmount == 1) {
      return 1;
    } else if (deviceAmount <= 4) {
      return 2;
    } else {
      return 3;
    }
  }

  @override
  Widget build(BuildContext context) {
    final view = context.watch<DesktopViewProvider>();
    final children = [
      const DesktopSidebar(),
      Expanded(
        child: Material(
          color: Colors.black,
          child: SizedBox.expand(
            child: () {
              List<Device> devices = view.currentLayout.devices;

              if (devices.isEmpty) {
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

              final dl = devices.length;
              if (view.currentLayout.layoutType ==
                      DesktopLayoutType.compactView &&
                  dl >= 4) {
                FoldedDevices foldedDevices =
                    devices.reversed.fold<List<List<Device>>>(
                  [[]],
                  (collection, device) {
                    if (collection.last.length == 4) {
                      collection.add([device]);
                    } else {
                      collection.last.add(device);
                    }

                    return collection;
                  },
                );
                final crossAxisCount =
                    calculateCrossAxisCount(foldedDevices.length);

                final amountOfItemsOnScreen = crossAxisCount * crossAxisCount;

                // if there are space left on screen
                if (amountOfItemsOnScreen > foldedDevices.length) {
                  // final diff = amountOfItemsOnScreen - foldedDevices.length;
                  while (amountOfItemsOnScreen > foldedDevices.length) {
                    final lastFullFold =
                        foldedDevices.lastWhere((fold) => fold.length > 1);
                    final foldIndex = foldedDevices.indexOf(lastFullFold);
                    foldedDevices.insert(foldIndex + 1, [lastFullFold.last]);
                    lastFullFold.removeLast();
                  }
                }

                return ReorderableGridView.builder(
                  physics: const NeverScrollableScrollPhysics(),
                  shrinkWrap: true,
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: crossAxisCount,
                    mainAxisSpacing: kGridInnerPadding,
                    crossAxisSpacing: kGridInnerPadding,
                    childAspectRatio: 16 / 9,
                  ),
                  padding: const EdgeInsets.all(10.0),
                  onReorder: view.reorder,
                  itemCount: foldedDevices.length,
                  itemBuilder: (context, index) {
                    final fold = foldedDevices[index];

                    if (fold.length == 1) {
                      final device = fold.first;
                      return DesktopDeviceTile(
                        key: ValueKey('$device;${device.server.serverUUID}'),
                        device: device,
                      );
                    }

                    return DesktopCompactTile(
                      key: ValueKey('$fold;${fold.length}'),
                      devices: fold,
                    );
                  },
                );
              }

              final crossAxisCount = calculateCrossAxisCount(dl);

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
                itemCount: devices.length,
                itemBuilder: (context, index) {
                  final device = devices[index];

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

    return Container(
      height: mq.size.height,
      color: Colors.grey.shade900,
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
                widget.device.fullName,
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
                      icon: const Icon(Icons.open_in_new, shadows: shadows),
                      tooltip: 'Open in a new window',
                      color: Colors.white,
                      iconSize: 22.0,
                      onPressed: () {
                        widget.device.openInANewWindow();
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
