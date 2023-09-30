import 'package:flutter/material.dart';

class AppearanceSettings extends StatelessWidget {
  const AppearanceSettings({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListView(children: [
      Text(
        'Appearance',
        style: theme.textTheme.titleLarge,
      ),
    ]);
  }
}
