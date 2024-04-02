import 'package:flutter/foundation.dart';

/// Convert a date string to a DateTime object, considering the timezone offset.
DateTime timezoneAwareDate(String originalDateString) {
  final originalDateTime = DateTime.parse(originalDateString);

  try {
    final offsetString = originalDateString.split('-').last;
    final parts = offsetString.split(':');

    // Convert hours and minutes strings to integers
    final hours = int.parse(parts[0]);
    final minutes = int.parse(parts[1]);

    // Create a Duration object based on the offset sign
    final offset = Duration(hours: -hours, minutes: -minutes);

    return originalDateTime.add(offset);
  } catch (e) {
    debugPrint('Failed to parse date string: $originalDateString');
    return originalDateTime;
  }
}
