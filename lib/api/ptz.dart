import 'package:flutter/widgets.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

enum PTZCommand {
  move,
  stop;

  String locale(BuildContext context) {
    final localizations = AppLocalizations.of(context);
    switch (this) {
      case PTZCommand.stop:
        return localizations.stop;
      case PTZCommand.move:
      default:
        return localizations.move;
    }
  }
}

enum Movement {
  noMovement,
  moveNorth,
  moveSouth,
  moveWest,
  moveEast,
  moveWide,
  moveTele;

  String locale(BuildContext context) {
    final localizations = AppLocalizations.of(context);
    switch (this) {
      case Movement.moveNorth:
        return localizations.moveNorth;
      case Movement.moveSouth:
        return localizations.moveSouth;
      case Movement.moveWest:
        return localizations.moveWest;
      case Movement.moveEast:
        return localizations.moveEast;
      case Movement.moveWide:
        return localizations.moveWide;
      case Movement.moveTele:
        return localizations.moveTele;
      case Movement.noMovement:
      default:
        return localizations.noMovement;
    }
  }
}

enum PresetCommand {
  query,
  save,
  rename,
  go,
  clear;
}
