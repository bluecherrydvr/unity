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

import 'package:bluecherry_client/models/device.dart';
import 'package:bluecherry_client/providers/settings_provider.dart';
import 'package:bluecherry_client/utils/constants.dart';
import 'package:bluecherry_client/utils/extensions.dart';
import 'package:flutter/foundation.dart';

/// A [Server] added by a user.
class Server {
  /// The name of the server.
  final String name;

  /// The IP address of the server.
  final String ip;

  /// The port of the server.
  final int port;

  /// The RTSP port of the server.
  ///
  /// This is used to connect to the RTSP streams.
  final int rtspPort;

  /// The username to connect to the server.
  final String login;

  /// The password to connect to the server.
  final String password;

  /// Whether to connect to this server automatically at startup.
  ///
  /// If false, the server will have to be connected to manually.
  final bool connectAutomaticallyAtStartup;

  /// The list of devices that are available on this server.
  List<Device> devices = [];
  final String? serverUUID;
  final String? cookie;

  /// Whether this server is online or not.
  bool online = true;

  /// Whether the server has their certificates. This enables us to make use of
  /// https:// calls.
  ///
  /// See also:
  ///
  ///   * [Device.hlsURL]
  bool passedCertificates = true;

  /// The preferred streaming type.
  ///
  /// If not provided, defaults to the type declared in the app settings.
  final StreamingType? preferredStreamingType;

  /// Creates a new [Server].
  Server({
    required this.name,
    required this.ip,
    required this.port,
    required this.login,
    required this.password,
    required this.devices,
    this.rtspPort = kDefaultRTSPPort,
    this.serverUUID,
    this.cookie,
    this.connectAutomaticallyAtStartup = true,
    this.online = true,
    this.passedCertificates = true,
    this.preferredStreamingType,
  });

  /// Creates a server with fake values.
  ///
  /// See also:
  ///
  ///   * [Device.dump]
  Server.dump({
    this.name = 'server',
    this.ip = 'server:ip',
    this.port = 7001,
    this.login = kDefaultUsername,
    this.password = kDefaultPassword,
    this.devices = const [],
    this.rtspPort = kDefaultRTSPPort,
    this.serverUUID,
    this.cookie,
    this.connectAutomaticallyAtStartup = true,
    this.online = true,
    this.passedCertificates = true,
    this.preferredStreamingType,
  });

  String get id {
    return '$name;$ip;$port';
  }

  @override
  String toString() =>
      'Server($name, $ip, $port, $rtspPort, $login, $password, $devices, $serverUUID, $cookie, $online, $passedCertificates)';

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is Server &&
        other.name == name &&
        other.ip == ip &&
        other.port == port &&
        other.rtspPort == rtspPort &&
        other.login == login &&
        other.password == password &&
        other.connectAutomaticallyAtStartup == connectAutomaticallyAtStartup &&
        listEquals(other.devices, devices) &&
        other.serverUUID == serverUUID &&
        other.cookie == cookie &&
        other.online == online &&
        other.passedCertificates == passedCertificates &&
        other.preferredStreamingType == preferredStreamingType;
  }

  @override
  int get hashCode {
    return name.hashCode ^
        ip.hashCode ^
        port.hashCode ^
        rtspPort.hashCode ^
        login.hashCode ^
        password.hashCode ^
        connectAutomaticallyAtStartup.hashCode ^
        devices.hashCode ^
        serverUUID.hashCode ^
        cookie.hashCode ^
        online.hashCode ^
        passedCertificates.hashCode ^
        preferredStreamingType.hashCode;
  }

  Server copyWith({
    String? name,
    String? ip,
    int? port,
    int? rtspPort,
    String? login,
    String? password,
    List<Device>? devices,
    String? serverUUID,
    String? cookie,
    bool? online,
    StreamingType? preferredStreamingType,
  }) {
    return Server(
      name: name ?? this.name,
      ip: ip ?? this.ip,
      port: port ?? this.port,
      login: login ?? this.login,
      password: password ?? this.password,
      devices: devices ?? this.devices,
      rtspPort: rtspPort ?? this.rtspPort,
      serverUUID: serverUUID ?? this.serverUUID,
      cookie: cookie ?? this.cookie,
      preferredStreamingType:
          preferredStreamingType ?? this.preferredStreamingType,
    );
  }

  Map<String, dynamic> toJson({
    bool devices = true,
  }) =>
      {
        'name': name,
        'ip': ip,
        'port': port,
        'rtspPort': rtspPort,
        'login': login,
        'password': password,
        'devices': !devices ? [] : this.devices.map((e) => e.toJson()).toList(),
        'serverUUID': serverUUID,
        'cookie': cookie,
        'preferredStreamingType': preferredStreamingType?.name,
      };

  factory Server.fromJson(Map<String, dynamic> json) => Server(
        name: json['name'],
        ip: json['ip'],
        port: json['port'],
        login: json['login'],
        password: json['password'],
        devices: (json['devices'] as List)
            .cast<Map<String, dynamic>>()
            .map(Device.fromJson)
            .toList()
            .cast<Device>(),
        rtspPort: json['rtspPort'],
        serverUUID: json['serverUUID'],
        cookie: json['cookie'],
        preferredStreamingType: StreamingType.values.firstWhereOrNull(
          (type) => type.name == json['preferredStreamingType'],
        ),
      );
}
