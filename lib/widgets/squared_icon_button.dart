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
    final widget = Padding(
      padding: padding,
      child: InkWell(
        borderRadius: BorderRadius.circular(6.0),
        onTap: onPressed,
        child: Padding(
          padding: const EdgeInsetsDirectional.all(2.5),
          child: IconTheme.merge(
            data: const IconThemeData(size: 18.0),
            child: icon,
          ),
        ),
      ),
    );

    if (tooltip != null) {
      return Tooltip(message: tooltip!, child: widget);
    }

    return widget;
  }
}
