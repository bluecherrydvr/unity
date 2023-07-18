import 'package:flutter/material.dart';

class TimelineDeviceView extends StatelessWidget {
  const TimelineDeviceView({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Column(children: [
        AspectRatio(
          aspectRatio: 16 / 9,
          child: Container(
            color: Colors.black,
          ),
        ),
      ]),
    );
  }
}
