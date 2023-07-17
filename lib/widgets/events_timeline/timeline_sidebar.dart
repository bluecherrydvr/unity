import 'package:bluecherry_client/widgets/device_grid/device_grid.dart';
import 'package:flutter/material.dart';

class TimelineSidebar extends StatelessWidget {
  const TimelineSidebar({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: kSidebarConstraints,
      height: double.infinity,
      child: const Card(
        margin: EdgeInsetsDirectional.symmetric(horizontal: 4.0),
        child: Column(
          children: [
            Center(child: Text('haha lesgo')),
          ],
        ),
      ),
    );
  }
}
