import 'dart:ui' as ui;

import 'package:bluecherry_client/utils/theme.dart';
import 'package:flutter/material.dart';

class SplashScreen extends StatelessWidget {
  const SplashScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isDark = ui.window.platformBrightness == ui.Brightness.dark;
    final theme = createTheme(
      themeMode: isDark ? ThemeMode.dark : ThemeMode.light,
    );

    return Container(
      color: theme.scaffoldBackgroundColor,
      alignment: Alignment.center,
      child: Image.asset(
        'assets/images/icon.png',
        height: 100.0,
        width: 100.0,
      ),
    );
  }
}
