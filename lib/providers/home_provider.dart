import 'package:flutter/foundation.dart';

import 'server_provider.dart';

class HomeProvider extends ChangeNotifier {
  int tab = ServersProvider.instance.serverAdded ? 0 : 3;

  void setTab(int tab) {
    this.tab = tab;
    notifyListeners();
  }
}
