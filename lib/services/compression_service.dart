import 'dart:io';
import 'dart:typed_data';
import 'package:archive/archive.dart';

class CompressionService {
  /// Compress a file using GZip
  Future<File> compressFile(File inputFile, {String? outputPath}) async {
    final bytes = await inputFile.readAsBytes();
    final compressed = GZipEncoder().encode(bytes);
    
    if (compressed == null) {
      throw Exception('Failed to compress file');
    }
    
    final output = outputPath ?? '${inputFile.path}.gz';
    final outputFile = File(output);
    await outputFile.writeAsBytes(compressed);
    
    return outputFile;
  }

  /// Decompress a GZip file
  Future<File> decompressFile(File inputFile, {required String outputPath}) async {
    final bytes = await inputFile.readAsBytes();
    final decoded = GZipDecoder().decodeBytes(bytes);
    
    final outputFile = File(outputPath);
    await outputFile.writeAsBytes(decoded);
    
    return outputFile;
  }

  /// Compress bytes in memory
  Uint8List compressBytes(Uint8List data) {
    final compressed = GZipEncoder().encode(data);
    if (compressed == null) {
      throw Exception('Failed to compress data');
    }
    return Uint8List.fromList(compressed);
  }

  /// Decompress bytes in memory
  Uint8List decompressBytes(Uint8List data) {
    final decompressed = GZipDecoder().decodeBytes(data);
    return Uint8List.fromList(decompressed);
  }

  /// Get compression ratio
  double getCompressionRatio(int originalSize, int compressedSize) {
    if (originalSize == 0) return 0;
    return ((originalSize - compressedSize) / originalSize) * 100;
  }

  /// Check if file would benefit from compression
  /// Returns false for already compressed formats
  bool shouldCompress(String fileName) {
    final extension = fileName.split('.').last.toLowerCase();
    final noCompressExtensions = [
      'zip', 'rar', '7z', 'gz', 'bz2', 'xz',
      'jpg', 'jpeg', 'png', 'gif', 'webp',
      'mp4', 'avi', 'mkv', 'mov', 'webm',
      'mp3', 'aac', 'ogg', 'flac', 'm4a',
      'pdf', 'doc', 'docx', 'ppt', 'pptx',
    ];
    
    return !noCompressExtensions.contains(extension);
  }

  /// Estimate compressed size (rough estimate)
  int estimateCompressedSize(int originalSize, String fileName) {
    if (!shouldCompress(fileName)) {
      return originalSize;
    }
    
    // Text files compress well (70% reduction)
    final extension = fileName.split('.').last.toLowerCase();
    if (['txt', 'json', 'xml', 'html', 'css', 'js'].contains(extension)) {
      return (originalSize * 0.3).toInt();
    }
    
    // Binary files compress moderately (40% reduction)
    return (originalSize * 0.6).toInt();
  }
}
