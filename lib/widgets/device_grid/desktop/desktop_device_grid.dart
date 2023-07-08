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
  /// A list of global keys that represent every device
  final devicesKeys = <Device, GlobalKey>{};

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final view = context.watch<DesktopViewProvider>();

    for (final device in view.currentLayout.devices) {
      if (devicesKeys.containsKey(device)) continue;

      devicesKeys[device] = GlobalKey(debugLabel: device.fullName);
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
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
        child: Material(
          color: Colors.black,
          child: SizedBox.expand(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 100),
              child: () {
                final devices = view.currentLayout.devices;

                if (devices.isEmpty) {
                  return Center(
                    child: Text(
                      loc.selectACamera,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 12.0,
                      ),
                    ),
                  );
                }

                final dl = devices.length;

                if (dl == 1) {
                  final device = devices.first;
                  return AspectRatio(
                    aspectRatio: 16 / 9,
                    child: Padding(
                      key: ValueKey(view.currentLayout.hashCode),
                      padding: kGridPadding,
                      child: DesktopDeviceTile(
                        // key: ValueKey('$device.${device.server.serverUUID}'),
                        key: devicesKeys[device],
                        device: device,
                      ),
                    ),
                  );
                }

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
                    key: ValueKey(view.currentLayout.hashCode),
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
                  );
                }

                final crossAxisCount = calculateCrossAxisCount(dl);

                return RepaintBoundary(
                  child: StaticGrid(
                    key: ValueKey(view.currentLayout.hashCode),
                    crossAxisCount: crossAxisCount.clamp(1, 50),
                    childAspectRatio: 16 / 9,
                    onReorder: view.reorder,
                    children: devices.map((device) {
                      return DesktopDeviceTile(
                        key: devicesKeys[device],
                        device: device,
                      );
                    }).toList(),
                  ),
                );
              }(),
            ),
          ),
        ),
      ),
    ];

    if (isReversed) {
      return Row(children: children.reversed.toList());
    }

    return Row(children: children);
  }
}

class DesktopDeviceTile extends StatefulWidget {
  const DesktopDeviceTile({super.key, required this.device});

  final Device device;

  @override
  State<DesktopDeviceTile> createState() => _DesktopDeviceTileState();
}

class _DesktopDeviceTileState extends State<DesktopDeviceTile> {
  UnityVideoPlayer? videoPlayer;
  Size? size;

  @override
  void initState() {
    super.initState();
    videoPlayer = DesktopViewProvider.instance.players[widget.device];
  }

  @override
  Widget build(BuildContext context) {
    if (videoPlayer == null) {
      return const Center(child: CircularProgressIndicator.adaptive());
    }

    return LayoutBuilder(builder: (context, consts) {
      // TODO(bdlukaa): for some odd reason, this crashes
      // if (size == null || size != consts.biggest) {
      //   size = consts.biggest;
      //   debugPrint('Resizing video controller');
      //   WidgetsBinding.instance.addPostFrameCallback((_) {
      //     videoPlayer!.setSize(size!);
      //   });
      // }

      return UnityVideoView(
        player: videoPlayer!,
        color: createTheme(themeMode: ThemeMode.dark).canvasColor,
        paneBuilder: (context, controller) {
          // debugPrint(controller.dataSource);
          return DesktopTileViewport(
            controller: controller,
            device: widget.device,
          );
        },
      );
    });
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
  final UnityVideoPlayer controller;
  final Device device;

  /// Whether this viewport is in a sub view.
  ///
  /// Some features aren't allow in subview
  final bool isSubView;

  const DesktopTileViewport({
    super.key,
    required this.controller,
    required this.device,
    this.isSubView = false,
  });

  @override
  State<DesktopTileViewport> createState() => _DesktopTileViewportState();
}

class _DesktopTileViewportState extends State<DesktopTileViewport> {
  bool ptzEnabled = false;

  double? volume;

  void updateVolume() {
    widget.controller.volume.then((value) {
      if (mounted) setState(() => volume = value);
    });
  }

  @override
  void initState() {
    super.initState();
    updateVolume();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final view = context.watch<DesktopViewProvider>();

    if (widget.controller.error != null) {
      return ErrorWarning(message: widget.controller.error!);
    } else if (!widget.controller.isSeekable) {
      return const Center(
        child: CircularProgressIndicator.adaptive(
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

    Widget foreground = PTZController(
      enabled: ptzEnabled,
      device: widget.device,
      builder: (context, commands) {
        final states = HoverButton.of(context).states;
        final loc = AppLocalizations.of(context);

        return Stack(children: [
          Column(children: [
            if (!widget.isSubView)
              Container(
                height: 48.0,
                padding: const EdgeInsets.symmetric(horizontal: 12.0).add(
                  const EdgeInsetsDirectional.only(top: 8.0),
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
                        tooltip: loc.removeCamera,
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
                    .add(const EdgeInsetsDirectional.only(bottom: 4.0)),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
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
                          shadows: shadows,
                        ),
                        tooltip: isMuted ? loc.enableAudio : loc.disableAudio,
                        color: Colors.white,
                        iconSize: 18.0,
                        onPressed: () async {
                          if (isMuted) {
                            await widget.controller.setVolume(1.0);
                          } else {
                            await widget.controller.setVolume(0.0);
                          }

                          updateVolume();
                        },
                      );
                    }(),
                    IconButton(
                      icon: const Icon(
                        Icons.high_quality,
                        shadows: shadows,
                      ),
                      tooltip: loc.selectResolution,
                      color: Colors.white,
                      iconSize: 18.0,
                      onPressed: () => showResolutionDialog(
                        context,
                        widget.controller,
                      ),
                    ),
                    if (isDesktop && !widget.isSubView)
                      IconButton(
                        icon: const Icon(
                          Icons.open_in_new,
                          shadows: shadows,
                        ),
                        tooltip: loc.openInANewWindow,
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
                        tooltip: loc.showFullscreenCamera,
                        color: Colors.white,
                        iconSize: 18.0,
                        onPressed: () async {
                          var player = view.players[widget.device];
                          var isLocalController = false;
                          if (player == null) {
                            player = getVideoPlayerControllerForDevice(
                                widget.device);
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
                      icon: const Icon(
                        Icons.replay_outlined,
                        shadows: shadows,
                      ),
                      tooltip: loc.reloadCamera,
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
          ]),
          PositionedDirectional(
            end: 16.0,
            top: 50.0,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: commands
                  .map<String>((cmd) {
                    switch (cmd.command) {
                      case PTZCommand.move:
                        return '${cmd.command.locale(context)}: ${cmd.movement.locale(context)}';
                      case PTZCommand.stop:
                        return cmd.command.locale(context);
                    }
                  })
                  .map<Widget>(
                    (text) => Text(
                      text,
                      style: const TextStyle(color: Colors.white70),
                    ),
                  )
                  .toList(),
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

Future<void> showResolutionDialog(
  BuildContext context,
  UnityVideoPlayer controller,
) {
  return showModalBottomSheet(
    context: context,
    builder: (context) {
      final theme = Theme.of(context);
      final loc = AppLocalizations.of(context);

      return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Stack(alignment: Alignment.center, children: [
          Center(
            child: Container(
              margin: const EdgeInsets.symmetric(vertical: 14.0),
              width: 40.0,
              height: 6.0,
              decoration: BoxDecoration(
                color: theme.dividerColor,
                borderRadius: BorderRadius.circular(100.0),
              ),
            ),
          ),
          if (isDesktop)
            Align(
              alignment: AlignmentDirectional.centerEnd,
              child: Padding(
                padding: const EdgeInsetsDirectional.only(end: 8.0),
                child: IconButton(
                  icon: const Icon(Icons.close),
                  tooltip: loc.close,
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ),
            ),
        ]),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                loc.setResolution,
                style: theme.textTheme.titleLarge,
              ),
              Text(
                loc.setResolutionDescription,
                style: theme.textTheme.bodySmall,
              ),
            ],
          ),
        ),
        ...UnityVideoQuality.values.map((quality) {
          return RadioListTile<UnityVideoQuality>(
            groupValue: controller.quality,
            value: quality,
            title: RichText(
              text: TextSpan(
                text: quality.str(context),
                children: [
                  if (quality.isHD)
                    WidgetSpan(
                      child: Tooltip(
                        message: loc.hd,
                        child: const Icon(
                          Icons.hd,
                          size: 18.0,
                          color: Colors.yellow,
                        ),
                      ),
                    ),
                  if (SettingsProvider.instance.videoQuality == quality)
                    WidgetSpan(
                      child: Tooltip(
                        message: loc.defaultResolution,
                        child: const Icon(
                          Icons.verified,
                          color: Colors.blue,
                          size: 18.0,
                        ),
                      ),
                    )
                ],
              ),
            ),
            controlAffinity: ListTileControlAffinity.trailing,
            onChanged: (quality) {
              if (quality == null) return;

              controller.setResolution(quality);
              Navigator.of(context).pop();
            },
          );
        }),
      ]);
    },
  );
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
