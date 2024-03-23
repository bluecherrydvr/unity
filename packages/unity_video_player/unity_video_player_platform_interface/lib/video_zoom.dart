import 'dart:ui';

class VideoZoom {
  MatrixType matrixType = MatrixType.t1;
  bool softwareZoom = false;

  Rect zoomRect = Rect.zero;
  (int row, int col) zoomAxis = (-1, -1);
}

enum MatrixType {
  t16(4),
  t9(3),
  t4(2),
  t1(1);

  final int size;

  const MatrixType(this.size);

  @override
  String toString() {
    return switch (this) {
      MatrixType.t16 => '4x4',
      MatrixType.t9 => '3x3',
      MatrixType.t4 => '2x2',
      MatrixType.t1 => '1x1',
    };
  }

  MatrixType get next {
    return switch (this) {
      MatrixType.t16 => MatrixType.t9,
      MatrixType.t9 => MatrixType.t4,
      MatrixType.t4 => MatrixType.t16,
      // ideally, t1 is never reached
      MatrixType.t1 => MatrixType.t16,
    };
  }
}
