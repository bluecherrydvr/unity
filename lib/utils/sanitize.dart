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

/// Helpers to keep credentials out of user-visible strings and log files.
///
/// The Bluecherry server API historically embeds cleartext credentials in
/// event media URLs (`https://<login>:<password>@<host>:<port>/...`). Those
/// URLs must never be shown verbatim in error dialogs, copied to the
/// clipboard, or written to log files.
library;

/// Matches the `user:password@` authority portion of an absolute URL, e.g.
/// `https://manager:s3cret@host:7001/...`.
///
/// Group 1 is the scheme prefix (`https://`) and group 2 is the user. The
/// password is matched greedily up to the last `@` before the host, so
/// passwords containing `@` are redacted in full.
final _urlCredentialsRegExp = RegExp(
  r'([a-zA-Z][a-zA-Z0-9+.-]*://)([^/\s@?#:]+):([^/\s?#]*)@',
);

/// Matches a password-less `user@` authority portion of an absolute URL.
final _urlUserRegExp = RegExp(r'([a-zA-Z][a-zA-Z0-9+.-]*://)([^/\s@?#:]+)@');

/// Matches session bearer tokens in query parameters, e.g. the `authtoken`
/// (a PHP session id) appended to HLS playlist links.
///
/// Group 1 is the parameter name with its separator. Matched
/// case-insensitively; names that merely start with a keyword (such as
/// `tokenOnly`) do not match because `=` must follow the name.
final _sensitiveQueryParamRegExp = RegExp(
  r'([?&](?:authtoken|access_token|sessionid|session_id|token)=)([^&\s]*)',
  caseSensitive: false,
);

/// Redacts credentials embedded in [text].
///
/// `https://manager:s3cret@host/...` becomes `https://manager:***@host/...`
/// and a bare `https://manager@host/...` becomes `https://***@host/...`.
/// Text without embedded URL credentials is returned unchanged.
String sanitizeSensitiveData(String text) {
  var sanitized = text.replaceAllMapped(
    _urlCredentialsRegExp,
    (match) => '${match.group(1)}${match.group(2)}:***@',
  );
  sanitized = sanitized.replaceAllMapped(
    _urlUserRegExp,
    (match) => '${match.group(1)}***@',
  );
  sanitized = sanitized.replaceAllMapped(
    _sensitiveQueryParamRegExp,
    (match) => '${match.group(1)}***',
  );
  return sanitized;
}

/// Returns [uri] without any embedded credentials (`userInfo`).
///
/// The resulting URI is safe to display, log, or hand to a player that
/// authenticates via HTTP headers instead.
Uri stripUrlCredentials(Uri uri) {
  if (!uri.hasAuthority || uri.userInfo.isEmpty) return uri;
  // Rebuild without `userInfo` instead of `uri.replace(userInfo: '')`,
  // which would serialize as `scheme://@host`.
  return Uri(
    scheme: uri.scheme,
    host: uri.host,
    port: uri.hasPort ? uri.port : null,
    path: uri.path,
    query: uri.hasQuery ? uri.query : null,
  );
}
