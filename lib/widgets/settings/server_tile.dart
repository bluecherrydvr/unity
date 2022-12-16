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
                          child: const Icon(Icons.add, size: 30.0),
                          backgroundColor: Colors.transparent,
                          foregroundColor: Theme.of(context).iconTheme.color,
                        ),
                        const SizedBox(height: 8.0),
                        Text(
                          AppLocalizations.of(context).addNewServer,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.titleSmall,
                        ),
                        // Text(
                        //   fetched
                        //       ? [
                        //           if (widget.server.name != widget.server.ip)
                        //             widget.server.ip,
                        //           AppLocalizations.of(context)
                        //               .nDevices(widget.server.devices.length),
                        //         ].join(' • ')
                        //       : AppLocalizations.of(context).gettingDevices,
                        //   overflow: TextOverflow.ellipsis,
                        //   style: theme.textTheme.caption,
                        // ),
                        const SizedBox(height: 15.0),
                        // Transform.scale(
                        //   scale: 0.9,
                        //   child: OutlinedButton(
                        //     child: const Text('Remove'),
                        //     onPressed: () =>
                        //         widget.onRemoveServer(context, widget.server),
                        //   ),
                        // ),
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
                child: const Icon(Icons.add),
                backgroundColor: Colors.transparent,
                foregroundColor: Theme.of(context).iconTheme.color,
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
        child: const Icon(Icons.dns),
        backgroundColor: Colors.transparent,
        foregroundColor: Theme.of(context).iconTheme.color,
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
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            CircleAvatar(
              child: const Icon(Icons.dns, size: 30.0),
              backgroundColor: Colors.transparent,
              foregroundColor: Theme.of(context).iconTheme.color,
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
                      AppLocalizations.of(context)
                          .nDevices(widget.server.devices.length),
                    ].join(' • ')
                  : AppLocalizations.of(context).gettingDevices,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.caption,
            ),
            const SizedBox(height: 15.0),
            Transform.scale(
              scale: 0.9,
              child: OutlinedButton(
                child: const Text('Disconnect'),
                onPressed: () => widget.onRemoveServer(context, widget.server),
              ),
            ),
          ]),
        ),
      ),
    );
  }
}
