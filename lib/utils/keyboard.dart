import 'package:bluecherry_client/providers/home_provider.dart';
import 'package:bluecherry_client/providers/settings_provider.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';

Map<ShortcutActivator, VoidCallback> globalShortcuts(BuildContext context) {
  final settings = context.read<SettingsProvider>();
  final home = context.read<HomeProvider>();

  void setTab(int index) {
    index--;
    if (index >= 0 && index < UnityTab.values.length) {
      final tab = NavigatorData.of(context)[index];
      home.setTab(tab.tab);
    }
  }

  return {
    SingleActivator(LogicalKeyboardKey.f11): () {
      settings.kFullscreen.value = !settings.kFullscreen.value;
    },
    SingleActivator(LogicalKeyboardKey.f12): () {
      settings.kImmersiveMode.value = !settings.kImmersiveMode.value;
    },
    SingleActivator(LogicalKeyboardKey.digit1, alt: true): () => setTab(1),
    SingleActivator(LogicalKeyboardKey.digit2, alt: true): () => setTab(2),
    SingleActivator(LogicalKeyboardKey.numpad2, alt: true): () => setTab(2),
    SingleActivator(LogicalKeyboardKey.digit3, alt: true): () => setTab(3),
    SingleActivator(LogicalKeyboardKey.numpad3, alt: true): () => setTab(3),
    SingleActivator(LogicalKeyboardKey.digit4, alt: true): () => setTab(4),
    SingleActivator(LogicalKeyboardKey.numpad4, alt: true): () => setTab(4),
    SingleActivator(LogicalKeyboardKey.digit5, alt: true): () => setTab(5),
    SingleActivator(LogicalKeyboardKey.numpad5, alt: true): () => setTab(5),
    SingleActivator(LogicalKeyboardKey.digit6, alt: true): () => setTab(6),
    SingleActivator(LogicalKeyboardKey.numpad6, alt: true): () => setTab(6),
    SingleActivator(LogicalKeyboardKey.digit7, alt: true): () => setTab(7),
    SingleActivator(LogicalKeyboardKey.numpad7, alt: true): () => setTab(7),
    SingleActivator(LogicalKeyboardKey.digit8, alt: true): () => setTab(8),
    SingleActivator(LogicalKeyboardKey.numpad8, alt: true): () => setTab(8),
    SingleActivator(LogicalKeyboardKey.digit9, alt: true): () => setTab(9),
    SingleActivator(LogicalKeyboardKey.numpad9, alt: true): () => setTab(9),
  };
}
