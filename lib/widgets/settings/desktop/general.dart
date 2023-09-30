import 'package:flutter/material.dart';

class GeneralSettings extends StatelessWidget {
  const GeneralSettings({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListView(children: [
      Text(
        'General',
        style: theme.textTheme.titleLarge,
      ),
    ]);
  }
}
