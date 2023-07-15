import 'package:bluecherry_client/main.dart';
import 'package:bluecherry_client/providers/desktop_view_provider.dart';
import 'package:bluecherry_client/providers/home_provider.dart';
import 'package:bluecherry_client/utils/theme.dart';
import 'package:bluecherry_client/widgets/desktop_buttons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';

class AlternativeWindow extends StatefulWidget {
  final ThemeMode mode;

  final Widget child;

  const AlternativeWindow({
    Key? key,
    required this.mode,
    required this.child,
  }) : super(key: key);

  static AlternativeWindowState? maybeOf(BuildContext context) {
    return context.findAncestorStateOfType<AlternativeWindowState>();
  }

  @override
  State<AlternativeWindow> createState() => AlternativeWindowState();
}

class AlternativeWindowState extends State<AlternativeWindow> {
  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => HomeProvider()),
        ChangeNotifierProvider.value(value: DesktopViewProvider.instance),
      ],
      child: MaterialApp(
        navigatorKey: navigatorKey,
        navigatorObservers: [NObserver()],
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        themeMode: widget.mode,
        theme: createTheme(themeMode: ThemeMode.light),
        darkTheme: createTheme(themeMode: ThemeMode.dark),
        debugShowCheckedModeBanner: false,
        home: widget.child,
      ),
    );
  }
}
