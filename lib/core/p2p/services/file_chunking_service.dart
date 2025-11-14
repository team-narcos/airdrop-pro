import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:crypto/crypto.dart';
import 'dart:convert';

/// Service for chunking files into smaller pieces and reassembling them
class FileChunkingService {
  static const int defaultChunkSize = 4 * 1024 * 1024; // 4MB
  
  /// Calculate total number of chunks for a file
  static int calculateTotalChunks(int fileSize, int chunkSize) {
    return (fileSize / chunkSize).ceil();
  }
  
  /// Read a specific chunk from a file
  static Future<Uint8List> readChunk({
    required String filePath,
    required int chunkIndex,
    required int chunkSize,
  }) async {
    final file = File(filePath);
    
    if (!await file.exists()) {
      throw FileSystemException('File not found', filePath);
    }
    
    final fileSize = await file.length();
    final offset = chunkIndex * chunkSize;
    
    if (offset >= fileSize) {
      throw RangeError('Chunk index $chunkIndex is out of range');
    }
    
    // Calculate actual chunk size (last chunk may be smaller)
    final remainingBytes = fileSize - offset;
    final actualChunkSize = remainingBytes < chunkSize ? remainingBytes : chunkSize;
    
    // Read chunk
    final randomAccessFile = await file.open(mode: FileMode.read);
    try {
      await randomAccessFile.setPosition(offset);
      final bytes = await randomAccessFile.read(actualChunkSize);
      return Uint8List.fromList(bytes);
    } finally {
      await randomAccessFile.close();
    }
  }
  
  /// Write a chunk to a file at specific position
  static Future<void> writeChunk({
    required String filePath,
    required int chunkIndex,
    required int chunkSize,
    required Uint8List data,
  }) async {
    final file = File(filePath);
    final offset = chunkIndex * chunkSize;
    
    // Ensure parent directory exists
    await file.parent.create(recursive: true);
    
    // Write chunk at specific position
    final randomAccessFile = await file.open(mode: FileMode.append);
    try {
      await randomAccessFile.setPosition(offset);
      await randomAccessFile.writeFrom(data);
    } finally {
      await randomAccessFile.close();
    }
  }
  
  /// Calculate SHA256 hash of a file
  static Future<String> calculateFileHash(String filePath) async {
    final file = File(filePath);
    
    if (!await file.exists()) {
      throw FileSystemException('File not found', filePath);
    }
    
    final digest = await sha256.bind(file.openRead()).first;
    return digest.toString();
  }
  
  /// Calculate SHA256 hash of a chunk
  static String calculateChunkHash(Uint8List data) {
    final digest = sha256.convert(data);
    return digest.toString();
  }
  
  /// Verify file integrity by comparing hash
  static Future<bool> verifyFileHash({
    required String filePath,
    required String expectedHash,
  }) async {
    try {
      final actualHash = await calculateFileHash(filePath);
      return actualHash == expectedHash;
    } catch (e) {
      debugPrint('[FileChunking] Error verifying hash: $e');
      return false;
    }
  }
  
  /// Get file info
  static Future<LocalFileInfo> getFileInfo(String filePath) async {
    final file = File(filePath);
    
    if (!await file.exists()) {
      throw FileSystemException('File not found', filePath);
    }
    
    final stat = await file.stat();
    final name = file.uri.pathSegments.last;
    final size = stat.size;
    final extension = name.contains('.') ? name.split('.').last : '';
    
    return LocalFileInfo(
      path: filePath,
      name: name,
      size: size,
      extension: extension,
      modified: stat.modified,
    );
  }
  
  /// Create a temporary file for receiving chunks
  static Future<File> createTempFile(String fileName) async {
    final tempDir = Directory.systemTemp;
    final tempFile = File('${tempDir.path}/airdrop_$fileName');
    await tempFile.create(recursive: true);
    return tempFile;
  }
  
  /// Move temp file to final destination
  static Future<void> moveTempFile({
    required String tempPath,
    required String finalPath,
  }) async {
    final tempFile = File(tempPath);
    final finalFile = File(finalPath);
    
    // Ensure destination directory exists
    await finalFile.parent.create(recursive: true);
    
    // Move file
    await tempFile.copy(finalPath);
    await tempFile.delete();
  }
}

/// Local file information model
class LocalFileInfo {
  final String path;
  final String name;
  final int size;
  final String extension;
  final DateTime modified;
  
  const LocalFileInfo({
    required this.path,
    required this.name,
    required this.size,
    required this.extension,
    required this.modified,
  });
  
  /// Get MIME type based on extension
  String get mimeType {
    switch (extension.toLowerCase()) {
      // Images
      case 'jpg':
      case 'jpeg':
        return 'image/jpeg';
      case 'png':
        return 'image/png';
      case 'gif':
        return 'image/gif';
      case 'webp':
        return 'image/webp';
      case 'svg':
        return 'image/svg+xml';
      
      // Videos
      case 'mp4':
        return 'video/mp4';
      case 'mov':
        return 'video/quicktime';
      case 'avi':
        return 'video/x-msvideo';
      case 'mkv':
        return 'video/x-matroska';
      case 'webm':
        return 'video/webm';
      
      // Audio
      case 'mp3':
        return 'audio/mpeg';
      case 'wav':
        return 'audio/wav';
      case 'm4a':
        return 'audio/mp4';
      case 'flac':
        return 'audio/flac';
      case 'ogg':
        return 'audio/ogg';
      
      // Documents
      case 'pdf':
        return 'application/pdf';
      case 'doc':
        return 'application/msword';
      case 'docx':
        return 'application/vnd.openxmlformats-officedocument.wordprocessingml.document';
      case 'xls':
        return 'application/vnd.ms-excel';
      case 'xlsx':
        return 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet';
      case 'ppt':
        return 'application/vnd.ms-powerpoint';
      case 'pptx':
        return 'application/vnd.openxmlformats-officedocument.presentationml.presentation';
      
      // Archives
      case 'zip':
        return 'application/zip';
      case 'rar':
        return 'application/x-rar-compressed';
      case '7z':
        return 'application/x-7z-compressed';
      case 'tar':
        return 'application/x-tar';
      case 'gz':
        return 'application/gzip';
      
      // Text
      case 'txt':
        return 'text/plain';
      case 'json':
        return 'application/json';
      case 'xml':
        return 'application/xml';
      case 'html':
        return 'text/html';
      case 'css':
        return 'text/css';
      case 'js':
        return 'application/javascript';
      
      default:
        return 'application/octet-stream';
    }
  }
  
  /// Format file size for display
  String get formattedSize {
    if (size < 1024) return '$size B';
    if (size < 1024 * 1024) return '${(size / 1024).toStringAsFixed(1)} KB';
    if (size < 1024 * 1024 * 1024) {
      return '${(size / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    return '${(size / (1024 * 1024 * 1024)).toStringAsFixed(2)} GB';
  }
}
