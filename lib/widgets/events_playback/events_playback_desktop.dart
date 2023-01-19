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

import 'package:bluecherry_client/api/api.dart';
import 'package:bluecherry_client/models/device.dart';
import 'package:bluecherry_client/models/event.dart';
import 'package:bluecherry_client/providers/events_playback_provider.dart';
import 'package:bluecherry_client/providers/server_provider.dart';
import 'package:bluecherry_client/providers/settings_provider.dart';
import 'package:bluecherry_client/utils/extensions.dart';
import 'package:bluecherry_client/widgets/device_grid/device_grid.dart';
import 'package:bluecherry_client/widgets/events_playback/events_playback.dart';
import 'package:bluecherry_client/widgets/misc.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:provider/provider.dart';

const kDeviceNameWidth = 140.0;
const kTimelineViewHeight = 190.0;

class EventsPlaybackDesktop extends StatefulWidget {
  final EventsData events;

  const EventsPlaybackDesktop({
    Key? key,
    required this.events,
  }) : super(key: key);

  @override
  State<EventsPlaybackDesktop> createState() => _EventsPlaybackDesktopState();
}

class _EventsPlaybackDesktopState extends State<EventsPlaybackDesktop> {
  double _thumbPosition = 0;

  @override
  Widget build(BuildContext context) {
    final events = context.watch<EventsProvider>();

    return Row(children: [
      Expanded(
        child: Column(children: [
          Expanded(
            child: Container(
              color: Colors.black,
              alignment: Alignment.center,
              child: events.selectedIds.isEmpty
                  ? const Text('Select an event')
                  : GridView.count(
                      crossAxisCount: 2,
                      childAspectRatio: 16 / 9,
                      children: events.selectedIds.map((id) {
                        final eventsForDevice = widget.events[id];

                        return Center(child: Text(id));
                      }).toList(),
                    ),
            ),
          ),
          SizedBox(
            height: kTimelineViewHeight,
            child: Card(
              margin: EdgeInsets.zero,
              shape: const RoundedRectangleBorder(),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                child: () {
                  final allEvents = (widget.events.isEmpty
                      ? <Event>[]
                      : widget.events.values
                          .reduce((value, element) => value + element))
                    ..sort((e1, e2) {
                      return e1.published.compareTo(e2.published);
                    });

                  final oldest = allEvents.isEmpty ? null : allEvents.first;
                  final newest = allEvents.isEmpty ? null : allEvents.last;

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          CircleAvatar(child: Icon(Icons.pause)),
                        ],
                      ),
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8.0),
                        child: Row(children: [
                          const SizedBox(
                            width: kDeviceNameWidth,
                            child: Text('Device name'),
                          ),
                          Text(
                            oldest == null
                                ? '--'
                                : SettingsProvider.instance.dateFormat
                                    .format(oldest.published),
                          ),
                          const Spacer(),
                          Text(
                            newest == null
                                ? '--'
                                : SettingsProvider.instance.dateFormat
                                    .format(newest.published),
                          ),
                        ]),
                      ),
                      Expanded(
                        child: Stack(children: [
                          Positioned.fill(
                            child: ListView.builder(
                              itemCount: widget.events.entries.length,
                              itemBuilder: (context, index) {
                                final e =
                                    widget.events.entries.elementAt(index);
                                final device = ServersProvider.instance.servers
                                    .findDevice(e.key);
                                if (device == null) {
                                  return const SizedBox.shrink();
                                }

                                final events = e.value;

                                return _DeviceTimelineTile(device: device);
                              },
                            ),
                          ),
                          Positioned(
                            top: 0,
                            bottom: 0,
                            left: kDeviceNameWidth,
                            child: Container(
                              height: double.infinity,
                              width: 2,
                              color: Theme.of(context).indicatorColor,
                            ),
                          ),
                        ]),
                      ),
                    ],
                  );
                }(),
              ),
            ),
          ),
        ]),
      ),
      ConstrainedBox(
        constraints: kSidebarConstraints,
        child: Material(
          child: Column(children: [
            Expanded(
              child: ListView.builder(
                padding: EdgeInsets.only(
                  bottom: MediaQuery.viewPaddingOf(context).bottom,
                ),
                itemCount: ServersProvider.instance.servers.length,
                itemBuilder: (context, i) {
                  final server = ServersProvider.instance.servers[i];
                  return FutureBuilder(
                    future: (() async => server.devices.isEmpty
                        ? API.instance.getDevices(
                            await API.instance.checkServerCredentials(server))
                        : true)(),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData) {
                        return Center(
                          child: Container(
                            alignment: AlignmentDirectional.center,
                            height: 156.0,
                            child: const CircularProgressIndicator.adaptive(),
                          ),
                        );
                      }

                      return ListView.builder(
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
                          if (!widget.events.keys
                              .contains(EventsProvider.idForDevice(device))) {
                            return const SizedBox.shrink();
                          }

                          final selected = events.selectedIds
                              .contains(EventsProvider.idForDevice(device));

                          return _DeviceTile(
                            device: device,
                            selected: selected,
                          );
                        },
                      );
                    },
                  );
                },
              ),
            ),
            SizedBox(
              height: kTimelineViewHeight,
              child: Card(
                margin: EdgeInsets.zero,
                shape: const RoundedRectangleBorder(),
                child: Padding(
                  padding: const EdgeInsets.only(
                    top: 8.0,
                    bottom: 8.0,
                    left: 8.0,
                    right: 16.0,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Text('Filter'),
                      Expanded(child: Placeholder()),
                    ],
                  ),
                ),
              ),
            ),
          ]),
        ),
      ),
    ]);
  }
}

class _DeviceTile extends StatefulWidget {
  const _DeviceTile({
    Key? key,
    required this.device,
    required this.selected,
  }) : super(key: key);

  final Device device;
  final bool selected;

  @override
  State<_DeviceTile> createState() => _DesktopDeviceSelectorTileState();
}

class _DesktopDeviceSelectorTileState extends State<_DeviceTile> {
  PointerDeviceKind? currentLongPressDeviceKind;

  @override
  Widget build(BuildContext context) {
    // subscribe to media query updates
    MediaQuery.of(context);
    final theme = Theme.of(context);
    final events = context.watch<EventsProvider>();

    return InkWell(
      onTap: !widget.device.status
          ? null
          : () {
              if (widget.selected) {
                events.remove(widget.device);
              } else {
                events.add(widget.device);
              }
            },
      child: SizedBox(
        height: 40.0,
        child: Row(children: [
          const SizedBox(width: 16.0),
          Container(
            height: 6.0,
            width: 6.0,
            margin: const EdgeInsetsDirectional.only(end: 8.0),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: widget.device.status ? Colors.green.shade100 : Colors.red,
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
          const SizedBox(width: 16.0),
        ]),
      ),
    );
  }
}

class _DeviceTimelineTile extends StatelessWidget {
  final Device device;

  const _DeviceTimelineTile({Key? key, required this.device}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 24.0,
      child: Material(
        child: Row(children: [
          SizedBox(
            width: kDeviceNameWidth,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              child: Text(
                '${device.server.name}/${device.name}',
                maxLines: 1,
                overflow: TextOverflow.fade,
              ),
            ),
          ),
          const VerticalDivider(
            width: 2,
          ),
          Expanded(
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: Colors.green.shade700,
                border: Border(
                  bottom: BorderSide(color: Theme.of(context).canvasColor),
                ),
              ),
              child: const SizedBox.expand(),
            ),
          ),
        ]),
      ),
    );
  }
}
