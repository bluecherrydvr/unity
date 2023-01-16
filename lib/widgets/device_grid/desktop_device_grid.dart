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
  /// Calculates how many views there will be in the grid view
  ///
  /// Basically, we take the square root of the provided [deviceAmount], and round
  /// it to the next number. We can do this because the grid displays only numbers
  /// that have an exact square root (1, 4, 9, etc).
  ///
  /// For example, if [deviceAmount] is between 17-25, the returned value is is 5
  int calculateCrossAxisCount(int deviceAmount) {
    return sqrt(deviceAmount).ceil();
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
              final devices = view.currentLayout.devices;

              if (devices.isEmpty) {
                return Center(
                  child: Text(
                    AppLocalizations.of(context).selectACamera,
                    style: const TextStyle(
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
                var foldedDevices = devices
                    .fold<List<List<Device>>>(
                      [[]],
                      (collection, device) {
                        if (collection.last.length == 4) {
                          collection.add([device]);
                        } else {
                          collection.last.add(device);
                        }

                        return collection;
                      },
                    )
                    .reversed
                    .toList();
                final crossAxisCount =
                    calculateCrossAxisCount(foldedDevices.length);

                final amountOfItemsOnScreen = crossAxisCount * crossAxisCount;

                // if there are space left on screen
                if (amountOfItemsOnScreen > foldedDevices.length) {
                  // final diff = amountOfItemsOnScreen - foldedDevices.length;
                  while (amountOfItemsOnScreen > foldedDevices.length) {
                    final lastFullFold =
                        foldedDevices.firstWhere((fold) => fold.length > 1);
                    final foldIndex = foldedDevices.indexOf(lastFullFold);
                    foldedDevices.insert(
                      (foldIndex - 1).clamp(0, foldedDevices.length).toInt(),
                      [lastFullFold.last],
                    );
                    lastFullFold.removeLast();
                  }
                }

                foldedDevices = foldedDevices.toList();

                return GridView.builder(
                  physics: const NeverScrollableScrollPhysics(),
                  shrinkWrap: true,
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: crossAxisCount,
                    mainAxisSpacing: kGridInnerPadding,
                    crossAxisSpacing: kGridInnerPadding,
                    childAspectRatio: 16 / 9,
                  ),
                  padding: const EdgeInsets.all(10.0),
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
  UnityVideoPlayer? videoPlayer;

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
      child: UnityVideoView(
        player: videoPlayer!,
        color: createTheme(themeMode: ThemeMode.dark).canvasColor,
        paneBuilder: (context, controller) {
          return DesktopTileViewport(
            controller: controller,
            device: widget.device,
          );
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

    final device1 = devices[0];
    final device2 = devices[1];

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

class DesktopTileViewport extends StatefulWidget {
  final UnityVideoPlayer controller;
  final Device device;

  /// Whether this viewport is in a sub view.
  ///
  /// Some features aren't allow in subview
  final bool isSubView;

  const DesktopTileViewport({
    Key? key,
    required this.controller,
    required this.device,
    this.isSubView = false,
  }) : super(key: key);

  @override
  State<DesktopTileViewport> createState() => _DesktopTileViewportState();
}

class _DesktopTileViewportState extends State<DesktopTileViewport> {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final view = context.watch<DesktopViewProvider>();

    if (widget.controller.error != null) {
      return ErrorWarning(message: widget.controller.error!);
    } else if (!widget.controller.isSeekable) {
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
        offset: Offset(-4, -4),
      ),
      Shadow(
        blurRadius: 10,
        offset: Offset(4, 4),
      ),
      Shadow(
        blurRadius: 10,
        offset: Offset(-4, 4),
      ),
      Shadow(
        blurRadius: 10,
        offset: Offset(4, -4),
      ),
    ];

    final foreground = HoverButton(
      onPressed: () {},
      builder: (context, states) {
        return Column(children: [
          if (!widget.isSubView)
            Container(
              height: 48.0,
              padding: const EdgeInsets.symmetric(horizontal: 12.0).add(
                const EdgeInsets.only(top: 8.0),
              ),
              alignment: AlignmentDirectional.centerStart,
              child: Row(children: [
                Expanded(
                  child: Text(
                    widget.device.fullName,
                    style: const TextStyle(
                      color: Colors.white,
                      shadows: shadows,
                    ),
                  ),
                ),
                if (!widget.isSubView)
                  AnimatedOpacity(
                    opacity: !states.isHovering ? 0 : 1,
                    duration: const Duration(milliseconds: 200),
                    curve: Curves.easeInOut,
                    child: IconButton(
                      icon: const Icon(
                        Icons.close_outlined,
                        shadows: shadows,
                      ),
                      color: Colors.white,
                      tooltip: AppLocalizations.of(context).removeCamera,
                      iconSize: 18.0,
                      onPressed: () {
                        DesktopViewProvider.instance.remove(widget.device);
                      },
                    ),
                  ),
              ]),
            ),
          const Spacer(),
          AnimatedOpacity(
            opacity: !states.isHovering ? 0 : 1,
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeInOut,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12.0)
                  .add(const EdgeInsets.only(bottom: 4.0)),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  FutureBuilder<double>(
                    future: widget.controller.volume,
                    initialData: 0.0,
                    builder: (context, snapshot) {
                      if (snapshot.hasData) {
                        final volume = snapshot.data!;
                        final isMuted = volume == 0.0;

                        return IconButton(
                          icon: Icon(
                            isMuted
                                ? Icons.volume_mute_rounded
                                : Icons.volume_up_rounded,
                            shadows: shadows,
                          ),
                          tooltip: isMuted
                              ? AppLocalizations.of(context).enableAudio
                              : AppLocalizations.of(context).disableAudio,
                          color: Colors.white,
                          iconSize: 18.0,
                          onPressed: () async {
                            if (isMuted) {
                              await widget.controller.setVolume(1.0);
                            } else {
                              await widget.controller.setVolume(0.0);
                            }

                            setState(() {});
                          },
                        );
                      }

                      return const SizedBox.shrink();
                    },
                  ),
                  const VerticalDivider(
                    color: Colors.white,
                    indent: 10,
                    endIndent: 10,
                  ),
                  if (isDesktop && !widget.isSubView)
                    IconButton(
                      icon: const Icon(
                        Icons.open_in_new,
                        shadows: shadows,
                      ),
                      tooltip: AppLocalizations.of(context).openInANewWindow,
                      color: Colors.white,
                      iconSize: 18.0,
                      onPressed: () {
                        widget.device.openInANewWindow();
                      },
                    ),
                  if (!widget.isSubView)
                    IconButton(
                      icon: const Icon(
                        Icons.fullscreen_rounded,
                        shadows: shadows,
                      ),
                      tooltip:
                          AppLocalizations.of(context).showFullscreenCamera,
                      color: Colors.white,
                      iconSize: 18.0,
                      onPressed: () async {
                        var player = view.players[widget.device];
                        var isLocalController = false;
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
                    iconSize: 18.0,
                    onPressed: () {
                      DesktopViewProvider.instance.reload(widget.device);
                    },
                  ),
                ],
              ),
            ),
          ),
        ]);
      },
    );

    return TooltipTheme(
      data: TooltipTheme.of(context).copyWith(
        preferBelow: false,
        verticalOffset: 20.0,
        decoration: BoxDecoration(
          color: theme.brightness == Brightness.light
              ? Colors.black
              : Colors.white,
          borderRadius: isMobile
              ? BorderRadius.circular(16.0)
              : BorderRadius.circular(6.0),
        ),
      ),
      child: foreground,
    );
  }
}
