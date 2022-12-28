import 'dart:io';

import 'package:flutter/material.dart';
import 'package:unity_multi_window/unity_multi_window.dart';

void main(List<String> args) {
  if (args.isNotEmpty) {
    print(args);

    runApp(const SecondaryWindow());

    return;
  }

  runApp(const HomeWindow());
}

class HomeWindow extends StatelessWidget {
  const HomeWindow({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: Material(
        child: Center(
          child: TextButton(
            child: const Text('CREATE WINDOW'),
            onPressed: () {
              final window = MultiWindow.run([
                'RUNNING A NEW WINDOW HEHEHE',
              ]);
            },
          ),
        ),
      ),
    );
  }
}

class SecondaryWindow extends StatelessWidget {
  const SecondaryWindow({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: Material(
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('THIS IS A SECONDARY WINDOW'),
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
