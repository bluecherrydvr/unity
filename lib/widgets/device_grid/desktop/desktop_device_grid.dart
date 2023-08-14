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

part of '../device_grid.dart';

typedef FoldedDevices = List<List<Device>>;

class DesktopDeviceGrid extends StatefulWidget {
  const DesktopDeviceGrid({super.key, required this.width});

  final double width;

  @override
  State<DesktopDeviceGrid> createState() => _DesktopDeviceGridState();
}

/// Calculates how many views there will be in the grid view
///
/// Basically, we take the square root of the provided [deviceAmount], and round
/// it to the next number. We can do this because the grid displays only numbers
/// that have an exact square root (1, 4, 9, etc).
///
/// For example, if [deviceAmount] is between 17-25, the returned value is is 5
int calculateCrossAxisCount(int deviceAmount) {
  final count = sqrt(deviceAmount).ceil();

  if (count == 0) return 1;

  return count;
}

class _DesktopDeviceGridState extends State<DesktopDeviceGrid> {
  @override
  Widget build(BuildContext context) {
    final view = context.watch<DesktopViewProvider>();
    final isReversed = widget.width <= 900;

    final children = [
      CollapsableSidebar(
        left: !isReversed,
        builder: (context, collapseButton) {
          return DesktopSidebar(collapseButton: collapseButton);
        },
      ),
      Expanded(
        child: LayoutView(
          layout: view.currentLayout,
          onAccept: view.add,
          onReorder: view.reorder,
          onWillAccept: (device) {
            if (device == null) return false;
            if (view.currentLayout.type == DesktopLayoutType.singleView) {
              return view.currentLayout.devices.isEmpty;
            }
            return !view.currentLayout.devices.contains(device);
          },
        ),
      ),
    ];

    return Row(children: isReversed ? children.reversed.toList() : children);
  }
}

class LayoutView extends StatelessWidget {
  const LayoutView({
    super.key,
    required this.layout,
    this.onAccept,
    this.onWillAccept,
    this.onReorder,
  });

  final Layout layout;

  final ValueChanged<Device>? onAccept;
  final DragTargetWillAccept<Device>? onWillAccept;
  final ReorderCallback? onReorder;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final loc = AppLocalizations.of(context);

    return DragTarget<Device>(
      onAccept: onAccept,
      onWillAccept: onWillAccept,
      builder: (context, candidateItems, rejectedItems) {
        late Widget child;

        final devices = <Device>[
          ...layout.devices,
          ...candidateItems.whereType<Device>(),
        ];
        final dl = devices.length;

        if (rejectedItems.isNotEmpty) {
          child = ColoredBox(
            color: theme.colorScheme.errorContainer,
            child: Center(
              child: Icon(
                Icons.block,
                size: 48.0,
                color: theme.colorScheme.onErrorContainer,
              ),
            ),
          );
        } else if (devices.isEmpty) {
          child = Center(
            child: Text(
              loc.selectACamera,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 12.0,
              ),
            ),
          );
        } else if (dl == 1) {
          final device = devices.first;
          child = Padding(
            key: ValueKey(layout.hashCode),
            padding: kGridPadding,
            child: AspectRatio(
              aspectRatio: 16 / 9,
              child: DesktopDeviceTile(device: device),
            ),
          );
        } else if (layout.type == DesktopLayoutType.compactView && dl >= 4) {
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
          final crossAxisCount = calculateCrossAxisCount(foldedDevices.length);

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

          child = AbsorbPointer(
            absorbing: candidateItems.isNotEmpty,
            child: GridView.builder(
              key: ValueKey(layout.hashCode),
              physics: const NeverScrollableScrollPhysics(),
              shrinkWrap: true,
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: crossAxisCount,
                mainAxisSpacing: kGridInnerPadding,
                crossAxisSpacing: kGridInnerPadding,
                childAspectRatio: 16 / 9,
              ),
              padding: kGridPadding,
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
            ),
          );
        } else {
          final crossAxisCount = calculateCrossAxisCount(dl);

          child = RepaintBoundary(
            child: AbsorbPointer(
              absorbing: candidateItems.isNotEmpty,
              child: StaticGrid(
                key: ValueKey(layout.hashCode),
                crossAxisCount: crossAxisCount.clamp(1, 50),
                childAspectRatio: 16 / 9,
                reorderable: onReorder != null,
                onReorder: onReorder ?? (a, b) {},
                children: devices.map((device) {
                  return DesktopDeviceTile(device: device);
                }).toList(),
              ),
            ),
          );
        }

        return Material(
          color: Colors.black,
          child: Center(child: child),
        );
      },
    );
  }
}

class DesktopDeviceTile extends StatelessWidget {
  const DesktopDeviceTile({super.key, required this.device});

  final Device device;

  @override
  Widget build(BuildContext context) {
    final videoPlayer = UnityPlayers.players[device];

    if (videoPlayer == null) {
      return Card(
        clipBehavior: Clip.hardEdge,
        child: DesktopTileViewport(controller: null, device: device),
      );
    }

    return UnityVideoView(
      key: ValueKey(device.fullName),
      heroTag: device.streamURL,
      player: videoPlayer,
      paneBuilder: (context, controller) {
        return DesktopTileViewport(controller: controller, device: device);
      },
    );
  }
}

class DesktopCompactTile extends StatelessWidget {
  const DesktopCompactTile({
    super.key,
    required this.devices,
  }) : assert(devices.length >= 2 && devices.length <= 4);

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
  final UnityVideoPlayer? controller;
  final Device device;

  const DesktopTileViewport({
    super.key,
    required this.controller,
    required this.device,
  });

  @override
  State<DesktopTileViewport> createState() => _DesktopTileViewportState();
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

class _DesktopTileViewportState extends State<DesktopTileViewport> {
  bool ptzEnabled = false;

  double? volume;

  void updateVolume() {
    assert(widget.controller != null);
    widget.controller?.volume.then((value) {
      if (mounted) setState(() => volume = value);
    });
  }

  @override
  void initState() {
    super.initState();
    if (widget.controller != null) {
      updateVolume();
    }
  }

  @override
  void didUpdateWidget(covariant DesktopTileViewport oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller == null && widget.controller != null) {
      updateVolume();
    }
  }

  @override
  Widget build(BuildContext context) {
    final error = UnityVideoView.maybeOf(context)?.error;
    if (error != null) {
      return ErrorWarning(message: error);
    }

    final video = UnityVideoView.maybeOf(context);

    final theme = Theme.of(context);
    final view = context.watch<DesktopViewProvider>();
    final isSubView = AlternativeWindow.maybeOf(context) != null;

    Widget foreground = PTZController(
      enabled: ptzEnabled,
      device: widget.device,
      builder: (context, commands, constraints) {
        final states = HoverButton.of(context).states;
        final loc = AppLocalizations.of(context);

        return Stack(children: [
          Padding(
            padding: const EdgeInsetsDirectional.symmetric(
              horizontal: 12.0,
              vertical: 8.0,
            ),
            child: RichText(
              text: TextSpan(
                text: widget.device.name,
                style: theme.textTheme.labelLarge?.copyWith(
                  color: Colors.white,
                  shadows: outlinedText(),
                ),
                children: [
                  if (states.isHovering)
                    TextSpan(
                      text: '\n${widget.device.server.name}',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: Colors.white,
                        shadows: outlinedText(),
                      ),
                    ),
                ],
              ),
            ),
          ),
          PositionedDirectional(
            end: 16.0,
            top: 50.0,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: commands.map<String>((cmd) {
                switch (cmd.command) {
                  case PTZCommand.move:
                    return '${cmd.command.locale(context)}: ${cmd.movement.locale(context)}';
                  case PTZCommand.stop:
                    return cmd.command.locale(context);
                }
              }).map<Widget>((text) {
                return Text(
                  text,
                  style: const TextStyle(color: Colors.white70),
                );
              }).toList(),
            ),
          ),
          if (video != null) ...[
            if (!widget.controller!.isSeekable)
              const Center(
                child: SizedBox(
                  height: 20.0,
                  width: 20.0,
                  child: CircularProgressIndicator.adaptive(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation(Colors.white),
                  ),
                ),
              ),
            PositionedDirectional(
              end: 0,
              start: 0,
              bottom: 4.0,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  if (states.isHovering) ...[
                    const SizedBox(width: 12.0),
                    if (widget.device.hasPTZ) ...[
                      IconButton(
                        icon: Icon(
                          Icons.videogame_asset,
                          color: ptzEnabled ? Colors.white : null,
                        ),
                        tooltip: ptzEnabled ? loc.enabledPTZ : loc.disabledPTZ,
                        onPressed: () =>
                            setState(() => ptzEnabled = !ptzEnabled),
                      ),
                      // TODO(bdlukaa): enable presets when the API is ready
                      // IconButton(
                      //   icon: Icon(
                      //     Icons.dataset,
                      //     color: ptzEnabled ? Colors.white : null,
                      //   ),
                      //   tooltip: ptzEnabled
                      //       ? loc.enabledPTZ
                      //       : loc.disabledPTZ,
                      //   onPressed: !ptzEnabled
                      //       ? null
                      //       : () {
                      //           showDialog(
                      //             context: context,
                      //             builder: (context) {
                      //               return PresetsDialog(device: widget.device);
                      //             },
                      //           );
                      //         },
                      // ),
                    ],
                    const Spacer(),
                    () {
                      final isMuted = volume == 0.0;

                      return IconButton(
                        icon: Icon(
                          isMuted
                              ? Icons.volume_mute_rounded
                              : Icons.volume_up_rounded,
                          shadows: outlinedText(),
                        ),
                        tooltip: isMuted ? loc.enableAudio : loc.disableAudio,
                        color: Colors.white,
                        iconSize: 18.0,
                        onPressed: () async {
                          if (isMuted) {
                            await widget.controller!.setVolume(1.0);
                          } else {
                            await widget.controller!.setVolume(0.0);
                          }

                          updateVolume();
                        },
                      );
                    }(),
                    if (isDesktop && !isSubView)
                      IconButton(
                        icon: Icon(
                          Icons.open_in_new,
                          shadows: outlinedText(),
                        ),
                        tooltip: loc.openInANewWindow,
                        color: Colors.white,
                        iconSize: 18.0,
                        onPressed: () {
                          widget.device.openInANewWindow();
                        },
                      ),
                    if (!isSubView)
                      IconButton(
                        icon: Icon(
                          Icons.fullscreen_rounded,
                          shadows: outlinedText(),
                        ),
                        tooltip: loc.showFullscreenCamera,
                        color: Colors.white,
                        iconSize: 18.0,
                        onPressed: () async {
                          var player = UnityPlayers.players[widget.device];
                          var isLocalController = false;
                          if (player == null) {
                            player = UnityPlayers.forDevice(widget.device);
                            isLocalController = true;
                          }

                          await Navigator.of(context).pushNamed(
                            '/fullscreen',
                            arguments: {
                              'device': widget.device,
                              'player': player,
                              'ptzEnabled': ptzEnabled,
                            },
                          );
                          if (isLocalController) await player.release();
                        },
                      ),
                    IconButton(
                      icon: Icon(
                        Icons.replay_outlined,
                        shadows: outlinedText(),
                      ),
                      tooltip: loc.reloadCamera,
                      color: Colors.white,
                      iconSize: 18.0,
                      onPressed: () => view.reload(widget.device),
                    ),
                    const SizedBox(width: 12.0),
                  ],
                  () {
                    final color = video.isImageOld
                        ? Colors.amber.shade600
                        : Colors.red.shade600;
                    final text = video.isImageOld ? loc.timedOut : loc.live;
                    return AnimatedContainer(
                      duration: const Duration(milliseconds: 500),
                      padding: const EdgeInsetsDirectional.symmetric(
                        horizontal: 4.0,
                        vertical: 2.0,
                      ),
                      margin: const EdgeInsetsDirectional.only(
                        end: 6.0,
                        bottom: 6.0,
                      ),
                      decoration: BoxDecoration(
                        color: color,
                        borderRadius: BorderRadius.circular(4.0),
                      ),
                      child: Text(
                        text,
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: color.computeLuminance() > 0.5
                              ? Colors.black
                              : Colors.white,
                        ),
                      ),
                    );
                  }(),
                ],
              ),
            ),
            if (!isSubView &&
                view.currentLayout.devices.contains(widget.device))
              PositionedDirectional(
                top: 4.0,
                end: 4.0,
                child: AnimatedOpacity(
                  opacity: !states.isHovering ? 0 : 1,
                  duration: const Duration(milliseconds: 200),
                  curve: Curves.easeInOut,
                  child: IconButton(
                    icon: const Icon(Icons.close_outlined),
                    color: theme.colorScheme.error,
                    tooltip: loc.removeCamera,
                    iconSize: 18.0,
                    onPressed: () {
                      view.remove(widget.device);
                    },
                  ),
                ),
              ),
          ],
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

class PresetsDialog extends StatelessWidget {
  final Device device;
  final bool hasSelected = false;

  const PresetsDialog({super.key, required this.device});

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final theme = Theme.of(context);

    return SimpleDialog(
      title: Row(children: [
        Expanded(child: Text(loc.presets)),
        Text('0', style: theme.textTheme.bodySmall),
      ]),
      children: [
        SizedBox(
          height: 200,
          child: Center(child: Text(loc.noPresets)),
        ),
        Container(
          height: 30.0,
          margin: const EdgeInsets.symmetric(horizontal: 12.0),
          child: Row(children: [
            Tooltip(
              message: loc.newPreset,
              child: TextButton(
                child: const Icon(Icons.add),
                onPressed: () {},
              ),
            ),
            const VerticalDivider(),
            Tooltip(
              message: loc.goToPreset,
              child: TextButton(
                onPressed: hasSelected ? () {} : null,
                child: const Icon(Icons.logout),
              ),
            ),
            Tooltip(
              message: loc.renamePreset,
              child: TextButton(
                onPressed: hasSelected ? () {} : null,
                child: const Icon(Icons.edit),
              ),
            ),
            Tooltip(
              message: loc.deletePreset,
              child: TextButton(
                onPressed: hasSelected ? () {} : null,
                child: const Icon(Icons.delete),
              ),
            ),
            const VerticalDivider(),
            Tooltip(
              message: loc.refreshPresets,
              child: TextButton(
                child: const Icon(Icons.refresh),
                onPressed: () {},
              ),
            ),
          ]),
        ),
      ],
    );
  }
}
