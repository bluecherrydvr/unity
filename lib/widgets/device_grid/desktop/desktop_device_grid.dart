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

const _kReverseBreakpoint = 900.0;

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
    final theme = Theme.of(context);
    final view = context.watch<DesktopViewProvider>();
    final settings = context.watch<SettingsProvider>();
    final loc = AppLocalizations.of(context);

    final isReversed = widget.width <= _kReverseBreakpoint;

    final children = [
      CollapsableSidebar(
        left: !isReversed,
        builder: (context, collapsed, collapseButton) {
          if (collapsed) {
            return Column(children: [
              collapseButton,
              const Spacer(),
              IconButton(
                icon: Icon(
                  Icons.cyclone,
                  size: 18.0,
                  color: settings.layoutCyclingEnabled
                      ? theme.colorScheme.primary
                      : IconTheme.of(context).color,
                ),
                padding: EdgeInsetsDirectional.zero,
                tooltip: loc.cycle,
                onPressed: settings.toggleCycling,
              ),
              Container(
                padding: const EdgeInsetsDirectional.all(8.0),
                margin: const EdgeInsetsDirectional.only(bottom: 8.0, top: 4.0),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: theme.colorScheme.primaryContainer,
                ),
                child: Text(
                  '${view.currentLayout.devices.length}',
                  style: TextStyle(
                    color: theme.colorScheme.onPrimaryContainer,
                  ),
                ),
              ),
            ]);
          }
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
              final lastFullFold = foldedDevices.firstWhere(
                (fold) => fold.length > 1,
                orElse: () => foldedDevices.first,
              );
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

        final isReversed =
            context.findAncestorWidgetOfExactType<DesktopDeviceGrid>()!.width <
                _kReverseBreakpoint;

        return Material(
          color: Colors.black,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadiusDirectional.only(
              topStart: isReversed ? Radius.zero : const Radius.circular(8.0),
              topEnd: isReversed ? const Radius.circular(8.0) : Radius.zero,
            ),
          ),
          child: SafeArea(child: Center(child: child)),
        );
      },
    );
  }
}

class DesktopDeviceTile extends StatefulWidget {
  const DesktopDeviceTile({super.key, required this.device});

  final Device device;

  @override
  State<DesktopDeviceTile> createState() => _DesktopDeviceTileState();
}

class _DesktopDeviceTileState extends State<DesktopDeviceTile> {
  late UnityVideoFit fit = SettingsProvider.instance.cameraViewFit;

  @override
  Widget build(BuildContext context) {
    // watch for changes in the players list. usually happens when reloading
    // or releasing a device
    context.watch<UnityPlayers>();
    final videoPlayer = UnityPlayers.players[widget.device.uuid];

    if (videoPlayer == null) {
      return Card(
        clipBehavior: Clip.hardEdge,
        child: DesktopTileViewport(
          controller: null,
          device: widget.device,
          onFitChanged: (fit) => setState(() => this.fit = fit),
        ),
      );
    }

    return UnityVideoView(
      key: ValueKey(widget.device.fullName),
      heroTag: widget.device.streamURL,
      player: videoPlayer,
      fit: fit,
      paneBuilder: (context, controller) {
        return DesktopTileViewport(
          controller: controller,
          device: widget.device,
          onFitChanged: (fit) => setState(() => this.fit = fit),
        );
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
  final ValueChanged<UnityVideoFit> onFitChanged;

  const DesktopTileViewport({
    super.key,
    required this.controller,
    required this.device,
    required this.onFitChanged,
  });

  @override
  State<DesktopTileViewport> createState() => _DesktopTileViewportState();
}

class _DesktopTileViewportState extends State<DesktopTileViewport> {
  bool ptzEnabled = false;
  late double? volume = widget.controller?.volume;

  void updateVolume() {
    if (widget.controller != null && mounted) {
      setState(() => volume = widget.controller!.volume);
    }
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
    final loc = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final view = context.watch<DesktopViewProvider>();
    final closeButton = IconButton(
      icon: const Icon(Icons.close_outlined),
      color: theme.colorScheme.error,
      tooltip: loc.removeCamera,
      iconSize: 18.0,
      onPressed: () {
        view.remove(widget.device);
      },
    );

    final error = UnityVideoView.maybeOf(context)?.error;
    final video = UnityVideoView.maybeOf(context);
    final isSubView = AlternativeWindow.maybeOf(context) != null;

    final reloadButton = IconButton(
      icon: Icon(
        Icons.replay_outlined,
        shadows: outlinedText(),
      ),
      tooltip: loc.reloadCamera,
      color: Colors.white,
      iconSize: 18.0,
      onPressed: () async {
        await UnityPlayers.reloadDevice(widget.device);
        setState(() {});
      },
    );

    Widget foreground = PTZController(
      enabled: ptzEnabled,
      device: widget.device,
      builder: (context, commands, constraints) {
        final states = HoverButton.of(context).states;

        return Stack(children: [
          Positioned.fill(child: MulticastViewport(device: widget.device)),
          if (error != null)
            Positioned.fill(child: ErrorWarning(message: error)),
          IgnorePointer(
            child: Padding(
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
          ),
          PositionedDirectional(
            end: 16.0,
            top: 50.0,
            child: PTZData(commands: commands),
          ),
          if (video != null) ...[
            if (!widget.controller!.isSeekable && error == null)
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
              child: Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
                if (states.isHovering && error == null) ...[
                  const SizedBox(width: 12.0),
                  if (widget.device.hasPTZ)
                    PTZToggleButton(
                      ptzEnabled: ptzEnabled,
                      onChanged: (enabled) =>
                          setState(() => ptzEnabled = enabled),
                    ),
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
                  if (isDesktopPlatform && !isSubView)
                    IconButton(
                      icon: Icon(
                        Icons.open_in_new_sharp,
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
                        var player = UnityPlayers.players[widget.device.uuid];
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
                  reloadButton,
                  CameraViewFitButton(
                    fit: context
                            .findAncestorWidgetOfExactType<UnityVideoView>()
                            ?.fit ??
                        SettingsProvider.instance.cameraViewFit,
                    onChanged: widget.onFitChanged,
                  ),
                ] else ...[
                  const Spacer(),
                  if (states.isHovering) reloadButton,
                ],
                const SizedBox(width: 12.0),
                Padding(
                  padding: const EdgeInsetsDirectional.only(
                    end: 6.0,
                    bottom: 6.0,
                  ),
                  child: VideoStatusLabel(
                    video: video,
                    device: widget.device,
                  ),
                ),
              ]),
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
                  child: closeButton,
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
          margin: const EdgeInsetsDirectional.symmetric(horizontal: 12.0),
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
