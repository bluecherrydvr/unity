import 'package:bluecherry_client/models/server.dart';
import 'package:bluecherry_client/widgets/servers/add_server.dart';
import 'package:bluecherry_client/widgets/servers/edit_server.dart';
import 'package:flutter/material.dart';

Future<void> showEditServerSettings(BuildContext context, Server server) {
  return showDialog(
    context: context,
    barrierDismissible: true,
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
        onNext: () {
          throw UnimplementedError('This should never be reached');
        },
      ),
    );
  }
}
