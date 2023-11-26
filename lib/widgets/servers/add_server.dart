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
import 'package:bluecherry_client/widgets/servers/error.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:url_launcher/link.dart';

class AddServerWizard extends StatefulWidget {
  final VoidCallback onFinish;

  const AddServerWizard({super.key, required this.onFinish});

  @override
  State<AddServerWizard> createState() => _AddServerWizardState();
}

class _AddServerWizardState extends State<AddServerWizard> {
  Server? server;
  final controller = PageController(
    initialPage:
        HomeProvider.instance.automaticallyGoToAddServersScreen ? 1 : 0,
  );

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  void _onNext() {
    controller.nextPage(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  void _onBack() {
    controller.previousPage(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.white12,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
      ),
      child: DecoratedBox(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/images/background.webp'),
            fit: BoxFit.cover,
          ),
        ),
        child: SafeArea(
          child: Stack(children: [
            Padding(
              padding: MediaQuery.viewInsetsOf(context),
              child: PageView(
                controller: controller,
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  Center(child: AddServerInfoScreen(onNext: _onNext)),
                  Center(
                    child: ConfigureDVRServerScreen(
                      onBack: _onBack,
                      onNext: _onNext,
                      onServerChange: (server) =>
                          setState(() => this.server = server),
                      server: server,
                    ),
                  ),
                  LetsGoScreen(
                    server: server,
                    onFinish: widget.onFinish,
                    onBack: _onBack,
                  ),
                ],
              ),
            ),
            if (Scaffold.hasDrawer(context))
              PositionedDirectional(
                top: MediaQuery.paddingOf(context).top,
                start: 0,
                child: const Material(
                  type: MaterialType.transparency,
                  color: Colors.amber,
                  child: SizedBox(
                    height: kToolbarHeight,
                    width: kToolbarHeight,
                    child: UnityDrawerButton(iconColor: Colors.white),
                  ),
                ),
              ),
          ]),
        ),
      ),
    );
  }
}

class AddServerInfoScreen extends StatelessWidget {
  final VoidCallback onNext;

  const AddServerInfoScreen({super.key, required this.onNext});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final loc = AppLocalizations.of(context);

    return IntrinsicWidth(
      child: Container(
        constraints: BoxConstraints(
          minWidth: MediaQuery.sizeOf(context).width / 2.5,
        ),
        alignment: AlignmentDirectional.center,
        child: Card(
          color: theme.cardColor,
          elevation: 4.0,
          clipBehavior: Clip.antiAlias,
          margin: const EdgeInsets.all(16) + MediaQuery.paddingOf(context),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsetsDirectional.all(16.0),
                child: Column(mainAxisSize: MainAxisSize.min, children: [
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
                  Row(mainAxisAlignment: MainAxisAlignment.end, children: [
                    Link(
                      uri: Uri.https('www.bluecherrydvr.com', '/'),
                      builder: (context, open) {
                        return TextButton(
                          onPressed: open,
                          child: Text(loc.website),
                        );
                      },
                    ),
                    const SizedBox(width: 8.0),
                    Link(
                      uri: Uri.https(
                        'www.bluecherrydvr.com',
                        '/product/v3license/',
                      ),
                      builder: (context, open) {
                        return TextButton(
                          onPressed: open,
                          child: Text(loc.purchase),
                        );
                      },
                    ),
                  ]),
                  const Divider(thickness: 1.0),
                  const SizedBox(height: 16.0),
                  Text(
                    loc.welcome,
                    style: theme.textTheme.displayLarge?.copyWith(
                      fontSize: 20.0,
                      fontWeight: FontWeight.w600,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8.0),
                  Text(
                    loc.welcomeDescription,
                    style: theme.textTheme.headlineSmall,
                    textAlign: TextAlign.center,
                  ),
                ]),
              ),
              const SizedBox(height: 16.0),
              Material(
                child: InkWell(
                  onTap: onNext,
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
    );
  }
}

class ConfigureDVRServerScreen extends StatefulWidget {
  final VoidCallback onBack;
  final VoidCallback onNext;
  final ValueChanged<Server> onServerChange;
  final Server? server;

  const ConfigureDVRServerScreen({
    super.key,
    required this.onBack,
    required this.onNext,
    required this.onServerChange,
    required this.server,
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

  bool _nameTextFieldEverFocused = false;
  bool connectAutomaticallyAtStartup = true;
  bool disableFinishButton = false;
  bool showingPassword = false;

  final formKey = GlobalKey<FormState>();
  final finishFocusNode = FocusNode();

  String getServerHostname(String text) {
    if (Uri.parse(text).scheme.isEmpty) text = 'https://$text';
    return Uri.parse(text).host;
  }

  @override
  void dispose() {
    hostnameController.dispose();
    portController.dispose();
    rtspPortController.dispose();
    nameController.dispose();
    usernameController.dispose();
    passwordController.dispose();
    finishFocusNode.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    hostnameController.addListener(() {
      final hostname = getServerHostname(hostnameController.text);
      if (!_nameTextFieldEverFocused && hostname.isNotEmpty) {
        nameController.text = hostname.split('.').first;
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
      textInputAction: TextInputAction.next,
      style: theme.textTheme.headlineMedium,
      decoration: InputDecoration(
        label: Text(loc.hostname),
        hintText: loc.hostnameExample,
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
      textInputAction: TextInputAction.next,
      style: theme.textTheme.headlineMedium,
      decoration: InputDecoration(
        label: Text(loc.port),
        hintText: '$kDefaultPort',
        border: const OutlineInputBorder(),
      ),
    );

    final rtspPortField = TextFormField(
      enabled: !disableFinishButton,
      // https://github.com/bluecherrydvr/unity/issues/182
      // validator: (value) {
      //   if (value == null || value.isEmpty) {
      //     return loc.errorTextField(loc.rtspPort);
      //   }
      //   return null;
      // },
      controller: rtspPortController,
      autofocus: true,
      keyboardType: TextInputType.number,
      textInputAction: TextInputAction.next,
      style: theme.textTheme.headlineMedium,
      decoration: InputDecoration(
        label: Text(loc.rtspPort),
        hintText: '$kDefaultRTSPPort',
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
      onTap: () => _nameTextFieldEverFocused = true,
      controller: nameController,
      textCapitalization: TextCapitalization.words,
      keyboardType: TextInputType.name,
      textInputAction: TextInputAction.next,
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
      keyboardType: TextInputType.name,
      textInputAction: TextInputAction.next,
      decoration: InputDecoration(
        label: Text(loc.username),
        hintText: loc.usernameHint,
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
      keyboardType: TextInputType.visiblePassword,
      textInputAction: TextInputAction.done,
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
      onFieldSubmitted: (_) => finish(context),
    );

    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) async {
        if (widget.server == null) {
          widget.onBack();
        }
      },
      child: IntrinsicWidth(
        child: Container(
          constraints: BoxConstraints(
            minWidth: MediaQuery.sizeOf(context).width / 2.5,
          ),
          margin: const EdgeInsetsDirectional.all(16.0),
          child: Card(
            elevation: 4.0,
            margin: EdgeInsets.zero,
            child: FocusTraversalGroup(
              policy: OrderedTraversalPolicy(),
              child: Form(
                key: formKey,
                child: SingleChildScrollView(
                  padding: const EdgeInsetsDirectional.symmetric(
                    horizontal: 16.0,
                    vertical: 24.0,
                  ),
                  child: Column(mainAxisSize: MainAxisSize.min, children: [
                    Row(children: [
                      IconButton(
                        icon: const BackButtonIcon(),
                        tooltip:
                            MaterialLocalizations.of(context).backButtonTooltip,
                        onPressed: () {
                          widget.onBack();
                          FocusScope.of(context).unfocus();
                        },
                      ),
                      const SizedBox(width: 8.0),
                      Text(
                        loc.configure,
                        style: const TextStyle(
                          fontWeight: FontWeight.w500,
                          color: Colors.white,
                        ),
                      ),
                    ]),
                    const SizedBox(height: 12.0),
                    Text(
                      loc.configureDescription,
                      style: theme.textTheme.headlineMedium
                          ?.copyWith(color: Colors.white.withOpacity(0.87)),
                    ),
                    const SizedBox(height: 20.0),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
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
                      ],
                    ),
                    const SizedBox(height: 16.0),
                    FocusTraversalOrder(
                      order: const NumericFocusOrder(3),
                      child: nameField,
                    ),
                    const SizedBox(height: 16.0),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
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
                            order: NumericFocusOrder(isMobilePlatform ? -1 : 4),
                            child: MaterialButton(
                              onPressed: disableFinishButton
                                  ? null
                                  : () {
                                      usernameController.text =
                                          kDefaultUsername;
                                      passwordController.text =
                                          kDefaultPassword;
                                      finishFocusNode.requestFocus();
                                    },
                              child: Text(loc.useDefault.toUpperCase()),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16.0),
                    FocusTraversalOrder(
                      order: const NumericFocusOrder(6),
                      child: passwordField,
                    ),
                    const SizedBox(height: 8.0),
                    FocusTraversalOrder(
                      order: const NumericFocusOrder(7),
                      child: CheckboxListTile.adaptive(
                        value: connectAutomaticallyAtStartup,
                        onChanged: (value) => setState(
                          () => connectAutomaticallyAtStartup = value ?? true,
                        ),
                        title: Text(loc.connectAutomaticallyAtStartup),
                        dense: true,
                        controlAffinity: ListTileControlAffinity.leading,
                        secondary: Tooltip(
                          message: loc.connectAutomaticallyAtStartupDescription,
                          child: Icon(
                            Icons.info_outline,
                            color: theme.colorScheme.secondary,
                            size: 20.0,
                          ),
                        ),
                      ),
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
                      FocusTraversalOrder(
                        order: const NumericFocusOrder(9),
                        child: MaterialButton(
                          onPressed: disableFinishButton
                              ? null
                              : () {
                                  widget.onNext();
                                },
                          child: Padding(
                            padding: const EdgeInsetsDirectional.all(8.0),
                            child: Text(loc.skip.toUpperCase()),
                          ),
                        ),
                      ),
                      const SizedBox(width: 6.0),
                      FocusTraversalOrder(
                        order: const NumericFocusOrder(8),
                        child: FilledButton(
                          onPressed: disableFinishButton
                              ? null
                              : () => finish(context),
                          focusNode: finishFocusNode,
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
      ),
    );
  }

  Future<void> finish(BuildContext context) async {
    if (formKey.currentState?.validate() ?? false) {
      final focusScope = FocusScope.of(context);

      final name = nameController.text.trim();
      final hostname = getServerHostname(hostnameController.text.trim());

      if (ServersProvider.instance.servers.any((s) {
        final serverHost = Uri.parse(s.login).host;
        final newServerHost = Uri.parse(hostname).host;
        return serverHost.isNotEmpty &&
            newServerHost.isNotEmpty &&
            serverHost == newServerHost;
      })) {
        showDialog(
          context: context,
          builder: (context) {
            final loc = AppLocalizations.of(context);

            return ServerNotAddedErrorDialog(
              name: name,
              description: loc.serverAlreadyAdded(name),
            );
          },
        );
        return;
      }

      if (mounted) setState(() => disableFinishButton = true);
      final port = int.parse(portController.text.trim());
      final server = await API.instance.checkServerCredentials(
        Server(
          name: name,
          ip: hostname,
          port: port,
          login: usernameController.text.trim(),
          password: passwordController.text,
          devices: [],
          rtspPort: int.tryParse(rtspPortController.text.trim()) ?? port,
          connectAutomaticallyAtStartup: connectAutomaticallyAtStartup,
        ),
      );
      focusScope.unfocus();

      if (server.serverUUID != null && server.cookie != null) {
        widget.onServerChange(server);
        await ServersProvider.instance.add(server);
        widget.onNext();
      } else {
        if (mounted) {
          showDialog(
            context: context,
            builder: (context) {
              final loc = AppLocalizations.of(context);
              return ServerNotAddedErrorDialog(
                name: server.name,
                description: loc.serverNotAddedErrorDescription,
                onRetry: () {
                  Navigator.of(context).maybePop();
                  if (this.context.mounted) finish(this.context);
                },
              );
            },
          );
        }
      }

      if (mounted) setState(() => disableFinishButton = false);
    }
  }
}

class LetsGoScreen extends StatelessWidget {
  final VoidCallback onBack;
  final Server? server;
  final VoidCallback onFinish;

  const LetsGoScreen({
    super.key,
    required this.onBack,
    required this.server,
    required this.onFinish,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final loc = AppLocalizations.of(context);

    return PopScope(
      canPop: false,
      child: Center(
        child: IntrinsicWidth(
          child: Container(
            margin: const EdgeInsetsDirectional.all(16.0),
            constraints: BoxConstraints(
              minWidth: MediaQuery.sizeOf(context).width / 2.5,
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                if (server != null)
                  Card(
                    elevation: 4.0,
                    margin: const EdgeInsetsDirectional.only(bottom: 8.0),
                    color: Color.alphaBlend(
                      Colors.green.withOpacity(0.2),
                      theme.cardColor,
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
                  margin: EdgeInsets.zero,
                  child: Padding(
                    padding: const EdgeInsetsDirectional.all(16.0),
                    child: SelectionArea(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            loc.letsGoDescription,
                            style: theme.textTheme.headlineMedium?.copyWith(
                                color: Colors.white.withOpacity(0.87)),
                          ),
                          ...[loc.tip0, loc.tip1, loc.tip2, loc.tip3]
                              .map((tip) {
                            return Padding(
                              padding: const EdgeInsetsDirectional.only(
                                top: 8.0,
                              ),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(' • '),
                                  const SizedBox(width: 4.0),
                                  Expanded(
                                    child: Text(tip),
                                  ),
                                ],
                              ),
                            );
                          }),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 8.0),
                FloatingActionButton.extended(
                  onPressed: onFinish,
                  label: Text(loc.finish.toUpperCase()),
                  icon: const Icon(Icons.check),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
