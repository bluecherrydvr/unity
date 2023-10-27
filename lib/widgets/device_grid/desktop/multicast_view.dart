import 'package:bluecherry_client/providers/desktop_view_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:unity_video_player/unity_video_player.dart';

class MulticastViewport extends StatelessWidget {
  const MulticastViewport({super.key});

  @override
  Widget build(BuildContext context) {
    // final view = context.watch<DesktopViewProvider>();
    final view = UnityVideoView.of(context);
    const size = 4;
    return LayoutBuilder(builder: (context, constraints) {
      return GridView.count(
        crossAxisCount: size,
        childAspectRatio: 16 / 9,
        children: List.generate(size * size, (index) {
          final row = index ~/ size;
          final col = index % size;

          return GestureDetector(
            behavior: HitTestBehavior.opaque,
            onDoubleTap: () {
              view.player.crop(-1, -1, -1);
            },
            onTap: () {
              view.player.crop(row, col, size);
            },
            child: const Placeholder(),
          );
        }),
      );
    });
  }
}
