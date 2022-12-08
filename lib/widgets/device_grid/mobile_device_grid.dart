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

class MobileDeviceGrid extends StatefulWidget {
  const MobileDeviceGrid({
    Key? key,
  }) : super(key: key);

  @override
  State<MobileDeviceGrid> createState() => _MobileDeviceGridState();
}

class _MobileDeviceGridState extends State<MobileDeviceGrid> {
  @override
  Widget build(BuildContext context) {
    return Consumer<MobileViewProvider>(
      builder: (context, view, _) => Column(children: [
        if (view.tab == -1)
          const Spacer()
        else
          Expanded(
            child: PageTransitionSwitcher(
              child: {
                1: () => const _MobileDeviceGridChild(tab: 1),
                2: () => const _MobileDeviceGridChild(tab: 2),
                4: () => const _MobileDeviceGridChild(tab: 4),
              }[view.tab]!(),
              transitionBuilder:
                  (child, primaryAnimation, secondaryAnimation) =>
                      FadeThroughTransition(
                animation: primaryAnimation,
                secondaryAnimation: secondaryAnimation,
                child: child,
                fillColor: Colors.black,
              ),
            ),
          ),
        Container(
          decoration: const BoxDecoration(
            boxShadow: [
              BoxShadow(color: Colors.black45, blurRadius: 8.0),
            ],
          ),
          child: Material(
            color: Theme.of(context).primaryColor,
            child: Container(
              height: kMobileBottomBarHeight,
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              width: MediaQuery.of(context).size.width,
              child: Row(children: <Widget>[
                if (Scaffold.of(context).hasDrawer)
                  IconButton(
                    onPressed: Scaffold.of(context).openDrawer,
                    icon: const Icon(Icons.menu),
                    iconSize: 18.0,
                    color: Colors.white,
                    splashRadius: 24.0,
                  ),
                const Spacer(),
                ...[1, 2, 4].map((e) {
                  final child = view.tab == e
                      ? Card(
                          margin: EdgeInsets.zero,
                          elevation: 4.0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20.0),
                          ),
                          child: Container(
                            height: 40.0,
                            width: 40.0,
                            alignment: AlignmentDirectional.center,
                            child: Container(
                              height: 28.0,
                              width: 28.0,
                              alignment: AlignmentDirectional.center,
                              child: Text(
                                e.toString(),
                                style: const TextStyle(
                                  color: Colors.black,
                                  fontSize: 18.0,
                                ),
                              ),
                              decoration: BoxDecoration(
                                border: Border.all(
                                  color: Theme.of(context).primaryColor,
                                  width: 2.0,
                                ),
                                borderRadius: BorderRadius.circular(14.0),
                              ),
                            ),
                          ),
                          color: Colors.white,
                        )
                      : Text(
                          e.toString(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18.0,
                          ),
                        );
                  return Container(
                    height: 48.0,
                    width: 48.0,
                    alignment: AlignmentDirectional.centerEnd,
                    child: IconButton(
                      onPressed: () => view.setTab(e),
                      icon: child,
                    ),
                  );
                }).toList(),
              ]),
            ),
          ),
        ),
      ]),
    );
  }
}

class _MobileDeviceGridChild extends StatelessWidget {
  final int tab;
  const _MobileDeviceGridChild({
    Key? key,
    required this.tab,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Consumer<MobileViewProvider>(builder: (context, view, _) {
      if (tab == 1) {
        return DeviceTileSelector(
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
          return DeviceTileSelector(
            key: ValueKey(
                '${e.value}.${e.value?.server.serverUUID}.${counts[e.value]}'),
            index: e.key,
            tab: tab,
          );
        },
      ).toList();
      return Container(
        color: Colors.black,
        height: double.infinity,
        width: double.infinity,
        child: ReorderableGridView.count(
          physics: const NeverScrollableScrollPhysics(),
          shrinkWrap: true,
          crossAxisCount: <int, int>{
            4: 2,
            2: 2,
          }[tab]!,
          childAspectRatio: <int, double>{
            if (Platform.isIOS) ...{
              4: (MediaQuery.of(context).size.width) /
                  (MediaQuery.of(context).size.height - kMobileBottomBarHeight),
              2: (MediaQuery.of(context).size.width) *
                  0.5 /
                  (MediaQuery.of(context).size.height - kMobileBottomBarHeight),
            } else ...{
              4: (MediaQuery.of(context).size.width -
                      MediaQuery.of(context).padding.horizontal) /
                  (MediaQuery.of(context).size.height -
                      kMobileBottomBarHeight -
                      MediaQuery.of(context).padding.bottom),
              2: (MediaQuery.of(context).size.width -
                      MediaQuery.of(context).padding.horizontal) *
                  0.5 /
                  (MediaQuery.of(context).size.height -
                      kMobileBottomBarHeight -
                      MediaQuery.of(context).padding.bottom),
            }
          }[tab]!,
          mainAxisSpacing: 0.0,
          crossAxisSpacing: 0.0,
          padding: EdgeInsets.zero,
          onReorder: (initial, end) => view.reorder(tab, initial, end),
          children: children,
          dragStartBehavior: DragStartBehavior.start,
        ),
      );
    });
  }
}
