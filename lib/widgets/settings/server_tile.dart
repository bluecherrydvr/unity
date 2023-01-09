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

part of 'settings.dart';

typedef OnRemoveServer = void Function(BuildContext, Server);

class ServersList extends StatelessWidget {
  final ChangeTabCallback changeCurrentTab;

  const ServersList({
    Key? key,
    required this.changeCurrentTab,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, consts) {
      final theme = Theme.of(context);
      final serversProvider = context.watch<ServersProvider>();

      if (consts.maxWidth >= 800) {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12.0),
          child: Wrap(children: [
            ...serversProvider.servers.map((server) {
              return ServerCard(
                server: server,
                onRemoveServer: onRemoveServer,
              );
            }),
            SizedBox(
              height: 180,
              width: 180,
              child: Card(
                child: InkWell(
                  borderRadius: BorderRadius.circular(8.0),
                  onTap: () {
                    // Go to the "Add Server" tab.
                    changeCurrentTab.call(3);
                  },
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircleAvatar(
                          backgroundColor: Colors.transparent,
                          foregroundColor: Theme.of(context).iconTheme.color,
                          child: const Icon(Icons.add, size: 30.0),
                        ),
                        const SizedBox(height: 8.0),
                        Text(
                          AppLocalizations.of(context).addNewServer,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.titleSmall,
                        ),
                        const SizedBox(height: 15.0),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ]),
        );
      } else {
        return Column(
          children: [
            ...serversProvider.servers.map((server) {
              return ServerTile(
                server: server,
                onRemoveServer: onRemoveServer,
              );
            }),
            ListTile(
              leading: CircleAvatar(
                backgroundColor: Colors.transparent,
                foregroundColor: Theme.of(context).iconTheme.color,
                child: const Icon(Icons.add),
              ),
              title: Text(AppLocalizations.of(context).addNewServer),
              onTap: () {
                // Go to the "Add Server" tab.
                changeCurrentTab.call(3);
              },
            ),
            const Padding(
              padding: EdgeInsetsDirectional.only(top: 8.0),
              child: Divider(
                height: 1.0,
                thickness: 1.0,
              ),
            ),
          ],
        );
      }
    });
  }

  Future<void> onRemoveServer(BuildContext context, Server server) {
    return showDialog(
      context: context,
      builder: (context) => ConstrainedBox(
        constraints: const BoxConstraints(
          maxWidth: 300.0,
        ),
        child: AlertDialog(
          title: Text(AppLocalizations.of(context).remove),
          content: Text(
            AppLocalizations.of(context).removeServerDescription(server.name),
            style: Theme.of(context).textTheme.headline4,
            textAlign: TextAlign.start,
          ),
          actions: [
            MaterialButton(
              onPressed: Navigator.of(context).maybePop,
              child: Text(
                AppLocalizations.of(context).no.toUpperCase(),
                style: TextStyle(
                  color: Theme.of(context).colorScheme.secondary,
                ),
              ),
            ),
            MaterialButton(
              onPressed: () {
                ServersProvider.instance.remove(server);
                Navigator.of(context).maybePop();
              },
              child: Text(
                AppLocalizations.of(context).yes.toUpperCase(),
                style: TextStyle(
                  color: Theme.of(context).colorScheme.secondary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ServerTile extends StatefulWidget {
  final Server server;
  final OnRemoveServer onRemoveServer;

  const ServerTile({
    Key? key,
    required this.server,
    required this.onRemoveServer,
  }) : super(key: key);

  @override
  State<ServerTile> createState() => _ServerTileState();
}

class _ServerTileState extends State<ServerTile> {
  bool fetched = false;

  @override
  void initState() {
    super.initState();
    if (widget.server.devices.isEmpty) {
      WidgetsBinding.instance.addPostFrameCallback(
        (_) async {
          await API.instance.getDevices(
            await API.instance.checkServerCredentials(widget.server),
          );
          if (mounted) {
            setState(() {
              fetched = true;
            });
          }
        },
      );
    } else {
      setState(() => fetched = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: Colors.transparent,
        foregroundColor: Theme.of(context).iconTheme.color,
        child: const Icon(Icons.dns),
      ),
      title: Text(
        widget.server.name,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Text(
        fetched
            ? [
                if (widget.server.name != widget.server.ip) widget.server.ip,
                AppLocalizations.of(context)
                    .nDevices(widget.server.devices.length),
              ].join(' • ')
            : AppLocalizations.of(context).gettingDevices,
        overflow: TextOverflow.ellipsis,
      ),
      trailing: IconButton(
        icon: const Icon(
          Icons.delete,
        ),
        splashRadius: 24.0,
        onPressed: () => widget.onRemoveServer(context, widget.server),
      ),
    );
  }
}

class ServerCard extends StatefulWidget {
  final Server server;
  final OnRemoveServer onRemoveServer;

  const ServerCard({
    Key? key,
    required this.server,
    required this.onRemoveServer,
  }) : super(key: key);

  @override
  State<ServerCard> createState() => _ServerCardState();
}

class _ServerCardState extends State<ServerCard> {
  bool fetched = false;

  @override
  void initState() {
    super.initState();
    if (widget.server.devices.isEmpty) {
      WidgetsBinding.instance.addPostFrameCallback(
        (_) async {
          await API.instance.getDevices(
            await API.instance.checkServerCredentials(widget.server),
          );
          if (mounted) {
            setState(() {
              fetched = true;
            });
          }
        },
      );
    } else {
      setState(() => fetched = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SizedBox(
      height: 180,
      width: 180,
      child: Card(
        child: Stack(children: [
          Positioned.fill(
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircleAvatar(
                    backgroundColor: Colors.transparent,
                    foregroundColor: Theme.of(context).iconTheme.color,
                    child: const Icon(Icons.dns, size: 30.0),
                  ),
                  const SizedBox(height: 8.0),
                  Text(
                    widget.server.name,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.titleSmall,
                  ),
                  Text(
                    fetched
                        ? [
                            if (widget.server.name != widget.server.ip)
                              widget.server.ip,
                          ].join()
                        : AppLocalizations.of(context).gettingDevices,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.caption,
                  ),
                  Text(
                    fetched
                        ? AppLocalizations.of(context)
                            .nDevices(widget.server.devices.length)
                        : '',
                  ),
                  const SizedBox(height: 15.0),
                  Transform.scale(
                    scale: 0.9,
                    child: OutlinedButton(
                      child:
                          Text(AppLocalizations.of(context).disconnectServer),
                      onPressed: () {
                        widget.onRemoveServer(context, widget.server);
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
          PositionedDirectional(
            top: 4,
            end: 2,
            child: PopupMenuButton<Object>(
              iconSize: 20.0,
              splashRadius: 16.0,
              position: PopupMenuPosition.under,
              offset: const Offset(-128, 4.0),
              constraints: const BoxConstraints(maxWidth: 160.0),
              tooltip: AppLocalizations.of(context).serverOptions,
              itemBuilder: (context) {
                return [
                  PopupMenuItem(
                    child: Text(AppLocalizations.of(context).disconnectServer),
                    onTap: () {
                      widget.onRemoveServer(context, widget.server);
                    },
                  ),
                  const PopupMenuDivider(height: 1.0),
                  PopupMenuItem(
                    child: Text(AppLocalizations.of(context).browseEvents),
                    onTap: () {
                      // TODO(bdlukaa): browse events
                      // launchUrl(Uri.parse(widget.server.ip));
                    },
                  ),
                  PopupMenuItem(
                    child: Text(AppLocalizations.of(context).configureServer),
                    onTap: () {
                      launchUrl(Uri.parse(widget.server.ip));
                    },
                  ),
                  const PopupMenuDivider(height: 1.0),
                  PopupMenuItem(
                    child: Text(AppLocalizations.of(context).refreshDevices),
                    onTap: () async {
                      try {
                        await API.instance.getDevices(await API.instance
                            .checkServerCredentials(widget.server));
                      } catch (exception, stacktrace) {
                        debugPrint(exception.toString());
                        debugPrint(stacktrace.toString());
                      }
                    },
                  ),
                ];
              },
            ),
          ),
        ]),
      ),
    );
  }
}
