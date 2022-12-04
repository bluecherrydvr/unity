import 'package:flutter/material.dart';
import 'package:window_manager/window_manager.dart';

class WindowButtons extends StatelessWidget {
  const WindowButtons({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      color: theme.appBarTheme.backgroundColor,
      child: DragToMoveArea(
        child: Align(
          alignment: AlignmentDirectional.centerEnd,
          child: SizedBox(
            width: 138,
            height: 30,
            child: WindowCaption(
              brightness: theme.brightness,
              backgroundColor: Colors.transparent,
            ),
          ),
        ),
      ),
    );
  }
}
