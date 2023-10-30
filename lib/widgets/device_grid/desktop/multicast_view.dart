import 'package:flutter/material.dart';
import 'package:unity_video_player/unity_video_player.dart';

class MulticastViewport extends StatelessWidget {
  const MulticastViewport({super.key});

  @override
  Widget build(BuildContext context) {
    final view = UnityVideoView.of(context);

    if (view.player.isCropped) {
      return GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () {
          view.player.crop(-1, -1, -1);
        },
        child: const SizedBox.expand(),
      );
    }

    const size = 4;
    return GridView.count(
      crossAxisCount: size,
      childAspectRatio: 16 / 9,
      children: List.generate(size * size, (index) {
        final row = index ~/ size;
        final col = index % size;

        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () {
            view.player.crop(row, col, size);
          },
          child: const Placeholder(),
        );
      }),
    );
  }
}
