import 'package:bluecherry_client/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';

Future<void> showServerNotAddedErrorDialog({
  required BuildContext context,
  required String name,
  required String description,
  VoidCallback? onRetry,
}) async {
  return showDialog(
    context: context,
    builder: (context) {
      return ServerNotAddedErrorDialog(
        name: name,
        description: description,
        onRetry: onRetry,
      );
    },
  );
}

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
      content: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 400.0),
        child: Text(description, style: theme.textTheme.headlineMedium),
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
        ElevatedButton(
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
