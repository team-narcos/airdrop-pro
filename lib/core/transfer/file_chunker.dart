import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'package:path_provider/path_provider.dart';

/// File chunker and reassembler for large files with resume support.
class FileChunker {
  static const int defaultChunkSize = 1 << 16; // 64 KiB

  Stream<Uint8List> readInChunks(File file, {int chunkSize = defaultChunkSize}) async* {
    final raf = await file.open();
    try {
      final length = await raf.length();
      int offset = 0;
      while (offset < length) {
        final remaining = length - offset;
        final size = remaining < chunkSize ? remaining : chunkSize;
        await raf.setPosition(offset);
        final bytes = await raf.read(size);
        offset += bytes.length;
        yield Uint8List.fromList(bytes);
      }
    } finally {
      await raf.close();
    }
  }

  Future<File> writeChunk(String tempId, int index, Uint8List bytes) async {
    final dir = await getTemporaryDirectory();
    final chunk = File('${dir.path}/$tempId.$index.part');
    await chunk.writeAsBytes(bytes, flush: true);
    return chunk;
  }
}
