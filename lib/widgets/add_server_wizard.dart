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
import 'package:flutter/services.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:bluecherry_client/api/api.dart';
import 'package:bluecherry_client/models/server.dart';
import 'package:bluecherry_client/providers/server_provider.dart';
import 'package:bluecherry_client/utils/constants.dart';
import 'package:bluecherry_client/widgets/misc.dart';

class AddServerWizard extends StatefulWidget {
  final VoidCallback onFinish;
  const AddServerWizard({
    Key? key,
    required this.onFinish,
  }) : super(key: key);

  @override
  State<AddServerWizard> createState() => _AddServerWizardState();
}

class _AddServerWizardState extends State<AddServerWizard> {
  Server? server;
  final PageController controller = PageController();

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.white12,
        statusBarIconBrightness: Brightness.light,
      ),
      child: Scaffold(
        resizeToAvoidBottomInset: false,
        body: Stack(
          alignment: Alignment.center,
          children: [
            Positioned.fill(
              child: PageView(
                controller: controller,
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  SizedBox(
                    child: Stack(
                      children: [
                        Positioned.fill(
                          child: Image.asset(
                            'assets/images/background.webp',
                            fit: BoxFit.cover,
                            width: MediaQuery.of(context).size.width,
                            height: MediaQuery.of(context).size.height,
                          ),
                        ),
                        Container(
                          alignment: Alignment.center,
                          child: Card(
                            elevation: 4.0,
                            clipBehavior: Clip.antiAlias,
                            margin: const EdgeInsets.symmetric(
                                    horizontal: 16.0, vertical: 32.0) +
                                MediaQuery.of(context).padding,
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Padding(
                                  padding: const EdgeInsets.all(16.0),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.center,
                                    children: [
                                      Image.asset(
                                        'assets/images/icon.png',
                                        height: 124.0,
                                        width: 124.0,
                                        fit: BoxFit.contain,
                                      ),
                                      const SizedBox(height: 24.0),
                                      Text(
                                        'project_name'.tr(),
                                        style: Theme.of(context)
                                            .textTheme
                                            .headline1
                                            ?.copyWith(
                                              fontSize: 36.0,
                                              fontWeight: FontWeight.w600,
                                            ),
                                      ),
                                      const SizedBox(height: 4.0),
                                      Text(
                                        'project_description'.tr(),
                                        style: Theme.of(context)
                                            .textTheme
                                            .headline5,
                                      ),
                                      const SizedBox(height: 16.0),
                                      Align(
                                        alignment: Alignment.centerRight,
                                        child: Container(
                                          color: Theme.of(context).cardColor,
                                          padding: const EdgeInsets.all(8.0),
                                          child: Row(
                                            children: [
                                              const Spacer(),
                                              MouseRegion(
                                                cursor:
                                                    SystemMouseCursors.click,
                                                child: GestureDetector(
                                                  onTap: () {
                                                    launchUrl(
                                                      Uri.https(
                                                        'www.bluecherry.com',
                                                        '/',
                                                      ),
                                                    );
                                                  },
                                                  child: Text(
                                                    'website'.tr(),
                                                    style: Theme.of(context)
                                                        .textTheme
                                                        .headline4
                                                        ?.copyWith(
                                                          color:
                                                              Theme.of(context)
                                                                  .colorScheme
                                                                  .primary,
                                                        ),
                                                  ),
                                                ),
                                              ),
                                              const SizedBox(width: 16.0),
                                              MouseRegion(
                                                cursor:
                                                    SystemMouseCursors.click,
                                                child: GestureDetector(
                                                  onTap: () {
                                                    launchUrl(
                                                      Uri.https(
                                                        'www.bluecherry.com',
                                                        '/product/v3license/',
                                                      ),
                                                    );
                                                  },
                                                  child: Text(
                                                    'purchase'.tr(),
                                                    style: Theme.of(context)
                                                        .textTheme
                                                        .headline4
                                                        ?.copyWith(
                                                          color:
                                                              Theme.of(context)
                                                                  .colorScheme
                                                                  .primary,
                                                        ),
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                      const Divider(thickness: 1.0),
                                      const SizedBox(height: 16.0),
                                      Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'welcome'.tr(),
                                            style: Theme.of(context)
                                                .textTheme
                                                .headline1
                                                ?.copyWith(
                                                  fontSize: 20.0,
                                                  fontWeight: FontWeight.w600,
                                                ),
                                          ),
                                          const SizedBox(height: 8.0),
                                          Text(
                                            'welcome_description'.tr(),
                                            style: Theme.of(context)
                                                .textTheme
                                                .headline5,
                                            textAlign: TextAlign.justify,
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 16.0),
                                Material(
                                  color:
                                      Theme.of(context).colorScheme.secondary,
                                  child: InkWell(
                                    onTap: () {
                                      controller.nextPage(
                                        duration:
                                            const Duration(milliseconds: 300),
                                        curve: Curves.easeInOut,
                                      );
                                    },
                                    child: Container(
                                      alignment: Alignment.center,
                                      width: double.infinity,
                                      height: 56.0,
                                      child: Text(
                                        'lets_go'.tr().toUpperCase(),
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 16.0,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  ConfigureDVRServerScreen(
                    controller: controller,
                    setServer: setServer,
                    getServer: getServer,
                  ),
                  LetsGoScreen(
                    controller: controller,
                    getServer: getServer,
                    onFinish: widget.onFinish,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void setServer(Server server) => setState(() {
        this.server = server;
      });

  Server? getServer() => server;
}

class ConfigureDVRServerScreen extends StatefulWidget {
  final PageController controller;
  final void Function(Server) setServer;
  final Server? Function() getServer;
  const ConfigureDVRServerScreen({
    Key? key,
    required this.controller,
    required this.setServer,
    required this.getServer,
  }) : super(key: key);

  @override
  State<ConfigureDVRServerScreen> createState() =>
      _ConfigureDVRServerScreenState();
}

class _ConfigureDVRServerScreenState extends State<ConfigureDVRServerScreen> {
  final ScrollController controller = ScrollController();
  final List<TextEditingController> textEditingControllers = [
    TextEditingController(),
    TextEditingController(text: kDefaultPort.toString()),
    TextEditingController(),
    TextEditingController(),
    TextEditingController(),
  ];
  bool savePassword = true;
  bool nameTextFieldEverFocused = false;
  bool connectAutomaticallyAtStartup = true;
  bool elevated = true;
  bool disableFinishButton = false;
  final GlobalKey<FormState> formKey = GlobalKey<FormState>();

  String getServerHostname(String text) => (text.startsWith('http')
          ? (text.split('//')..removeAt(0)).join('//')
          : text)
      .split('/')
      .first;

  @override
  void initState() {
    super.initState();
    textEditingControllers[0].addListener(() {
      if (!nameTextFieldEverFocused) {
        textEditingControllers[2].text =
            getServerHostname(textEditingControllers[0].text);
      }
    });
    controller.addListener(() {
      if (controller.offset == 0.0 && !elevated) {
        setState(() {
          elevated = true;
        });
      } else if (elevated) {
        setState(() {
          elevated = false;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final view = ListView(
      controller: controller,
      padding: isDesktop
          ? EdgeInsets.only(
              top: desktopTitleBarHeight + kDesktopAppBarHeight - 2.0,
            )
          : null,
      children: [
        Material(
          elevation: elevated ? 4.0 : 0.0,
          child: Container(
            height: 48.0,
            color: Theme.of(context).primaryColor,
            child: Padding(
              padding: const EdgeInsets.only(
                left: 16.0,
                right: 16.0,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 8.0),
                  Text(
                    'configure_description'.tr(),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context)
                        .textTheme
                        .headline4
                        ?.copyWith(color: Colors.white.withOpacity(0.87)),
                  ),
                ],
              ),
            ),
          ),
        ),
        Card(
          elevation: 4.0,
          margin: const EdgeInsets.all(16.0),
          child: Form(
            key: formKey,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        flex: 5,
                        child: TextFormField(
                          validator: (value) {
                            if (value?.isEmpty ?? true) {
                              return 'error_text_field'
                                  .tr(args: ['hostname'.tr()]);
                            }
                            return null;
                          },
                          controller: textEditingControllers[0],
                          autofocus: true,
                          keyboardType: TextInputType.url,
                          style: Theme.of(context).textTheme.headline4,
                          decoration: InputDecoration(
                            label: Text('hostname'.tr()),
                            border: const OutlineInputBorder(),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16.0),
                      Expanded(
                        flex: 2,
                        child: TextFormField(
                          validator: (value) {
                            if (value?.isEmpty ?? true) {
                              return 'error_text_field'.tr(args: ['port'.tr()]);
                            }
                            return null;
                          },
                          controller: textEditingControllers[1],
                          autofocus: true,
                          keyboardType: TextInputType.number,
                          style: Theme.of(context).textTheme.headline4,
                          decoration: InputDecoration(
                            label: Text('port'.tr()),
                            border: const OutlineInputBorder(),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16.0),
                  TextFormField(
                    validator: (value) {
                      if (value?.isEmpty ?? true) {
                        return 'error_text_field'.tr(args: ['name'.tr()]);
                      }
                      return null;
                    },
                    onTap: () => nameTextFieldEverFocused = true,
                    controller: textEditingControllers[2],
                    textCapitalization: TextCapitalization.words,
                    keyboardType: TextInputType.name,
                    style: Theme.of(context).textTheme.headline4,
                    decoration: InputDecoration(
                      label: Text('name'.tr()),
                      border: const OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16.0),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: TextFormField(
                          validator: (value) {
                            if (value?.isEmpty ?? true) {
                              return 'error_text_field'
                                  .tr(args: ['username'.tr()]);
                            }
                            return null;
                          },
                          controller: textEditingControllers[3],
                          style: Theme.of(context).textTheme.headline4,
                          decoration: InputDecoration(
                            label: Text('username'.tr()),
                            border: const OutlineInputBorder(),
                          ),
                        ),
                      ),
                      SizedBox(
                        width: isDesktop ? 16.0 : 8.0,
                      ),
                      if (isDesktop)
                        Padding(
                          padding: const EdgeInsets.only(top: 8.0),
                          child: MaterialButton(
                            onPressed: () {
                              textEditingControllers[3].text = kDefaultUsername;
                              textEditingControllers[4].text = kDefaultPassword;
                            },
                            child: Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Text(
                                'use_default'.tr().toUpperCase(),
                              ),
                            ),
                            textColor: Theme.of(context).colorScheme.secondary,
                          ),
                        ),
                      Padding(
                        padding: const EdgeInsets.only(top: 8.0),
                        child: MaterialButton(
                          onPressed: () {
                            textEditingControllers[3].text = kDefaultUsername;
                            textEditingControllers[4].text = kDefaultPassword;
                          },
                          child: Text(
                            'use_default'.tr().toUpperCase(),
                          ),
                          textColor: Theme.of(context).colorScheme.secondary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16.0),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: TextFormField(
                          validator: (value) {
                            if (value?.isEmpty ?? true) {
                              return 'error_text_field'
                                  .tr(args: ['password'.tr()]);
                            }
                            return null;
                          },
                          controller: textEditingControllers[4],
                          obscureText: true,
                          style: Theme.of(context).textTheme.headline4,
                          decoration: InputDecoration(
                            label: Text('password'.tr()),
                            border: const OutlineInputBorder(),
                          ),
                        ),
                      ),
                      // Padding(
                      //   padding: const EdgeInsets.only(top: 8.0),
                      //   child: Row(
                      //     children: [
                      //       Checkbox(
                      //         value: savePassword,
                      //         onChanged: (value) {
                      //           setState(() {
                      //             savePassword = value!;
                      //           });
                      //         },
                      //       ),
                      //       Text(
                      //         'save_password'.tr(),
                      //         maxLines: 2,
                      //         overflow: TextOverflow.ellipsis,
                      //         style: Theme.of(context).textTheme.headline4,
                      //       ),
                      //     ],
                      //   ),
                      // ),
                      const SizedBox(width: 16.0),
                    ],
                  ),
                  // const SizedBox(height: 16.0),
                  // Row(
                  //   children: [
                  //     Checkbox(
                  //       value: connectAutomaticallyAtStartup,
                  //       onChanged: (value) {
                  //         setState(() {
                  //           connectAutomaticallyAtStartup = value!;
                  //         });
                  //       },
                  //     ),
                  //     Text(
                  //       'connect_automatically_at_startup'.tr(),
                  //       maxLines: 2,
                  //       overflow: TextOverflow.ellipsis,
                  //       style: Theme.of(context).textTheme.headline4,
                  //     ),
                  //   ],
                  // ),
                  const SizedBox(height: 16.0),
                  Align(
                    alignment: Alignment.bottomRight,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        MaterialButton(
                          onPressed: disableFinishButton
                              ? null
                              : () {
                                  widget.controller.nextPage(
                                    duration: const Duration(
                                      milliseconds: 300,
                                    ),
                                    curve: Curves.easeInOut,
                                  );
                                },
                          child: Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Text(
                              'skip'.tr().toUpperCase(),
                            ),
                          ),
                          textColor: Theme.of(context).colorScheme.secondary,
                        ),
                        MaterialButton(
                          onPressed: disableFinishButton
                              ? null
                              : () async {
                                  if (formKey.currentState?.validate() ??
                                      false) {
                                    setState(() {
                                      disableFinishButton = true;
                                    });
                                    final server = await API.instance
                                        .checkServerCredentials(
                                      Server(
                                        textEditingControllers[2].text,
                                        getServerHostname(
                                            textEditingControllers[0].text),
                                        int.parse(
                                            textEditingControllers[1].text),
                                        textEditingControllers[3].text,
                                        textEditingControllers[4].text,
                                        [],
                                        savePassword: savePassword,
                                        connectAutomaticallyAtStartup:
                                            connectAutomaticallyAtStartup,
                                      ),
                                    );
                                    FocusScope.of(context).unfocus();
                                    if (server.serverUUID != null &&
                                        server.cookie != null) {
                                      widget.setServer(server);
                                      await ServersProvider.instance
                                          .add(server);
                                      widget.controller.nextPage(
                                        duration: const Duration(
                                          milliseconds: 300,
                                        ),
                                        curve: Curves.easeInOut,
                                      );
                                    } else {
                                      showDialog(
                                        context: context,
                                        builder: (context) => AlertDialog(
                                          title: Text('error'.tr()),
                                          content: Text(
                                            'server_not_added_error'
                                                .tr(args: [server.name]),
                                            style: Theme.of(context)
                                                .textTheme
                                                .headline4,
                                          ),
                                          actions: [
                                            MaterialButton(
                                              onPressed: Navigator.of(context)
                                                  .maybePop,
                                              child: Padding(
                                                padding:
                                                    const EdgeInsets.all(8.0),
                                                child: Text(
                                                  'ok'.tr().toUpperCase(),
                                                ),
                                              ),
                                              textColor: Theme.of(context)
                                                  .colorScheme
                                                  .secondary,
                                            ),
                                          ],
                                        ),
                                      );
                                    }
                                    setState(() {
                                      disableFinishButton = false;
                                    });
                                  }
                                },
                          child: Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Text(
                              'finish'.tr().toUpperCase(),
                            ),
                          ),
                          textColor: Theme.of(context).colorScheme.secondary,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
    if (isDesktop) {
      return Stack(
        children: [
          view,
          DesktopAppBar(
            elevation: elevated ? 0.0 : 4.0,
            color: Theme.of(context).appBarTheme.backgroundColor,
            title: 'configure'.tr(),
            leading: NavigatorPopButton(
              color: Colors.white,
              onTap: () {
                widget.controller.previousPage(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeInOut,
                );
              },
            ),
          ),
        ],
      );
    }
    return WillPopScope(
      child: Scaffold(
          resizeToAvoidBottomInset: false,
          appBar: AppBar(
            leading: NavigatorPopButton(
              color: Colors.white,
              onTap: () {
                widget.controller.previousPage(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeInOut,
                );
                FocusScope.of(context).unfocus();
              },
            ),
            backgroundColor: Theme.of(context).primaryColor,
            elevation: elevated ? 0.0 : 4.0,
            systemOverlayStyle: const SystemUiOverlayStyle(
              statusBarColor: Colors.white12,
              statusBarIconBrightness: Brightness.light,
              statusBarBrightness: Brightness.light,
            ),
            title: Text(
              'configure'.tr(),
              style: const TextStyle(
                fontWeight: FontWeight.w500,
                color: Colors.white,
              ),
            ),
          ),
          body: view),
      onWillPop: () {
        if (widget.getServer() == null) {
          widget.controller.previousPage(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
          );
        }
        return Future.value(false);
      },
    );
  }
}

class LetsGoScreen extends StatefulWidget {
  final PageController controller;
  final Server? Function() getServer;
  final VoidCallback onFinish;
  const LetsGoScreen({
    Key? key,
    required this.controller,
    required this.getServer,
    required this.onFinish,
  }) : super(key: key);

  @override
  State<LetsGoScreen> createState() => _LetsGoScreenState();
}

class _LetsGoScreenState extends State<LetsGoScreen> {
  final ScrollController controller = ScrollController();
  bool elevated = true;

  @override
  void initState() {
    super.initState();
    controller.addListener(() {
      if (controller.offset == 0.0 && !elevated) {
        setState(() {
          elevated = true;
        });
      } else if (elevated) {
        setState(() {
          elevated = false;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    Widget body = ListView(
      controller: controller,
      padding: isDesktop
          ? EdgeInsets.only(
              top: desktopTitleBarHeight + kDesktopAppBarHeight - 2.0,
            )
          : null,
      children: [
        Material(
          elevation: elevated ? 4.0 : 0.0,
          child: Container(
            height: 48.0,
            color: Theme.of(context).primaryColor,
            child: Padding(
              padding: const EdgeInsets.only(
                left: 16.0,
                right: 16.0,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 8.0),
                  Text(
                    'lets_go_description'.tr(),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context)
                        .textTheme
                        .headline4
                        ?.copyWith(color: Colors.white.withOpacity(0.87)),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 8.0),
        if (widget.getServer() != null)
          Card(
            elevation: 4.0,
            color: Color.alphaBlend(
              Colors.green.withOpacity(0.2),
              Theme.of(context).cardColor,
            ),
            margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  Icon(
                    Icons.check,
                    color: Colors.green.shade400,
                  ),
                  const SizedBox(width: 16.0),
                  Text('server_added'.tr(args: [widget.getServer()!.name]))
                ],
              ),
            ),
          ),
        Card(
          elevation: 4.0,
          margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ...List.generate(kInAppTipsCount, (index) => 'tip_$index'.tr())
                    .map(
                  (e) => Padding(
                    padding: const EdgeInsets.symmetric(
                      vertical: 8.0,
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(' • '),
                        const SizedBox(width: 4.0),
                        Expanded(
                          child: Text(e),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 8.0),
      ],
    );
    if (isDesktop) {
      body = Stack(
        children: [
          body,
          DesktopAppBar(
            elevation: elevated ? 0.0 : 4.0,
            color: Theme.of(context).appBarTheme.backgroundColor,
            title: 'lets_go'.tr(),
            leading: widget.getServer() != null
                ? const SizedBox.shrink()
                : NavigatorPopButton(
                    color: Colors.white,
                    onTap: () {
                      widget.controller.previousPage(
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeInOut,
                      );
                    },
                  ),
          ),
        ],
      );
    }
    return WillPopScope(
      child: Scaffold(
        appBar: isMobile
            ? AppBar(
                leading: widget.getServer() != null
                    ? null
                    : NavigatorPopButton(
                        color: Colors.white,
                        onTap: () {
                          widget.controller.previousPage(
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.easeInOut,
                          );
                          FocusScope.of(context).unfocus();
                        },
                      ),
                systemOverlayStyle: const SystemUiOverlayStyle(
                  statusBarColor: Colors.white12,
                  statusBarIconBrightness: Brightness.light,
                  statusBarBrightness: Brightness.light,
                ),
                backgroundColor: Theme.of(context).primaryColor,
                title: Text(
                  'lets_go'.tr(),
                  style: const TextStyle(
                    fontWeight: FontWeight.w500,
                    color: Colors.white,
                  ),
                ),
                elevation: elevated ? 0.0 : 4.0,
              )
            : null,
        body: body,
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () {
            widget.onFinish.call();
          },
          backgroundColor: Theme.of(context).colorScheme.secondary,
          label: Text('finish'.tr().toUpperCase()),
          icon: const Icon(Icons.check),
        ),
        floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      ),
      onWillPop: () {
        // if (widget.getServer() == null) {
        //   widget.controller.previousPage(
        //     duration: const Duration(milliseconds: 300),
        //     curve: Curves.easeInOut,
        //   );
        // }
        return Future.value(false);
      },
    );
  }
}
