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

const kDeviceSelectorTileHeight = 32.0;
const kSidebarConstraints = BoxConstraints(maxWidth: 256.0);
const kCompactSidebarConstraints = BoxConstraints(maxWidth: 80.0);

class DesktopSidebar extends StatefulWidget {
  final Widget collapseButton;

  const DesktopSidebar({super.key, required this.collapseButton});

  @override
  State<DesktopSidebar> createState() => _DesktopSidebarState();
}

class _DesktopSidebarState extends State<DesktopSidebar> {
  var isSidebarHovering = false;
  var searchQuery = '';
  final _servers = <Server, Iterable<Device>>{};

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _updateServers();
  }

  void _updateServers() {
    final servers = context.read<ServersProvider>();

    _servers.clear();
    for (final server in servers.servers) {
      final devices = server.devices.sorted(
        searchQuery: searchQuery,
      );
      _servers[server] = devices;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final loc = AppLocalizations.of(context);

    final servers = context.watch<ServersProvider>();
    final view = context.watch<DesktopViewProvider>();
    final settings = context.watch<SettingsProvider>();

    return SafeArea(
      top: false,
      right: false,
      child: Material(
        color: theme.canvasColor,
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          LayoutManager(
            collapseButton: widget.collapseButton,
            onSearchChanged: (text) {
              setState(() {
                searchQuery = text;
                _updateServers();
              });
            },
          ),
          if (servers.servers.isEmpty)
            const Expanded(child: NoServers())
          else
            Expanded(
              child: MouseRegion(
                onEnter: (e) => setState(() => isSidebarHovering = true),
                onExit: (e) => setState(() => isSidebarHovering = false),
                // Add another material here because its descendants must be clipped.
                child: Material(
                  type: MaterialType.transparency,
                  child: CustomScrollView(slivers: [
                    for (final entry in _servers.entries)
                      () {
                        final server = entry.key;
                        final devices = entry.value;
                        final isLoading = servers.isServerLoading(server);
                        if (!isLoading &&
                            devices.isEmpty &&
                            searchQuery.isNotEmpty) {
                          return const SliverToBoxAdapter(
                            child: SizedBox.shrink(),
                          );
                        }

                        /// Whether all the online devices are in the current view.
                        final isAllInView = devices
                            .where((d) => d.status)
                            .every(
                                (d) => view.currentLayout.devices.contains(d));

                        return MultiSliver(pushPinnedChildren: true, children: [
                          SliverPinnedHeader(
                            child: SubHeader(
                              server.name,
                              materialType: MaterialType.canvas,
                              subtext: () {
                                if (!settings.checkServerCertificates(server)) {
                                  return loc.certificateNotPassed;
                                } else if (server.online) {
                                  return loc.nDevices(devices.length);
                                } else {
                                  return loc.offline;
                                }
                              }(),
                              subtextStyle: TextStyle(
                                color: !server.online
                                    ? theme.colorScheme.error
                                    : null,
                              ),
                              trailing: Builder(builder: (context) {
                                if (isLoading) {
                                  // wrap in an icon button to ensure ui consistency
                                  return const SquaredIconButton(
                                    onPressed: null,
                                    icon: SizedBox(
                                      height: 16.0,
                                      width: 16.0,
                                      child: CircularProgressIndicator.adaptive(
                                        strokeWidth: 1.5,
                                      ),
                                    ),
                                  );
                                } else if (!server.online &&
                                    isSidebarHovering) {
                                  return SquaredIconButton(
                                    icon: const Icon(Icons.refresh),
                                    tooltip: loc.refreshServer,
                                    onPressed: () => servers
                                        .refreshDevices(ids: [server.id]),
                                  );
                                } else if (isSidebarHovering &&
                                    devices.isNotEmpty) {
                                  return SquaredIconButton(
                                    icon: Icon(
                                      isAllInView
                                          ? Icons.playlist_remove
                                          : Icons.playlist_add,
                                    ),
                                    tooltip: isAllInView
                                        ? loc.removeAllFromView
                                        : loc.addAllToView,
                                    onPressed: () {
                                      if (isAllInView) {
                                        view.removeDevicesFromCurrentLayout(
                                          devices,
                                        );
                                      } else {
                                        for (final device in devices) {
                                          if (device.status &&
                                              !view.currentLayout.devices
                                                  .contains(device)) {
                                            view.add(device);
                                          }
                                        }
                                      }
                                    },
                                  );
                                } else {
                                  return const SizedBox.shrink();
                                }
                              }),
                            ),
                          ),
                          if (server.online && !isLoading)
                            SliverList.builder(
                              itemCount: devices.length,
                              itemBuilder: (context, index) {
                                final device = devices.elementAt(index);
                                final selected =
                                    view.currentLayout.devices.contains(device);

                                final tile = DeviceSelectorTile(
                                  device: device,
                                  selected: selected,
                                );

                                if (!device.status &&
                                    !settings.kListOfflineDevices.value) {
                                  return const SizedBox.shrink();
                                }
                                if (selected || !device.status) return tile;

                                final isBlocked = view.currentLayout.type ==
                                        DesktopLayoutType.singleView &&
                                    view.currentLayout.devices.isNotEmpty;

                                return Draggable<Device>(
                                  data: device,
                                  feedback: Card(
                                    child: SizedBox(
                                      height: kDeviceSelectorTileHeight,
                                      width: kSidebarConstraints.maxWidth,
                                      child: Row(children: [
                                        Expanded(child: tile),
                                        if (isBlocked)
                                          Icon(
                                            Icons.block,
                                            color: theme.colorScheme.error,
                                            size: 18.0,
                                          ),
                                        const SizedBox(width: 16.0),
                                      ]),
                                    ),
                                  ),
                                  child: tile,
                                );
                              },
                            ),
                        ]);
                      }(),
                  ]),
                ),
              ),
            ),
          const Divider(),
          ListTile(
            dense: true,
            trailing: const Icon(Icons.camera_outdoor, size: 20.0),
            title: Text(loc.addExternalStream),
            onTap: () => AddExternalStreamDialog.show(context),
          ),
        ]),
      ),
    );
  }
}

class NoServers extends StatelessWidget {
  const NoServers({super.key});

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final home = context.watch<HomeProvider>();
    return Padding(
      padding: const EdgeInsetsDirectional.all(8.0),
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        const Icon(
          Icons.dns,
          size: 48.0,
        ),
        const SizedBox(height: 6.0),
        Text(loc.noServersAdded, textAlign: TextAlign.center),
        Text.rich(
          TextSpan(
            text: loc.howToAddServer,
            style: TextStyle(
              color: Theme.of(context).colorScheme.primary,
            ),
            recognizer: TapGestureRecognizer()
              ..onTap = () => home.setTab(UnityTab.addServer, context),
          ),
          textAlign: TextAlign.center,
        ),
      ]),
    );
  }
}

class DeviceSelectorTile extends StatefulWidget {
  const DeviceSelectorTile({
    super.key,
    required this.device,
    required this.selected,
    this.selectable = true,
  });

  final Device device;
  final bool selected;
  final bool selectable;

  @override
  State<DeviceSelectorTile> createState() => _DeviceSelectorTileState();
}

class _DeviceSelectorTileState extends State<DeviceSelectorTile> {
  /// Used to check if the long press was caused by a touch input.
  PointerDeviceKind? _currentLongPressDeviceKind;

  /// Whether the user is hovering the tile.
  bool hovering = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final view = context.watch<DesktopViewProvider>();
    final loc = AppLocalizations.of(context);

    return GestureDetector(
      onSecondaryTap: () => _displayOptions(context),

      // Only display options on long press if it's caused by a touch input
      onLongPressDown: (details) => _currentLongPressDeviceKind = details.kind,
      onLongPressEnd: (details) {
        switch (_currentLongPressDeviceKind) {
          case PointerDeviceKind.touch:
            _displayOptions(context);
            break;
          default:
            break;
        }

        _currentLongPressDeviceKind = null;
      },
      child: InkWell(
        onTap: !widget.device.status || !widget.selectable
            ? null
            : () {
                if (widget.selected) {
                  view.remove(widget.device);
                } else {
                  view.add(widget.device);
                }
              },
        child: MouseRegion(
          onEnter: (_) {
            if (mounted) setState(() => hovering = true);
          },
          onHover: (_) {
            if (mounted && !hovering) setState(() => hovering = true);
          },
          onExit: (_) {
            if (mounted) setState(() => hovering = false);
          },
          child: SizedBox(
            height: widget.device.status
                ? kDeviceSelectorTileHeight
                : kDeviceSelectorTileHeight / 1.5,
            child: Row(children: [
              Container(
                margin: const EdgeInsetsDirectional.only(
                  start: 16.0,
                  end: 8.0,
                ),
                width: 12.0,
                alignment: AlignmentDirectional.centerStart,
                child: Container(
                  height: 6.0,
                  width: 6.0,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: widget.device.status
                        ? theme.extension<UnityColors>()!.successColor
                        : theme.colorScheme.error,
                  ),
                ),
              ),
              Expanded(
                child: AutoSizeText(
                  widget.device.name.uppercaseFirst,
                  maxLines: 1,
                  style: theme.textTheme.titleMedium!.copyWith(
                    color: widget.selected
                        ? theme.colorScheme.primary
                        : !widget.device.status
                            ? theme.disabledColor
                            : null,
                    decoration: !widget.device.status
                        ? TextDecoration.lineThrough
                        : null,
                  ),
                ),
              ),
              if (isMobile || hovering)
                Tooltip(
                  message: widget.device.status
                      ? loc.cameraOptions
                      : loc.viewDeviceDetails,
                  preferBelow: false,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(4.0),
                    onTap: widget.device.status
                        ? () => _displayOptions(context)
                        : () => showDeviceInfoDialog(context, widget.device),
                    child: Icon(moreIconData, size: 20.0),
                  ),
                ),
              const SizedBox(width: 16.0),
            ]),
          ),
        ),
      ),
    );
  }

  /// Display the options for the current device.
  ///
  /// There must be a [Navigator] above the provided [context]
  Future<void> _displayOptions(BuildContext context) async {
    if (!widget.device.status) return;

    final theme = Theme.of(context);
    final loc = AppLocalizations.of(context);
    final view = context.read<DesktopViewProvider>();

    const padding = EdgeInsets.symmetric(horizontal: 16.0);

    final renderBox = context.findRenderObject() as RenderBox;
    final offset = renderBox.localToGlobal(Offset(
      padding.left,
      padding.top,
    ));
    final size = Size(
      renderBox.size.width - padding.right * 2,
      renderBox.size.height - padding.bottom,
    );

    await showMenu(
      context: context,
      elevation: 4.0,
      position: RelativeRect.fromLTRB(
        offset.dx,
        offset.dy,
        offset.dx + size.width,
        offset.dy + size.height,
      ),
      constraints: BoxConstraints(maxWidth: size.width, minWidth: size.width),
      items: <PopupMenuEntry>[
        PopupMenuLabel(
          label: Padding(
            padding: padding
                .add(const EdgeInsetsDirectional.symmetric(vertical: 6.0)),
            child: Text(
              widget.device.name,
              maxLines: 1,
              style: theme.textTheme.labelSmall,
            ),
          ),
        ),
        const PopupMenuDivider(),
        if (widget.selectable)
          PopupMenuItem(
            child: Text(
              widget.selected ? loc.removeFromView : loc.addToView,
            ),
            onTap: () {
              if (widget.selected) {
                view.remove(widget.device);
              } else {
                view.add(widget.device);
              }
            },
          ),
        if (widget.device.status)
          PopupMenuItem(
            child: Text(loc.showFullscreenCamera),
            onTap: () async {
              WidgetsBinding.instance.addPostFrameCallback((_) async {
                if (!context.mounted) return;
                var player = UnityPlayers.players[widget.device.uuid];
                final isLocalController = player == null;
                if (isLocalController) {
                  player = UnityPlayers.forDevice(widget.device);
                }

                await Navigator.of(context).pushNamed(
                  '/fullscreen',
                  arguments: {
                    'device': widget.device,
                    'player': player,
                  },
                );
                if (isLocalController) await player.dispose();
              });
            },
          ),
        if (isDesktop && widget.device.status)
          PopupMenuItem(
            child: Text(loc.openInANewWindow),
            onTap: () async {
              WidgetsBinding.instance.addPostFrameCallback((_) async {
                widget.device.openInANewWindow();
              });
            },
          ),
        const PopupMenuDivider(),
        PopupMenuItem(
          child: Text(loc.viewDeviceDetails),
          onTap: () async {
            WidgetsBinding.instance.addPostFrameCallback((_) async {
              if (!context.mounted) return;
              await showDeviceInfoDialog(context, widget.device);
            });
          },
        ),
      ],
    );
  }
}

class CollapsedSidebar extends StatelessWidget {
  final Widget collapseButton;

  const CollapsedSidebar({super.key, required this.collapseButton});

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsProvider>();
    final theme = Theme.of(context);
    final loc = AppLocalizations.of(context);
    final view = context.watch<DesktopViewProvider>();
    return Column(children: [
      collapseButton,
      SquaredIconButton(
        icon: Icon(
          view.currentLayout.type.icon,
          size: 20.0,
        ),
        tooltip: loc.switchToNext,
        onPressed: view.layouts.length > 1 ? view.switchToNextLayout : null,
      ),
      SquaredIconButton(
        icon: Icon(
          Icons.cyclone,
          size: 20.0,
          color: settings.kLayoutCycleEnabled.value
              ? theme.colorScheme.primary
              : IconTheme.of(context).color,
        ),
        tooltip: loc.cycle,
        onPressed: settings.toggleCycling,
      ),
      const Spacer(),
      SquaredIconButton(
        icon: const Icon(Icons.camera_outdoor, size: 20.0),
        tooltip: loc.addExternalStream,
        onPressed: () => AddExternalStreamDialog.show(context),
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
          style: TextStyle(color: theme.colorScheme.onPrimaryContainer),
        ),
      ),
    ]);
  }
}
