import 'package:bluecherry_client/providers/app_provider_interface.dart';
import 'package:bluecherry_client/utils/constants.dart';
import 'package:bluecherry_client/utils/storage.dart';
import 'package:flutter/foundation.dart';

class EventsProvider extends UnityProvider {
  EventsProvider._();

  static late final EventsProvider instance;
  static Future<EventsProvider> ensureInitialized() async {
    instance = EventsProvider._();
    await instance.initialize();
    debugPrint('EventsProvider initialized');
    return instance;
  }

  @override
  Future<void> initialize() async {
    await tryReadStorage(() => initializeStorage(events, kStorageEvents));
  }

  @override
  Future<void> save({bool notifyListeners = true}) async {
    try {
      await events.write({});
    } catch (error, stackTrace) {
      debugPrint('Failed to save desktop view:\n $error\n$stackTrace');
    }

    super.save(notifyListeners: notifyListeners);
  }

  @override
  Future<void> restore({bool notifyListeners = true}) async {
    final data = await tryReadStorage(() => desktopView.read());

    super.save(notifyListeners: notifyListeners);
  }
}
