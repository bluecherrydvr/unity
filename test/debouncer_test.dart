import 'package:bluecherry_client/utils/debouncer.dart';
import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Debouncer', () {
    test('runs the action after the duration', () {
      var calls = 0;
      final debouncer = Debouncer(const Duration(milliseconds: 300));

      FakeAsync().run((async) {
        debouncer.run(() => calls++);
        expect(calls, 0);

        async.elapse(const Duration(milliseconds: 300));
        expect(calls, 1);
      });
    });

    test('coalesces rapid calls into one', () {
      var calls = 0;
      final debouncer = Debouncer(const Duration(milliseconds: 300));

      FakeAsync().run((async) {
        for (var i = 0; i < 10; i++) {
          debouncer.run(() => calls++);
          async.elapse(const Duration(milliseconds: 100));
        }

        async.elapse(const Duration(milliseconds: 300));
        expect(calls, 1);
      });
    });

    test('runs the latest action', () {
      var value = 0;
      final debouncer = Debouncer(const Duration(milliseconds: 300));

      FakeAsync().run((async) {
        debouncer.run(() => value = 1);
        debouncer.run(() => value = 2);

        async.elapse(const Duration(milliseconds: 300));
        expect(value, 2);
      });
    });

    test('cancel prevents a pending action', () {
      var calls = 0;
      final debouncer = Debouncer(const Duration(milliseconds: 300));

      FakeAsync().run((async) {
        debouncer.run(() => calls++);
        debouncer.cancel();

        async.elapse(const Duration(milliseconds: 600));
        expect(calls, 0);
      });
    });

    test('can be reused after firing', () {
      var calls = 0;
      final debouncer = Debouncer(const Duration(milliseconds: 300));

      FakeAsync().run((async) {
        debouncer.run(() => calls++);
        async.elapse(const Duration(milliseconds: 300));
        expect(calls, 1);

        debouncer.run(() => calls++);
        async.elapse(const Duration(milliseconds: 300));
        expect(calls, 2);
      });
    });
  });
}
