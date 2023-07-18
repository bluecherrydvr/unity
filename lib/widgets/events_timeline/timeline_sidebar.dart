import 'package:bluecherry_client/providers/server_provider.dart';
import 'package:bluecherry_client/utils/extensions.dart';
import 'package:bluecherry_client/utils/tree_view/tree_view.dart';
import 'package:bluecherry_client/widgets/device_grid/device_grid.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class TimelineSidebar extends StatefulWidget {
  const TimelineSidebar({super.key});

  @override
  State<TimelineSidebar> createState() => _TimelineSidebarState();
}

class _TimelineSidebarState extends State<TimelineSidebar> {
  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: kSidebarConstraints,
      height: double.infinity,
      child: Card(
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadiusDirectional.vertical(
            top: Radius.circular(12.0),
          ),
        ),
        margin: const EdgeInsetsDirectional.symmetric(horizontal: 4.0),
        child: Column(
          children: [
            Expanded(
              child: buildTreeView(context, setState: setState),
            ),
          ],
        ),
      ),
    );
  }

  Widget buildTreeView(
    BuildContext context, {
    double checkboxScale = 0.8,
    double gapCheckboxText = 0.0,
    required void Function(VoidCallback fn) setState,
  }) {
    final theme = Theme.of(context);
    final servers = context.watch<ServersProvider>();

    return TreeView(
      indent: 56,
      iconSize: 18.0,
      nodes: servers.servers.map((server) {
        final isTriState = false;
        // disabledDevices
        //     .any((d) => server.devices.any((device) => device.rtspURL == d));
        final isOffline = !server.online;
        // final serverEvents = events[server];
        final serverEvents = [];

        return TreeNode(
          content: Row(children: [
            buildCheckbox(
              value: true,
              // value: !allowedServers.contains(server) || isOffline
              //     ? false
              //     : isTriState
              //         ? null
              //         : true,
              isError: isOffline,
              onChanged: (v) {
                setState(() {
                  // if (isTriState) {
                  //   disabledDevices.removeWhere((d) =>
                  //       server.devices.any((device) => device.rtspURL == d));
                  // } else if (v == null || !v) {
                  //   allowedServers.remove(server);
                  // } else {
                  //   allowedServers.add(server);
                  // }
                });
              },
              checkboxScale: checkboxScale,
            ),
            SizedBox(width: gapCheckboxText),
            Expanded(
              child: Text(
                server.name,
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
                softWrap: false,
              ),
            ),
            Text(
              '${server.devices.length}',
              style: theme.textTheme.labelSmall,
            ),
            const SizedBox(width: 10.0),
          ]),
          children: () {
            if (isOffline) {
              return <TreeNode>[];
            } else {
              return server.devices.sorted().map((device) {
                final enabled = true;
                // isOffline || !allowedServers.contains(server)
                //     ? false
                //     : !disabledDevices.contains(device.rtspURL);
                final eventsForDevice =
                    serverEvents?.where((event) => event.deviceID == device.id);
                return TreeNode(
                  content: Row(children: [
                    IgnorePointer(
                      ignoring: !device.status,
                      child: buildCheckbox(
                        value: device.status ? enabled : false,
                        isError: !device.status,
                        onChanged: (v) {
                          if (!device.status) return;

                          // setState(() {
                          //   if (enabled) {
                          //     disabledDevices.add(device.rtspURL);
                          //   } else {
                          //     disabledDevices.remove(device.rtspURL);
                          //   }
                          // });
                        },
                        checkboxScale: checkboxScale,
                      ),
                    ),
                    SizedBox(width: gapCheckboxText),
                    Flexible(
                      child: Text(
                        device.name,
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                        softWrap: false,
                      ),
                    ),
                    if (eventsForDevice != null) ...[
                      Text(
                        ' (${eventsForDevice.length})',
                        style: theme.textTheme.labelSmall,
                      ),
                      const SizedBox(width: 10.0),
                    ],
                  ]),
                );
              }).toList();
            }
          }(),
        );
      }).toList(),
    );
  }
}
