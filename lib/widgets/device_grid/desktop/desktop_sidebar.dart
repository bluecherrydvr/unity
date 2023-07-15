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
const kSidebarConstraints = BoxConstraints(maxWidth: 220.0);
const kCompactSidebarConstraints = BoxConstraints(maxWidth: 65.0);

class DesktopSidebar extends StatefulWidget {
  final Widget collapseButton;

  const DesktopSidebar({
    super.key,
    required this.collapseButton,
  });

  @override
  State<DesktopSidebar> createState() => _DesktopSidebarState();
}

class _DesktopSidebarState extends State<DesktopSidebar> {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final loc = AppLocalizations.of(context);

    final servers = context.watch<ServersProvider>();
    final view = context.watch<DesktopViewProvider>();

    return Material(
      color: theme.canvasColor,
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        LayoutManager(collapseButton: widget.collapseButton),
        Expanded(
          child: Material(
            type: MaterialType.transparency,
            child: ListView.builder(
              padding: EdgeInsetsDirectional.only(
                bottom: MediaQuery.viewPaddingOf(context).bottom,
              ),
              itemCount: ServersProvider.instance.servers.length,
              itemBuilder: (context, i) {
                final server = ServersProvider.instance.servers[i];
                final devices = server.devices.sorted();
                final isLoading = servers.isServerLoading(server);

                return ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount:
                      !server.online || isLoading ? 1 : devices.length + 1,
                  itemBuilder: (context, index) {
                    if (index == 0) {
                      return SubHeader(
                        server.name,
                        subtext: server.online
                            ? loc.nDevices(
                                devices.length,
                              )
                            : loc.offline,
                        subtextStyle: TextStyle(
                          color:
                              !server.online ? theme.colorScheme.error : null,
                        ),
                        trailing: isLoading
                            ? const SizedBox(
                                height: 16.0,
                                width: 16.0,
                                child: CircularProgressIndicator.adaptive(
                                  strokeWidth: 1.5,
                                ),
                              )
                            : null,
                      );
                    }

                    index--;
                    final device = devices[index];
                    final selected =
                        view.currentLayout.devices.contains(device);

                    final tile = DesktopDeviceSelectorTile(
                      device: device,
                      selected: selected,
                    );

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
                              const Icon(
                                Icons.block,
                                color: Colors.red,
                                size: 18.0,
                              ),
                            const SizedBox(width: 16.0),
                          ]),
                        ),
                      ),
                      child: tile,
                    );
                  },
                );
              },
            ),
          ),
        ),
      ]),
    );
  }
}

class DesktopDeviceSelectorTile extends StatefulWidget {
  const DesktopDeviceSelectorTile({
    super.key,
    required this.device,
    required this.selected,
  });

  final Device device;
  final bool selected;

  @override
  State<DesktopDeviceSelectorTile> createState() =>
      _DesktopDeviceSelectorTileState();
}

class _DesktopDeviceSelectorTileState extends State<DesktopDeviceSelectorTile> {
  PointerDeviceKind? currentLongPressDeviceKind;

  bool hovering = false;

  @override
  Widget build(BuildContext context) {
    // subscribe to media query updates
    MediaQuery.of(context);
    final theme = Theme.of(context);
    final view = context.watch<DesktopViewProvider>();
    final loc = AppLocalizations.of(context);

    return GestureDetector(
      onSecondaryTap: () => _displayOptions(context),

      // Only display options on long press if it's caused by a touch input
      onLongPressEnd: (details) {
        switch (currentLongPressDeviceKind) {
          case PointerDeviceKind.touch:
            _displayOptions(context);
            break;
          default:
            break;
        }

        currentLongPressDeviceKind = null;
      },
      onLongPressDown: (details) => currentLongPressDeviceKind = details.kind,
      child: InkWell(
        onTap: !widget.device.status
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
            height: kDeviceSelectorTileHeight,
            child: Row(children: [
              const SizedBox(width: 16.0),
              Container(
                height: 6.0,
                width: 6.0,
                margin: const EdgeInsetsDirectional.only(end: 8.0),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: widget.device.status
                      ? theme.extension<UnityColors>()!.successColor
                      : theme.colorScheme.error,
                ),
              ),
              Expanded(
                child: Text(
                  widget.device.name.uppercaseFirst(),
                  style: theme.textTheme.titleMedium!.copyWith(
                    color: widget.selected
                        ? theme.colorScheme.primary
                        : !widget.device.status
                            ? theme.disabledColor
                            : null,
                  ),
                ),
              ),
              if (isMobile || hovering)
                Tooltip(
                  message: loc.cameraOptions,
                  preferBelow: false,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(4.0),
                    onTap: widget.device.status
                        ? () => _displayOptions(context)
                        : null,
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
      constraints: BoxConstraints(
        maxWidth: size.width,
        minWidth: size.width,
      ),
      items: <PopupMenuEntry>[
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
        const PopupMenuDivider(height: 8),
        PopupMenuItem(
          child: Text(
            loc.showFullscreenCamera,
          ),
          onTap: () async {
            WidgetsBinding.instance.addPostFrameCallback((_) async {
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
                },
              );
              if (isLocalController) await player.release();
            });
          },
        ),
        if (isDesktop)
          PopupMenuItem(
            child: Text(loc.openInANewWindow),
            onTap: () async {
              WidgetsBinding.instance.addPostFrameCallback((_) async {
                widget.device.openInANewWindow();
              });
            },
          ),
      ],
    );
  }
}
