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
import 'package:bluecherry_client/providers/server_provider.dart';
import 'package:bluecherry_client/screens/servers/error.dart';
import 'package:bluecherry_client/screens/servers/wizard.dart';
import 'package:bluecherry_client/utils/constants.dart';
import 'package:bluecherry_client/utils/methods.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

enum _ServerAddState {
  none,
  checkingServerCredentials,
  gettingDevices;
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
  bool disableFinishButton = false;
  bool showingPassword = false;

  final formKey = GlobalKey<FormState>();
  final finishFocusNode = FocusNode();

  String getServerHostname(String text) {
    if (Uri.parse(text).scheme.isEmpty) text = 'https://$text';
    return Uri.parse(text).host;
  }

  _ServerAddState state = _ServerAddState.none;

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
      onChanged: (value) {
        portController.text = value.replaceAll(RegExp(r'[^0-9]'), '');
      },
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
      onChanged: (value) {
        rtspPortController.text = value.replaceAll(RegExp(r'[^0-9]'), '');
      },
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
                    buildCardAppBar(
                      title: loc.configure,
                      description: loc.configureDescription,
                      onBack: widget.onBack,
                    ),
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
                    const SizedBox(height: 16.0),
                    Row(mainAxisAlignment: MainAxisAlignment.end, children: [
                      if (disableFinishButton) ...[
                        const SizedBox(
                          height: 16.0,
                          width: 16.0,
                          child: CircularProgressIndicator.adaptive(
                            strokeWidth: 1.5,
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsetsDirectional.symmetric(
                            horizontal: 8.0,
                          ),
                          child: Text(switch (state) {
                            _ServerAddState.checkingServerCredentials =>
                              loc.checkingServerCredentials,
                            _ServerAddState.gettingDevices =>
                              loc.gettingDevices,
                            _ServerAddState.none => '',
                          }),
                        ),
                      ],
                      FocusTraversalOrder(
                        order: const NumericFocusOrder(8),
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
                        order: const NumericFocusOrder(7),
                        child: FilledButton(
                          onPressed: disableFinishButton
                              ? null
                              : () => finish(context),
                          focusNode: finishFocusNode,
                          child: Padding(
                            padding: const EdgeInsetsDirectional.all(8.0),
                            child: Text(loc.next.toUpperCase()),
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

      if (mounted) {
        setState(() {
          disableFinishButton = true;
          state = _ServerAddState.checkingServerCredentials;
        });
      }
      final port = int.parse(portController.text.trim());
      final (code, server) = await API.instance.checkServerCredentials(
        Server(
          name: name,
          ip: hostname,
          port: port,
          login: usernameController.text.trim(),
          password: passwordController.text,
          devices: [],
          rtspPort: int.tryParse(rtspPortController.text.trim()) ?? port,
        ),
      );
      focusScope.unfocus();

      if (server.serverUUID != null &&
          server.hasCookies &&
          code == ServerAdditionResponse.validated) {
        widget.onServerChange(server);
        state = _ServerAddState.gettingDevices;
        await ServersProvider.instance.add(server);
        widget.onNext();
      } else {
        state = _ServerAddState.none;
        if (context.mounted) {
          showDialog(
            context: context,
            builder: (context) {
              final loc = AppLocalizations.of(context);
              return ServerNotAddedErrorDialog(
                name: server.name,
                description: switch (code) {
                  ServerAdditionResponse.versionMismatch =>
                    loc.serverVersionMismatch,
                  ServerAdditionResponse.unknown ||
                  _ =>
                    loc.serverNotAddedErrorDescription(
                      server.port.toString(),
                      server.rtspPort.toString(),
                    )
                },
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
