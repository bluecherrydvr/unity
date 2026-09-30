/*
 * This file is a part of Bluecherry Client (https://github.com/bluecherrydvr/unity).
 *
 * Copyright 2022 Bluecherry, LLC
 *
 * This program is free software; you can redistribute it and/or
 * modify it under the terms of the GNU General Public License as
 * published by the Free Software Foundation; either version 3 of
 * the License, or (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program. If not, see <http://www.gnu.org/licenses/>.
 */

import 'package:bluecherry_client/providers/settings_provider.dart';
import 'package:bluecherry_client/utils/sanitize.dart';
import 'package:flutter/foundation.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

/// DSN of the `flutter` project in the `bluecherry` Sentry organization.
///
/// A DSN is a public client identifier by design. It can be overridden at
/// build time with `--dart-define=SENTRY_DSN=...`.
const sentryDsn = String.fromEnvironment(
  'SENTRY_DSN',
  defaultValue:
      'https://ecd1bb466abf49a015f969d92f894311@o4512176097722368.ingest.us.sentry.io/4512176106504192',
);

/// Maximum number of error events sent per hour.
///
/// Client-side quota guard for the Sentry free plan: a crash or error loop
/// (e.g. a player failing on every retry) must not burn a month of quota in
/// minutes. The first reports still get through; the rest are dropped.
const kMaxSentryEventsPerHour = 30;

bool _sentryInitialized = false;

/// Whether the Sentry SDK is currently initialized and sending.
bool get isCrashReportingInitialized => _sentryInitialized;

/// Whether crash reporting is currently permitted.
///
/// Requires a release build, no `--dart-define=SENTRY_DSN=` opt-out (empty
/// string disables), and both privacy settings enabled
/// ([SettingsProvider.kAllowCrashReports] and
/// [SettingsProvider.kAllowDataCollection]).
bool get isCrashReportingPermitted {
  if (!kReleaseMode) return false;
  if (sentryDsn.isEmpty) return false;
  try {
    final settings = SettingsProvider.instance;
    return settings.kAllowCrashReports.value == EnabledPreference.on &&
        settings.kAllowDataCollection.value;
  } catch (_) {
    // Settings are not ready (e.g. very early startup): do not report.
    return false;
  }
}

int _windowStartMillis = 0;
int _eventsInWindow = 0;

/// Rolling client-side quota guard. See [kMaxSentryEventsPerHour].
bool _withinEventBudget() {
  final now = DateTime.now().millisecondsSinceEpoch;
  if (now - _windowStartMillis > const Duration(hours: 1).inMilliseconds) {
    _windowStartMillis = now;
    _eventsInWindow = 0;
  }
  if (_eventsInWindow >= kMaxSentryEventsPerHour) return false;
  _eventsInWindow++;
  return true;
}

/// Initializes Sentry for crash reports and session (release-health) metrics.
///
/// Must be called after [SettingsProvider.ensureInitialized]. Never throws:
/// crash reporting must not break startup.
///
/// Free-plan guardrails, all intentional:
/// * `tracesSampleRate` is 0 — no performance transactions are collected.
/// * No session-replay, screenshots, or view hierarchies are attached.
/// * `sendDefaultPii` stays false and [scrubSentryEvent] redacts embedded
///   stream credentials from every event.
/// * [_withinEventBudget] caps volume client-side.
Future<void> initCrashReporting() async {
  if (_sentryInitialized || !isCrashReportingPermitted) return;

  var release = 'bluecherry-client';
  try {
    final packageInfo = await PackageInfo.fromPlatform();
    release =
        'bluecherry-client@${packageInfo.version}+${packageInfo.buildNumber}';
  } catch (_) {
    // Fall through with the default release name.
  }

  try {
    await SentryFlutter.init((options) {
      options.dsn = sentryDsn;
      options.release = release;
      // No performance monitoring on the free plan.
      options.tracesSampleRate = 0.0;
      options.sampleRate = 1.0;
      options.sendDefaultPii = false;
      // Release-health (crash-free sessions) stays on: it is what turns
      // raw crashes into metrics, at no extra quota cost.
      options.enableAutoSessionTracking = true;
      options.attachScreenshot = false;
      options.maxBreadcrumbs = 50;
      options.beforeSend = scrubSentryEvent;
      options.debug = false;
    });
    _sentryInitialized = true;
  } catch (_) {
    _sentryInitialized = false;
  }
}

/// Applies the current privacy settings to a running app.
///
/// Call after the user toggles crash reporting or data collection: starts
/// Sentry on opt-in, shuts it down on opt-out.
Future<void> applyCrashReportingSettings() async {
  if (isCrashReportingPermitted && !_sentryInitialized) {
    await initCrashReporting();
  } else if (!isCrashReportingPermitted && _sentryInitialized) {
    try {
      await Sentry.close();
    } catch (_) {
      // Ignore shutdown errors.
    }
    _sentryInitialized = false;
  }
}

/// Forwards an error to Sentry, if permitted, initialized, and in budget.
///
/// Called from the central error funnel (`handleError`), so every zoned
/// Dart error is a candidate. Never throws.
Future<void> reportErrorToSentry(
  dynamic error, [
  StackTrace? stackTrace,
]) async {
  if (!_sentryInitialized || !isCrashReportingPermitted) return;
  if (!_withinEventBudget()) return;
  try {
    await Sentry.captureException(error, stackTrace: stackTrace);
  } catch (_) {
    // Reporting must never break the app.
  }
}

/// Redacts sensitive data from a Sentry event before upload.
///
/// Stream URLs embed cleartext credentials (`user:password@host`); error
/// text, exception values, breadcrumbs, and request URLs may all carry
/// them. Pure function, unit-tested.
SentryEvent? scrubSentryEvent(SentryEvent event, Hint hint) {
  String? scrub(String? value) =>
      value == null ? null : sanitizeSensitiveData(value);

  final message = event.message;
  if (message != null) {
    message.formatted = sanitizeSensitiveData(message.formatted);
  }
  for (final exception in event.exceptions ?? <SentryException>[]) {
    exception.type = sanitizeSensitiveData(exception.type ?? '');
    exception.value = scrub(exception.value);
  }
  for (final crumb in event.breadcrumbs ?? <Breadcrumb>[]) {
    crumb.message = sanitizeSensitiveData(crumb.message ?? '');
    // HTTP breadcrumb payloads carry full URLs, including credentials and
    // session tokens.
    final data = crumb.data;
    if (data != null) {
      crumb.data = {
        for (final entry in data.entries)
          entry.key:
              entry.value is String
                  ? sanitizeSensitiveData(entry.value as String)
                  : entry.value,
      };
    }
  }
  final request = event.request;
  if (request != null) {
    request.url = sanitizeSensitiveData(request.url ?? '');
  }
  return event;
}
