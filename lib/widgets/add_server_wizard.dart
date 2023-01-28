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

import 'dart:io';

import 'package:bluecherry_client/api/api.dart';
import 'package:bluecherry_client/models/server.dart';
import 'package:bluecherry_client/providers/server_provider.dart';
import 'package:bluecherry_client/utils/constants.dart';
import 'package:bluecherry_client/utils/methods.dart';
import 'package:bluecherry_client/widgets/misc.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:url_launcher/url_launcher.dart';

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
        statusBarBrightness: Brightness.dark,
      ),
      child: Scaffold(
        resizeToAvoidBottomInset: false,
        body: PageView(
          controller: controller,
          physics: const NeverScrollableScrollPhysics(),
          children: [
            Stack(children: [
              Positioned.fill(
                child: Image.asset(
                  'assets/images/background.webp',
                  fit: BoxFit.cover,
                  width: MediaQuery.sizeOf(context).width,
                  height: MediaQuery.sizeOf(context).height,
                ),
              ),
              Container(
                alignment: AlignmentDirectional.center,
                child: Card(
                  color: Theme.of(context).cardColor,
                  elevation: 4.0,
                  clipBehavior: Clip.antiAlias,
                  margin: const EdgeInsets.symmetric(
                        horizontal: 16.0,
                        vertical: 16.0,
                      ) +
                      MediaQuery.paddingOf(context),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Padding(
                        padding: const EdgeInsetsDirectional.all(16.0),
                        child: Column(children: [
                          Image.asset(
                            'assets/images/icon.png',
                            height: 124.0,
                            width: 124.0,
                            fit: BoxFit.contain,
                          ),
                          const SizedBox(height: 24.0),
                          Text(
                            AppLocalizations.of(context).projectName,
                            style: Theme.of(context)
                                .textTheme
                                .displayLarge
                                ?.copyWith(
                                  fontSize: 36.0,
                                  fontWeight: FontWeight.w600,
                                ),
                          ),
                          const SizedBox(height: 4.0),
                          Text(
                            AppLocalizations.of(context).projectDescription,
                            style: Theme.of(context).textTheme.headlineSmall,
                          ),
                          const SizedBox(height: 16.0),
                          Container(
                            alignment: AlignmentDirectional.centerEnd,
                            padding: const EdgeInsetsDirectional.all(8.0),
                            child: Row(children: [
                              const Spacer(),
                              MouseRegion(
                                cursor: SystemMouseCursors.click,
                                child: GestureDetector(
                                  onTap: () {
                                    launchUrl(
                                      Uri.https(
                                        'www.bluecherrydvr.com',
                                        '/',
                                      ),
                                      mode: LaunchMode.externalApplication,
                                    );
                                  },
                                  child: Text(
                                    AppLocalizations.of(context).website,
                                    style: Theme.of(context)
                                        .textTheme
                                        .headlineMedium
                                        ?.copyWith(
                                          color: Theme.of(context)
                                              .colorScheme
                                              .primary,
                                        ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 16.0),
                              MouseRegion(
                                cursor: SystemMouseCursors.click,
                                child: GestureDetector(
                                  onTap: () {
                                    launchUrl(
                                      Uri.https(
                                        'www.bluecherrydvr.com',
                                        '/product/v3license/',
                                      ),
                                      mode: LaunchMode.externalApplication,
                                    );
                                  },
                                  child: Text(
                                    AppLocalizations.of(context).purchase,
                                    style: Theme.of(context)
                                        .textTheme
                                        .headlineMedium
                                        ?.copyWith(
                                          color: Theme.of(context)
                                              .colorScheme
                                              .primary,
                                        ),
                                  ),
                                ),
                              ),
                            ]),
                          ),
                          const Divider(thickness: 1.0),
                          const SizedBox(height: 16.0),
                          Column(
                            crossAxisAlignment: Platform.isIOS
                                ? CrossAxisAlignment.center
                                : CrossAxisAlignment.start,
                            children: [
                              Text(
                                AppLocalizations.of(context).welcome,
                                style: Theme.of(context)
                                    .textTheme
                                    .displayLarge
                                    ?.copyWith(
                                      fontSize: 20.0,
                                      fontWeight: FontWeight.w600,
                                    ),
                              ),
                              const SizedBox(height: 8.0),
                              Text(
                                AppLocalizations.of(context).welcomeDescription,
                                style:
                                    Theme.of(context).textTheme.headlineSmall,
                              ),
                            ],
                          ),
                        ]),
                      ),
                      const SizedBox(height: 16.0),
                      Material(
                        color: Theme.of(context).colorScheme.secondary,
                        child: InkWell(
                          onTap: () {
                            controller.nextPage(
                              duration: const Duration(milliseconds: 300),
                              curve: Curves.easeInOut,
                            );
                          },
                          child: Container(
                            alignment: AlignmentDirectional.center,
                            width: double.infinity,
                            height: 56.0,
                            child: Text(
                              AppLocalizations.of(context).letsGo.toUpperCase(),
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
              if (Scaffold.of(context).hasDrawer)
                Positioned.fill(
                  bottom: MediaQuery.sizeOf(context).height * 3 / 4,
                  child: Material(
                    color: Colors.transparent,
                    child: Container(
                      color: Colors.transparent,
                      padding: EdgeInsetsDirectional.only(
                        top: MediaQuery.paddingOf(context).top,
                      ),
                      height:
                          kToolbarHeight + MediaQuery.paddingOf(context).top,
                      alignment: AlignmentDirectional.topStart,
                      child: Row(children: [
                        const SizedBox(width: 8.0),
                        IconButton(
                          splashRadius: 20.0,
                          onPressed: Scaffold.of(context).openDrawer,
                          icon: const Icon(
                            Icons.menu,
                            color: Colors.white,
                          ),
                        ),
                      ]),
                    ),
                  ),
                ),
            ]),
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
    );
  }

  void setServer(Server server) {
    setState(() {
      this.server = server;
    });
  }

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
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      child: Scaffold(
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
          backgroundColor: Theme.of(context).brightness == Brightness.light
              ? Theme.of(context).colorScheme.primary
              : Theme.of(context).cardColor,
          systemOverlayStyle: const SystemUiOverlayStyle(
            statusBarColor: Colors.white12,
            statusBarIconBrightness: Brightness.light,
            statusBarBrightness: Brightness.dark,
          ),
          title: Text(
            AppLocalizations.of(context).configure,
            style: const TextStyle(
              fontWeight: FontWeight.w500,
              color: Colors.white,
            ),
          ),
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(32.0),
            child: Container(
              height: 32.0,
              padding: const EdgeInsetsDirectional.only(start: 16.0),
              alignment: Theme.of(context).appBarTheme.centerTitle ?? false
                  ? AlignmentDirectional.topCenter
                  : AlignmentDirectional.topStart,
              child: Text(
                AppLocalizations.of(context).configureDescription,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context)
                    .textTheme
                    .headlineMedium
                    ?.copyWith(color: Colors.white.withOpacity(0.87)),
              ),
            ),
          ),
        ),
        body: Card(
          elevation: 4.0,
          margin: const EdgeInsetsDirectional.all(16.0),
          child: Form(
            key: formKey,
            child: Padding(
              padding: const EdgeInsetsDirectional.all(16.0),
              child: Column(children: [
                Row(children: [
                  Expanded(
                    flex: 5,
                    child: TextFormField(
                      validator: (value) {
                        if (value?.isEmpty ?? true) {
                          return AppLocalizations.of(context).errorTextField(
                            AppLocalizations.of(context).hostname,
                          );
                        }
                        return null;
                      },
                      controller: textEditingControllers[0],
                      autofocus: true,
                      autocorrect: false,
                      enableSuggestions: false,
                      keyboardType: TextInputType.url,
                      style: Theme.of(context).textTheme.headlineMedium,
                      decoration: InputDecoration(
                        label: Text(AppLocalizations.of(context).hostname),
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
                          return AppLocalizations.of(context).errorTextField(
                            AppLocalizations.of(context).port,
                          );
                        }
                        return null;
                      },
                      controller: textEditingControllers[1],
                      autofocus: true,
                      keyboardType: TextInputType.number,
                      style: Theme.of(context).textTheme.headlineMedium,
                      decoration: InputDecoration(
                        label: Text(AppLocalizations.of(context).port),
                        border: const OutlineInputBorder(),
                      ),
                    ),
                  ),
                ]),
                const SizedBox(height: 16.0),
                TextFormField(
                  validator: (value) {
                    if (value?.isEmpty ?? true) {
                      return AppLocalizations.of(context).errorTextField(
                        AppLocalizations.of(context).name,
                      );
                    }
                    return null;
                  },
                  onTap: () => nameTextFieldEverFocused = true,
                  controller: textEditingControllers[2],
                  textCapitalization: TextCapitalization.words,
                  keyboardType: TextInputType.name,
                  style: Theme.of(context).textTheme.headlineMedium,
                  decoration: InputDecoration(
                    label: Text(AppLocalizations.of(context).name),
                    border: const OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16.0),
                Row(children: [
                  Expanded(
                    child: TextFormField(
                      validator: (value) {
                        if (value?.isEmpty ?? true) {
                          return AppLocalizations.of(context).errorTextField(
                            AppLocalizations.of(context).username,
                          );
                        }
                        return null;
                      },
                      controller: textEditingControllers[3],
                      style: Theme.of(context).textTheme.headlineMedium,
                      decoration: InputDecoration(
                        label: Text(AppLocalizations.of(context).username),
                        border: const OutlineInputBorder(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8.0),
                  Padding(
                    padding: const EdgeInsetsDirectional.only(top: 8.0),
                    child: MaterialButton(
                      onPressed: () {
                        textEditingControllers[3].text = kDefaultUsername;
                        textEditingControllers[4].text = kDefaultPassword;
                      },
                      textColor: Theme.of(context).colorScheme.secondary,
                      child: Text(
                        AppLocalizations.of(context).useDefault.toUpperCase(),
                      ),
                    ),
                  ),
                ]),
                const SizedBox(height: 16.0),
                Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Expanded(
                    child: TextFormField(
                      validator: (value) {
                        if (value?.isEmpty ?? true) {
                          return AppLocalizations.of(context).errorTextField(
                            AppLocalizations.of(context).password,
                          );
                        }
                        return null;
                      },
                      controller: textEditingControllers[4],
                      obscureText: true,
                      style: Theme.of(context).textTheme.headlineMedium,
                      decoration: InputDecoration(
                        label: Text(AppLocalizations.of(context).password),
                        border: const OutlineInputBorder(),
                      ),
                    ),
                  ),
                  // Padding(
                  //   padding: const EdgeInsetsDirectional.only(top: 8.0),
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
                ]),
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
                  alignment: AlignmentDirectional.bottomEnd,
                  child:
                      Row(mainAxisAlignment: MainAxisAlignment.end, children: [
                    MaterialButton(
                      onPressed: disableFinishButton
                          ? null
                          : () {
                              widget.controller.nextPage(
                                duration: const Duration(milliseconds: 300),
                                curve: Curves.easeInOut,
                              );
                            },
                      textColor: Theme.of(context).colorScheme.secondary,
                      child: Padding(
                        padding: const EdgeInsetsDirectional.all(8.0),
                        child: Text(
                          AppLocalizations.of(context).skip.toUpperCase(),
                        ),
                      ),
                    ),
                    MaterialButton(
                      onPressed:
                          disableFinishButton ? null : () => finish(context),
                      textColor: Theme.of(context).colorScheme.secondary,
                      child: Padding(
                        padding: const EdgeInsetsDirectional.all(8.0),
                        child: Text(
                          AppLocalizations.of(context).finish.toUpperCase(),
                        ),
                      ),
                    ),
                  ]),
                ),
              ]),
            ),
          ),
        ),
      ),
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

  Future<void> finish(BuildContext context) async {
    if (formKey.currentState?.validate() ?? false) {
      final focusScope = FocusScope.of(context);

      setState(() {
        disableFinishButton = true;
      });
      final server = await API.instance.checkServerCredentials(
        Server(
          textEditingControllers[2].text.trim(),
          getServerHostname(textEditingControllers[0].text.trim()),
          int.parse(textEditingControllers[1].text.trim()),
          textEditingControllers[3].text.trim(),
          textEditingControllers[4].text,
          [],
          savePassword: savePassword,
          connectAutomaticallyAtStartup: connectAutomaticallyAtStartup,
        ),
      );
      focusScope.unfocus();

      if (server.serverUUID != null && server.cookie != null) {
        widget.setServer(server);
        await ServersProvider.instance.add(server);
        widget.controller.nextPage(
          duration: const Duration(
            milliseconds: 300,
          ),
          curve: Curves.easeInOut,
        );
      } else {
        if (mounted) {
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: Text(AppLocalizations.of(context).error),
              content: Text(
                AppLocalizations.of(context).serverNotAddedError(server.name),
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              actions: [
                MaterialButton(
                  onPressed: Navigator.of(context).maybePop,
                  textColor: Theme.of(context).colorScheme.secondary,
                  child: Padding(
                    padding: const EdgeInsetsDirectional.all(8.0),
                    child: Text(
                      AppLocalizations.of(context).ok,
                    ),
                  ),
                ),
              ],
            ),
          );
        }
      }
      setState(() {
        disableFinishButton = false;
      });
    }
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
  @override
  Widget build(BuildContext context) {
    final server = widget.getServer();

    return WillPopScope(
      child: Scaffold(
        appBar: showIf<AppBar>(
          isMobile,
          child: AppBar(
            leading: server != null
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
              statusBarBrightness: Brightness.dark,
            ),
            backgroundColor: Theme.of(context).brightness == Brightness.light
                ? Theme.of(context).colorScheme.primary
                : Theme.of(context).cardColor,
            title: Text(
              AppLocalizations.of(context).letsGo,
              style: const TextStyle(
                fontWeight: FontWeight.w500,
                color: Colors.white,
              ),
            ),
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(32.0),
              child: Container(
                height: 32.0,
                padding: const EdgeInsetsDirectional.only(start: 16.0),
                alignment: Theme.of(context).appBarTheme.centerTitle ?? false
                    ? AlignmentDirectional.topCenter
                    : AlignmentDirectional.topStart,
                child: Text(
                  AppLocalizations.of(context).letsGoDescription,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context)
                      .textTheme
                      .headlineMedium
                      ?.copyWith(color: Colors.white.withOpacity(0.87)),
                ),
              ),
            ),
          ),
        ),
        body: ListView(children: [
          const SizedBox(height: 8.0),
          if (server != null)
            Card(
              elevation: 4.0,
              color: Color.alphaBlend(
                Colors.green.withOpacity(0.2),
                Theme.of(context).cardColor,
              ),
              margin: const EdgeInsets.symmetric(
                horizontal: 16.0,
                vertical: 8.0,
              ),
              child: Padding(
                padding: const EdgeInsetsDirectional.all(16.0),
                child: Row(children: [
                  Icon(
                    Icons.check,
                    color: Colors.green.shade400,
                  ),
                  const SizedBox(width: 16.0),
                  Expanded(
                    child: Text(AppLocalizations.of(context).serverAdded),
                  ),
                ]),
              ),
            ),
          Card(
            elevation: 4.0,
            margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Padding(
              padding: const EdgeInsetsDirectional.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      vertical: 8.0,
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(' • '),
                        const SizedBox(width: 4.0),
                        Expanded(
                          child: Text(AppLocalizations.of(context).tip0),
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      vertical: 8.0,
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(' • '),
                        const SizedBox(width: 4.0),
                        Expanded(
                          child: Text(AppLocalizations.of(context).tip1),
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8.0),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(' • '),
                        const SizedBox(width: 4.0),
                        Expanded(
                          child: Text(AppLocalizations.of(context).tip2),
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      vertical: 8.0,
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(' • '),
                        const SizedBox(width: 4.0),
                        Expanded(
                          child: Text(AppLocalizations.of(context).tip3),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8.0),
        ]),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () {
            widget.onFinish.call();
          },
          backgroundColor: Theme.of(context).colorScheme.secondary,
          label: Text(AppLocalizations.of(context).finish.toUpperCase()),
          icon: const Icon(Icons.check),
        ),
        floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      ),
      onWillPop: () {
        return Future.value(false);
      },
    );
  }
}
