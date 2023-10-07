import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class ServerNotAddedErrorDialog extends StatelessWidget {
  final String name;
  final String description;

  final VoidCallback? onRetry;

  const ServerNotAddedErrorDialog({
    super.key,
    required this.name,
    required this.description,
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final loc = AppLocalizations.of(context);

    return AlertDialog(
      title: Text(loc.serverNotAddedError(name)),
      content: Text(
        description,
        style: theme.textTheme.headlineMedium,
      ),
      actions: [
        if (onRetry != null)
          TextButton(
            onPressed: () {
              Navigator.of(context).maybePop();
              if (context.mounted) onRetry?.call();
            },
            child: Padding(
              padding: const EdgeInsetsDirectional.all(8.0),
              child: Text(loc.retry.toUpperCase()),
            ),
          ),
        MaterialButton(
          onPressed: Navigator.of(context).maybePop,
          child: Padding(
            padding: const EdgeInsetsDirectional.all(8.0),
            child: Text(loc.ok),
          ),
        ),
      ],
    );
  }
}
