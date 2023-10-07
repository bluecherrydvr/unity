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

import 'package:bluecherry_client/api/api.dart';
import 'package:bluecherry_client/models/server.dart';
import 'package:bluecherry_client/providers/home_provider.dart';
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

  const AddServerWizard({super.key, required this.onFinish});

  @override
  State<AddServerWizard> createState() => _AddServerWizardState();
}

class _AddServerWizardState extends State<AddServerWizard> {
  Server? server;
  final PageController controller = PageController(
    initialPage:
        HomeProvider.instance.automaticallyGoToAddServersScreen ? 1 : 0,
  );

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final loc = AppLocalizations.of(context);

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.white12,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
      ),
      child: PageView(
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
                color: theme.cardColor,
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
                          loc.projectName,
                          style: theme.textTheme.displayLarge?.copyWith(
                            fontSize: 36.0,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 4.0),
                        Text(
                          loc.projectDescription,
                          style: theme.textTheme.headlineSmall,
                        ),
                        const SizedBox(height: 16.0),
                        Container(
                          alignment: AlignmentDirectional.centerEnd,
                          padding: const EdgeInsetsDirectional.all(8.0),
                          child: Row(children: [
                            const Spacer(),
                            MaterialButton(
                              onPressed: () {
                                launchUrl(
                                  Uri.https(
                                    'www.bluecherrydvr.com',
                                    '/',
                                  ),
                                  mode: LaunchMode.externalApplication,
                                );
                              },
                              child: Text(
                                loc.website,
                                style: theme.textTheme.headlineMedium?.copyWith(
                                  color: theme.colorScheme.primary,
                                ),
                              ),
                            ),
                            MaterialButton(
                              onPressed: () {
                                launchUrl(
                                  Uri.https(
                                    'www.bluecherrydvr.com',
                                    '/product/v3license/',
                                  ),
                                  mode: LaunchMode.externalApplication,
                                );
                              },
                              child: Text(
                                loc.purchase,
                                style: theme.textTheme.headlineMedium?.copyWith(
                                  color: theme.colorScheme.primary,
                                ),
                              ),
                            ),
                          ]),
                        ),
                        const Divider(thickness: 1.0),
                        const SizedBox(height: 16.0),
                        Column(
                          crossAxisAlignment:
                              (AppBarTheme.of(context).centerTitle ?? false)
                                  ? CrossAxisAlignment.center
                                  : CrossAxisAlignment.start,
                          children: [
                            Text(
                              loc.welcome,
                              style: theme.textTheme.displayLarge?.copyWith(
                                fontSize: 20.0,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 8.0),
                            Text(
                              loc.welcomeDescription,
                              style: theme.textTheme.headlineSmall,
                            ),
                          ],
                        ),
                      ]),
                    ),
                    const SizedBox(height: 16.0),
                    Material(
                      // color: theme.colorScheme.primaryContainer,
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
                            loc.letsGo.toUpperCase(),
                            style: TextStyle(
                              color: theme.colorScheme.onPrimaryContainer,
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
            if (Scaffold.hasDrawer(context))
              PositionedDirectional(
                top: MediaQuery.paddingOf(context).top,
                start: 0,
                child: const Material(
                  type: MaterialType.transparency,
                  child: SizedBox(
                    height: kToolbarHeight,
                    width: kToolbarHeight,
                    child: UnityDrawerButton(iconColor: Colors.white),
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
  final ValueChanged<Server> setServer;
  final Server? Function() getServer;

  const ConfigureDVRServerScreen({
    super.key,
    required this.controller,
    required this.setServer,
    required this.getServer,
  });

  @override
  State<ConfigureDVRServerScreen> createState() =>
      _ConfigureDVRServerScreenState();
}

class _ConfigureDVRServerScreenState extends State<ConfigureDVRServerScreen> {
  final hostnameController = TextEditingController();
  final portController = TextEditingController(text: '$kDefaultPort');
  final rtspPortController = TextEditingController(text: '$kDefaultRTSPPort');
  final nameController = TextEditingController();
  final usernameController = TextEditingController();
  final passwordController = TextEditingController();
  bool showingPassword = false;

  bool savePassword = true;
  bool nameTextFieldEverFocused = false;
  bool connectAutomaticallyAtStartup = true;
  bool disableFinishButton = false;
  final formKey = GlobalKey<FormState>();

  String getServerHostname(String text) {
    if (Uri.parse(text).scheme.isEmpty) text = 'https://$text';
    return Uri.parse(text).host;
  }

  @override
  void initState() {
    super.initState();
    hostnameController.addListener(() {
      final hostname = getServerHostname(hostnameController.text);
      if (!nameTextFieldEverFocused && hostname.isNotEmpty) {
        nameController.text = hostname;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final loc = AppLocalizations.of(context);

    final hostnameField = TextFormField(
      enabled: !disableFinishButton,
      validator: (value) {
        if (value == null || value.isEmpty) {
          return loc.errorTextField(
            loc.hostname,
          );
        }
        return null;
      },
      controller: hostnameController,
      autofocus: true,
      autocorrect: false,
      enableSuggestions: false,
      keyboardType: TextInputType.url,
      style: theme.textTheme.headlineMedium,
      decoration: InputDecoration(
        label: Text(loc.hostname),
        border: const OutlineInputBorder(),
      ),
    );

    final portField = TextFormField(
      enabled: !disableFinishButton,
      validator: (value) {
        if (value == null || value.isEmpty) {
          return loc.errorTextField(loc.port);
        }
        return null;
      },
      controller: portController,
      autofocus: true,
      keyboardType: TextInputType.number,
      style: theme.textTheme.headlineMedium,
      decoration: InputDecoration(
        label: Text(loc.port),
        border: const OutlineInputBorder(),
      ),
    );

    final rtspPortField = TextFormField(
      enabled: !disableFinishButton,
      validator: (value) {
        if (value == null || value.isEmpty) {
          return loc.errorTextField(loc.rtspPort);
        }
        return null;
      },
      controller: rtspPortController,
      autofocus: true,
      keyboardType: TextInputType.number,
      style: theme.textTheme.headlineMedium,
      decoration: InputDecoration(
        label: Text(loc.rtspPort),
        border: const OutlineInputBorder(),
      ),
    );

    final nameField = TextFormField(
      enabled: !disableFinishButton,
      validator: (value) {
        if (value == null || value.isEmpty) {
          return loc.errorTextField(loc.serverName);
        }
        return null;
      },
      onTap: () => nameTextFieldEverFocused = true,
      controller: nameController,
      textCapitalization: TextCapitalization.words,
      keyboardType: TextInputType.name,
      style: theme.textTheme.headlineMedium,
      decoration: InputDecoration(
        label: Text(loc.serverName),
        border: const OutlineInputBorder(),
      ),
    );

    final usernameField = TextFormField(
      enabled: !disableFinishButton,
      validator: (value) {
        if (value == null || value.isEmpty) {
          return loc.errorTextField(
            loc.username,
          );
        }
        return null;
      },
      controller: usernameController,
      style: theme.textTheme.headlineMedium,
      decoration: InputDecoration(
        label: Text(loc.username),
        border: const OutlineInputBorder(),
      ),
    );

    final passwordField = TextFormField(
      enabled: !disableFinishButton,
      validator: (value) {
        if (value == null || value.isEmpty) {
          return loc.errorTextField(loc.password);
        }
        return null;
      },
      controller: passwordController,
      obscureText: !showingPassword,
      style: theme.textTheme.headlineMedium,
      decoration: InputDecoration(
        label: Text(loc.password),
        border: const OutlineInputBorder(),
        suffix: Tooltip(
          message: showingPassword ? loc.hidePassword : loc.showPassword,
          child: InkWell(
            borderRadius: BorderRadius.circular(8.0),
            child: Icon(
              showingPassword ? Icons.visibility : Icons.visibility_off,
              size: 22.0,
            ),
            onTap: () => setState(
              () => showingPassword = !showingPassword,
            ),
          ),
        ),
      ),
    );

    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) async {
        if (widget.getServer() == null) {
          widget.controller.previousPage(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
          );
        }
      },
      child: Scaffold(
        appBar: AppBar(
          leading: BackButton(
            onPressed: () {
              widget.controller.previousPage(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut,
              );
              FocusScope.of(context).unfocus();
            },
          ),
          backgroundColor: theme.brightness == Brightness.light
              ? theme.colorScheme.primary
              : theme.cardColor,
          systemOverlayStyle: const SystemUiOverlayStyle(
            statusBarColor: Colors.white12,
            statusBarIconBrightness: Brightness.light,
            statusBarBrightness: Brightness.dark,
          ),
          title: Text(
            loc.configure,
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
              alignment: theme.appBarTheme.centerTitle ?? false
                  ? AlignmentDirectional.topCenter
                  : AlignmentDirectional.topStart,
              child: Text(
                loc.configureDescription,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.headlineMedium
                    ?.copyWith(color: Colors.white.withOpacity(0.87)),
              ),
            ),
          ),
        ),
        body: Card(
          elevation: 4.0,
          margin: const EdgeInsetsDirectional.all(16.0),
          child: Padding(
            padding: const EdgeInsetsDirectional.all(16.0),
            child: FocusTraversalGroup(
              policy: OrderedTraversalPolicy(),
              child: Form(
                key: formKey,
                child: Column(children: [
                  Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Expanded(
                      flex: 5,
                      child: FocusTraversalOrder(
                        order: const NumericFocusOrder(0),
                        child: hostnameField,
                      ),
                    ),
                    const SizedBox(width: 16.0),
                    Expanded(
                      flex: 2,
                      child: FocusTraversalOrder(
                        order: const NumericFocusOrder(1),
                        child: portField,
                      ),
                    ),
                    const SizedBox(width: 16.0),
                    Expanded(
                      flex: 2,
                      child: FocusTraversalOrder(
                        order: const NumericFocusOrder(2),
                        child: rtspPortField,
                      ),
                    ),
                  ]),
                  const SizedBox(height: 16.0),
                  FocusTraversalOrder(
                    order: const NumericFocusOrder(3),
                    child: nameField,
                  ),
                  const SizedBox(height: 16.0),
                  Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Expanded(
                      child: FocusTraversalOrder(
                        order: const NumericFocusOrder(5),
                        child: usernameField,
                      ),
                    ),
                    const SizedBox(width: 8.0),
                    Padding(
                      padding: const EdgeInsetsDirectional.only(top: 8.0),
                      child: FocusTraversalOrder(
                        order: const NumericFocusOrder(4),
                        child: MaterialButton(
                          onPressed: disableFinishButton
                              ? null
                              : () {
                                  usernameController.text = kDefaultUsername;
                                  passwordController.text = kDefaultPassword;
                                },
                          child: Text(loc.useDefault.toUpperCase()),
                        ),
                      ),
                    ),
                  ]),
                  const SizedBox(height: 16.0),
                  FocusTraversalOrder(
                    order: const NumericFocusOrder(6),
                    child: passwordField,
                  ),
                  const SizedBox(height: 16.0),
                  Row(mainAxisAlignment: MainAxisAlignment.end, children: [
                    if (disableFinishButton)
                      const SizedBox(
                        height: 24.0,
                        width: 24.0,
                        child: CircularProgressIndicator.adaptive(
                          strokeWidth: 2.0,
                        ),
                      ),
                    MaterialButton(
                      onPressed: disableFinishButton
                          ? null
                          : () {
                              widget.controller.nextPage(
                                duration: const Duration(milliseconds: 300),
                                curve: Curves.easeInOut,
                              );
                            },
                      child: Padding(
                        padding: const EdgeInsetsDirectional.all(8.0),
                        child: Text(loc.skip.toUpperCase()),
                      ),
                    ),
                    FocusTraversalOrder(
                      order: const NumericFocusOrder(7),
                      child: MaterialButton(
                        onPressed:
                            disableFinishButton ? null : () => finish(context),
                        child: Padding(
                          padding: const EdgeInsetsDirectional.all(8.0),
                          child: Text(loc.finish.toUpperCase()),
                        ),
                      ),
                    ),
                  ]),
                ]),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> finish(BuildContext context) async {
    if (formKey.currentState?.validate() ?? false) {
      final focusScope = FocusScope.of(context);

      if (mounted) setState(() => disableFinishButton = true);
      final server = await API.instance.checkServerCredentials(
        Server(
          nameController.text.trim(),
          getServerHostname(hostnameController.text.trim()),
          int.parse(portController.text.trim()),
          usernameController.text.trim(),
          passwordController.text,
          [],
          rtspPort: int.parse(rtspPortController.text.trim()),
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
            builder: (context) {
              final theme = Theme.of(context);
              final loc = AppLocalizations.of(context);

              return AlertDialog(
                title: Text(loc.serverNotAddedError(server.name)),
                content: Text(
                  loc.serverNotAddedErrorDescription,
                  style: theme.textTheme.headlineMedium,
                ),
                actions: [
                  TextButton(
                    onPressed: () {
                      Navigator.of(context).maybePop();
                      if (this.context.mounted) finish(this.context);
                    },
                    child: Padding(
                      padding: const EdgeInsetsDirectional.all(8.0),
                      child: Text(loc.retry.toUpperCase()),
                    ),
                  ),
                  MaterialButton(
                    onPressed: Navigator.of(context).maybePop,
                    child: Padding(
                      padding: const EdgeInsetsDirectional.all(8.0),
                      child: Text(loc.ok),
                    ),
                  ),
                ],
              );
            },
          );
        }
      }

      if (mounted) setState(() => disableFinishButton = false);
    }
  }
}

class LetsGoScreen extends StatefulWidget {
  final PageController controller;
  final Server? Function() getServer;
  final VoidCallback onFinish;

  const LetsGoScreen({
    super.key,
    required this.controller,
    required this.getServer,
    required this.onFinish,
  });

  @override
  State<LetsGoScreen> createState() => _LetsGoScreenState();
}

class _LetsGoScreenState extends State<LetsGoScreen> {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final loc = AppLocalizations.of(context);
    final server = widget.getServer();

    return PopScope(
      canPop: false,
      child: Scaffold(
        appBar: showIf<AppBar>(
          isMobile,
          child: AppBar(
            leading: server != null
                ? null
                : BackButton(
                    color: Colors.white,
                    onPressed: () {
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
            backgroundColor: theme.brightness == Brightness.light
                ? theme.colorScheme.primary
                : theme.cardColor,
            title: Text(
              loc.letsGo,
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
                alignment: theme.appBarTheme.centerTitle ?? false
                    ? AlignmentDirectional.topCenter
                    : AlignmentDirectional.topStart,
                child: Text(
                  loc.letsGoDescription,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.headlineMedium
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
                theme.cardColor,
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
                    child: Text(loc.serverAdded),
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
                          child: Text(loc.tip0),
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
                          child: Text(loc.tip1),
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
                          child: Text(loc.tip2),
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
                          child: Text(loc.tip3),
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
          label: Text(loc.finish.toUpperCase()),
          icon: const Icon(Icons.check),
        ),
        floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      ),
    );
  }
}
