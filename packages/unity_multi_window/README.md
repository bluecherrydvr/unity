<!--
This README describes the package. If you publish this package to pub.dev,
this README's contents appear on the landing page for your package.

For information about how to write a good package README, see the guide for
[writing package pages](https://dart.dev/guides/libraries/writing-package-pages).

For general information about developing packages, see the Dart guide for
[creating packages](https://dart.dev/guides/libraries/create-library-packages)
and the Flutter guide for
[developing packages and plugins](https://flutter.dev/developing-packages).
-->

A package that makes it possible to create multiple flutter windows.

## Features

- [x] Create multiple flutter windows
- [x] Close sub windows programatically
- [ ] Window interopability
- [ ] Hot reload / Hot Restart

## Getting started

## Usage

To run a new window, run `MultiWindow.run`:

```dart
final result = await MultiWindow.run([
  'window id',
]);
```

In your `main.dart`'s `main` function, do as the following:

```dart
void main(List<String> arguments) async {
  // handles the secondary window
  if (arguments.isNotEmpty) {

    final id = arguments[0];

    if (id == 'window id') {
      runApp(const SecondaryWindow());
      return;
    }
  }

  // the default app
  runApp(const MyApp());
}
```

## Additional information

This is just an experimental project.
