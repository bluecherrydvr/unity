import 'package:bluecherry_client/models/server.dart';
import 'package:bluecherry_client/screens/servers/additional_server_settings.dart';
import 'package:bluecherry_client/screens/servers/edit_server.dart';
import 'package:flutter/material.dart';

Future<void> showEditServerSettings(BuildContext context, Server server) {
  return showDialog(
    context: context,
    builder: (context) {
      return EditServerSettings(server: server);
    },
  );
}

class EditServerSettings extends StatelessWidget {
  final Server server;

  const EditServerSettings({
    super.key,
    required this.server,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: AdditionalServerSettings(
        isEditing: true,
        server: server,
        onServerChanged: (serverCopy) async {
          await updateServer(context, serverCopy);
        },
        onBack: () {},
        onNext: () {},
      ),
    );
  }
}
