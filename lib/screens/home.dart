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
import 'package:bluecherry_client/screens/direct_camera.dart';
import 'package:bluecherry_client/screens/downloads/downloads_manager.dart';
import 'package:bluecherry_client/screens/events_browser/events_screen.dart';
import 'package:bluecherry_client/screens/events_timeline/events_playback.dart';
import 'package:bluecherry_client/screens/layouts/device_grid.dart';
import 'package:bluecherry_client/screens/servers/wizard.dart';
import 'package:bluecherry_client/screens/settings/settings.dart';
import 'package:bluecherry_client/utils/constants.dart';
import 'package:bluecherry_client/utils/methods.dart';
import 'package:bluecherry_client/widgets/desktop_buttons.dart';
import 'package:bluecherry_client/widgets/search.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:provider/provider.dart';

class NavigatorData {
  /// The tab that this navigator data represents.
  final UnityTab tab;
  final IconData icon;
  final IconData selectedIcon;
  final String text;

  const NavigatorData({
    required this.tab,
    required this.icon,
    required this.selectedIcon,
    required this.text,
  });

  static List<NavigatorData> of(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final screenSize = MediaQuery.sizeOf(context);

    return [
      NavigatorData(
        tab: UnityTab.deviceGrid,
        icon: Icons.window_outlined,
        selectedIcon: Icons.window,
        text: loc.screens,
      ),
      NavigatorData(
        tab: UnityTab.eventsTimeline,
        icon: Icons.subscriptions_outlined,
        selectedIcon: Icons.subscriptions,
        text: loc.eventsTimeline,
      ),
      if (screenSize.width <= kMobileBreakpoint.width ||
          Scaffold.hasDrawer(context))
        NavigatorData(
          tab: UnityTab.directCameraScreen,
          icon: Icons.videocam_outlined,
          selectedIcon: Icons.videocam,
          text: loc.directCamera,
        ),
      NavigatorData(
        tab: UnityTab.eventsHistory,
        icon: Icons.featured_play_list_outlined,
        selectedIcon: Icons.featured_play_list,
        text: loc.eventBrowser,
      ),
      NavigatorData(
        tab: UnityTab.addServer,
        icon: Icons.dns_outlined,
        selectedIcon: Icons.dns,
        text: loc.addServer,
      ),
      if (!kIsWeb)
        NavigatorData(
          tab: UnityTab.downloads,
          icon: Icons.download_outlined,
          selectedIcon: Icons.download,
          text: loc.downloads,
        ),
      NavigatorData(
        tab: UnityTab.settings,
        icon: Icons.settings_outlined,
        selectedIcon: Icons.settings,
        text: loc.settings,
      ),
    ];
  }
}

class Home extends StatefulWidget {
  const Home({super.key});

  @override
  State<Home> createState() => _MobileHomeState();
}

class _MobileHomeState extends State<Home> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
      if (!context.mounted) return;
      context.read<HomeProvider>().refreshDeviceOrientation(context);
    });
  }

  final directCameraKey = GlobalKey<DirectCameraScreenState>();

  @override
  Widget build(BuildContext context) {
    final home = context.watch<HomeProvider>();
    final tab = home.tab;

    return LayoutBuilder(builder: (context, constraints) {
      /// Whether there is enough space for a navigation rail to pop off.
      ///
      /// The screen must be horizontally wide ([isWide]) and vertically tall ([isTall]), since
      /// the navigation rail requires space. The environment must not be a desktop environment [!isDesktop].
      /// On desktop, [WindowButtons] is the responsible to handle navigation-related tasks.
      ///
      /// If the conditions are not met, the drawer is displayed instead.
      ///
      /// When a navigation item is added, for example, these breakpoints need to be updated
      /// in order to delight a good user experience
      final isWide = constraints.biggest.width > 700;
      final isTall = constraints.biggest.height > 440;
      final showNavigationRail = isWide && isTall && !isDesktop;

      return Scaffold(
        resizeToAvoidBottomInset: false,
        drawer: isDesktop || showNavigationRail
            ? null
            : Builder(builder: buildDrawer),
        body: Column(children: [
          const WindowButtons(),
          Expanded(
            child: Row(children: [
              if (showNavigationRail)
                SafeArea(
                  right: Directionality.of(context) == TextDirection.rtl,
                  child: Builder(builder: buildNavigationRail),
                ),
              Expanded(
                child: ClipRect(
                  child: PageTransitionSwitcher(
                    transitionBuilder: (child, animation, secondaryAnimation) {
                      return SharedAxisTransition(
                        animation: animation,
                        secondaryAnimation: secondaryAnimation,
                        transitionType: SharedAxisTransitionType.vertical,
                        child: child,
                      );
                    },
                    child: switch (tab) {
                      UnityTab.deviceGrid => const DeviceGrid(),
                      UnityTab.directCameraScreen =>
                        DirectCameraScreen(key: directCameraKey),
                      UnityTab.eventsTimeline => EventsPlayback(),
                      UnityTab.eventsHistory =>
                        EventsScreen(key: eventsScreenKey),
                      UnityTab.addServer => AddServerWizard(
                          onFinish: () async =>
                              home.setTab(UnityTab.deviceGrid, context),
                        ),
                      UnityTab.downloads => DownloadsManagerScreen(
                          initiallyExpandedEventId:
                              home.initiallyExpandedDownloadEventId,
                        ),
                      UnityTab.settings => const Settings(),
                    },
                  ),
                ),
              ),
            ]),
          ),
        ]),
      );
    });
  }

  Widget buildDrawer(BuildContext context) {
    final theme = NavigationRailDrawerData(theme: Theme.of(context));

    final home = context.watch<HomeProvider>();
    final tab = home.tab;

    final navData = NavigatorData.of(context);

    return Drawer(
      child: ListView(
        physics: const NeverScrollableScrollPhysics(),
        padding: EdgeInsetsDirectional.zero,
        children: [
          Container(
            width: double.infinity,
            height: MediaQuery.paddingOf(context).top,
            color: Color.lerp(
              Theme.of(context).drawerTheme.backgroundColor,
              Colors.black,
              0.2,
            ),
          ),
          const SizedBox(height: 8.0),
          ...navData.map((data) {
            final isSelected = tab == data.tab;

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
                    final navigator = Navigator.of(context);

                    await Future.delayed(const Duration(milliseconds: 200));
                    navigator.pop();
                    if (tab != data.tab && context.mounted) {
                      home.setTab(data.tab, context);
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

  Widget buildNavigationRail(BuildContext context) {
    final theme = NavigationRailDrawerData(theme: Theme.of(context));
    final home = context.watch<HomeProvider>();

    const imageSize = 42.0;
    final navData = NavigatorData.of(context);

    return Card(
      child: Column(children: [
        Padding(
          padding: const EdgeInsetsDirectional.only(top: 16.0),
          child: Image.asset(
            'assets/images/icon.png',
            width: imageSize,
            height: imageSize,
          ),
        ),
        Expanded(
          child: NavigationRail(
            minExtendedWidth: 220,
            backgroundColor: Colors.transparent,
            // useIndicator: true,
            indicatorColor: theme.selectedBackgroundColor,
            selectedLabelTextStyle: TextStyle(
              color: theme.selectedForegroundColor,
            ),
            unselectedLabelTextStyle: TextStyle(
              color: theme.unselectedForegroundColor,
            ),
            destinations: navData.map((data) {
              final isSelected = home.tab == data.tab;

              final icon = isSelected ? data.selectedIcon : data.icon;
              final text = data.text;

              return NavigationRailDestination(
                icon: Icon(
                  icon,
                  color: isSelected
                      ? theme.selectedForegroundColor
                      : theme.unselectedForegroundColor,
                ),
                label: Text(text),
              );
            }).toList(),
            selectedIndex: navData.indexOf(navData.firstWhere(
              (data) => data.tab == home.tab,
              orElse: () => navData.first,
            )),
            onDestinationSelected: (index) {
              final nav = navData[index];
              home.setTab(nav.tab, context);
            },
          ),
        ),
        if (directCameraKey.currentState != null)
          SearchToggleButton(
            searchable: directCameraKey.currentState!,
            iconSize: 24.0,
          ),
        if (home.isLoading)
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
