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
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

Future<void> showEditServer(BuildContext context, Server server) {
  return showDialog(
    context: context,
    builder: (context) {
      return AlertDialog(
        title: Text(
          AppLocalizations.of(context).editServer(
            server.name,
          ),
        ),
        content: ConstrainedBox(
          constraints: const BoxConstraints(minWidth: 300.0),
          child: EditServer(
            serverIp: server.ip,
            serverPort: server.port,
          ),
        ),
      );
    },
  );
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

  Server get server => ServersProvider.instance.servers.firstWhere(
        (server) =>
            server.ip == widget.serverIp && server.port == widget.serverPort,
      );

  /// [0] -- ip
  /// [1] -- port
  /// [2] -- name
  /// [3] -- login
  /// [4] -- password
  late final List<TextEditingController> textEditingControllers = [
    TextEditingController(text: server.ip),
    TextEditingController(text: '${server.port}'),
    TextEditingController(text: server.name),
    TextEditingController(text: server.login),
    TextEditingController(text: server.password),
  ];

  @override
  void dispose() {
    for (final controller in textEditingControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return WillPopScope(
      onWillPop: () async => !disableFinishButton,
      child: Form(
        key: formKey,
        child: Column(mainAxisSize: MainAxisSize.min, children: [
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
                style: theme.textTheme.headlineMedium,
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
                style: theme.textTheme.headlineMedium,
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
            style: theme.textTheme.headlineMedium,
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
                style: theme.textTheme.headlineMedium,
                decoration: InputDecoration(
                  label: Text(AppLocalizations.of(context).username),
                  border: const OutlineInputBorder(),
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
                style: theme.textTheme.headlineMedium,
                decoration: InputDecoration(
                  label: Text(AppLocalizations.of(context).password),
                  border: const OutlineInputBorder(),
                ),
              ),
            ),
          ]),
          const SizedBox(height: 16.0),
          Align(
            alignment: AlignmentDirectional.bottomEnd,
            child: Row(mainAxisAlignment: MainAxisAlignment.end, children: [
              MaterialButton(
                onPressed: Navigator.of(context).pop,
                textColor: theme.colorScheme.secondary,
                child: Padding(
                  padding: const EdgeInsetsDirectional.all(8.0),
                  child: Text(AppLocalizations.of(context).cancel),
                ),
              ),
              MaterialButton(
                onPressed: disableFinishButton ? null : update,
                textColor: theme.colorScheme.secondary,
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
    );
  }

  Future<void> update() async {
    if (formKey.currentState?.validate() ?? false) {
      if (mounted) setState(() => disableFinishButton = true);

      final copyServer = server.copyWith(
        ip: textEditingControllers[0].text,
        port: int.parse(textEditingControllers[1].text),
        name: textEditingControllers[2].text,
        login: textEditingControllers[3].text,
        password: textEditingControllers[4].text,
      );

      final updatedServer = await API.instance.checkServerCredentials(
        copyServer,
      );

      if (server.serverUUID != null && server.cookie != null) {
        await ServersProvider.instance.update(updatedServer);

        if (mounted) Navigator.of(context).pop();
      } else if (mounted) {
        showDialog(
          context: context,
          builder: (context) {
            final theme = Theme.of(context);
            return AlertDialog(
              title: Text(AppLocalizations.of(context).error),
              content: Text(
                AppLocalizations.of(context).serverNotAddedError(server.name),
                style: theme.textTheme.headlineMedium,
              ),
              actions: [
                MaterialButton(
                  onPressed: Navigator.of(context).maybePop,
                  textColor: theme.colorScheme.secondary,
                  child: Padding(
                    padding: const EdgeInsetsDirectional.all(8.0),
                    child: Text(
                      AppLocalizations.of(context).ok,
                    ),
                  ),
                ),
              ],
            );
          },
        );
      }

      if (mounted) setState(() => disableFinishButton = false);
    }
  }
}
