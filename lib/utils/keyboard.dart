import 'package:bluecherry_client/main.dart';
import 'package:bluecherry_client/providers/app_provider_interface.dart';
import 'package:bluecherry_client/providers/home_provider.dart';
import 'package:bluecherry_client/providers/layouts_provider.dart';
import 'package:bluecherry_client/providers/settings_provider.dart';
import 'package:bluecherry_client/screens/layouts/desktop/layout_manager.dart';
import 'package:bluecherry_client/utils/logging.dart';
import 'package:bluecherry_client/utils/storage.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';

Map<ShortcutActivator, VoidCallback> globalShortcuts(
  BuildContext context,
  KeyboardBindings bindings,
) {
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
    bindings.toggleFullscreen: () {
      settings.kFullscreen.value = !settings.kFullscreen.value;
    },
    bindings.toggleImmersiveMode: () {
      settings.kImmersiveMode.value = !settings.kImmersiveMode.value;
    },
    bindings.setTab1: () => setTab(1),
    bindings.setTab2: () => setTab(2),
    bindings.setTab3: () => setTab(3),
    bindings.setTab4: () => setTab(4),
    bindings.setTab5: () => setTab(5),
    bindings.setTab6: () => setTab(6),
    bindings.setTab7: () => setTab(7),
    bindings.setTab8: () => setTab(8),
    bindings.setTab9: () => setTab(9),
  };
}

Map<ShortcutActivator, VoidCallback> layoutShortcuts(
  BuildContext context,
  KeyboardBindings bindings,
) {
  context = navigatorKey.currentContext ?? context;
  final settings = context.read<SettingsProvider>();
  final layouts = context.read<LayoutsProvider>();

  return {
    bindings.setLayout1: () => layouts.updateCurrentLayout(0),
    bindings.setLayout2: () => layouts.updateCurrentLayout(1),
    bindings.setLayout3: () => layouts.updateCurrentLayout(2),
    bindings.setLayout4: () => layouts.updateCurrentLayout(3),
    bindings.setLayout5: () => layouts.updateCurrentLayout(4),
    bindings.setLayout6: () => layouts.updateCurrentLayout(5),
    bindings.setLayout7: () => layouts.updateCurrentLayout(6),
    bindings.setLayout8: () => layouts.updateCurrentLayout(7),
    bindings.setLayout9: () => layouts.updateCurrentLayout(8),
    bindings.toggleLayoutCycling: settings.toggleCycling,
    bindings.toggleLayoutSidebar: () {
      layouts.sidebarKey.currentState?.toggle();
    },
    bindings.showNewLayoutDialog: () {
      if (navigatorKey.currentContext == null) return;
      showNewLayoutDialog(navigatorKey.currentContext!);
    },
    bindings.switchToNextLayout: layouts.switchToNextLayout,
    bindings.switchToPreviousLayout: layouts.switchToNextLayout,
    bindings.toggleLayoutLock: () {
      layouts.toggleLayoutLock(layouts.currentLayout);
    },
  };
}

Map<ShortcutActivator, VoidCallback> settingsShortcuts(
  BuildContext context,
  KeyboardBindings bindings,
) {
  context = navigatorKey.currentContext ?? context;
  final settings = context.read<SettingsProvider>();

  return {
    bindings.setSettingsTab1: () => settings.settingsIndex = 0,
    bindings.setSettingsTab2: () => settings.settingsIndex = 1,
    bindings.setSettingsTab3: () => settings.settingsIndex = 2,
    bindings.setSettingsTab4: () => settings.settingsIndex = 3,
    bindings.setSettingsTab5: () => settings.settingsIndex = 4,
    bindings.setSettingsTab6: () => settings.settingsIndex = 5,
  };
}

class KeyboardBindings extends UnityProvider {
  KeyboardBindings._();

  static late KeyboardBindings instance;

  // Global shortcuts
  final _toggleFullscreen = KeybindingSetting(
    name: 'Toggle Fullscreen',
    system: 'Global',
    key: 'global.fullscreen',
    def: SingleActivator(LogicalKeyboardKey.f11),
  );

  SingleActivator get toggleFullscreen => _toggleFullscreen.value;

  final _toggleImmersiveMode = KeybindingSetting(
    name: 'Toggle Immersive Mode',
    system: 'Global',
    key: 'global.immersiveMode',
    def: SingleActivator(LogicalKeyboardKey.f12),
  );

  SingleActivator get toggleImmersiveMode => _toggleImmersiveMode.value;

  final _setTab1 = KeybindingSetting(
    name: 'Set Tab 1',
    system: 'Global',
    key: 'global.setTab1',
    def: SingleActivator(LogicalKeyboardKey.digit1, alt: true),
  );

  SingleActivator get setTab1 => _setTab1.value;

  final _setTab2 = KeybindingSetting(
    name: 'Set Tab 2',
    system: 'Global',
    key: 'global.setTab2',
    def: SingleActivator(LogicalKeyboardKey.digit2, alt: true),
  );

  SingleActivator get setTab2 => _setTab2.value;

  final _setTab3 = KeybindingSetting(
    name: 'Set Tab 3',
    system: 'Global',
    key: 'global.setTab3',
    def: SingleActivator(LogicalKeyboardKey.digit3, alt: true),
  );

  SingleActivator get setTab3 => _setTab3.value;

  final _setTab4 = KeybindingSetting(
    name: 'Set Tab 4',
    system: 'Global',
    key: 'global.setTab4',
    def: SingleActivator(LogicalKeyboardKey.digit4, alt: true),
  );

  SingleActivator get setTab4 => _setTab4.value;

  final _setTab5 = KeybindingSetting(
    name: 'Set Tab 5',
    system: 'Global',
    key: 'global.setTab5',
    def: SingleActivator(LogicalKeyboardKey.digit5, alt: true),
  );

  SingleActivator get setTab5 => _setTab5.value;

  final _setTab6 = KeybindingSetting(
    name: 'Set Tab 6',
    system: 'Global',
    key: 'global.setTab6',
    def: SingleActivator(LogicalKeyboardKey.digit6, alt: true),
  );

  SingleActivator get setTab6 => _setTab6.value;

  final _setTab7 = KeybindingSetting(
    name: 'Set Tab 7',
    system: 'Global',
    key: 'global.setTab7',
    def: SingleActivator(LogicalKeyboardKey.digit7, alt: true),
  );

  SingleActivator get setTab7 => _setTab7.value;

  final _setTab8 = KeybindingSetting(
    name: 'Set Tab 8',
    system: 'Global',
    key: 'global.setTab8',
    def: SingleActivator(LogicalKeyboardKey.digit8, alt: true),
  );

  SingleActivator get setTab8 => _setTab8.value;

  final _setTab9 = KeybindingSetting(
    name: 'Set Tab 9',
    system: 'Global',
    key: 'global.setTab9',
    def: SingleActivator(LogicalKeyboardKey.digit9, alt: true),
  );

  SingleActivator get setTab9 => _setTab9.value;

  // Layout shortcuts
  final _setLayout1 = KeybindingSetting(
    name: 'Set Layout 1',
    system: 'Layout',
    key: 'layout.setLayout1',
    def: SingleActivator(LogicalKeyboardKey.digit1, control: true),
  );

  SingleActivator get setLayout1 => _setLayout1.value;

  final _setLayout2 = KeybindingSetting(
    name: 'Set Layout 2',
    system: 'Layout',
    key: 'layout.setLayout2',
    def: SingleActivator(LogicalKeyboardKey.digit2, control: true),
  );

  SingleActivator get setLayout2 => _setLayout2.value;

  final _setLayout3 = KeybindingSetting(
    name: 'Set Layout 3',
    system: 'Layout',
    key: 'layout.setLayout3',
    def: SingleActivator(LogicalKeyboardKey.digit3, control: true),
  );

  SingleActivator get setLayout3 => _setLayout3.value;

  final _setLayout4 = KeybindingSetting(
    name: 'Set Layout 4',
    system: 'Layout',
    key: 'layout.setLayout4',
    def: SingleActivator(LogicalKeyboardKey.digit4, control: true),
  );

  SingleActivator get setLayout4 => _setLayout4.value;

  final _setLayout5 = KeybindingSetting(
    name: 'Set Layout 5',
    system: 'Layout',
    key: 'layout.setLayout5',
    def: SingleActivator(LogicalKeyboardKey.digit5, control: true),
  );

  SingleActivator get setLayout5 => _setLayout5.value;

  final _setLayout6 = KeybindingSetting(
    name: 'Set Layout 6',
    system: 'Layout',
    key: 'layout.setLayout6',
    def: SingleActivator(LogicalKeyboardKey.digit6, control: true),
  );

  SingleActivator get setLayout6 => _setLayout6.value;

  final _setLayout7 = KeybindingSetting(
    name: 'Set Layout 7',
    system: 'Layout',
    key: 'layout.setLayout7',
    def: SingleActivator(LogicalKeyboardKey.digit7, control: true),
  );

  SingleActivator get setLayout7 => _setLayout7.value;

  final _setLayout8 = KeybindingSetting(
    name: 'Set Layout 8',
    system: 'Layout',
    key: 'layout.setLayout8',
    def: SingleActivator(LogicalKeyboardKey.digit8, control: true),
  );

  SingleActivator get setLayout8 => _setLayout8.value;

  final _setLayout9 = KeybindingSetting(
    name: 'Set Layout 9',
    system: 'Layout',
    key: 'layout.setLayout9',
    def: SingleActivator(LogicalKeyboardKey.digit9, control: true),
  );

  SingleActivator get setLayout9 => _setLayout9.value;

  final _toggleLayoutCycling = KeybindingSetting(
    name: 'Toggle Layout Cycling',
    system: 'Layout',
    key: 'layout.toggleLayoutCycling',
    def: SingleActivator(LogicalKeyboardKey.keyC, control: true, shift: true),
  );

  SingleActivator get toggleLayoutCycling => _toggleLayoutCycling.value;

  final _toggleLayoutSidebar = KeybindingSetting(
    name: 'Toggle Layout Sidebar',
    system: 'Layout',
    key: 'layout.toggleLayoutSidebar',
    def: SingleActivator(LogicalKeyboardKey.keyB, control: true),
  );

  SingleActivator get toggleLayoutSidebar => _toggleLayoutSidebar.value;

  final _showNewLayoutDialog = KeybindingSetting(
    name: 'Show New Layout Dialog',
    system: 'Layout',
    key: 'layout.showNewLayoutDialog',
    def: SingleActivator(LogicalKeyboardKey.keyN, control: true),
  );

  SingleActivator get showNewLayoutDialog => _showNewLayoutDialog.value;

  final _switchToNextLayout = KeybindingSetting(
    name: 'Switch to Next Layout',
    system: 'Layout',
    key: 'layout.switchToNextLayout',
    def: SingleActivator(LogicalKeyboardKey.tab, control: true),
  );

  SingleActivator get switchToNextLayout => _switchToNextLayout.value;

  final _switchToPreviousLayout = KeybindingSetting(
    name: 'Switch to Previous Layout',
    system: 'Layout',
    key: 'layout.switchToPreviousLayout',
    def: SingleActivator(LogicalKeyboardKey.tab, control: true, shift: true),
  );

  SingleActivator get switchToPreviousLayout => _switchToPreviousLayout.value;

  final _toggleLayoutLock = KeybindingSetting(
    name: 'Toggle Layout Lock',
    system: 'Layout',
    key: 'layout.toggleLayoutLock',
    def: SingleActivator(LogicalKeyboardKey.keyL, control: true),
  );

  SingleActivator get toggleLayoutLock => _toggleLayoutLock.value;

  // Settings shortcuts
  final _setSettingsTab1 = KeybindingSetting(
    name: 'Set Settings Tab 1',
    system: 'Settings',
    key: 'settings.setSettingsTab1',
    def: SingleActivator(LogicalKeyboardKey.digit1, control: true),
  );

  SingleActivator get setSettingsTab1 => _setSettingsTab1.value;

  final _setSettingsTab2 = KeybindingSetting(
    name: 'Set Settings Tab 2',
    system: 'Settings',
    key: 'settings.setSettingsTab2',
    def: SingleActivator(LogicalKeyboardKey.digit2, control: true),
  );

  SingleActivator get setSettingsTab2 => _setSettingsTab2.value;

  final _setSettingsTab3 = KeybindingSetting(
    name: 'Set Settings Tab 3',
    system: 'Settings',
    key: 'settings.setSettingsTab3',
    def: SingleActivator(LogicalKeyboardKey.digit3, control: true),
  );

  SingleActivator get setSettingsTab3 => _setSettingsTab3.value;

  final _setSettingsTab4 = KeybindingSetting(
    name: 'Set Settings Tab 4',
    system: 'Settings',
    key: 'settings.setSettingsTab4',
    def: SingleActivator(LogicalKeyboardKey.digit4, control: true),
  );

  SingleActivator get setSettingsTab4 => _setSettingsTab4.value;

  final _setSettingsTab5 = KeybindingSetting(
    name: 'Set Settings Tab 5',
    system: 'Settings',
    key: 'settings.setSettingsTab5',
    def: SingleActivator(LogicalKeyboardKey.digit5, control: true),
  );

  SingleActivator get setSettingsTab5 => _setSettingsTab5.value;

  final _setSettingsTab6 = KeybindingSetting(
    name: 'Set Settings Tab 6',
    system: 'Settings',
    key: 'settings.setSettingsTab6',
    def: SingleActivator(LogicalKeyboardKey.digit6, control: true),
  );

  SingleActivator get setSettingsTab6 => _setSettingsTab6.value;

  List<KeybindingSetting> get all => [
    _toggleFullscreen,
    _toggleImmersiveMode,
    _setTab1,
    _setTab2,
    _setTab3,
    _setTab4,
    _setTab5,
    _setTab6,
    _setTab7,
    _setTab8,
    _setTab9,
    _setLayout1,
    _setLayout2,
    _setLayout3,
    _setLayout4,
    _setLayout5,
    _setLayout6,
    _setLayout7,
    _setLayout8,
    _setLayout9,
    _toggleLayoutCycling,
    _toggleLayoutSidebar,
    _showNewLayoutDialog,
    _switchToNextLayout,
    _switchToPreviousLayout,
    _toggleLayoutLock,
    _setSettingsTab1,
    _setSettingsTab2,
    _setSettingsTab3,
    _setSettingsTab4,
    _setSettingsTab5,
    _setSettingsTab6,
  ];

  /// Initializes the [KeyboardBindings] instance & fetches state from `async`
  /// `package:hive` method-calls. Called before [runApp].
  static Future<KeyboardBindings> ensureInitialized() async {
    instance = KeyboardBindings._();
    await instance.initialize();
    debugPrint('KeyboardBindings initialized');
    return instance;
  }

  @override
  Future<void> initialize() async {
    try {
      await initializeStorage('keybindings');
    } catch (error, stackTrace) {
      handleError(
        error,
        stackTrace,
        'Error initializing keybindings storage. Fallback to memory',
      );
    }

    for (final setting in _allSettings) {
      await setting.loadData();
    }

    notifyListeners();
  }

  @override
  Future<void> save({bool notifyListeners = true}) async {
    await write(<String, dynamic>{
      for (final setting in _allSettings)
        ...() {
          try {
            return <String, String>{setting.key: setting.saveAs(setting.value)};
          } catch (error, stackTrace) {
            handleError(
              error,
              stackTrace,
              'Error            saving setting ${setting.key}',
            );
          }
          return <String, String>{};
        }(),
    });
    super.save(notifyListeners: notifyListeners);
  }

  Future<void> updateProperty(Future Function() update) async {
    await update();
    save();
  }

  Future<void> restoreDefaults() async {
    for (final setting in _allSettings) {
      setting._value = setting.def;
    }
    await save();
    await initialize();
  }

  // The list of all keybinding settings
  late final List<KeybindingSetting> _allSettings = [
    _toggleFullscreen,
    _toggleImmersiveMode,
    _setTab1,
    _setTab2,
    _setTab3,
    _setTab4,
    _setTab5,
    _setTab6,
    _setTab7,
    _setTab8,
    _setTab9,
    _setLayout1,
    _setLayout2,
    _setLayout3,
    _setLayout4,
    _setLayout5,
    _setLayout6,
    _setLayout7,
    _setLayout8,
    _setLayout9,
    _toggleLayoutCycling,
    _toggleLayoutSidebar,
    _showNewLayoutDialog,
    _switchToNextLayout,
    _switchToPreviousLayout,
    _toggleLayoutLock,
    _setSettingsTab1,
    _setSettingsTab2,
    _setSettingsTab3,
    _setSettingsTab4,
    _setSettingsTab5,
    _setSettingsTab6,
  ];
}

class KeybindingSetting {
  final String name;
  final String system;
  final String key;
  final SingleActivator def;

  late SingleActivator _value;

  SingleActivator get value => _value;

  set value(SingleActivator newValue) {
    _value = newValue;
    KeyboardBindings.instance.save();
  }

  KeybindingSetting({
    required this.name,
    required this.system,
    required this.key,
    required this.def,
  });

  String saveAs(SingleActivator activator) {
    return [
      if (activator.alt) 'alt',
      if (activator.control) 'control',
      if (activator.shift) 'shift',
      activator.trigger.keyId,
    ].join(',');
  }

  SingleActivator loadFrom(String value) {
    final keys = value.split(',');
    return SingleActivator(
      LogicalKeyboardKey.findKeyByKeyId(int.parse(keys.last))!,
      control: keys.contains('control'),
      shift: keys.contains('shift'),
      alt: keys.contains('alt'),
    );
  }

  Future<SingleActivator> get defaultValue async {
    try {
      final serializedData = await secureStorage.read(key: key);
      if (serializedData != null) {
        return loadFrom(serializedData);
      }
    } catch (error, stack) {
      handleError(error, stack, 'Failed to get keybinding for $key');
    }
    return def;
  }

  Future<void> loadData() async {
    try {
      var serializedData = await secureStorage.read(key: key);
      serializedData ??= saveAs(def);
      _value = loadFrom(serializedData);
    } catch (error, stackTrace) {
      handleError(
        error,
        stackTrace,
        'Error loading data for $key. Fallback to default value',
      );
      _value = def;
    }
  }
}
