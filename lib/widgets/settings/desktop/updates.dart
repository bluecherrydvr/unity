import 'package:flutter/material.dart';

class UpdatesSettings extends StatelessWidget {
  const UpdatesSettings({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListView(children: [
      Text(
        'Updates',
        style: theme.textTheme.titleLarge,
      ),
    ]);
  }
}
