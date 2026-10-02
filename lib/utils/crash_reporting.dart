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

import 'dart:async';

import 'package:bluecherry_client/providers/settings_provider.dart';
import 'package:bluecherry_client/utils/sanitize.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:uuid/uuid.dart';

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
/// (e.g. a player failing on every retry, or an exception thrown from a
/// widget build) must not burn a month of quota in minutes. The first
/// reports still get through; the rest are dropped. The window is persisted,
/// so restarting the app does not mint a fresh budget.
const kMaxSentryEventsPerHour = 30;

/// Length of the event-budget window in milliseconds.
const _budgetWindowMillis = 60 * 60 * 1000;

/// Keys for the persisted event budget. See [kMaxSentryEventsPerHour].
@visibleForTesting
const sentryBudgetWindowStartKey = 'sentry.eventBudget.windowStartMillis';
@visibleForTesting
const sentryBudgetCountKey = 'sentry.eventBudget.count';

/// Key for the stable anonymous install ID. See [loadSentryInstallId].
@visibleForTesting
const sentryInstallIdKey = 'sentry.installId';

/// Private secure-storage handle for the event budget. Kept separate from
/// the app-wide `secureStorage` singleton to avoid an import cycle:
/// `storage.dart` funnels errors through this library.
final _budgetStorage = FlutterSecureStorage();

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
  if (now - _windowStartMillis > _budgetWindowMillis) {
    _windowStartMillis = now;
    _eventsInWindow = 0;
  }
  if (_eventsInWindow >= kMaxSentryEventsPerHour) return false;
  _eventsInWindow++;
  unawaited(_persistBudget());
  return true;
}

/// Persists the current budget window. Fire-and-forget from
/// [_withinEventBudget]: at most [kMaxSentryEventsPerHour] small writes per
/// hour, and a lost write only costs this restart's accounting. Never throws.
Future<void> _persistBudget() async {
  try {
    await _budgetStorage.write(
      key: sentryBudgetWindowStartKey,
      value: '$_windowStartMillis',
    );
    await _budgetStorage.write(
      key: sentryBudgetCountKey,
      value: '$_eventsInWindow',
    );
  } catch (_) {
    // Reporting must never break the app.
  }
}

Future<int?> _readBudgetInt(String key) async {
  final value = await _budgetStorage.read(key: key);
  return int.tryParse(value ?? '');
}

/// Restores the hourly event budget persisted by a previous run.
///
/// Called from [initCrashReporting] before the SDK can capture anything, so
/// a crash loop that restarts the app cannot mint a fresh budget per
/// restart. Expired, missing, or unreadable state restarts the budget.
/// Never throws.
Future<void> restoreSentryEventBudget() async {
  var windowStart = 0;
  var count = 0;
  try {
    final now = DateTime.now().millisecondsSinceEpoch;
    windowStart = await _readBudgetInt(sentryBudgetWindowStartKey) ?? 0;
    count = await _readBudgetInt(sentryBudgetCountKey) ?? 0;
    if (windowStart > now || now - windowStart > _budgetWindowMillis) {
      // Expired, or the clock moved backwards: start fresh.
      windowStart = 0;
      count = 0;
    } else {
      count = count.clamp(0, kMaxSentryEventsPerHour);
    }
  } catch (_) {
    windowStart = 0;
    count = 0;
  }
  _windowStartMillis = windowStart;
  _eventsInWindow = count;
}

/// Resets the in-memory hourly event budget. Test-only: production windows
/// roll over on their own. Persisted state is untouched, so calling this
/// followed by [restoreSentryEventBudget] simulates a restart.
@visibleForTesting
void resetSentryEventBudget() {
  _windowStartMillis = 0;
  _eventsInWindow = 0;
}

String? _fallbackInstallId;

/// Loads the stable anonymous install ID, creating and persisting it on
/// first run.
///
/// There is no central auth (each deployment runs its own), so this random
/// ID is what turns Sentry's user counts into affected-install counts. It
/// carries no identity: it cannot be traced to a person or a server. When
/// storage is unavailable, falls back to a session-stable random ID.
/// Never throws.
Future<String> loadSentryInstallId() async {
  try {
    var id = await _budgetStorage.read(key: sentryInstallIdKey);
    if (id == null || id.isEmpty) {
      id = const Uuid().v4();
      await _budgetStorage.write(key: sentryInstallIdKey, value: id);
    }
    return id;
  } catch (_) {
    return _fallbackInstallId ??= const Uuid().v4();
  }
}

/// Derives a stable fingerprint for a server identity string.
///
/// The raw identity (a server UUID, or `ip:port` when unknown) never leaves
/// the device: only this truncated hash is reported, letting crashes be
/// correlated per deployment without exposing addresses.
String sentryServerFingerprint(String rawId) => const Uuid()
    .v5(Namespace.url.value, rawId)
    .replaceAll('-', '')
    .substring(0, 16);

/// Records the current server inventory on the Sentry scope.
///
/// Called by the servers provider whenever the list loads or changes.
/// No-op unless Sentry is initialized. Never throws.
void updateSentryServerContext({
  required int serverCount,
  required Iterable<String> serverFingerprints,
}) {
  if (!_sentryInitialized) return;
  try {
    Sentry.configureScope(
      (scope) => applySentryServerContext(
        scope,
        serverCount: serverCount,
        serverFingerprints: serverFingerprints,
      ),
    );
  } catch (_) {
    // Reporting must never break the app.
  }
}

/// Applies the server inventory to a Sentry scope: the count as an indexed
/// tag (low cardinality), the fingerprints as unindexed context.
@visibleForTesting
void applySentryServerContext(
  Scope scope, {
  required int serverCount,
  required Iterable<String> serverFingerprints,
}) {
  scope.setTag('server_count', '$serverCount');
  scope.setContexts('servers', {
    'count': serverCount,
    'fingerprints': List.of(serverFingerprints),
  });
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
/// * Identity is a random per-install ID ([loadSentryInstallId]); no
///   usernames, emails, or addresses are ever sent.
/// * [beforeSendSentryEvent] caps volume client-side, persisted across
///   restarts by [restoreSentryEventBudget].
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

  // Restore the persisted budget before the SDK can capture anything.
  await restoreSentryEventBudget();

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
      options.beforeSend = beforeSendSentryEvent;
      options.debug = false;
    });
    _sentryInitialized = true;
  } catch (_) {
    _sentryInitialized = false;
  }
  if (!_sentryInitialized) return;

  // Stable anonymous install ID for affected-install counts. Best effort:
  // reporting must work even if identity fails.
  try {
    final installId = await loadSentryInstallId();
    Sentry.configureScope((scope) => scope.setUser(SentryUser(id: installId)));
  } catch (_) {}
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

/// Forwards an error to Sentry, if permitted and initialized.
///
/// Called from the central error funnel (`handleError`), so every zoned
/// Dart error is a candidate. Volume is capped in [beforeSendSentryEvent],
/// the single enforcement point. Never throws.
Future<void> reportErrorToSentry(
  dynamic error, [
  StackTrace? stackTrace,
]) async {
  if (!_sentryInitialized || !isCrashReportingPermitted) return;
  try {
    await Sentry.captureException(error, stackTrace: stackTrace);
  } catch (_) {
    // Reporting must never break the app.
  }
}

/// Gates an outgoing Sentry event on the hourly budget, then scrubs it.
///
/// Wired as [SentryOptions.beforeSend], so it covers both manually reported
/// errors ([reportErrorToSentry]) and SDK-captured unhandled errors, which
/// previously bypassed the budget entirely: a fatal crash loop could exceed
/// [kMaxSentryEventsPerHour] within seconds of a release. Returns null to
/// drop over-budget events.
SentryEvent? beforeSendSentryEvent(SentryEvent event, Hint hint) {
  if (!_withinEventBudget()) return null;
  return scrubSentryEvent(event, hint);
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
