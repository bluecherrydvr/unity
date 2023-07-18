import 'package:bluecherry_client/providers/settings_provider.dart';
import 'package:bluecherry_client/utils/extensions.dart';
import 'package:bluecherry_client/utils/tree_view/tree_view.dart';
import 'package:bluecherry_client/widgets/device_grid/device_grid.dart';
import 'package:bluecherry_client/widgets/events_timeline/events_playback.dart';
import 'package:bluecherry_client/widgets/events_timeline/timeline.dart';
import 'package:bluecherry_client/widgets/misc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class TimelineSidebar extends StatefulWidget {
  const TimelineSidebar({super.key, required this.timeline});

  final Timeline timeline;

  @override
  State<TimelineSidebar> createState() => _TimelineSidebarState();
}

class _TimelineSidebarState extends State<TimelineSidebar> {
  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);

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
        child: Column(children: [
          SubHeader(loc.servers, height: 40.0),
          Expanded(
            child: buildTreeView(context, setState: setState),
          ),
          const SubHeader('Time filter', height: 24.0),
          ListTile(
            title: Text(SettingsProvider.instance.dateFormat
                .format(widget.timeline.currentDate)),
            onTap: () async {
              final date = await showDatePicker(
                context: context,
                initialDate: widget.timeline.currentDate,
                firstDate: DateTime(DateTime.now().year),
                lastDate: DateTime.now(),
                initialEntryMode: DatePickerEntryMode.calendarOnly,
                currentDate: widget.timeline.currentDate,
              );
              debugPrint('date: $date');
            },
          ),
        ]),
      ),
    );
  }

  Widget buildTreeView(
    BuildContext context, {
    double checkboxScale = 0.8,
    double gapCheckboxText = 0.0,
    required void Function(VoidCallback fn) setState,
  }) {
    if (eventsPlaybackScreenKey.currentState == null) {
      return const SizedBox.shrink();
    }
    final state = eventsPlaybackScreenKey.currentState!;

    final theme = Theme.of(context);
    final servers = state.devices.keys.map((d) => d.server).toSet();

    return TreeView(
      indent: 56,
      iconSize: 18.0,
      nodes: servers.map((server) {
        final isTriState = state.disabledDevices.any(server.devices.contains);
        final isOffline = !server.online;

        final serverDevices =
            server.devices.where(state.realDevices.containsKey).sorted();

        return TreeNode(
          content: Row(children: [
            buildCheckbox(
              value: isOffline ||
                      !widget.timeline.tiles.any(
                        (tile) => server.devices.contains(tile.device),
                      )
                  ? false
                  : isTriState
                      ? null
                      : true,
              isError: isOffline,
              onChanged: (v) {
                if (isTriState || v == null || !v) {
                  for (final device in serverDevices) {
                    if (widget.timeline.tiles
                        .any((tile) => tile.device == device)) {
                      widget.timeline.removeTile(
                        widget.timeline.tiles
                            .firstWhere((tile) => tile.device == device),
                      );
                    }
                  }
                } else {
                  for (final device in serverDevices) {
                    widget.timeline.add([
                      state.realDevices.entries
                          .firstWhere((e) => e.key == device)
                          .buildTimelineTile(),
                    ]);
                  }
                }

                setState(() {});
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
              '${serverDevices.length}',
              style: theme.textTheme.labelSmall,
            ),
            const SizedBox(width: 10.0),
          ]),
          children: () {
            if (isOffline) {
              return <TreeNode>[];
            } else {
              return serverDevices.map((device) {
                final enabled = widget.timeline.tiles.any(
                  (tile) => tile.device == device,
                );
                final eventsForDevice = state.devices[device];

                return TreeNode(
                  content: Row(children: [
                    IgnorePointer(
                      ignoring: !device.status,
                      child: buildCheckbox(
                        value: device.status ? enabled : false,
                        isError: !device.status,
                        onChanged: (v) {
                          if (!device.status) return;

                          if (enabled && state.disabledDevices.length < 4) {
                            widget.timeline.removeTile(
                              widget.timeline.tiles.firstWhere(
                                (tile) => tile.device == device,
                              ),
                            );
                          } else if (state.realDevices.entries
                                  .any((e) => e.key == device) &&
                              !enabled) {
                            widget.timeline.add([
                              state.realDevices.entries
                                  .firstWhere((e) => e.key == device)
                                  .buildTimelineTile(),
                            ]);
                          }
                          setState(() {});
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
