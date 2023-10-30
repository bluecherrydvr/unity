import 'package:bluecherry_client/widgets/misc.dart';
import 'package:flutter/material.dart';
import 'package:unity_video_player/unity_video_player.dart';

class MulticastViewport extends StatelessWidget {
  final String? overlayText;
  final TextStyle? overlayStyle;
  final Offset? overlayPosition;

  const MulticastViewport({
    super.key,
    this.overlayText,
    this.overlayStyle = const TextStyle(
      color: Colors.green,
      fontSize: 32,
    ),
    this.overlayPosition = const Offset(250, 250),
  });

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
    return Stack(children: [
      if (overlayText != null)
        Positioned(
          left: overlayPosition?.dx,
          top: overlayPosition?.dy,
          child: IgnorePointer(
            child: Text(
              overlayText!,
              style: TextStyle(
                shadows: outlinedText(),
              ).merge(overlayStyle),
            ),
          ),
        ),
      Positioned.fill(
        child: GridView.count(
          crossAxisCount: size,
          childAspectRatio: 16 / 9,
          physics: const NeverScrollableScrollPhysics(),
          children: List.generate(size * size, (index) {
            final row = index ~/ size;
            final col = index % size;

            return GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () {
                view.player.crop(row, col, size);
              },
              child: const SizedBox.expand(
                  // child: Placeholder(),
                  ),
            );
          }),
        ),
      ),
    ]);
  }
}
