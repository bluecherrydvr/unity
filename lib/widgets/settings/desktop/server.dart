import 'package:flutter/material.dart';

class ServerSettings extends StatelessWidget {
  const ServerSettings({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListView(children: [
      Text(
        'Servers',
        style: theme.textTheme.titleLarge,
      ),
    ]);
  }
}
