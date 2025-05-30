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

class SmallDeviceGrid extends StatefulWidget {
  const SmallDeviceGrid({super.key});

  @override
  State<SmallDeviceGrid> createState() => _SmallDeviceGridState();
}

class _SmallDeviceGridState extends State<SmallDeviceGrid> {
  Timer? timer;

  @override
  void initState() {
    super.initState();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersive);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final settings = context.watch<SettingsProvider>();
    timer?.cancel();
    timer = Timer.periodic(settings.kLayoutCyclePeriod.value, (timer) {
      final settings = SettingsProvider.instance;
      final view = MobileViewProvider.instance;

      if (settings.kLayoutCycleEnabled.value) {
        if (view.tab == view.devices.keys.last) {
          view.setTab(view.devices.keys.first);
        } else {
          final index = view.devices.keys.toList().indexOf(view.tab);
          final next = view.devices.keys.toList()[index + 1];
          view.setTab(next);
        }
      }
    });
  }

  @override
  void dispose() {
    timer?.cancel();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final view = context.watch<MobileViewProvider>();
    final settings = context.watch<SettingsProvider>();
    final theme = Theme.of(context);
    final loc = AppLocalizations.of(context);

    return Column(
      children: [
        if (view.tab == -1)
          const Spacer()
        else
          Expanded(
            child: SafeArea(
              bottom: false,
              child: PageTransitionSwitcher(
                child: view.devices.keys
                    .map((key) => _SmallDeviceGridChild(tab: key))
                    .elementAt(
                      view.devices.keys
                          .toList()
                          .indexOf(view.tab)
                          .clamp(0, view.devices.length - 1),
                    ),
                transitionBuilder: (
                  child,
                  primaryAnimation,
                  secondaryAnimation,
                ) {
                  return FadeThroughTransition(
                    animation: primaryAnimation,
                    secondaryAnimation: secondaryAnimation,
                    fillColor: theme.colorScheme.surface,
                    child: child,
                  );
                },
              ),
            ),
          ),
        Material(
          child: SafeArea(
            top: false,
            child: Container(
              height: kMobileBottomBarHeight,
              padding: const EdgeInsetsDirectional.symmetric(horizontal: 16.0),
              width: double.infinity,
              child: Row(
                children: <Widget>[
                  UnityDrawerButton(
                    iconColor: theme.colorScheme.onSurface,
                    iconSize: 18.0,
                    splashRadius: 24.0,
                  ),
                  IconButton(
                    icon: Icon(
                      Icons.cyclone,
                      size: 18.0,
                      color:
                          settings.kLayoutCycleEnabled.value
                              ? theme.colorScheme.primary
                              : theme.colorScheme.onSurface,
                    ),
                    tooltip: loc.cycle,
                    onPressed: settings.toggleCycling,
                  ),
                  const Spacer(),
                  ...view.devices.keys.map((tab) {
                    return Container(
                      height: 48.0,
                      width: 48.0,
                      alignment: AlignmentDirectional.centerEnd,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(100),
                          color:
                              view.tab == tab
                                  ? theme.colorScheme.primary
                                  : null,
                        ),
                        child: IconButton(
                          onPressed: () => view.setTab(tab),
                          icon: Text(
                            '$tab',
                            style: TextStyle(
                              color:
                                  view.tab == tab
                                      ? theme.colorScheme.onPrimary
                                      : theme.colorScheme.onSurface,
                              fontSize: 18.0,
                            ),
                          ),
                        ),
                      ),
                    );
                  }),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _SmallDeviceGridChild extends StatelessWidget {
  final int tab;

  const _SmallDeviceGridChild({required this.tab});

  @override
  Widget build(BuildContext context) {
    final view = context.watch<MobileViewProvider>();
    if (tab == 1) {
      return MobileDeviceView(
        key: ValueKey(Random().nextInt((pow(2, 31)) ~/ 1 - 1)),
        index: 0,
        tab: 1,
      );
    }

    // Since, multiple tiles showing same camera can exist in a same tab.
    // This [Map] is used for assigning unique [ValueKey] to each.
    final counts = <Device?, int>{};
    for (final device in view.devices[tab]!) {
      counts[device] = !counts.containsKey(device) ? 1 : counts[device]! + 1;
    }

    final children =
        view.devices[tab]!.asMap().entries.map((e) {
          counts[e.value] = counts[e.value]! - 1;
          debugPrint(
            '${e.value}.${e.value?.server.serverUUID}.${counts[e.value]}',
          );
          return MobileDeviceView(
            key: ValueKey(
              '${e.value}.${e.value?.server.serverUUID}.${counts[e.value]}',
            ),
            index: e.key,
            tab: tab,
          );
        }).toList();

    return LayoutBuilder(
      builder: (context, consts) {
        final size = consts.biggest;

        final width = size.width - kGridInnerPadding;
        final height = size.height - kGridInnerPadding;

        return Container(
          height: size.height,
          width: size.width,
          padding: const EdgeInsetsDirectional.all(kGridInnerPadding),
          child: AspectRatio(
            aspectRatio: kHorizontalAspectRatio,
            child: Center(
              child: StaticGrid(
                crossAxisCount: switch (tab) {
                  9 => 3,
                  6 => 3,
                  4 => 2,
                  2 => 2,
                  _ => 1,
                },
                childAspectRatio: switch (tab) {
                  2 => width * 0.5 / height,
                  4 => width / height,
                  _ => kHorizontalAspectRatio,
                },
                reorderable: view.current.any((device) => device != null),
                padding: EdgeInsetsDirectional.zero,
                onReorder: (initial, end) => view.reorder(tab, initial, end),
                children: children,
              ),
            ),
          ),
        );
      },
    );
  }
}
