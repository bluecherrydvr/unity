import 'package:flutter/material.dart';

class LocalizationSettings extends StatelessWidget {
  const LocalizationSettings({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListView(children: [
      Text(
        'Date and Language',
        style: theme.textTheme.titleLarge,
      ),
    ]);
  }
}
