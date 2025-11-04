import 'dart:io';
import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

class FileOperationsService {
  /// Pick multiple files using system file picker
  Future<List<SelectedFile>> pickFiles() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        allowMultiple: true,
        type: FileType.any,
        withData: true, // For web
        withReadStream: true, // For large files
      );
      
      if (result == null) return [];
      
      return result.files.map((file) {
        return SelectedFile(
          name: file.name,
          path: file.path,
          size: file.size,
          extension: file.extension ?? '',
          bytes: file.bytes,
        );
      }).toList();
    } catch (e) {
      return [];
    }
  }
  
  /// Get received files directory
  /// MUST match the directory used in TcpTransferService
  Future<Directory> getReceivedFilesDirectory() async {
    Directory? dir;
    try {
      // Use external storage on Android (works with FileProvider)
      if (Platform.isAndroid) {
        final externalDir = await getExternalStorageDirectory();
        if (externalDir != null) {
          dir = Directory(p.join(externalDir.path, 'ReceivedFiles'));
        }
      }
      // Fallback to documents directory for iOS/other platforms
      if (dir == null) {
        final docDir = await getApplicationDocumentsDirectory();
        dir = Directory(p.join(docDir.path, 'ReceivedFiles'));
      }
    } catch (e) {
      print('[FileOps] Error getting storage directory: $e');
      final docDir = await getApplicationDocumentsDirectory();
      dir = Directory(p.join(docDir.path, 'ReceivedFiles'));
    }
    
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    
    return dir;
  }
  
  /// Save received file
  Future<File> saveReceivedFile(String fileName, Uint8List data) async {
    final dir = await getReceivedFilesDirectory();
    final filePath = p.join(dir.path, _makeUniqueFileName(fileName));
    final file = File(filePath);
    await file.writeAsBytes(data);
    return file;
  }
  
  /// Get all received files with metadata
  Future<List<ReceivedFileInfo>> getReceivedFiles() async {
    try {
      final dir = await getReceivedFilesDirectory();
      
      if (!await dir.exists()) {
        return [];
      }
      
      final files = <ReceivedFileInfo>[];
      
      await for (final entity in dir.list()) {
        if (entity is File) {
          final stat = await entity.stat();
          final size = stat.size;
          final modified = stat.modified;
          
          files.add(ReceivedFileInfo(
            name: p.basename(entity.path),
            path: entity.path,
            size: size,
            receivedAt: modified,
            extension: p.extension(entity.path).replaceAll('.', ''),
          ));
        }
      }
      
      // Sort by date, newest first
      files.sort((a, b) => b.receivedAt.compareTo(a.receivedAt));
      
      return files;
    } catch (e) {
      return [];
    }
  }
  
  /// Calculate storage usage
  Future<StorageInfo> getStorageInfo() async {
    try {
      final dir = await getReceivedFilesDirectory();
      
      if (!await dir.exists()) {
        return StorageInfo(usedBytes: 0, fileCount: 0);
      }
      
      int totalBytes = 0;
      int fileCount = 0;
      
      await for (final entity in dir.list()) {
        if (entity is File) {
          final stat = await entity.stat();
          totalBytes += stat.size;
          fileCount++;
        }
      }
      
      return StorageInfo(usedBytes: totalBytes, fileCount: fileCount);
    } catch (e) {
      return StorageInfo(usedBytes: 0, fileCount: 0);
    }
  }
  
  /// Delete a file
  Future<bool> deleteFile(String path) async {
    try {
      final file = File(path);
      if (await file.exists()) {
        await file.delete();
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }
  
  /// Clear all received files
  Future<int> clearAllFiles() async {
    try {
      final dir = await getReceivedFilesDirectory();
      
      if (!await dir.exists()) {
        return 0;
      }
      
      int deletedCount = 0;
      
      await for (final entity in dir.list()) {
        if (entity is File) {
          await entity.delete();
          deletedCount++;
        }
      }
      
      return deletedCount;
    } catch (e) {
      return 0;
    }
  }
  
  /// Format bytes to human readable
  static String formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(2)} GB';
  }
  
  /// Get file category
  static FileCategory getFileCategory(String extension) {
    final ext = extension.toLowerCase();
    
    if (['jpg', 'jpeg', 'png', 'gif', 'bmp', 'webp', 'svg'].contains(ext)) {
      return FileCategory.image;
    }
    if (['mp4', 'avi', 'mov', 'mkv', 'webm', 'flv'].contains(ext)) {
      return FileCategory.video;
    }
    if (['mp3', 'wav', 'aac', 'm4a', 'flac', 'ogg'].contains(ext)) {
      return FileCategory.audio;
    }
    if (['pdf', 'doc', 'docx', 'txt', 'rtf', 'odt'].contains(ext)) {
      return FileCategory.document;
    }
    
    return FileCategory.other;
  }
  
  String _makeUniqueFileName(String fileName) {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final ext = p.extension(fileName);
    final nameWithoutExt = p.basenameWithoutExtension(fileName);
    return '${nameWithoutExt}_$timestamp$ext';
  }
}

class SelectedFile {
  final String name;
  final String? path;
  final int size;
  final String extension;
  final Uint8List? bytes;
  
  SelectedFile({
    required this.name,
    this.path,
    required this.size,
    required this.extension,
    this.bytes,
  });
}

class ReceivedFileInfo {
  final String name;
  final String path;
  final int size;
  final DateTime receivedAt;
  final String extension;
  
  ReceivedFileInfo({
    required this.name,
    required this.path,
    required this.size,
    required this.receivedAt,
    required this.extension,
  });
}

class StorageInfo {
  final int usedBytes;
  final int fileCount;
  
  StorageInfo({
    required this.usedBytes,
    required this.fileCount,
  });
}

enum FileCategory {
  image,
  video,
  audio,
  document,
  other,
}
