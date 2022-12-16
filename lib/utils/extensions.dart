import 'package:bluecherry_client/providers/settings_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

extension DurationExtension on Duration {
  /// Return [Duration] as typical formatted string.
  String get label {
    if (this > const Duration(days: 1)) {
      final days = inDays.toString().padLeft(3, '0');
      final hours = (inHours - (inDays * 24)).toString().padLeft(2, '0');
      final minutes = (inMinutes - (inHours * 60)).toString().padLeft(2, '0');
      final seconds = (inSeconds - (inMinutes * 60)).toString().padLeft(2, '0');
      return '$days:$hours:$minutes:$seconds';
    } else if (this > const Duration(hours: 1)) {
      final hours = inHours.toString().padLeft(2, '0');
      final minutes = (inMinutes - (inHours * 60)).toString().padLeft(2, '0');
      final seconds = (inSeconds - (inMinutes * 60)).toString().padLeft(2, '0');
      return '$hours:$minutes:$seconds';
    } else {
      final minutes = inMinutes.toString().padLeft(2, '0');
      final seconds = (inSeconds - (inMinutes * 60)).toString().padLeft(2, '0');
      return '$minutes:$seconds';
    }
  }

  String get humanReadable {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final String hours = twoDigits(inHours);
    final String minutes = twoDigits(inMinutes.remainder(60));
    final String seconds = twoDigits(inSeconds.remainder(60));

    List<String> finalStrings = [];

    // TODO: translate
    if (hours.isNotEmpty) {
      finalStrings.add('$hours hours');
    }

    if (minutes.isNotEmpty) {
      finalStrings.add('$minutes minutes');
    }

    if (seconds.isNotEmpty) {
      finalStrings.add('$seconds seconds');
    }

    return finalStrings.join(', ');
  }

  String get humanReadableCompact {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final String hours = twoDigits(inHours);
    final String minutes = twoDigits(inMinutes.remainder(60));
    final String seconds = twoDigits(inSeconds.remainder(60));

    List<String> finalStrings = [];

    // TODO: translate
    if (hours.isNotEmpty) {
      finalStrings.add('${hours}h');
    }

    if (minutes.isNotEmpty) {
      finalStrings.add('${minutes}m');
    }

    if (seconds.isNotEmpty) {
      finalStrings.add('${seconds}s');
    }

    return finalStrings.join('');
  }
}

extension NotificationExtensions on NotificationClickAction {
  String str(BuildContext context) => {
        NotificationClickAction.showFullscreenCamera:
            AppLocalizations.of(context).showFullscreenCamera,
        NotificationClickAction.showEventsScreen:
            AppLocalizations.of(context).showEventsScreen,
      }[this]!;
}

extension CameraViewFitExtension on CameraViewFit {
  String str(BuildContext context) => {
        CameraViewFit.contain: AppLocalizations.of(context).contain,
        CameraViewFit.cover: AppLocalizations.of(context).cover,
        CameraViewFit.fill: AppLocalizations.of(context).fill,
      }[this]!;
}

extension StringExtension on String {
  String uppercaseFirst() {
    if (isEmpty) return this;

    return substring(0, 1).toUpperCase() + substring(1);
  }
}
