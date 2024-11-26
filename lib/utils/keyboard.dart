import 'package:bluecherry_client/main.dart';
import 'package:bluecherry_client/providers/home_provider.dart';
import 'package:bluecherry_client/providers/layouts_provider.dart';
import 'package:bluecherry_client/providers/settings_provider.dart';
import 'package:bluecherry_client/screens/layouts/desktop/layout_manager.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';

Map<ShortcutActivator, VoidCallback> globalShortcuts() {
  final context = navigatorKey.currentContext!;
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

Map<ShortcutActivator, VoidCallback> layoutShortcuts() {
  final context = navigatorKey.currentContext!;
  final settings = context.read<SettingsProvider>();
  final layouts = context.read<LayoutsProvider>();

  return {
    for (var i = 1; i < layouts.layouts.length.clamp(1, 9); i++)
      SingleActivator(
        {
          1: LogicalKeyboardKey.digit1,
          2: LogicalKeyboardKey.digit2,
          3: LogicalKeyboardKey.digit3,
          4: LogicalKeyboardKey.digit4,
          5: LogicalKeyboardKey.digit5,
          6: LogicalKeyboardKey.digit6,
          7: LogicalKeyboardKey.digit7,
          8: LogicalKeyboardKey.digit8,
          9: LogicalKeyboardKey.digit9,
        }[i]!,
        control: true,
      ): () {
        layouts.updateCurrentLayout(i - 1);
      },
    for (var i = 1; i < layouts.layouts.length.clamp(1, 9); i++)
      SingleActivator(
        {
          1: LogicalKeyboardKey.numpad1,
          2: LogicalKeyboardKey.numpad2,
          3: LogicalKeyboardKey.numpad3,
          4: LogicalKeyboardKey.numpad4,
          5: LogicalKeyboardKey.numpad5,
          6: LogicalKeyboardKey.numpad6,
          7: LogicalKeyboardKey.numpad7,
          8: LogicalKeyboardKey.numpad8,
          9: LogicalKeyboardKey.numpad9,
        }[i]!,
        control: true,
      ): () {
        layouts.updateCurrentLayout(i - 1);
      },
    SingleActivator(LogicalKeyboardKey.keyC, control: true, shift: true):
        settings.toggleCycling,
    SingleActivator(LogicalKeyboardKey.keyB, control: true): () {
      layouts.sidebarKey.currentState?.toggle();
    },
    SingleActivator(LogicalKeyboardKey.keyN, control: true): () {
      showNewLayoutDialog(context);
    },
    SingleActivator(LogicalKeyboardKey.tab, control: true):
        layouts.switchToNextLayout,
    SingleActivator(LogicalKeyboardKey.tab, control: true, shift: true):
        layouts.switchToNextLayout,
    SingleActivator(LogicalKeyboardKey.keyL, control: true): () {
      layouts.toggleLayoutLock(layouts.currentLayout);
    },
  };
}
