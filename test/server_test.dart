import 'package:bluecherry_client/models/device.dart';
import 'package:bluecherry_client/models/server.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Server.toString', () {
    test('never exposes password or cookie', () {
      final server = Server(
        name: 'dvr',
        ip: '192.168.1.10',
        port: 7001,
        login: 'manager',
        password: 's3cret-password',
        devices: <Device>[],
        cookie: 'session-cookie-value',
      );

      final text = server.toString();
      expect(text, isNot(contains('s3cret-password')));
      expect(text, isNot(contains('session-cookie-value')));
      expect(text, contains('manager'));
      expect(text, contains('192.168.1.10'));
    });
  });
}
