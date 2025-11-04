import 'dart:math' as math;
import 'dart:typed_data';

Iterable<Uint8List> chunk(Uint8List data, {int size = 64 * 1024}) sync* {
  for (int i = 0; i < data.length; i += size) {
    final end = math.min(i + size, data.length);
    yield Uint8List.sublistView(data, i, end);
  }
}
