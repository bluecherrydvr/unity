import 'package:bluecherry_client/widgets/settings/desktop/appearance.dart';
import 'package:bluecherry_client/widgets/settings/desktop/date_language.dart';
import 'package:bluecherry_client/widgets/settings/desktop/general.dart';
import 'package:bluecherry_client/widgets/settings/desktop/server.dart';
import 'package:bluecherry_client/widgets/settings/desktop/updates.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class DesktopSettings extends StatefulWidget {
  const DesktopSettings({super.key});

  @override
  State<DesktopSettings> createState() => _DesktopSettingsState();
}

class _DesktopSettingsState extends State<DesktopSettings> {
  int currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    return Row(children: [
      NavigationRail(
        destinations: [
          const NavigationRailDestination(
            icon: Icon(Icons.dashboard),
            label: Text('General'),
          ),
          NavigationRailDestination(
            icon: const Icon(Icons.dns),
            label: Text(loc.servers),
          ),
          const NavigationRailDestination(
            icon: Icon(Icons.brightness_auto),
            label: Text('Appearance'),
          ),
          NavigationRailDestination(
            icon: const Icon(Icons.update),
            label: Text(loc.updates),
          ),
          const NavigationRailDestination(
            icon: Icon(Icons.language),
            label: Text('Date and Language'),
          ),
        ],
        selectedIndex: currentIndex,
        onDestinationSelected: (index) => setState(() => currentIndex = index),
      ),
      Expanded(
        child: Card(
          margin: EdgeInsetsDirectional.zero,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadiusDirectional.only(
              topStart: Radius.circular(12.0),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: AnimatedSwitcher(
              duration: kThemeChangeDuration,
              child: switch (currentIndex) {
                0 => const GeneralSettings(),
                1 => const ServerSettings(),
                2 => const AppearanceSettings(),
                3 => const UpdatesSettings(),
                4 => const LocalizationSettings(),
                _ => const GeneralSettings(),
              },
            ),
          ),
        ),
      ),
    ]);
  }
}
