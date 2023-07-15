import 'package:bluecherry_client/models/layout.dart';
import 'package:bluecherry_client/providers/desktop_view_provider.dart';
import 'package:bluecherry_client/widgets/device_grid/device_grid.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class AlternativeLayoutView extends StatelessWidget {
  const AlternativeLayoutView({super.key, required this.layout});

  final Layout layout;

  @override
  Widget build(BuildContext context) {
    final view = context.watch<DesktopViewProvider>();

    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: LayoutView(
        layout: layout,
        onReorder: view.reorder,
      ),
    );
  }
}
