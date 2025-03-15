import 'package:flutter/material.dart';

class SquaredIconButton extends StatelessWidget {
  /// Called when the button is pressed.
  ///
  /// If null, the button is disabled.
  final VoidCallback? onPressed;

  /// The icon
  final Widget icon;

  /// The tooltip message.
  ///
  /// See also
  ///
  ///  * [Tooltip.message]
  final String? tooltip;

  /// The padding around this button.
  ///
  /// Defaults to 4.0 logical pixels on all sides
  final EdgeInsetsDirectional padding;

  const SquaredIconButton({
    super.key,
    required this.onPressed,
    required this.icon,
    this.tooltip,
    this.padding = const EdgeInsetsDirectional.only(
      top: 4.0,
      bottom: 4.0,
      end: 4.0,
    ),
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final widget = Padding(
      padding: padding,
      child: InkWell(
        borderRadius: BorderRadius.circular(6.0),
        onTap: onPressed,
        child: Padding(
          padding: const EdgeInsetsDirectional.all(2.5),
          child: IconTheme.merge(
            data: IconThemeData(
              size: 18.0,
              color:
                  onPressed == null
                      ? theme.disabledColor
                      : theme.colorScheme.onSurface.withValues(alpha: 0.9),
            ),
            child: icon,
          ),
        ),
      ),
    );

    if (tooltip != null && onPressed != null) {
      return Tooltip(message: tooltip!, child: widget);
    }

    return widget;
  }
}
