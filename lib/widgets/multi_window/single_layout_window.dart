import 'package:bluecherry_client/models/layout.dart';
import 'package:bluecherry_client/widgets/desktop_buttons.dart';
import 'package:bluecherry_client/widgets/device_grid/device_grid.dart';
import 'package:flutter/material.dart';

class AlternativeLayoutView extends StatelessWidget {
  const AlternativeLayoutView({super.key, required this.layout});

  final Layout layout;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.black,
      child: SafeArea(
        child: Column(children: [
          WindowButtons(
            title: layout.name,
            showNavigator: false,
          ),
          Expanded(
            child: LayoutView(
              layout: layout,
            ),
          ),
        ]),
      ),
    );
  }
}
