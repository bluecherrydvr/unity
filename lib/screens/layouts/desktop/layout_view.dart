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

class _LargeDeviceGridState extends State<LargeDeviceGrid>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animationController;
  Timer? cycleTimer;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final settings = context.watch<SettingsProvider>();
    cycleTimer?.cancel();
    cycleTimer = Timer.periodic(settings.kLayoutCyclePeriod.value, (_) {
      if (!mounted) return;
      if (settings.kLayoutCycleEnabled.value) {
        context.read<LayoutsProvider>().switchToNextLayout();
      }
    });
  }

  @override
  void dispose() {
    cycleTimer?.cancel();
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsProvider>();
    final view = context.watch<LayoutsProvider>();
    final isReversed = widget.width <= _kReverseBreakpoint;

    final sidebar = CollapsableSidebar(
      key: view.sidebarKey,
      initiallyClosed:
          app_links.openedFromFile || view.currentLayout.devices.isNotEmpty,
      left: !isReversed,
      builder: (context, collapsed, collapseButton) {
        if (collapsed) {
          return CollapsedSidebar(collapseButton: collapseButton);
        }
        return DesktopSidebar(collapseButton: collapseButton);
      },
    );

    final layoutView = AnimatedSwitcher(
      duration: const Duration(milliseconds: 500),
      child: LayoutView(
        key: ValueKey(view.currentLayout.hashCode),
        layout: view.currentLayout,
        onAccept: view.add,
        onReorder: view.reorder,
        onWillAccept: (device) {
          if (device == null) return false;
          if (view.isLayoutLocked(view.currentLayout)) return false;
          if (view.currentLayout.type == DesktopLayoutType.singleView) {
            return view.currentLayout.devices.isEmpty;
          }
          return !view.currentLayout.devices.contains(device);
        },
      ),
    );

    if (settings.isImmersiveMode) {
      return Row(
        children: [
          MouseRegion(
            onEnter: (_) {
              showOverlayEntry(context, sidebar);
            },
            child: const SizedBox(height: double.infinity, width: 4.0),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsetsDirectional.only(end: 4.0, bottom: 4.0),
              child: layoutView,
            ),
          ),
        ],
      );
    }

    final children = [sidebar, Expanded(child: layoutView)];
    return Row(children: isReversed ? children.reversed.toList() : children);
  }

  OverlayEntry? _overlayEntry;
  Future<void> showOverlayEntry(BuildContext context, Widget bar) async {
    await dismissOverlayEntry();
    _overlayEntry = OverlayEntry(
      builder: (context) {
        return AnimatedBuilder(
          animation: _animationController,
          child: bar,
          builder: (context, animation) {
            return Positioned(
              top: 0,
              bottom: 0,
              left: 0,
              child: IgnorePointer(
                ignoring:
                    _animationController.status == AnimationStatus.forward,
                child: MouseRegion(
                  onExit: (_) => dismissOverlayEntry(),
                  child: Material(
                    color: Colors.transparent,
                    elevation: 8,
                    child: SlideTransition(
                      position: Tween<Offset>(
                        begin: const Offset(-1, 0),
                        end: Offset.zero,
                      ).animate(
                        CurvedAnimation(
                          parent: _animationController,
                          curve: Curves.easeInOut,
                        ),
                      ),
                      child: animation,
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
    if (context.mounted) {
      Overlay.of(context).insert(_overlayEntry!);
      await _animationController.forward();
    }
  }

  Future<void> dismissOverlayEntry() async {
    try {
      await _animationController.reverse();
    } catch (error) {
      // ignore
    }
    _overlayEntry?.remove();
    _overlayEntry = null;
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
    final settings = context.watch<SettingsProvider>();

    return DragTarget<Device>(
      onWillAcceptWithDetails:
          onWillAccept == null
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
            key: ValueKey(layout.hashCode),
            padding: kGridPadding,
            child: AspectRatio(
              aspectRatio: kHorizontalAspectRatio,
              child: DesktopDeviceTile(device: device),
            ),
          );
        } else if (layout.type == DesktopLayoutType.compactView && dl >= 4) {
          var foldedDevices =
              devices
                  .fold<List<List<Device>>>([[]], (collection, device) {
                    if (collection.last.length == 4) {
                      collection.add([device]);
                    } else {
                      collection.last.add(device);
                    }

                    return collection;
                  })
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
                padding: EdgeInsets.zero,
                children:
                    devices.map((device) {
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
            borderRadius:
                isAlternativeWindow || settings.isImmersiveMode
                    ? BorderRadius.zero
                    : BorderRadiusDirectional.only(
                      topStart:
                          isReversed ? Radius.zero : const Radius.circular(8.0),
                      topEnd:
                          isReversed ? const Radius.circular(8.0) : Radius.zero,
                    ),
          ),
          child: SafeArea(
            child: Column(
              children: [
                if (!settings.isImmersiveMode && !isAlternativeWindow)
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: IntrinsicHeight(
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              layout.name,
                              style: theme.textTheme.titleSmall?.copyWith(
                                color: Colors.white,
                              ),
                            ),
                          ),
                          LayoutOptions(layout: layout),
                        ],
                      ),
                    ),
                  ),
                if (devices.isNotEmpty)
                  Expanded(
                    child: SizedBox.fromSize(size: Size.infinite, child: child),
                  )
                else
                  Expanded(child: Center(child: Text('Add a camera'))),
              ],
            ),
          ),
        );
      },
    );
  }
}

class LayoutOptions extends StatefulWidget {
  final Layout layout;

  const LayoutOptions({super.key, required this.layout});

  @override
  State<LayoutOptions> createState() => _LayoutOptionsState();
}

class _LayoutOptionsState extends State<LayoutOptions> {
  bool _volumeSliderVisible = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final loc = AppLocalizations.of(context);
    final view = context.watch<LayoutsProvider>();
    final isAlternativeWindow = AlternativeWindow.maybeOf(context) != null;

    return Row(
      spacing: 4.0,
      children: [
        if (widget.layout.devices.isNotEmpty)
          ...() {
            final volume =
                widget.layout.devices
                    .map((device) => device.volume)
                    .findMaxDuplicatedElementInList()
                    .toDouble();
            return <Widget>[
              if (_volumeSliderVisible)
                SizedBox(
                  height: 24.0,
                  child: Slider(
                    value: volume,
                    divisions: 100,
                    label: '${(volume * 100).round()}%',
                    onChanged: (value) async {
                      await widget.layout.setVolume(value);
                      if (mounted) setState(() {});
                    },
                    onChangeEnd: (value) async {
                      await widget.layout.setVolume(value);
                      view.save();
                    },
                  ),
                ),
              SquaredIconButton(
                icon: const Icon(Icons.equalizer, color: Colors.white),
                tooltip: loc.layoutVolume((volume * 100).round()),
                onPressed: () {
                  setState(() {
                    _volumeSliderVisible = !_volumeSliderVisible;
                  });
                },
              ),
            ];
          }(),
        SquaredIconButton(
          icon: Icon(
            view.isLayoutLocked(widget.layout) ? Icons.lock : Icons.lock_open,
            color: Colors.white,
          ),
          tooltip:
              view.isLayoutLocked(widget.layout)
                  ? loc.unlockLayout
                  : loc.lockLayout,
          onPressed: () => view.toggleLayoutLock(widget.layout),
        ),
        SquaredIconButton(
          icon: const Icon(Icons.satellite_alt, color: Colors.white),
          tooltip: loc.addExternalStream,
          onPressed: () {
            AddExternalStreamDialog.show(context, targetLayout: widget.layout);
          },
        ),
        if (canOpenNewWindow && !isAlternativeWindow)
          SquaredIconButton(
            icon: const Icon(Icons.open_in_new, color: Colors.white),
            tooltip: loc.openInANewWindow,
            onPressed: widget.layout.openInANewWindow,
          ),
        if (!isAlternativeWindow)
          SquaredIconButton(
            icon: Icon(Icons.fullscreen_rounded, color: Colors.white),
            tooltip: loc.showFullscreenCamera,
            onPressed: () async {
              Navigator.of(context).pushNamed(
                '/fullscreen-layout',
                arguments: {'layout': widget.layout},
              );
            },
          ),
        // TODO(bdlukaa): "Add" button. Displays a popup with the current
        //                available cameras
        SquaredIconButton(
          icon: const Icon(Icons.edit, color: Colors.white),
          tooltip: loc.editLayout,
          onPressed: () {
            showDialog(
              context: context,
              builder: (context) => EditLayoutDialog(layout: widget.layout),
            );
          },
        ),
        SquaredIconButton(
          icon: const Icon(Icons.import_export, color: Colors.white),
          tooltip: loc.exportLayout,
          onPressed: () {
            widget.layout.export(dialogTitle: loc.exportLayout);
          },
        ),
        if (widget.layout.devices.isNotEmpty) ...[
          const VerticalDivider(),
          SquaredIconButton(
            icon: Icon(Icons.clear, color: theme.colorScheme.error),
            tooltip: loc.clearLayout(widget.layout.devices.length),
            // TODO(bdlukaa): Add a confirmation and an UNDO option
            onPressed: view.clearLayout,
          ),
        ],
      ],
    );
  }
}

class DesktopCompactTile extends StatelessWidget {
  const DesktopCompactTile({super.key, required this.devices})
    : assert(devices.length >= 2 && devices.length <= 4);

  final List<Device> devices;

  @override
  Widget build(BuildContext context) {
    if (devices.isEmpty) return const SizedBox.shrink();

    final device1 = devices[0];
    final device2 = devices[1];

    return Column(
      children: [
        Expanded(
          child: Row(
            children: [
              Expanded(child: DesktopDeviceTile(device: device1)),
              const SizedBox(width: kGridInnerPadding),
              Expanded(child: DesktopDeviceTile(device: device2)),
            ],
          ),
        ),
        const SizedBox(height: kGridInnerPadding),
        Expanded(
          child: Row(
            children: [
              Expanded(
                child:
                    devices.length >= 3
                        ? DesktopDeviceTile(device: devices[2])
                        : const SizedBox.shrink(),
              ),
              const SizedBox(width: kGridInnerPadding),
              Expanded(
                child:
                    devices.length == 4
                        ? DesktopDeviceTile(device: devices[3])
                        : const SizedBox.shrink(),
              ),
            ],
          ),
        ),
      ],
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
      title: Row(
        children: [
          Expanded(child: Text(loc.presets)),
          Text('0', style: theme.textTheme.bodySmall),
        ],
      ),
      children: [
        SizedBox(height: 200, child: Center(child: Text(loc.noPresets))),
        Container(
          height: 30.0,
          margin: const EdgeInsetsDirectional.symmetric(horizontal: 12.0),
          child: Row(
            children: [
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
            ],
          ),
        ),
      ],
    );
  }
}
