import 'dart:io';

import 'package:flutter/material.dart';
import 'package:unity_multi_window/unity_multi_window.dart';

void main(List<String> args) {
  if (args.isNotEmpty) {
    debugPrint('$args');

    runApp(const SecondaryWindow());

    return;
  }

  runApp(const HomeWindow());
}

class HomeWindow extends StatelessWidget {
  const HomeWindow({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      home: Material(
        child: Center(
          child: TextButton(
            child: const Text('CREATE WINDOW'),
            onPressed: () {
              MultiWindow.run([
                'window id',
              ]);
            },
          ),
        ),
      ),
    );
  }
}

class SecondaryWindow extends StatelessWidget {
  const SecondaryWindow({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      home: Material(
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('THIS IS A SECONDARY WINDOWr'),
              TextButton(
                onPressed: () {
                  exit(0);
                },
                child: const Text('CLOSE'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
