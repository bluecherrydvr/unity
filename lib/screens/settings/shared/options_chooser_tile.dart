import 'package:flutter/material.dart';

class Option<T> {
  final T value;
  final IconData icon;
  final String text;

  Option({
    required this.value,
    required this.icon,
    required this.text,
  });
}

class OptionsChooserTile<T> extends StatelessWidget {
  final String title;
  final String description;
  final IconData icon;

  final String selected;
  final T value;
  final List<Option<T>> values;
  final ValueChanged<T> onChanged;

  const OptionsChooserTile({
    super.key,
    required this.title,
    required this.description,
    required this.icon,
    required this.selected,
    required this.value,
    required this.values,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    // final settings = context.watch<SettingsProvider>();
    // final loc = AppLocalizations.of(context);

    return ExpansionTile(
      leading: CircleAvatar(
        backgroundColor: Colors.transparent,
        foregroundColor: theme.iconTheme.color,
        child: Icon(icon),
      ),
      title: Text(title),
      textColor: theme.textTheme.bodyLarge?.color,
      subtitle: Text(
        description,
        style: theme.textTheme.bodyMedium?.copyWith(
          color: theme.textTheme.bodySmall?.color,
        ),
      ),
      trailing: Text(selected),
      children: values.map((option) {
        return RadioListTile<T>.adaptive(
          contentPadding: const EdgeInsetsDirectional.only(
            start: 68.0,
            end: 16.0,
          ),
          value: option.value,
          groupValue: value,
          onChanged: (value) {
            if (value != null) {
              onChanged(value);
            }
          },
          secondary: Icon(option.icon),
          controlAffinity: ListTileControlAffinity.trailing,
          title: Padding(
            padding: const EdgeInsetsDirectional.only(start: 16.0),
            child: Text(option.text),
          ),
        );
      }).toList(),
    );
  }
}
