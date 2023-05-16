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

class MobileDeviceGrid extends StatefulWidget {
  const MobileDeviceGrid({super.key});

  @override
  State<MobileDeviceGrid> createState() => _MobileDeviceGridState();
}

class _MobileDeviceGridState extends State<MobileDeviceGrid> {
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
    timer = Timer.periodic(settings.layoutCyclingTogglePeriod, (timer) {
      final settings = SettingsProvider.instance;
      final view = MobileViewProvider.instance;

      if (settings.layoutCyclingEnabled) {
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
    final viewPadding = MediaQuery.viewPaddingOf(context);
    final theme = Theme.of(context);
    final loc = AppLocalizations.of(context);

    return Column(children: [
      SizedBox(height: viewPadding.top),
      if (view.tab == -1)
        const Spacer()
      else
        Expanded(
          child: PageTransitionSwitcher(
            child: {
              for (var key in view.devices.keys)
                key: _MobileDeviceGridChild(tab: key)
            }[view.tab],
            transitionBuilder: (child, primaryAnimation, secondaryAnimation) {
              return FadeThroughTransition(
                animation: primaryAnimation,
                secondaryAnimation: secondaryAnimation,
                fillColor: theme.colorScheme.background,
                child: child,
              );
            },
          ),
        ),
      DecoratedBox(
        decoration: const BoxDecoration(boxShadow: [
          BoxShadow(color: Colors.black45, blurRadius: 8.0),
        ]),
        child: Material(
          child: Container(
            height: kMobileBottomBarHeight + viewPadding.bottom,
            padding: EdgeInsets.only(
              left: 16.0 + viewPadding.horizontal,
              right: 16.0 + viewPadding.horizontal,
              bottom: viewPadding.bottom,
            ),
            width: double.infinity,
            child: Row(children: <Widget>[
              UnityDrawerButton(
                iconColor: theme.colorScheme.onBackground,
                iconSize: 18.0,
                splashRadius: 24.0,
              ),
              IconButton(
                icon: Icon(
                  Icons.cyclone,
                  size: 18.0,
                  color: settings.layoutCyclingEnabled
                      ? theme.colorScheme.primary
                      : theme.colorScheme.onBackground,
                ),
                padding: EdgeInsets.zero,
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
                      color: view.tab == tab ? theme.colorScheme.primary : null,
                    ),
                    child: IconButton(
                      onPressed: () => view.setTab(tab),
                      icon: Text(
                        '$tab',
                        style: TextStyle(
                          color: view.tab == tab
                              ? theme.colorScheme.onPrimary
                              : theme.colorScheme.onBackground,
                          fontSize: 18.0,
                        ),
                      ),
                    ),
                  ),
                );
              }),
            ]),
          ),
        ),
      ),
    ]);
  }
}

class _MobileDeviceGridChild extends StatelessWidget {
  final int tab;

  const _MobileDeviceGridChild({required this.tab});

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

    final children = view.devices[tab]!.asMap().entries.map(
      (e) {
        counts[e.value] = counts[e.value]! - 1;
        debugPrint(
            '${e.value}.${e.value?.server.serverUUID}.${counts[e.value]}');
        return MobileDeviceView(
          key: ValueKey(
            '${e.value}.${e.value?.server.serverUUID}.${counts[e.value]}',
          ),
          index: e.key,
          tab: tab,
        );
      },
    ).toList();

    return LayoutBuilder(builder: (context, consts) {
      final size = consts.biggest;

      return Container(
        alignment: Alignment.center,
        height: double.infinity,
        width: double.infinity,
        child: StaticGrid(
          // crossAxisSpacing: 0.0,
          // mainAxisSpacing: 0.0,
          crossAxisCount: <int, int>{
            6: 3,
            4: 2,
            2: 2,
          }[tab]!,
          childAspectRatio: <int, double>{
                4: size.width / size.height,
                2: size.width * 0.5 / size.height,
              }[tab] ??
              16 / 9,
          reorderable: view.current.any((device) => device != null),
          padding: EdgeInsets.zero,
          onReorder: (initial, end) => view.reorder(tab, initial, end),
          children: children,
        ),
      );
    });
  }
}
