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

class LargeDeviceGrid extends StatefulWidget {
  const LargeDeviceGrid({super.key, required this.width});

  final double width;

  @override
  State<LargeDeviceGrid> createState() => _LargeDeviceGridState();
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

class _LargeDeviceGridState extends State<LargeDeviceGrid> {
  @override
  Widget build(BuildContext context) {
    final view = context.watch<DesktopViewProvider>();
    final isReversed = widget.width <= _kReverseBreakpoint;

    final children = [
      CollapsableSidebar(
        initiallyClosed:
            app_links.openedFromFile || view.currentLayout.devices.isNotEmpty,
        left: !isReversed,
        builder: (context, collapsed, collapseButton) {
          if (collapsed) {
            return CollapsedSidebar(collapseButton: collapseButton);
          }
          return DesktopSidebar(collapseButton: collapseButton);
        },
      ),
      Expanded(
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 500),
          child: LayoutView(
            key: ValueKey(view.currentLayout.hashCode),
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
      ),
    ];

    return Row(children: isReversed ? children.reversed.toList() : children);
  }
}

class LayoutView extends StatefulWidget {
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
  State<LayoutView> createState() => _LayoutViewState();
}

class _LayoutViewState extends State<LayoutView> {
  var _volumeSliderVisible = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final loc = AppLocalizations.of(context);
    final view = context.watch<DesktopViewProvider>();

    return DragTarget<Device>(
      onWillAcceptWithDetails: widget.onWillAccept == null
          ? null
          : (details) => widget.onWillAccept!.call(details.data),
      onAcceptWithDetails: (details) => widget.onAccept?.call(details.data),
      builder: (context, candidateItems, rejectedItems) {
        late Widget child;

        final devices = <Device>[
          ...widget.layout.devices,
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
          // }
          // else if (devices.isEmpty) {
          // child = Center(
          //   child: Text(
          //     loc.selectACamera,
          //     style: const TextStyle(
          //       color: Colors.white70,
          //       fontSize: 12.0,
          //     ),
          //   ),
          // );
        } else if (dl == 1) {
          final device = devices.first;
          child = Padding(
            key: ValueKey(widget.layout.hashCode),
            padding: kGridPadding,
            child: AspectRatio(
              aspectRatio: kHorizontalAspectRatio,
              child: DesktopDeviceTile(device: device),
            ),
          );
        } else if (widget.layout.type == DesktopLayoutType.compactView &&
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
              key: ValueKey(widget.layout.hashCode),
              physics: const NeverScrollableScrollPhysics(),
              shrinkWrap: true,
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: crossAxisCount,
                mainAxisSpacing: kGridInnerPadding,
                crossAxisSpacing: kGridInnerPadding,
                childAspectRatio: kHorizontalAspectRatio,
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
                key: ValueKey(widget.layout.hashCode),
                crossAxisCount: crossAxisCount.clamp(1, 50),
                childAspectRatio: kHorizontalAspectRatio,
                reorderable: widget.onReorder != null,
                onReorder: widget.onReorder ?? (a, b) {},
                children: devices.map((device) {
                  return DesktopDeviceTile(device: device);
                }).toList(),
              ),
            ),
          );
        }

        final isAlternativeWindow = AlternativeWindow.maybeOf(context) != null;
        final parent = context.findAncestorWidgetOfExactType<LargeDeviceGrid>();
        final isReversed =
            parent == null ? false : parent.width <= _kReverseBreakpoint;

        return Material(
          color: Colors.black,
          shape: RoundedRectangleBorder(
            borderRadius: isAlternativeWindow
                ? BorderRadius.zero
                : BorderRadiusDirectional.only(
                    topStart:
                        isReversed ? Radius.zero : const Radius.circular(8.0),
                    topEnd:
                        isReversed ? const Radius.circular(8.0) : Radius.zero,
                  ),
          ),
          child: SafeArea(
            child: Column(children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: IntrinsicHeight(
                  child: Row(children: [
                    Expanded(
                      child: Text(
                        widget.layout.name,
                        style: theme.textTheme.titleSmall?.copyWith(
                          color: Colors.white,
                        ),
                      ),
                    ),
                    if (widget.layout.devices.isNotEmpty)
                      ...() {
                        final volume = widget.layout.devices
                            .map((e) => e.volume)
                            .findMaxDuplicatedElementInList()
                            .toDouble();
                        return <Widget>[
                          if (_volumeSliderVisible)
                            SizedBox(
                              height: 24.0,
                              child: Slider(
                                value: widget.layout.devices
                                    .map((e) => e.volume)
                                    .findMaxDuplicatedElementInList()
                                    .toDouble(),
                                divisions: 100,
                                label: '${(volume * 100).round()}%',
                                onChanged: (value) async {
                                  for (final device in widget.layout.devices) {
                                    final player =
                                        UnityPlayers.players[device.uuid];
                                    if (player != null) {
                                      await player.setVolume(value);
                                      device.volume = value;
                                    }
                                  }
                                  if (mounted) setState(() {});
                                },
                              ),
                            ),
                          SquaredIconButton(
                            icon: const Icon(
                              Icons.equalizer,
                              color: Colors.white,
                            ),
                            tooltip:
                                'Layout Volume • ${(volume * 100).round()}%',
                            onPressed: () {
                              setState(() {
                                _volumeSliderVisible = !_volumeSliderVisible;
                              });
                            },
                          ),
                        ];
                      }(),
                    if (canOpenNewWindow)
                      SquaredIconButton(
                        icon: const Icon(
                          Icons.open_in_new,
                          color: Colors.white,
                        ),
                        tooltip: loc.openInANewWindow,
                        onPressed: widget.layout.openInANewWindow,
                      ),
                    SquaredIconButton(
                      icon: const Icon(Icons.edit, color: Colors.white),
                      tooltip: loc.editLayout,
                      onPressed: () {
                        showDialog(
                          context: context,
                          builder: (context) =>
                              EditLayoutDialog(layout: widget.layout),
                        );
                      },
                    ),
                    SquaredIconButton(
                      icon: const Icon(
                        Icons.import_export,
                        color: Colors.white,
                      ),
                      tooltip: loc.exportLayout,
                      onPressed: () {
                        widget.layout.export(dialogTitle: loc.exportLayout);
                      },
                    ),
                    if (widget.layout.devices.isNotEmpty) ...[
                      const VerticalDivider(),
                      SquaredIconButton(
                        icon: Icon(
                          Icons.clear,
                          color: theme.colorScheme.error,
                        ),
                        tooltip: loc.clearLayout(widget.layout.devices.length),
                        onPressed: view.clearLayout,
                      ),
                    ],
                  ]),
                ),
              ),
              Expanded(child: Center(child: child)),
            ]),
          ),
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
