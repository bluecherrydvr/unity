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

import 'dart:convert';

import 'package:bluecherry_client/api/api.dart';
import 'package:bluecherry_client/models/server.dart';
import 'package:bluecherry_client/providers/server_provider.dart';
import 'package:bluecherry_client/providers/settings_provider.dart';
import 'package:bluecherry_client/screens/layouts/desktop/external_stream.dart';
import 'package:bluecherry_client/utils/config.dart';
import 'package:bluecherry_client/utils/extensions.dart';
import 'package:flutter/foundation.dart';

class ExternalDeviceData {
  final String? rackName;
  final Uri? serverIp;

  const ExternalDeviceData({
    required this.rackName,
    required this.serverIp,
  });

  @override
  String toString() =>
      'ExternalDeviceData(rackName: $rackName, serverIp: $serverIp)';

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is ExternalDeviceData &&
        other.rackName == rackName &&
        other.serverIp == serverIp;
  }

  @override
  int get hashCode => rackName.hashCode ^ serverIp.hashCode;

  Map<String, dynamic> toMap() {
    return {
      'rackName': rackName,
      'serverIp': serverIp,
    };
  }

  factory ExternalDeviceData.fromMap(Map<String, dynamic> map) {
    return ExternalDeviceData(
      rackName: map['rackName'] ?? '',
      serverIp: map['serverIp'] ?? '',
    );
  }
}

/// A [Device] present on a server.
class Device {
  /// Name of the device.
  final String name;

  /// [Uri] to the RTSP stream associated with the device.
  final int id;

  /// `true` [status] indicates that device device is working correctly or is `Online`.
  final bool status;

  /// Horizontal resolution of the device device.
  final int? resolutionX;

  /// Vertical resolution of the device device.
  final int? resolutionY;

  /// Whether this device has a PTZ protocol
  final bool hasPTZ;

  /// Reference to the [Server], to which this camera [Device] belongs.
  ///
  /// May be [Server.dump] if this does not belong to any server.
  Server server;

  /// An alternative url.
  ///
  /// If provided, this url will be used instead of the default [streamURL].
  final String? url;

  /// The type of zoom matrix of this device.
  ///
  /// If not provided, used from the settings.
  final MatrixType? matrixType;

  /// A list of text overlays that will be rendered over the video.
  final List<VideoOverlay> overlays;

  /// The preferred streaming type.
  ///
  /// If not provided, defaults to [Server.preferredStreamingType]
  final StreamingType? preferredStreamingType;

  /// The external device data.
  final ExternalDeviceData? externalData;

  /// Creates a device.
  Device({
    required this.name,
    required this.id,
    this.status = true,
    this.resolutionX,
    this.resolutionY,
    required this.server,
    this.hasPTZ = false,
    this.url,
    this.matrixType,
    this.overlays = const [],
    this.preferredStreamingType,
    this.externalData,
  });

  /// Creates a device with fake values.
  Device.dump({
    this.name = 'device',
    this.id = -1,
    this.status = true,
    this.resolutionX = 640,
    this.resolutionY = 480,
    this.hasPTZ = false,
    this.url,
    this.matrixType = MatrixType.t16,
    this.overlays = const [],
    this.preferredStreamingType,
    this.externalData,
  }) : server = Server.dump();

  String get uri => 'live/$id';

  String get uuid {
    return '${server.ip}:${server.port}/$id';
  }

  static Device? fromUUID(String uuid) {
    if (uuid.isEmpty) return null;

    final serverIp = uuid.split(':')[0];
    final split = uuid.split(':')[1].split('/');
    if (split.length < 2) return null;

    final serverPort = int.tryParse(split[0]) ?? -1;
    final deviceId = int.tryParse(split[1]) ?? -1;

    final server = ServersProvider.instance.servers.firstWhere(
      (s) => s.ip == serverIp && s.port == serverPort,
      orElse: Server.dump,
    );

    return server.devices.firstWhereOrNull((d) => d.id == deviceId);
  }

  factory Device.fromServerJson(Map map, Server server) {
    return Device(
      name: map['device_name'],
      id: int.tryParse(map['id']) ?? 0,
      status: map['status'] == 'OK',
      resolutionX: int.tryParse(map['resolutionX']),
      resolutionY: int.tryParse(map['resolutionY']),
      server: server,
      hasPTZ: map['ptz_control_protocol'] != null,
    );
  }

  /// Returns the stream URL for this device.
  ///
  /// If the app is running on the web, then HLS is used, otherwise RTSP is used.
  String get streamURL {
    if (preferredStreamingType != null) {
      return switch (preferredStreamingType!) {
        StreamingType.rtsp => rtspURL,
        StreamingType.mjpeg => mjpegURL,
        StreamingType.hls => hlsURL,
      };
    } else if (kIsWeb) {
      return hlsURL;
    } else {
      return rtspURL;
    }
  }

  String get rtspURL {
    if (url != null) return url!;

    return Uri(
      scheme: 'rtsp',
      userInfo: '${Uri.encodeComponent(server.login)}'
          ':'
          '${Uri.encodeComponent(server.password)}',
      host: server.ip,
      port: server.rtspPort,
      path: uri,
    ).toString();
  }

  String get mjpegURL {
    if (url != null) return url!;

    return Uri(
      scheme: 'https',
      userInfo: '${Uri.encodeComponent(server.login)}'
          ':'
          '${Uri.encodeComponent(server.password)}',
      host: server.ip,
      port: server.port,
      pathSegments: ['media', 'mjpeg'],
      queryParameters: {
        'multipart': 'true',
        'id': '$id',
      },
    ).toString();
  }

  String get hlsURL {
    if (url != null) return url!;

    return Uri(
      scheme: 'https',
      userInfo: '${Uri.encodeComponent(server.login)}'
          ':'
          '${Uri.encodeComponent(server.password)}',
      host: server.ip,
      port: server.port,
      pathSegments: ['hls', '$id', 'index.m3u8'],
    ).toString();
  }

  Future<String> getHLSUrl([Device? device]) async {
    if (url != null) return url!;

    device ??= this;
    var data = {
      'id': device.id.toString(),
      'hostname': device.server.ip,
      'port': device.server.port.toString(),
    };

    final uri = Uri(
      scheme: 'https',
      userInfo: '${Uri.encodeComponent(device.server.login)}'
          ':'
          '${Uri.encodeComponent(device.server.password)}',
      host: device.server.ip,
      port: device.server.port,
      path: 'media/hls',
      queryParameters: data,
    );

    try {
      var response = await API.client.get(uri);

      if (response.statusCode == 200) {
        var ret = json.decode(response.body) as Map;

        if (ret['status'] == 6) {
          var hlsLink = ret['msg'][0];
          return Uri.encodeFull(hlsLink);
        }
      } else {
        debugPrint('Request failed with status: ${response.statusCode}');
      }
    } catch (error, stacktrace) {
      debugPrint('Failed to get HLS url($uri): $error, $stacktrace');
    }

    return hlsURL;
  }

  /// Returns the full name of this device, including the server name.
  ///
  /// Example: `device (server)`
  String get fullName {
    return '$name (${server.name})';
  }

  @override
  String toString() =>
      'Device($name, $uri, online: $status, ${resolutionX}x$resolutionY, ptz: $hasPTZ)';

  @override
  bool operator ==(covariant Device other) {
    if (identical(this, other)) return true;
    return uuid == other.uuid;

    // return other is Device &&
    //     other.name == name &&
    //     other.id == id &&
    //     other.status == status &&
    //     other.resolutionX == resolutionX &&
    //     other.resolutionY == resolutionY &&
    //     other.hasPTZ == hasPTZ &&
    //     other.server == server &&
    //     other.url == url &&
    //     other.matrixType == matrixType &&
    //     listEquals(other.overlays, overlays) &&
    //     other.preferredStreamingType == preferredStreamingType &&
    //     other.externalData == externalData;
  }

  @override
  int get hashCode {
    return name.hashCode ^
        id.hashCode ^
        status.hashCode ^
        resolutionX.hashCode ^
        resolutionY.hashCode ^
        hasPTZ.hashCode ^
        server.hashCode ^
        url.hashCode ^
        matrixType.hashCode ^
        overlays.hashCode ^
        preferredStreamingType.hashCode ^
        externalData.hashCode;
  }

  Device copyWith({
    String? name,
    int? id,
    bool? status,
    int? resolutionX,
    int? resolutionY,
    Server? server,
    bool? hasPTZ,
    String? url,
    MatrixType? matrixType,
    List<VideoOverlay>? overlays,
    StreamingType? preferredStreamingType,
    ExternalDeviceData? externalData,
  }) =>
      Device(
        name: name ?? this.name,
        id: id ?? this.id,
        status: status ?? this.status,
        resolutionX: resolutionX ?? this.resolutionX,
        resolutionY: resolutionY ?? this.resolutionY,
        server: server ?? this.server,
        hasPTZ: hasPTZ ?? this.hasPTZ,
        url: url ?? this.url,
        matrixType: matrixType ?? this.matrixType,
        overlays: overlays ?? this.overlays,
        preferredStreamingType:
            preferredStreamingType ?? this.preferredStreamingType,
        externalData: externalData ?? this.externalData,
      );

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'id': id,
      'status': status,
      'resolutionX': resolutionX,
      'resolutionY': resolutionY,
      'server': server.toJson(devices: false),
      'hasPTZ': hasPTZ,
      'url': url,
      if (matrixType != null) 'matrixType': matrixType!.index,
      'overlays': overlays.map((e) => e.toMap()).toList(),
      'preferredStreamingType': preferredStreamingType?.name,
      'externalData': externalData?.toMap(),
    };
  }

  factory Device.fromJson(Map<String, dynamic> json) {
    return Device(
      name: json['name'],
      id: int.tryParse(json['id']?.toString() ??
              json['uri']?.toString().replaceAll('live/', '') ??
              '') ??
          0,
      status: json['status'] ?? false,
      resolutionX: json['resolutionX'],
      resolutionY: json['resolutionY'],
      server: Server.fromJson(json['server'] as Map<String, dynamic>),
      hasPTZ: json['hasPTZ'] ?? false,
      url: json['url'],
      matrixType: MatrixType.values[json['matrixType'] ?? 0],
      overlays: json['overlays'] != null
          ? List<VideoOverlay>.from(
              (json['overlays'] as List).cast<Map>().map(VideoOverlay.fromMap))
          : [],
      preferredStreamingType: StreamingType.values.firstWhereOrNull(
        (type) => type.name == json['preferredStreamingType'],
      ),
      externalData: json['externalData'] != null
          ? ExternalDeviceData.fromMap(json['externalData'])
          : null,
    );
  }
}
