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
        initiallyClosed: app_links.openedFromFile,
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
      onWillAcceptWithDetails: onWillAccept == null
          ? null
          : (details) => onWillAccept!.call(details.data),
      onAcceptWithDetails: (details) => onAccept?.call(details.data),
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
              aspectRatio: kHorizontalAspectRatio,
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
                key: ValueKey(layout.hashCode),
                crossAxisCount: crossAxisCount.clamp(1, 50),
                childAspectRatio: kHorizontalAspectRatio,
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
            context.findAncestorWidgetOfExactType<LargeDeviceGrid>()!.width <=
                _kReverseBreakpoint;

        return Material(
          color: Colors.black,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadiusDirectional.only(
              topStart: isReversed ? Radius.zero : const Radius.circular(8.0),
              topEnd: isReversed ? const Radius.circular(8.0) : Radius.zero,
            ),
          ),
          child: SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Text(
                    layout.name,
                    style: theme.textTheme.titleSmall,
                  ),
                ),
                Expanded(child: child),
              ],
            ),
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
