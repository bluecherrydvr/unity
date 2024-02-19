import 'package:bluecherry_client/screens/settings/settings_desktop.dart';
import 'package:flutter/material.dart';

class Option<T> {
  final T value;
  final IconData? icon;
  final String text;

  Option({
    required this.value,
    required this.text,
    this.icon,
  });
}

class OptionsChooserTile<T> extends StatelessWidget {
  final String title;
  final String? description;
  final IconData icon;

  final T value;
  final Iterable<Option<T>> values;
  final ValueChanged<T> onChanged;

  const OptionsChooserTile({
    super.key,
    required this.title,
    this.description,
    required this.icon,
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
        child: Align(
          alignment: description == null
              ? Alignment.center
              : AlignmentDirectional.topCenter,
          child: Icon(icon),
        ),
      ),
      title: Text(title),
      textColor: theme.textTheme.bodyLarge?.color,
      subtitle: description == null
          ? null
          : Text(
              description!,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.textTheme.bodySmall?.color,
              ),
            ),
      tilePadding: DesktopSettings.horizontalPadding,
      trailing: Text(values
          .firstWhere(
            (v) => v.text == value,
            orElse: () => values.first,
          )
          .text),
      children: values.map((option) {
        return RadioListTile<T>.adaptive(
          contentPadding: const EdgeInsetsDirectional.only(
            start: 76.0,
            end: 16.0,
          ),
          value: option.value,
          groupValue: value,
          onChanged: (value) {
            if (value != null) {
              onChanged(value);
            }
          },
          secondary: option.icon == null ? null : Icon(option.icon),
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
