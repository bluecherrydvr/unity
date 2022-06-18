/*
 * This file is a part of Bluecherry Client (https://https://github.com/bluecherrydvr/bluecherry_client).
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
import 'package:fluttertoast/fluttertoast.dart';
import 'package:easy_localization/easy_localization.dart';

import 'package:bluecherry_client/widgets/device_grid.dart';
import 'package:bluecherry_client/widgets/events_screen.dart';
import 'package:bluecherry_client/widgets/settings.dart';
import 'package:bluecherry_client/widgets/misc.dart';
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
  final Map<IconData, String> drawer = {
    Icons.window: 'screens',
    Icons.camera: 'direct_camera',
    Icons.description: 'events_browser',
    Icons.dns: 'add_server',
    Icons.settings: 'settings',
  };

  DateTime? timeout;

  Future<bool> onWillPop() {
    DateTime now = DateTime.now();
    if (timeout == null ||
        now.difference(timeout ?? now) > const Duration(seconds: 2)) {
      timeout = now;
      Fluttertoast.showToast(msg: 'press_back_again_to_exit'.tr());
      return Future.value(false);
    }
    return Future.value(true);
  }

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
        await SystemChrome.setPreferredOrientations(
          [
            DeviceOrientation.landscapeLeft,
            DeviceOrientation.landscapeRight,
          ],
        );
      } else if (tab != 0) {
        await StatusBarControl.setHidden(false);
        await StatusBarControl.setStyle(
          Theme.of(context).brightness == Brightness.light
              ? StatusBarStyle.DARK_CONTENT
              : StatusBarStyle.LIGHT_CONTENT,
        );
        await SystemChrome.setPreferredOrientations(
          DeviceOrientation.values,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      /// Do not show "press back again to exit" when on [AddServerWizard].
      onWillPop: tab == 3 ? () => Future.value(true) : onWillPop,
      child: Scaffold(
        resizeToAvoidBottomInset: false,
        drawer: Drawer(
          child: ListView(
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
              ...drawer.entries.map((e) {
                final index = drawer.keys.toList().indexOf(e.key);
                return Stack(
                  children: [
                    ListTile(
                      leading: CircleAvatar(
                        backgroundColor: Colors.transparent,
                        child: Icon(
                          e.key,
                          color: index == tab
                              ? Theme.of(context).primaryColor
                              : Theme.of(context).iconTheme.color,
                        ),
                      ),
                      title: Text(
                        e.value.tr(),
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
                      borderRadius: BorderRadius.circular(8.0),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          vertical: 4.0,
                          horizontal: 12.0,
                        ),
                        width: double.infinity,
                        height: 56.0,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(8.0),
                          onTap: () async {
                            if (index == 0 && tab != 0) {
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
                            } else if (index != 0 && tab == 0) {
                              await StatusBarControl.setHidden(false);
                              await StatusBarControl.setStyle(
                                Theme.of(context).brightness == Brightness.light
                                    ? StatusBarStyle.DARK_CONTENT
                                    : StatusBarStyle.LIGHT_CONTENT,
                              );
                              await SystemChrome.setPreferredOrientations(
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
                              borderRadius: BorderRadius.circular(8.0),
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
            4: () => const Settings(),
          }[tab]!(),
          transitionBuilder: (child, animation, secondaryAnimation) =>
              SharedAxisTransition(
            child: child,
            animation: animation,
            secondaryAnimation: secondaryAnimation,
            transitionType: SharedAxisTransitionType.vertical,
          ),
        ),
      ),
    );
  }
}
