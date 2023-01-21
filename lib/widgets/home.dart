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

import 'package:animations/animations.dart';
import 'package:bluecherry_client/providers/home_provider.dart';
import 'package:bluecherry_client/utils/methods.dart';
import 'package:bluecherry_client/widgets/add_server_wizard.dart';
import 'package:bluecherry_client/widgets/desktop_buttons.dart';
import 'package:bluecherry_client/widgets/device_grid/device_grid.dart';
import 'package:bluecherry_client/widgets/direct_camera.dart';
import 'package:bluecherry_client/widgets/downloads_manager.dart';
import 'package:bluecherry_client/widgets/events/events_screen.dart';
import 'package:bluecherry_client/widgets/events_playback/events_playback.dart';
import 'package:bluecherry_client/widgets/misc.dart';
import 'package:bluecherry_client/widgets/settings/settings.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:provider/provider.dart';
import 'package:status_bar_control/status_bar_control.dart';

class NavigatorData {
  final IconData icon;
  final IconData selectedIcon;
  final String text;

  const NavigatorData({
    required this.icon,
    required this.selectedIcon,
    required this.text,
  });

  static List<NavigatorData> of(BuildContext context) {
    final loc = AppLocalizations.of(context);

    return [
      NavigatorData(
        icon: Icons.window_outlined,
        selectedIcon: Icons.window,
        text: loc.screens,
      ),
      const NavigatorData(
        icon: Icons.subscriptions_outlined,
        selectedIcon: Icons.subscriptions,
        text: 'Events Playback',
      ),
      NavigatorData(
        icon: Icons.camera_outlined,
        selectedIcon: Icons.camera,
        text: loc.directCamera,
      ),
      NavigatorData(
        icon: Icons.featured_play_list_outlined,
        selectedIcon: Icons.featured_play_list,
        text: loc.eventBrowser,
      ),
      NavigatorData(
        icon: Icons.dns_outlined,
        selectedIcon: Icons.dns,
        text: loc.addServer,
      ),
      NavigatorData(
        icon: Icons.download_outlined,
        selectedIcon: Icons.download,
        text: loc.downloads,
      ),
      NavigatorData(
        icon: Icons.settings_outlined,
        selectedIcon: Icons.settings,
        text: loc.settings,
      ),
    ];
  }
}

class Home extends StatefulWidget {
  const Home({Key? key}) : super(key: key);

  @override
  State<Home> createState() => _MobileHomeState();
}

class _MobileHomeState extends State<Home> {
  @override
  void initState() {
    super.initState();
    if (!isDesktop) {
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        final theme = Theme.of(context);
        final home = context.watch<HomeProvider>();
        final tab = home.tab;

        if (tab == 0) {
          await StatusBarControl.setHidden(true);
          await StatusBarControl.setStyle(
            getStatusBarStyleFromBrightness(theme.brightness),
          );
          DeviceOrientations.instance.set(
            [
              DeviceOrientation.landscapeLeft,
              DeviceOrientation.landscapeRight,
            ],
          );
        } else if (tab == 3) {
          // Use portrait orientation in "Add Server" tab.
          // See #14.
          await StatusBarControl.setHidden(false);
          await StatusBarControl.setStyle(
            getStatusBarStyleFromBrightness(theme.brightness),
          );
          DeviceOrientations.instance.set(
            [
              DeviceOrientation.portraitUp,
              DeviceOrientation.portraitDown,
            ],
          );
        } else {
          await StatusBarControl.setHidden(false);
          await StatusBarControl.setStyle(
            getStatusBarStyleFromBrightness(theme.brightness),
          );
          DeviceOrientations.instance.set(
            DeviceOrientation.values,
          );
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final home = context.watch<HomeProvider>();
    final tab = home.tab;

    return LayoutBuilder(builder: (context, constraints) {
      final isWide = constraints.biggest.width >= 640;

      // if isExtraWide is true, the rail will be extended. This is good for
      // desktop environments, but I like it compact (just like vscode)
      // final isExtraWide = constraints.biggest.width >= 1008;
      const isExtraWide = false;
      return Scaffold(
        resizeToAvoidBottomInset: false,
        drawer: isWide ? null : buildDrawer(context),
        body: SafeArea(
          child: Column(children: [
            const WindowButtons(),
            Expanded(
              child: Row(children: [
                // if it's desktop, we show the navigation in the window bar
                if ((isWide || isExtraWide) && !isDesktop) ...[
                  buildNavigationRail(context, isExtraWide: isExtraWide),
                  // SizedBox(
                  //   width: 4.0,
                  // ),
                ],
                Expanded(
                  child: ClipRect(
                    child: PageTransitionSwitcher(
                      child: RepaintBoundary(
                        child: <UnityTab, Widget Function()>{
                          UnityTab.deviceGrid: () => const DeviceGrid(),
                          UnityTab.eventsPlayback: () => const EventsPlayback(),
                          UnityTab.directCameraScreen: () =>
                              const DirectCameraScreen(),
                          UnityTab.eventsScreen: () => const EventsScreen(),
                          UnityTab.addServer: () => AddServerWizard(
                                onFinish: () async {
                                  home.setTab(UnityTab.deviceGrid.index);
                                  if (!isDesktop) {
                                    await StatusBarControl.setHidden(true);
                                    await StatusBarControl.setStyle(
                                      getStatusBarStyleFromBrightness(
                                          theme.brightness),
                                    );
                                    await SystemChrome.setPreferredOrientations(
                                      [
                                        DeviceOrientation.landscapeLeft,
                                        DeviceOrientation.landscapeRight,
                                      ],
                                    );
                                  }
                                },
                              ),
                          UnityTab.downloads: () => DownloadsManagerScreen(
                                initiallyExpandedEventId:
                                    home.initiallyExpandedDownloadEventId,
                              ),
                          UnityTab.settings: () =>
                              Settings(changeCurrentTab: home.setTab),
                        }[UnityTab.values[tab]]!(),
                      ),
                      transitionBuilder:
                          (child, animation, secondaryAnimation) {
                        return SharedAxisTransition(
                          animation: animation,
                          secondaryAnimation: secondaryAnimation,
                          transitionType: SharedAxisTransitionType.vertical,
                          child: child,
                        );
                      },
                    ),
                  ),
                ),
              ]),
            ),
          ]),
        ),
      );
    });
  }

  Drawer buildDrawer(BuildContext context) {
    final theme = NavigationRailDrawerData(theme: Theme.of(context));

    final home = context.watch<HomeProvider>();
    final tab = home.tab;

    final navData = NavigatorData.of(context);

    return Drawer(
      child: ListView(
        physics: const NeverScrollableScrollPhysics(),
        padding: EdgeInsets.zero,
        children: [
          Container(
            width: double.infinity,
            height: MediaQuery.of(context).padding.top,
            color: Color.lerp(
              Theme.of(context).drawerTheme.backgroundColor,
              Colors.black,
              0.2,
            ),
          ),
          const SizedBox(height: 8.0),
          ...navData.map((data) {
            final index = navData.indexOf(data);
            final isSelected = tab == index;

            final icon = isSelected ? data.selectedIcon : data.icon;
            final text = data.text;

            return Container(
              padding: const EdgeInsetsDirectional.only(
                end: 12.0,
                bottom: 4.0,
              ),
              width: double.infinity,
              height: 48.0,
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: const BorderRadiusDirectional.only(
                    topEnd: Radius.circular(28.0),
                    bottomEnd: Radius.circular(28.0),
                  ).resolve(Directionality.of(context)),
                  onTap: () async {
                    final theme = Theme.of(context);
                    final navigator = Navigator.of(context);

                    if (!isDesktop) {
                      if (index == 0 && tab != 0) {
                        debugPrint(index.toString());
                        await StatusBarControl.setHidden(true);
                        await StatusBarControl.setStyle(
                          getStatusBarStyleFromBrightness(theme.brightness),
                        );
                        DeviceOrientations.instance.set(
                          [
                            DeviceOrientation.landscapeLeft,
                            DeviceOrientation.landscapeRight,
                          ],
                        );
                      } else if (index == 3 && tab != 3) {
                        debugPrint(index.toString());
                        // Use portrait orientation in "Add Server" tab. See #14.
                        await StatusBarControl.setHidden(false);
                        await StatusBarControl.setStyle(
                          // Always white status bar style in [AddServerWizard].
                          StatusBarStyle.LIGHT_CONTENT,
                        );
                        DeviceOrientations.instance.set(
                          [
                            DeviceOrientation.portraitUp,
                            DeviceOrientation.portraitDown,
                          ],
                        );
                      } else if (![0, 3].contains(index) &&
                          [0, 3].contains(tab)) {
                        debugPrint(index.toString());
                        await StatusBarControl.setHidden(false);
                        await StatusBarControl.setStyle(
                          getStatusBarStyleFromBrightness(theme.brightness),
                        );
                        DeviceOrientations.instance.set(
                          DeviceOrientation.values,
                        );
                      }
                    }

                    await Future.delayed(const Duration(milliseconds: 200));
                    navigator.pop();
                    if (tab != index) {
                      home.setTab(index);
                    }
                  },
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: isSelected ? theme.selectedBackgroundColor : null,
                      borderRadius: const BorderRadiusDirectional.only(
                        topEnd: Radius.circular(28.0),
                        bottomEnd: Radius.circular(28.0),
                      ),
                    ),
                    child: ListTile(
                      dense: true,
                      leading: CircleAvatar(
                        backgroundColor: Colors.transparent,
                        child: Icon(
                          icon,
                          color: isSelected
                              ? theme.selectedForegroundColor
                              : theme.unselectedForegroundColor,
                        ),
                      ),
                      title: Text(
                        text,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                              color: isSelected
                                  ? theme.selectedForegroundColor
                                  : null,
                            ),
                      ),
                    ),
                  ),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget buildNavigationRail(
    BuildContext context, {
    required bool isExtraWide,
  }) {
    final theme = NavigationRailDrawerData(theme: Theme.of(context));
    final home = context.watch<HomeProvider>();

    const imageSize = 42.0;
    final navData = NavigatorData.of(context);

    return Card(
      child: Column(children: [
        Padding(
          padding: const EdgeInsets.only(top: 16.0),
          child: Image.asset(
            'assets/images/icon.png',
            width: imageSize,
            height: imageSize,
          ),
        ),
        const Spacer(),
        Expanded(
          flex: 3,
          child: Center(
            child: NavigationRail(
              minExtendedWidth: 220,
              backgroundColor: Colors.transparent,
              extended: isExtraWide,
              useIndicator: !isExtraWide,
              indicatorColor: theme.selectedBackgroundColor,
              selectedLabelTextStyle: TextStyle(
                color: theme.selectedForegroundColor,
              ),
              unselectedLabelTextStyle: TextStyle(
                color: theme.unselectedForegroundColor,
              ),
              destinations: navData.map((data) {
                final index = navData.indexOf(data);
                final isSelected = home.tab == index;

                final icon = isSelected ? data.selectedIcon : data.icon;
                final text = data.text;

                return NavigationRailDestination(
                  icon: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 200),
                    child: Icon(
                      icon,
                      key: ValueKey(isSelected),
                      fill: isSelected ? 1.0 : 0.0,
                      color: isSelected
                          ? theme.selectedForegroundColor
                          : theme.unselectedForegroundColor,
                    ),
                  ),
                  label: Text(text),
                );
              }).toList(),
              selectedIndex: home.tab,
              onDestinationSelected: (index) {
                if (home.tab != index) {
                  home.setTab(index);
                }
              },
            ),
          ),
        ),
        const Spacer(),
        SizedBox(
          height: imageSize + 16.0,
          child: () {
            if (home.isLoading) {
              return const Center(child: UnityLoadingIndicator());
            }
          }(),
        ),
      ]),
    );
  }
}

class NavigationRailDrawerData {
  final ThemeData theme;

  const NavigationRailDrawerData({required this.theme});

  Color get selectedBackgroundColor =>
      theme.colorScheme.primary.withOpacity(0.2);
  Color get selectedForegroundColor => theme.colorScheme.primary;
  Color? get unselectedForegroundColor => theme.iconTheme.color;
}
