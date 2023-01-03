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

class DesktopSidebar extends StatefulWidget {
  const DesktopSidebar({Key? key}) : super(key: key);

  @override
  State<DesktopSidebar> createState() => _DesktopSidebarState();
}

class _DesktopSidebarState extends State<DesktopSidebar> {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final mq = MediaQuery.of(context);

    final view = context.watch<DesktopViewProvider>();

    return ConstrainedBox(
      constraints: const BoxConstraints(
        maxWidth: 220.0,
      ),
      child: Material(
        color: theme.canvasColor,
        child: Column(children: [
          const LayoutManager(),
          Expanded(
            child: Material(
              type: MaterialType.transparency,
              child: ListView.builder(
                itemCount: ServersProvider.instance.servers.length,
                itemBuilder: (context, i) {
                  final server = ServersProvider.instance.servers[i];
                  return FutureBuilder(
                    future: (() async => server.devices.isEmpty
                        ? API.instance.getDevices(
                            await API.instance.checkServerCredentials(server))
                        : true)(),
                    builder: (context, snapshot) {
                      if (snapshot.hasData) {
                        return ListView.builder(
                          padding: const EdgeInsets.symmetric(vertical: 10.0) +
                              mq.viewPadding,
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: server.devices.length + 1,
                          itemBuilder: (context, index) {
                            if (index == 0) {
                              return SubHeader(
                                server.name,
                                subtext: AppLocalizations.of(context).nDevices(
                                  server.devices.length,
                                ),
                              );
                            }

                            index--;
                            final device = server.devices[index];
                            final selected =
                                view.currentLayout.devices.contains(device);

                            return DesktopDeviceSelectorTile(
                              device: device,
                              selected: selected,
                            );
                          },
                        );
                      } else {
                        return Center(
                          child: Container(
                            alignment: AlignmentDirectional.center,
                            height: 156.0,
                            child: const CircularProgressIndicator.adaptive(),
                          ),
                        );
                      }
                    },
                  );
                },
              ),
            ),
          ),
        ]),
      ),
    );
  }
}

class DesktopDeviceSelectorTile extends StatelessWidget {
  const DesktopDeviceSelectorTile({
    Key? key,
    required this.device,
    required this.selected,
  }) : super(key: key);

  final Device device;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    MediaQuery.of(context);
    final view = context.watch<DesktopViewProvider>();

    return GestureDetector(
      onSecondaryTap: () => displayOptions(context),

      // On mobile platforms, display it on long press
      onLongPress: isDesktop ? null : () => displayOptions(context),
      child: ListTile(
        enabled: device.status,
        selected: selected,
        dense: true,
        title: Row(children: [
          Container(
            height: 6.0,
            width: 6.0,
            margin: const EdgeInsetsDirectional.only(end: 8.0),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: device.status ? Colors.green.shade100 : Colors.red,
            ),
          ),
          Expanded(
            child: Text(
              device.name
                  .split(' ')
                  // uppercase all first
                  .map((e) => e[0].toUpperCase() + e.substring(1))
                  .join(' '),
            ),
          ),
          // if (isMobile)
          IconButton(
            onPressed: device.status ? () => displayOptions(context) : null,
            icon: Icon(moreIconData),
          ),
        ]),
        onTap: () {
          if (selected) {
            view.remove(device);
          } else {
            view.add(device);
          }
        },
      ),
    );
  }

  void displayOptions(BuildContext context) {
    if (!device.status) return;

    final view = context.read<DesktopViewProvider>();

    const EdgeInsets padding = EdgeInsets.symmetric(horizontal: 16.0);

    final renderBox = context.findRenderObject() as RenderBox;
    final offset = renderBox.localToGlobal(Offset(
      padding.left,
      padding.top,
    ));
    final size = Size(
      renderBox.size.width - padding.right * 2,
      renderBox.size.height - padding.bottom,
    );

    showMenu(
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
            selected
                ? AppLocalizations.of(context).removeFromView
                : AppLocalizations.of(context).addToView,
          ),
          onTap: () {
            if (selected) {
              view.remove(device);
            } else {
              view.add(device);
            }
          },
        ),
        const PopupMenuDivider(height: 8),
        PopupMenuItem(
          child: Text(
            AppLocalizations.of(context).showFullscreenCamera,
          ),
          onTap: () async {
            WidgetsBinding.instance.addPostFrameCallback((_) async {
              var player = view.players[device];
              bool isLocalController = false;
              if (player == null) {
                player = getVideoPlayerControllerForDevice(device);
                isLocalController = true;
              }

              await Navigator.of(context).pushNamed(
                '/fullscreen',
                arguments: {
                  'device': device,
                  'player': player,
                },
              );
              if (isLocalController) await player.release();
            });
          },
        ),
        if (isDesktop)
          PopupMenuItem(
            child: Text(AppLocalizations.of(context).openInANewWindow),
            onTap: () async {
              WidgetsBinding.instance.addPostFrameCallback((_) async {
                device.openInANewWindow();
              });
            },
          ),
      ],
    );
  }
}
