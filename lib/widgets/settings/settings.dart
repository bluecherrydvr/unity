import 'package:bluecherry_client/utils/constants.dart';
import 'package:bluecherry_client/widgets/settings/desktop/settings.dart';
import 'package:bluecherry_client/widgets/settings/mobile/settings.dart';
import 'package:flutter/material.dart';

class Settings extends StatelessWidget {
  const Settings({super.key});

  @override
  Widget build(BuildContext context) {
    final hasDrawer = Scaffold.hasDrawer(context);

    return Material(
      type: MaterialType.transparency,
      child: LayoutBuilder(builder: (context, consts) {
        final width = consts.biggest.width;

        if (hasDrawer || width < kMobileBreakpoint.width) {
          return const MobileSettings();
        } else {
          return const DesktopSettings();
        }
      }),
    );
  }
}
