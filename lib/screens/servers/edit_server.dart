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
import 'package:bluecherry_client/l10n/generated/app_localizations.dart';
import 'package:bluecherry_client/models/server.dart';
import 'package:bluecherry_client/providers/server_provider.dart';
import 'package:bluecherry_client/utils/constants.dart';
import 'package:bluecherry_client/utils/security.dart';
import 'package:flutter/material.dart';

Future<void> showEditServer(BuildContext context, Server server) async {
  final authorized = await UnityAuth.ask();
  if (!context.mounted) return;
  if (authorized) {
    return showDialog(
      context: context,
      builder: (context) {
        final loc = AppLocalizations.of(context);
        return AlertDialog(
          title: Text(loc.editServer(server.name)),
          content: ConstrainedBox(
            constraints: BoxConstraints(
              minWidth: MediaQuery.sizeOf(context).width * 0.75,
            ),
            child: EditServer(serverIp: server.ip, serverPort: server.port),
          ),
        );
      },
    );
  } else {
    UnityAuth.showAccessDeniedMessage(context);
  }
}

Future<void> updateServer(BuildContext context, Server serverCopy) async {
  final (code, updatedServer) = await API.instance.checkServerCredentials(
    serverCopy,
  );

  if (updatedServer.serverUUID != null &&
      updatedServer.hasCookies &&
      code == ServerAdditionResponse.validated) {
    await ServersProvider.instance.update(updatedServer);

    if (context.mounted) Navigator.of(context).pop();
  } else if (context.mounted) {
    showDialog(
      context: context,
      builder: (context) {
        final theme = Theme.of(context);
        final loc = AppLocalizations.of(context);

        return AlertDialog(
          title: Text(loc.error),
          content: Text(
            loc.serverNotAddedError(serverCopy.name),
            style: theme.textTheme.headlineMedium,
          ),
          actions: [
            MaterialButton(
              onPressed: Navigator.of(context).maybePop,
              textColor: theme.colorScheme.secondary,
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

class EditServer extends StatefulWidget {
  final String serverIp;
  final int serverPort;

  const EditServer({
    super.key,
    required this.serverIp,
    required this.serverPort,
  });

  @override
  State<EditServer> createState() => _EditServerState();
}

class _EditServerState extends State<EditServer> {
  final formKey = GlobalKey<FormState>();
  bool nameTextFieldEverFocused = false;
  bool disableFinishButton = false;
  bool showPassword = false;

  Server get server {
    return ServersProvider.instance.servers.firstWhere(
      (s) => s.ip == widget.serverIp && s.port == widget.serverPort,
      orElse: () => Server.dump(ip: widget.serverIp, port: widget.serverPort),
    );
  }

  late final hostnameController = TextEditingController(text: server.ip);
  late final portController = TextEditingController(text: '${server.port}');
  late final rtspPortController = TextEditingController(
    text: '${server.rtspPort}',
  );
  late final nameController = TextEditingController(text: server.name);
  late final usernameController = TextEditingController(text: server.login);
  late final passwordController = TextEditingController(text: server.password);

  @override
  void dispose() {
    hostnameController.dispose();
    portController.dispose();
    rtspPortController.dispose();
    nameController.dispose();
    usernameController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final loc = AppLocalizations.of(context);

    return PopScope(
      canPop: !disableFinishButton,
      child: Form(
        key: formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Expanded(
                  flex: 5,
                  child: TextFormField(
                    enabled: !disableFinishButton,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return loc.errorTextField(loc.hostname);
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
                  ),
                ),
                const SizedBox(width: 16.0),
                Expanded(
                  flex: 2,
                  child: TextFormField(
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
                  ),
                ),
                const SizedBox(width: 16.0),
                Expanded(
                  flex: 2,
                  child: TextFormField(
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
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16.0),
            TextFormField(
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
              textInputAction: TextInputAction.next,
              style: theme.textTheme.headlineMedium,
              decoration: InputDecoration(
                label: Text(loc.serverName),
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16.0),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    enabled: !disableFinishButton,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return loc.errorTextField(loc.username);
                      }
                      return null;
                    },
                    textInputAction: TextInputAction.next,
                    controller: usernameController,
                    style: theme.textTheme.headlineMedium,
                    decoration: InputDecoration(
                      label: Text(loc.username),
                      hintText: loc.usernameHint,
                      border: const OutlineInputBorder(),
                    ),
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
                    enabled: !disableFinishButton,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return loc.errorTextField(loc.password);
                      }
                      return null;
                    },
                    controller: passwordController,
                    obscureText: !showPassword,
                    style: theme.textTheme.headlineMedium,
                    textInputAction: TextInputAction.done,
                    decoration: InputDecoration(
                      label: Text(loc.password),
                      border: const OutlineInputBorder(),
                      suffixIcon: Padding(
                        padding: const EdgeInsetsDirectional.only(end: 8.0),
                        child: Tooltip(
                          message:
                              showPassword
                                  ? loc.hidePassword
                                  : loc.showPassword,
                          child: InkWell(
                            borderRadius: BorderRadius.circular(8.0),
                            child: Icon(
                              showPassword
                                  ? Icons.visibility
                                  : Icons.visibility_off,
                              size: 22.0,
                            ),
                            onTap:
                                () => setState(
                                  () => showPassword = !showPassword,
                                ),
                          ),
                        ),
                      ),
                    ),
                    onFieldSubmitted: (_) => update(),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16.0),
            Align(
              alignment: AlignmentDirectional.bottomEnd,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  MaterialButton(
                    onPressed:
                        !disableFinishButton
                            ? () => Navigator.of(context).pop(context)
                            : null,
                    child: Padding(
                      padding: const EdgeInsetsDirectional.all(8.0),
                      child: Text(loc.cancel),
                    ),
                  ),
                  const SizedBox(width: 8.0),
                  FilledButton(
                    onPressed: disableFinishButton ? null : update,
                    child: Padding(
                      padding: const EdgeInsetsDirectional.all(8.0),
                      child: Text(loc.finish.toUpperCase()),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> update() async {
    if (formKey.currentState?.validate() ?? false) {
      if (mounted) setState(() => disableFinishButton = true);

      final serverCopy = server.copyWith(
        ip: hostnameController.text,
        port: int.parse(portController.text),
        rtspPort: int.parse(rtspPortController.text),
        name: nameController.text,
        login: usernameController.text,
        password: passwordController.text,
      );

      await updateServer(context, serverCopy);

      if (mounted) setState(() => disableFinishButton = false);
    }
  }
}
