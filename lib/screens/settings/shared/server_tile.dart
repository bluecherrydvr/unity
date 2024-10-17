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

part of '../settings_mobile.dart';

typedef OnRemoveServer = void Function(BuildContext, Server);

class ServersList extends StatelessWidget {
  const ServersList({super.key});

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final home = context.watch<HomeProvider>();
    final serversProvider = context.watch<ServersProvider>();

    void addServersScreen() {
      home
        ..automaticallyGoToAddServersScreen = true
        ..setTab(UnityTab.addServer, context);
    }

    return LayoutBuilder(builder: (context, consts) {
      if (consts.maxWidth >= kMobileBreakpoint.width) {
        return Padding(
          padding: const EdgeInsetsDirectional.symmetric(horizontal: 12.0),
          child: Wrap(children: [
            ...serversProvider.servers.map((server) {
              return ServerCard(server: server, onRemoveServer: onRemoveServer);
            }),
            SizedBox(
              height: 180,
              width: 180,
              child: Card(
                child: InkWell(
                  borderRadius: BorderRadius.circular(8.0),
                  onTap: addServersScreen,
                  child: Padding(
                    padding: const EdgeInsetsDirectional.all(8.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircleAvatar(
                          backgroundColor: Colors.transparent,
                          foregroundColor: theme.iconTheme.color,
                          child: const Icon(Icons.add, size: 30.0),
                        ),
                        const SizedBox(height: 8.0),
                        Text(
                          loc.addNewServer,
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
        return Column(children: [
          ...serversProvider.servers.map((server) {
            return ServerTile(
              server: server,
              onRemoveServer: onRemoveServer,
            );
          }),
          ListTile(
            leading: CircleAvatar(
              backgroundColor: Colors.transparent,
              foregroundColor: theme.iconTheme.color,
              child: const Icon(Icons.add),
            ),
            title: Text(loc.addNewServer),
            onTap: addServersScreen,
          ),
          const Padding(
            padding: EdgeInsetsDirectional.only(top: 8.0),
            child: Divider(
              height: 1.0,
              thickness: 1.0,
            ),
          ),
        ]);
      }
    });
  }

  Future<void> onRemoveServer(BuildContext context, Server server) {
    return showDialog(
      context: context,
      builder: (context) {
        final theme = Theme.of(context);
        final loc = AppLocalizations.of(context);

        return AlertDialog(
          title: Text(loc.areYouSure),
          content: ConstrainedBox(
            constraints: const BoxConstraints(
              maxWidth: 300.0,
            ),
            child: Text(
              loc.removeServerDescription(server.name),
              style: theme.textTheme.headlineMedium,
              textAlign: TextAlign.start,
            ),
          ),
          actions: [
            OutlinedButton(
              onPressed: () {
                ServersProvider.instance.remove(server);
                Navigator.of(context).maybePop();
              },
              child: Text(
                loc.yes.toUpperCase(),
                style: TextStyle(
                  color: theme.colorScheme.secondary,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: Navigator.of(context).maybePop,
              autofocus: true,
              child: Text(
                loc.no.toUpperCase(),
                style: TextStyle(
                  color: theme.colorScheme.secondary,
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class ServerTile extends StatelessWidget {
  final Server server;
  final OnRemoveServer onRemoveServer;

  const ServerTile({
    super.key,
    required this.server,
    required this.onRemoveServer,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final servers = context.watch<ServersProvider>();
    final isLoading = servers.isServerLoading(server);
    final loc = AppLocalizations.of(context);

    void showMenu([Offset? position]) {
      final box = context.findRenderObject() as RenderBox;
      final pos = position ?? box.localToGlobal(Offset(box.size.width, 0));

      showServerMenu(
        context: context,
        onRemoveServer: onRemoveServer,
        server: server,
        pos: pos,
      );
    }

    return GestureDetector(
      onSecondaryTapUp: (d) => showMenu(d.globalPosition),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Colors.transparent,
          foregroundColor:
              server.online ? theme.iconTheme.color : theme.colorScheme.error,
          child:
              Icon(server.online ? Icons.dns : Icons.desktop_access_disabled),
        ),
        title: Text(
          server.name,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Text(
          !isLoading
              ? [
                  if (server.name != server.ip) server.ip,
                  if (server.online)
                    loc.nDevices(server.devices.length)
                  else
                    loc.offline,
                  if (!server.passedCertificates) loc.certificateNotPassed
                ].join(' • ')
              : loc.gettingDevices,
          overflow: TextOverflow.ellipsis,
        ),
        trailing: SquaredIconButton(
          icon: Icon(
            Icons.delete,
            color: theme.colorScheme.error,
          ),
          tooltip: loc.disconnectServer,
          // splashRadius: 24.0,
          onPressed: () => onRemoveServer(context, server),
        ),
        onTap: () {
          showEditServer(context, server);
        },
        onLongPress: showMenu,
      ),
    );
  }
}

class ServerCard extends StatelessWidget {
  final Server server;
  final OnRemoveServer onRemoveServer;

  const ServerCard({
    super.key,
    required this.server,
    required this.onRemoveServer,
  });

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final servers = context.watch<ServersProvider>();
    final settings = context.watch<SettingsProvider>();

    final isLoading = servers.isServerLoading(server);

    void showMenu() {
      final box = context.findRenderObject() as RenderBox;
      final pos = box.localToGlobal(const Offset(6.0, 50.0));

      showServerMenu(
        context: context,
        onRemoveServer: onRemoveServer,
        server: server,
        pos: pos,
      );
    }

    return GestureDetector(
      onSecondaryTap: showMenu,
      child: ConstrainedBox(
        constraints: const BoxConstraints(
          minHeight: 180.0,
          maxHeight: 200.0,
          minWidth: 180.0,
          maxWidth: 200.0,
        ),
        child: Card(
          child: Stack(alignment: AlignmentDirectional.center, children: [
            Padding(
              padding: const EdgeInsetsDirectional.all(8.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircleAvatar(
                    backgroundColor: Colors.transparent,
                    foregroundColor: theme.iconTheme.color,
                    child: const Icon(Icons.dns, size: 30.0),
                  ),
                  const SizedBox(height: 8.0),
                  Text(
                    server.name,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.titleSmall,
                  ),
                  Text(
                    !isLoading
                        ? [
                            if (server.name != server.ip) server.ip,
                          ].join()
                        : loc.gettingDevices,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodySmall,
                  ),
                  Text(
                    () {
                      if (!settings.checkServerCertificates(server)) {
                        return loc.certificateNotPassed;
                      } else if (!server.online) {
                        return loc.offline;
                      } else if (!isLoading) {
                        return loc.nDevices(server.devices.length);
                      }

                      return '';
                    }(),
                    style: TextStyle(
                      color: () {
                        if (!settings.checkServerCertificates(server)) {
                          return theme.colorScheme.error;
                        } else if (!server.online) {
                          return theme.colorScheme.error;
                        }

                        return null;
                      }(),
                      fontWeight: FontWeight.w600,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12.0),
                  Transform.scale(
                    scale: 0.9,
                    child: OutlinedButton(
                      child: Text(loc.disconnectServer),
                      onPressed: () {
                        onRemoveServer(context, server);
                      },
                    ),
                  ),
                ],
              ),
            ),
            PositionedDirectional(
              top: 4,
              start: 0,
              end: 0,
              child: Row(children: [
                if (isLoading)
                  const Padding(
                    padding: EdgeInsetsDirectional.only(start: 12.0),
                    child: SizedBox(
                      height: 18.0,
                      width: 18.0,
                      child:
                          CircularProgressIndicator.adaptive(strokeWidth: 1.5),
                    ),
                  )
                else if (server.online)
                  Padding(
                    padding: EdgeInsetsDirectional.only(start: 12.0),
                    child: Tooltip(
                      message: 'Online',
                      child: Icon(Icons.check, size: 18.0, color: Colors.green),
                    ),
                  )
                else if (server.additionResponse ==
                    ServerAdditionResponse.wrongCredentials)
                  Padding(
                    padding: EdgeInsetsDirectional.only(start: 12.0),
                    child: Tooltip(
                      message: 'Wrong credentials',
                      child: Icon(
                        Icons.vpn_key,
                        size: 18.0,
                        color: theme.colorScheme.error,
                      ),
                    ),
                  )
                else ...[
                  Padding(
                    padding: EdgeInsetsDirectional.only(start: 12.0),
                    child: Tooltip(
                      message: switch (server.additionResponse) {
                        ServerAdditionResponse.wrongCredentials =>
                          loc.serverWrongCredentialsShort,
                        ServerAdditionResponse.versionMismatch =>
                          loc.serverVersionMismatchShort,
                        _ => loc.offline,
                      },
                      child: Icon(
                        switch (server.additionResponse) {
                          ServerAdditionResponse.wrongCredentials =>
                            Icons.vpn_key,
                          ServerAdditionResponse.versionMismatch => Icons.rule,
                          _ => Icons.domain_disabled,
                        },
                        size: 18.0,
                        color: theme.colorScheme.error,
                      ),
                    ),
                  )
                ],
                Spacer(),
                SquaredIconButton(
                  tooltip: loc.serverOptions,
                  icon: Icon(moreIconData, size: 20.0),
                  onPressed: showMenu,
                ),
              ]),
            ),
          ]),
        ),
      ),
    );
  }
}

Future showServerMenu({
  required BuildContext context,
  required Offset pos,
  required Server server,
  required OnRemoveServer onRemoveServer,
}) {
  final home = context.read<HomeProvider>();
  final servers = context.read<ServersProvider>();
  final loc = AppLocalizations.of(context);
  final theme = Theme.of(context);

  return showMenu(
    context: context,
    position: RelativeRect.fromLTRB(
      pos.dx,
      pos.dy,
      pos.dx + 180.0,
      pos.dy + 200,
    ),
    color: theme.dialogBackgroundColor,
    items: <PopupMenuEntry>[
      PopupMenuItem(
        child: Text(loc.editServerInfo),
        onTap: () {
          WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
            if (context.mounted) showEditServer(context, server);
          });
        },
      ),
      PopupMenuItem(
        child: Text(loc.editServerSettingsInfo),
        onTap: () {
          WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
            if (context.mounted) showEditServerSettings(context, server);
          });
        },
      ),
      PopupMenuItem(
        child: Text(loc.disconnectServer),
        onTap: () {
          WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
            if (context.mounted) {
              onRemoveServer(context, server);
            }
          });
        },
      ),
      const PopupMenuDivider(height: 1.0),
      PopupMenuItem(
        child: Text(loc.browseEvents),
        onTap: () => home.setTab(UnityTab.eventsHistory, context),
      ),
      PopupMenuItem(
        child: Text(loc.configureServer),
        onTap: () {
          launchUrl(Uri.parse(server.ip));
        },
      ),
      const PopupMenuDivider(height: 1.0),
      PopupMenuItem(
        child: Text(server.online ? loc.refreshDevices : loc.refreshServer),
        onTap: () async {
          servers.refreshDevices(ids: [server.id]);
        },
      ),
      if (server.online)
        PopupMenuItem(
          child: Text(loc.viewDevices),
          onTap: () async {
            showDialog(
              context: context,
              builder: (context) => DevicesListDialog(server: server),
            );
          },
        ),
    ],
  );
}

class DevicesListDialog extends StatelessWidget {
  final Server server;

  const DevicesListDialog({super.key, required this.server});

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    return AlertDialog(
      title: Text(loc.serverDevices(server.name)),
      contentPadding: const EdgeInsetsDirectional.symmetric(
        horizontal: 16.0,
        vertical: 12.0,
      ),
      content: SizedBox(
        width: kSidebarConstraints.maxWidth,
        child: ListView.builder(
          itemCount: server.devices.length,
          shrinkWrap: true,
          itemBuilder: (context, index) {
            final device = server.devices[index];
            return DeviceSelectorTile(
              device: device,
              selected: false,
              selectable: false,
            );
          },
        ),
      ),
    );
  }
}
