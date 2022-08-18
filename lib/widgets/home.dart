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

import 'package:flutter/material.dart';
import 'package:animations/animations.dart';
import 'package:flutter/services.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

import 'package:bluecherry_client/widgets/device_grid.dart';
import 'package:bluecherry_client/widgets/events_screen.dart';
import 'package:bluecherry_client/widgets/settings.dart';
import 'package:bluecherry_client/widgets/misc.dart';
import 'package:bluecherry_client/utils/methods.dart';
import 'package:bluecherry_client/providers/server_provider.dart';
import 'package:bluecherry_client/widgets/add_server_wizard.dart';
import 'package:bluecherry_client/widgets/direct_camera.dart';
import 'package:status_bar_control/status_bar_control.dart';

class Home extends StatelessWidget {
  const Home({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (isDesktop) {
      // TODO: missing implementation.
      // WIP: [MobileHome].
      throw Exception('[DeviceGrid] is not supported on desktop.');
    } else {
      return const MobileHome();
    }
  }
}

class MobileHome extends StatefulWidget {
  const MobileHome({Key? key}) : super(key: key);

  @override
  State<MobileHome> createState() => _MobileHomeState();
}

class _MobileHomeState extends State<MobileHome> {
  int tab = ServersProvider.instance.serverAdded ? 0 : 3;
  final List<IconData> drawer = [
    Icons.window,
    Icons.camera,
    Icons.description,
    Icons.dns,
    Icons.settings,
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (tab == 0) {
        await StatusBarControl.setHidden(true);
        await StatusBarControl.setStyle(
          Theme.of(context).brightness == Brightness.light
              ? StatusBarStyle.DARK_CONTENT
              : StatusBarStyle.LIGHT_CONTENT,
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
          Theme.of(context).brightness == Brightness.light
              ? StatusBarStyle.DARK_CONTENT
              : StatusBarStyle.LIGHT_CONTENT,
        );
        DeviceOrientations.instance.set(
          [
            DeviceOrientation.portraitUp,
            DeviceOrientation.portraitDown,
          ],
        );
      } else if ([0, 3].contains(tab)) {
        await StatusBarControl.setHidden(false);
        await StatusBarControl.setStyle(
          Theme.of(context).brightness == Brightness.light
              ? StatusBarStyle.DARK_CONTENT
              : StatusBarStyle.LIGHT_CONTENT,
        );
        DeviceOrientations.instance.set(
          DeviceOrientation.values,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      drawer: Drawer(
        child: ListView(
          physics: const NeverScrollableScrollPhysics(),
          padding: EdgeInsets.zero,
          children: [
            // DrawerHeader(
            //   decoration: BoxDecoration(
            //     color: Theme.of(context).primaryColor,
            //   ),
            //   child: Text('project_name'.tr()),
            // ),
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
            ...drawer.map((e) {
              final index = drawer.toList().indexOf(e);
              return Stack(
                children: [
                  ListTile(
                    dense: true,
                    leading: CircleAvatar(
                      backgroundColor: Colors.transparent,
                      child: Icon(
                        e,
                        color: index == tab
                            ? Theme.of(context).primaryColor
                            : Theme.of(context).iconTheme.color,
                      ),
                    ),
                    title: Text(
                      {
                        Icons.window: AppLocalizations.of(context).screens,
                        Icons.camera: AppLocalizations.of(context).directCamera,
                        Icons.description:
                            AppLocalizations.of(context).eventBrowser,
                        Icons.dns: AppLocalizations.of(context).addServer,
                        Icons.settings: AppLocalizations.of(context).settings,
                      }[e]!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodyText1?.copyWith(
                            color: index == tab
                                ? Theme.of(context).primaryColor
                                : null,
                          ),
                    ),
                  ),
                  Material(
                    color: Colors.transparent,
                    child: Container(
                      padding: const EdgeInsets.only(
                        right: 12.0,
                      ),
                      width: double.infinity,
                      height: 48.0,
                      child: InkWell(
                        borderRadius: const BorderRadius.only(
                          topRight: Radius.circular(28.0),
                          bottomRight: Radius.circular(28.0),
                        ),
                        onTap: () async {
                          if (index == 0 && tab != 0) {
                            await StatusBarControl.setHidden(true);
                            await StatusBarControl.setStyle(
                              Theme.of(context).brightness == Brightness.light
                                  ? StatusBarStyle.DARK_CONTENT
                                  : StatusBarStyle.LIGHT_CONTENT,
                            );
                            DeviceOrientations.instance.set(
                              [
                                DeviceOrientation.landscapeLeft,
                                DeviceOrientation.landscapeRight,
                              ],
                            );
                          } else if (index == 3 && tab != 3) {
                            // Use portrait orientation in "Add Server" tab.
                            // See #14.
                            await StatusBarControl.setHidden(false);
                            await StatusBarControl.setStyle(
                              Theme.of(context).brightness == Brightness.light
                                  ? StatusBarStyle.DARK_CONTENT
                                  : StatusBarStyle.LIGHT_CONTENT,
                            );
                            DeviceOrientations.instance.set(
                              [
                                DeviceOrientation.portraitUp,
                                DeviceOrientation.portraitDown,
                              ],
                            );
                          } else if (![0, 3].contains(index) &&
                              [0, 3].contains(tab)) {
                            await StatusBarControl.setHidden(false);
                            await StatusBarControl.setStyle(
                              Theme.of(context).brightness == Brightness.light
                                  ? StatusBarStyle.DARK_CONTENT
                                  : StatusBarStyle.LIGHT_CONTENT,
                            );
                            DeviceOrientations.instance.set(
                              DeviceOrientation.values,
                            );
                          }

                          await Future.delayed(
                              const Duration(milliseconds: 200));
                          Navigator.of(context).pop();
                          if (tab != index) {
                            setState(() {
                              tab = index;
                            });
                          }
                        },
                        child: Container(
                          decoration: BoxDecoration(
                            color: index == tab
                                ? Theme.of(context)
                                    .primaryColor
                                    .withOpacity(0.2)
                                : null,
                            borderRadius: const BorderRadius.only(
                              topRight: Radius.circular(28.0),
                              bottomRight: Radius.circular(28.0),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              );
            }),
          ],
        ),
      ),
      body: PageTransitionSwitcher(
        duration: const Duration(milliseconds: 300),
        child: <int, Widget Function()>{
          0: () => const DeviceGrid(),
          1: () => const DirectCameraScreen(),
          2: () => const EventsScreen(),
          3: () => AddServerWizard(
                onFinish: () async {
                  setState(() => tab = 0);
                  await StatusBarControl.setHidden(true);
                  await StatusBarControl.setStyle(
                    Theme.of(context).brightness == Brightness.light
                        ? StatusBarStyle.DARK_CONTENT
                        : StatusBarStyle.LIGHT_CONTENT,
                  );
                  await SystemChrome.setPreferredOrientations(
                    [
                      DeviceOrientation.landscapeLeft,
                      DeviceOrientation.landscapeRight,
                    ],
                  );
                },
              ),
          4: () => Settings(
                changeCurrentTab: (i) => setState(() => tab = i),
              ),
        }[tab]!(),
        transitionBuilder: (child, animation, secondaryAnimation) =>
            SharedAxisTransition(
          child: child,
          animation: animation,
          secondaryAnimation: secondaryAnimation,
          transitionType: SharedAxisTransitionType.vertical,
        ),
      ),
    );
  }
}
