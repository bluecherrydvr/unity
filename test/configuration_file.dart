import 'package:bluecherry_client/utils/config.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('VideoOverlay serialization', () {
    const overlay = VideoOverlay(
      text: 'My overlay',
      textStyle: TextStyle(
        color: Color(0xFF000000),
        fontSize: 12.0,
      ),
      position: Offset(10.0, 10.0),
    );

    final map = overlay.toMap();
    expect(
      map,
      {
        'text': 'My overlay',
        'textStyle': {
          'color': 'ff000000',
          'fontSize': 12.0,
        },
        'position_x': 10.0,
        'position_y': 10.0,
        'visible': true,
      },
    );

    final overlay2 = VideoOverlay.fromMap(map);
    expect(overlay2.text, 'My overlay');
    expect(overlay2.textStyle?.color, const Color(0xFF000000));
    expect(overlay2.textStyle?.fontSize, 12.0);
    expect(overlay2.position, const Offset(10.0, 10.0));
    expect(overlay2.visible, true);
  });
}
