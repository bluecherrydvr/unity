import 'package:flutter/material.dart';

class SquaredIconButton extends StatelessWidget {
  final VoidCallback onPressed;
  final Widget icon;
  final String? tooltip;

  const SquaredIconButton({
    super.key,
    required this.onPressed,
    required this.icon,
    this.tooltip,
  });

  @override
  Widget build(BuildContext context) {
    final widget = Padding(
      padding:
          const EdgeInsetsDirectional.only(top: 4.0, bottom: 4.0, end: 4.0),
      child: InkWell(
        borderRadius: BorderRadius.circular(4.0),
        onTap: onPressed,
        child: Padding(
          padding: const EdgeInsetsDirectional.all(2.5),
          child: icon,
        ),
      ),
    );

    if (tooltip != null) {
      return Tooltip(message: tooltip!, child: widget);
    }

    return widget;
  }
}
