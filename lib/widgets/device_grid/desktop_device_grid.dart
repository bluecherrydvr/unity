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

class DesktopDeviceGrid extends StatefulWidget {
  const DesktopDeviceGrid({Key? key}) : super(key: key);

  @override
  State<DesktopDeviceGrid> createState() => _DesktopDeviceGridState();
}

class _DesktopDeviceGridState extends State<DesktopDeviceGrid> {
  List<Device> devices = [];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final mq = MediaQuery.of(context);

    return Row(children: [
      Expanded(
        child: ReorderableGridView.count(
          physics: const NeverScrollableScrollPhysics(),
          shrinkWrap: true,
          crossAxisCount: 2,
          mainAxisSpacing: 0.0,
          crossAxisSpacing: 0.0,
          padding: EdgeInsets.zero,
          onReorder: (initial, end) {
            // TODO: reorder
          },
          children: devices.asMap().entries.map(
            (e) {
              // counts[e.value] = counts[e.value]! - 1;
              // debugPrint(
              //     '${e.value}.${e.value.server.serverUUID}.${counts[e.value]}');

              return Text(
                '${e.value}.${e.value.server.serverUUID}',
                key: ValueKey('${e.value}.${e.value.server.serverUUID}'),
              );
              // return DeviceTileSelector(
              //   key: ValueKey(
              //       '${e.value}.${e.value.server.serverUUID}.${counts[e.value]}'),
              //   index: e.key,
              //   tab: tab,
              // );
            },
          ).toList(),
          dragStartBehavior: DragStartBehavior.start,
        ),
      ),
      Container(
        width: 180.0,
        color: theme.appBarTheme.backgroundColor,
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
                      if (index == 0) return SubHeader(server.name);

                      index--;
                      return ListTile(
                        enabled: server.devices[index].status,
                        title: Text(
                          server.devices[index].name
                              .split(' ')
                              .map((e) => e[0].toUpperCase() + e.substring(1))
                              .join(' '),
                        ),
                        subtitle: Text([
                          (server.devices[index].status
                                  ? AppLocalizations.of(context).online
                                  : AppLocalizations.of(context).offline) +
                              ' • ' +
                              server.devices[index].uri,
                          '${server.devices[index].resolutionX}x${server.devices[index].resolutionY}',
                        ].join('\n')),
                        isThreeLine: true,
                        onTap: () {
                          // Navigator.of(context).pop(server.devices[index]);
                          setState(() {
                            devices.add(server.devices[index]);
                          });
                        },
                      );
                    },
                  );
                } else {
                  return Center(
                    child: Container(
                      alignment: AlignmentDirectional.center,
                      height: 156.0,
                      child: const CircularProgressIndicator(),
                    ),
                  );
                }
              },
            );
          },
        ),
      ),
    ]);
  }
}

class DesktopDeviceTile extends StatelessWidget {
  const DesktopDeviceTile({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container();
  }
}
