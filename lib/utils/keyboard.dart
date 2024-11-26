import 'package:bluecherry_client/main.dart';
import 'package:bluecherry_client/providers/home_provider.dart';
import 'package:bluecherry_client/providers/layouts_provider.dart';
import 'package:bluecherry_client/providers/settings_provider.dart';
import 'package:bluecherry_client/screens/layouts/desktop/layout_manager.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';

Map<ShortcutActivator, VoidCallback> globalShortcuts(BuildContext context) {
  context = navigatorKey.currentContext ?? context;
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

Map<ShortcutActivator, VoidCallback> layoutShortcuts(BuildContext context) {
  context = navigatorKey.currentContext ?? context;
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
      if (navigatorKey.currentContext == null) return;
      showNewLayoutDialog(navigatorKey.currentContext!);
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

Map<ShortcutActivator, VoidCallback> settingsShortcuts(BuildContext context) {
  context = navigatorKey.currentContext ?? context;
  final settings = context.read<SettingsProvider>();

  return {
    for (var i = 0; i < 6; i++)
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
        }[i + 1]!,
        control: true,
      ): () {
        settings.settingsIndex = i;
      },
    for (var i = 0; i < 6; i++)
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
        }[i + 1]!,
        control: true,
      ): () {
        settings.settingsIndex = i;
      },
  };
}

class KeyboardBindings {
  // Global shortcuts
  static const toggleFullscreen = SingleActivator(LogicalKeyboardKey.f11);
  static const toggleImmersiveMode = SingleActivator(LogicalKeyboardKey.f12);
  static const setTab1 = SingleActivator(LogicalKeyboardKey.digit1, alt: true);
  static const setTab2 = SingleActivator(LogicalKeyboardKey.digit2, alt: true);
  static const setTab3 = SingleActivator(LogicalKeyboardKey.digit3, alt: true);
  static const setTab4 = SingleActivator(LogicalKeyboardKey.digit4, alt: true);
  static const setTab5 = SingleActivator(LogicalKeyboardKey.digit5, alt: true);
  static const setTab6 = SingleActivator(LogicalKeyboardKey.digit6, alt: true);
  static const setTab7 = SingleActivator(LogicalKeyboardKey.digit7, alt: true);
  static const setTab8 = SingleActivator(LogicalKeyboardKey.digit8, alt: true);
  static const setTab9 = SingleActivator(LogicalKeyboardKey.digit9, alt: true);

  // Layout shortcuts
  static const setLayout1 =
      SingleActivator(LogicalKeyboardKey.digit1, control: true);
  static const setLayout2 =
      SingleActivator(LogicalKeyboardKey.digit2, control: true);
  static const setLayout3 =
      SingleActivator(LogicalKeyboardKey.digit3, control: true);
  static const setLayout4 =
      SingleActivator(LogicalKeyboardKey.digit4, control: true);
  static const setLayout5 =
      SingleActivator(LogicalKeyboardKey.digit5, control: true);
  static const setLayout6 =
      SingleActivator(LogicalKeyboardKey.digit6, control: true);
  static const setLayout7 =
      SingleActivator(LogicalKeyboardKey.digit7, control: true);
  static const setLayout8 =
      SingleActivator(LogicalKeyboardKey.digit8, control: true);
  static const setLayout9 =
      SingleActivator(LogicalKeyboardKey.digit9, control: true);
  static const toggleLayoutCycling =
      SingleActivator(LogicalKeyboardKey.keyC, control: true, shift: true);
  static const toggleLayoutSidebar =
      SingleActivator(LogicalKeyboardKey.keyB, control: true);
  static const showNewLayoutDialog =
      SingleActivator(LogicalKeyboardKey.keyN, control: true);
  static const switchToNextLayout =
      SingleActivator(LogicalKeyboardKey.tab, control: true);
  static const switchToPreviousLayout =
      SingleActivator(LogicalKeyboardKey.tab, control: true, shift: true);
  static const toggleLayoutLock =
      SingleActivator(LogicalKeyboardKey.keyL, control: true);

  // Settings shortcuts
  static const setSettingsTab1 =
      SingleActivator(LogicalKeyboardKey.digit1, control: true);
  static const setSettingsTab2 =
      SingleActivator(LogicalKeyboardKey.digit2, control: true);
  static const setSettingsTab3 =
      SingleActivator(LogicalKeyboardKey.digit3, control: true);
  static const setSettingsTab4 =
      SingleActivator(LogicalKeyboardKey.digit4, control: true);
  static const setSettingsTab5 =
      SingleActivator(LogicalKeyboardKey.digit5, control: true);
  static const setSettingsTab6 =
      SingleActivator(LogicalKeyboardKey.digit6, control: true);

  static List<
      ({
        String name,
        String system,
        ShortcutActivator activator,
      })> get all {
    return [
      (
        name: 'Toggle Fullscreen',
        system: 'Global',
        activator: toggleFullscreen,
      ),
      (
        name: 'Toggle Immersive Mode',
        system: 'Global',
        activator: toggleImmersiveMode,
      ),
      (
        name: 'Set Layouts Tab',
        system: 'Global',
        activator: setTab1,
      ),
      (
        name: 'Set Events Timeline Tab',
        system: 'Global',
        activator: setTab2,
      ),
      (
        name: 'Set Add Server Tab',
        system: 'Global',
        activator: setTab3,
      ),
      (
        name: 'Set Downloads Tab',
        system: 'Global',
        activator: setTab4,
      ),
      (
        name: 'Set Settings Tab',
        system: 'Global',
        activator: setTab5,
      ),
      (
        name: 'Set Tab 6',
        system: 'Global',
        activator: setTab6,
      ),
      (
        name: 'Set Tab 7',
        system: 'Global',
        activator: setTab7,
      ),
      (
        name: 'Set Tab 8',
        system: 'Global',
        activator: setTab8,
      ),
      (
        name: 'Set Tab 9',
        system: 'Global',
        activator: setTab9,
      ),
      (
        name: 'Set Layout 1',
        system: 'Layout',
        activator: setLayout1,
      ),
      (
        name: 'Set Layout 2',
        system: 'Layout',
        activator: setLayout2,
      ),
      (
        name: 'Set Layout 3',
        system: 'Layout',
        activator: setLayout3,
      ),
      (
        name: 'Set Layout 4',
        system: 'Layout',
        activator: setLayout4,
      ),
      (
        name: 'Set Layout 5',
        system: 'Layout',
        activator: setLayout5,
      ),
      (
        name: 'Set Layout 6',
        system: 'Layout',
        activator: setLayout6,
      ),
      (
        name: 'Set Layout 7',
        system: 'Layout',
        activator: setLayout7,
      ),
      (
        name: 'Set Layout 8',
        system: 'Layout',
        activator: setLayout8,
      ),
      (
        name: 'Set Layout 9',
        system: 'Layout',
        activator: setLayout9,
      ),
      (
        name: 'Toggle Layout Cycling',
        system: 'Layout',
        activator: toggleLayoutCycling,
      ),
      (
        name: 'Toggle Layout Sidebar',
        system: 'Layout',
        activator: toggleLayoutSidebar,
      ),
      (
        name: 'Show New Layout Dialog',
        system: 'Layout',
        activator: showNewLayoutDialog,
      ),
      (
        name: 'Switch to Next Layout',
        system: 'Layout',
        activator: switchToNextLayout,
      ),
      (
        name: 'Switch to Previous Layout',
        system: 'Layout',
        activator: switchToPreviousLayout,
      ),
      (
        name: 'Toggle Layout Lock',
        system: 'Layout',
        activator: toggleLayoutLock,
      ),
      (
        name: 'Go to General Settings',
        system: 'Settings',
        activator: setSettingsTab1,
      ),
      (
        name: 'Go to Server and Devices Settings',
        system: 'Settings',
        activator: setSettingsTab2,
      ),
      (
        name: 'Go to Events and Downloads Settings',
        system: 'Settings',
        activator: setSettingsTab3,
      ),
      (
        name: 'Go to Application Settings',
        system: 'Settings',
        activator: setSettingsTab4,
      ),
      (
        name: 'Go to Updates and Help Settings',
        system: 'Settings',
        activator: setSettingsTab5,
      ),
      (
        name: 'Go to Advanced Options Settings',
        system: 'Settings',
        activator: setSettingsTab6,
      ),
    ];
  }
}
