import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'package:logger/logger.dart';
import 'package:path/path.dart' as path;
import 'package:image/image.dart' as img;

/// AI Content Recognition Engine
/// Features:
/// - ML-based file categorization
/// - Smart content-based search
/// - Image analysis
/// - Text extraction
/// - Automatic tagging
class ContentRecognitionEngine {
  final Logger _logger = Logger();
  
  bool _isInitialized = false;
  
  // Content categories
  final Map<String, List<String>> _categoryKeywords = {
    'work': ['document', 'report', 'presentation', 'spreadsheet', 'pdf', 'contract'],
    'personal': ['photo', 'selfie', 'family', 'vacation', 'birthday'],
    'media': ['video', 'movie', 'music', 'audio', 'song'],
    'archive': ['zip', 'rar', 'backup', 'archive'],
    'code': ['source', 'code', 'script', 'program', 'app'],
  };
  
  // Image analysis cache
  final Map<String, FileAnalysis> _analysisCache = {};
  
  /// Initialize AI engine
  Future<bool> initialize() async {
    if (_isInitialized) return true;
    
    try {
      _logger.i('[AI] Initializing content recognition engine...');
      
      // In a real implementation, this would load TensorFlow Lite models
      // For now, we'll use rule-based classification
      
      _isInitialized = true;
      _logger.i('[AI] Content recognition engine initialized');
      return true;
    } catch (e) {
      _logger.e('[AI] Initialization failed: $e');
      return false;
    }
  }
  
  /// Analyze file and extract metadata
  Future<FileAnalysis> analyzeFile(File file) async {
    try {
      final filePath = file.path;
      
      // Check cache
      if (_analysisCache.containsKey(filePath)) {
        return _analysisCache[filePath]!;
      }
      
      _logger.i('[AI] Analyzing file: ${path.basename(filePath)}');
      
      final analysis = FileAnalysis(
        filePath: filePath,
        fileName: path.basename(filePath),
        fileSize: await file.length(),
        extension: path.extension(filePath).toLowerCase(),
        mimeType: _detectMimeType(filePath),
        category: FileCategory.unknown,
        tags: [],
        confidence: 0.0,
        analyzedAt: DateTime.now(),
      );
      
      // Detect category
      analysis.category = _categorizeFile(file, analysis);
      
      // Extract content-specific metadata
      if (analysis.category == FileCategory.image) {
        await _analyzeImage(file, analysis);
      } else if (analysis.category == FileCategory.document) {
        await _analyzeDocument(file, analysis);
      } else if (analysis.category == FileCategory.video) {
        await _analyzeVideo(file, analysis);
      }
      
      // Generate tags
      analysis.tags = _generateTags(analysis);
      
      // Calculate confidence
      analysis.confidence = _calculateConfidence(analysis);
      
      // Cache result
      _analysisCache[filePath] = analysis;
      
      _logger.i('[AI] Analysis complete: ${analysis.category} (${analysis.confidence.toStringAsFixed(2)})');
      return analysis;
    } catch (e) {
      _logger.e('[AI] Analysis failed: $e');
      rethrow;
    }
  }
  
  /// Categorize file based on extension and content
  FileCategory _categorizeFile(File file, FileAnalysis analysis) {
    final ext = analysis.extension.replaceAll('.', '');
    
    // Image formats
    if (['jpg', 'jpeg', 'png', 'gif', 'bmp', 'webp', 'heic'].contains(ext)) {
      return FileCategory.image;
    }
    
    // Video formats
    if (['mp4', 'avi', 'mov', 'mkv', 'webm', 'flv'].contains(ext)) {
      return FileCategory.video;
    }
    
    // Audio formats
    if (['mp3', 'wav', 'flac', 'aac', 'ogg', 'm4a'].contains(ext)) {
      return FileCategory.audio;
    }
    
    // Document formats
    if (['pdf', 'doc', 'docx', 'txt', 'rtf', 'odt'].contains(ext)) {
      return FileCategory.document;
    }
    
    // Spreadsheet formats
    if (['xls', 'xlsx', 'csv'].contains(ext)) {
      return FileCategory.spreadsheet;
    }
    
    // Presentation formats
    if (['ppt', 'pptx', 'key'].contains(ext)) {
      return FileCategory.presentation;
    }
    
    // Archive formats
    if (['zip', 'rar', '7z', 'tar', 'gz'].contains(ext)) {
      return FileCategory.archive;
    }
    
    // Code formats
    if (['dart', 'java', 'py', 'js', 'html', 'css', 'json', 'xml'].contains(ext)) {
      return FileCategory.code;
    }
    
    return FileCategory.unknown;
  }
  
  /// Analyze image file
  Future<void> _analyzeImage(File file, FileAnalysis analysis) async {
    try {
      final bytes = await file.readAsBytes();
      final image = img.decodeImage(bytes);
      
      if (image != null) {
        analysis.metadata['width'] = image.width;
        analysis.metadata['height'] = image.height;
        analysis.metadata['aspectRatio'] = image.width / image.height;
        analysis.metadata['pixels'] = image.width * image.height;
        
        // Detect orientation
        if (image.width > image.height) {
          analysis.metadata['orientation'] = 'landscape';
        } else if (image.height > image.width) {
          analysis.metadata['orientation'] = 'portrait';
        } else {
          analysis.metadata['orientation'] = 'square';
        }
        
        // Detect if high resolution
        final megapixels = (image.width * image.height) / 1000000;
        analysis.metadata['megapixels'] = megapixels.toStringAsFixed(1);
        
        if (megapixels > 8) {
          analysis.tags.add('high-resolution');
        }
        
        // Simple color analysis
        analysis.metadata['dominantColor'] = _analyzeColors(image);
      }
    } catch (e) {
      _logger.w('[AI] Image analysis failed: $e');
    }
  }
  
  /// Analyze document file
  Future<void> _analyzeDocument(File file, FileAnalysis analysis) async {
    try {
      // For text files, we can analyze content
      if (analysis.extension == '.txt') {
        final content = await file.readAsString();
        
        analysis.metadata['wordCount'] = content.split(RegExp(r'\s+')).length;
        analysis.metadata['lineCount'] = content.split('\n').length;
        analysis.metadata['charCount'] = content.length;
        
        // Detect language (simple heuristic)
        if (content.contains(RegExp(r'[a-zA-Z]'))) {
          analysis.metadata['language'] = 'english';
        }
        
        // Check for code patterns
        if (content.contains('function') || content.contains('class') || content.contains('import')) {
          analysis.tags.add('code');
        }
      }
      
      // Add common document tags
      if (analysis.fileName.toLowerCase().contains('resume') ||
          analysis.fileName.toLowerCase().contains('cv')) {
        analysis.tags.add('resume');
        analysis.tags.add('work');
      }
      
      if (analysis.fileName.toLowerCase().contains('report')) {
        analysis.tags.add('report');
        analysis.tags.add('work');
      }
    } catch (e) {
      _logger.w('[AI] Document analysis failed: $e');
    }
  }
  
  /// Analyze video file
  Future<void> _analyzeVideo(File file, FileAnalysis analysis) async {
    try {
      // Basic video metadata (in real implementation, would use video decoder)
      analysis.metadata['type'] = 'video';
      
      // Estimate duration based on file size (rough approximation)
      final sizeInMB = analysis.fileSize / (1024 * 1024);
      final estimatedMinutes = (sizeInMB / 10).round(); // Assuming ~10MB per minute
      analysis.metadata['estimatedDuration'] = '$estimatedMinutes min';
      
      if (sizeInMB > 500) {
        analysis.tags.add('large-video');
      }
    } catch (e) {
      _logger.w('[AI] Video analysis failed: $e');
    }
  }
  
  /// Analyze dominant colors in image
  String _analyzeColors(img.Image image) {
    // Sample pixels to determine dominant color
    int r = 0, g = 0, b = 0, count = 0;
    
    for (int y = 0; y < image.height; y += 10) {
      for (int x = 0; x < image.width; x += 10) {
        final pixel = image.getPixel(x, y);
        r += pixel.r.toInt();
        g += pixel.g.toInt();
        b += pixel.b.toInt();
        count++;
      }
    }
    
    if (count > 0) {
      r ~/= count;
      g ~/= count;
      b ~/= count;
    }
    
    // Determine color name
    if (r > 200 && g > 200 && b > 200) return 'white';
    if (r < 50 && g < 50 && b < 50) return 'black';
    if (r > g && r > b) return 'red';
    if (g > r && g > b) return 'green';
    if (b > r && b > g) return 'blue';
    if (r > 150 && g > 150 && b < 100) return 'yellow';
    
    return 'mixed';
  }
  
  /// Generate tags based on analysis
  List<String> _generateTags(FileAnalysis analysis) {
    final tags = <String>[...analysis.tags];
    
    // Add category tag
    tags.add(analysis.category.toString().split('.').last);
    
    // Add size-based tags
    final sizeInMB = analysis.fileSize / (1024 * 1024);
    if (sizeInMB < 1) {
      tags.add('small');
    } else if (sizeInMB < 10) {
      tags.add('medium');
    } else {
      tags.add('large');
    }
    
    // Add date-based tags
    final now = DateTime.now();
    final fileDate = File(analysis.filePath).lastModifiedSync();
    
    if (now.difference(fileDate).inDays < 7) {
      tags.add('recent');
    }
    
    // Add extension tag
    tags.add(analysis.extension.replaceAll('.', ''));
    
    return tags.toSet().toList(); // Remove duplicates
  }
  
  /// Calculate confidence score
  double _calculateConfidence(FileAnalysis analysis) {
    double confidence = 0.5; // Base confidence
    
    // Increase confidence if we have metadata
    if (analysis.metadata.isNotEmpty) {
      confidence += 0.2;
    }
    
    // Increase confidence if category is not unknown
    if (analysis.category != FileCategory.unknown) {
      confidence += 0.2;
    }
    
    // Increase confidence if we have tags
    if (analysis.tags.isNotEmpty) {
      confidence += 0.1;
    }
    
    return confidence.clamp(0.0, 1.0);
  }
  
  /// Search files by content
  List<FileAnalysis> searchByContent(
    List<FileAnalysis> files,
    String query, {
    double minConfidence = 0.5,
  }) {
    final lowerQuery = query.toLowerCase();
    
    return files.where((analysis) {
      if (analysis.confidence < minConfidence) return false;
      
      // Search in filename
      if (analysis.fileName.toLowerCase().contains(lowerQuery)) return true;
      
      // Search in tags
      if (analysis.tags.any((tag) => tag.toLowerCase().contains(lowerQuery))) {
        return true;
      }
      
      // Search in metadata
      if (analysis.metadata.values.any(
        (value) => value.toString().toLowerCase().contains(lowerQuery),
      )) {
        return true;
      }
      
      return false;
    }).toList();
  }
  
  /// Group files by category
  Map<FileCategory, List<FileAnalysis>> groupByCategory(
    List<FileAnalysis> files,
  ) {
    final grouped = <FileCategory, List<FileAnalysis>>{};
    
    for (final analysis in files) {
      grouped.putIfAbsent(analysis.category, () => []).add(analysis);
    }
    
    return grouped;
  }
  
  /// Get similar files
  List<FileAnalysis> findSimilar(
    FileAnalysis target,
    List<FileAnalysis> candidates, {
    int limit = 10,
  }) {
    final similarities = <MapEntry<FileAnalysis, double>>[];
    
    for (final candidate in candidates) {
      if (candidate.filePath == target.filePath) continue;
      
      final similarity = _calculateSimilarity(target, candidate);
      similarities.add(MapEntry(candidate, similarity));
    }
    
    // Sort by similarity
    similarities.sort((a, b) => b.value.compareTo(a.value));
    
    return similarities.take(limit).map((e) => e.key).toList();
  }
  
  /// Calculate similarity between two files
  double _calculateSimilarity(FileAnalysis a, FileAnalysis b) {
    double score = 0.0;
    
    // Category match
    if (a.category == b.category) score += 0.4;
    
    // Extension match
    if (a.extension == b.extension) score += 0.2;
    
    // Tag overlap
    final commonTags = a.tags.toSet().intersection(b.tags.toSet());
    score += (commonTags.length / (a.tags.length + b.tags.length)) * 0.3;
    
    // Size similarity
    final sizeDiff = (a.fileSize - b.fileSize).abs() / a.fileSize;
    if (sizeDiff < 0.5) score += 0.1;
    
    return score;
  }
  
  /// Detect MIME type
  String _detectMimeType(String filePath) {
    final ext = path.extension(filePath).toLowerCase();
    
    final mimeTypes = {
      '.jpg': 'image/jpeg',
      '.jpeg': 'image/jpeg',
      '.png': 'image/png',
      '.gif': 'image/gif',
      '.pdf': 'application/pdf',
      '.doc': 'application/msword',
      '.docx': 'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
      '.mp4': 'video/mp4',
      '.mp3': 'audio/mpeg',
      '.zip': 'application/zip',
      '.txt': 'text/plain',
      '.json': 'application/json',
    };
    
    return mimeTypes[ext] ?? 'application/octet-stream';
  }
  
  /// Clear cache
  void clearCache() {
    _analysisCache.clear();
    _logger.i('[AI] Analysis cache cleared');
  }
  
  /// Get statistics
  Map<String, dynamic> getStatistics() {
    return {
      'cacheSize': _analysisCache.length,
      'isInitialized': _isInitialized,
    };
  }
}

/// File analysis result
class FileAnalysis {
  final String filePath;
  final String fileName;
  final int fileSize;
  final String extension;
  final String mimeType;
  FileCategory category;
  List<String> tags;
  final Map<String, dynamic> metadata;
  double confidence;
  final DateTime analyzedAt;
  
  FileAnalysis({
    required this.filePath,
    required this.fileName,
    required this.fileSize,
    required this.extension,
    required this.mimeType,
    required this.category,
    required this.tags,
    required this.confidence,
    required this.analyzedAt,
    Map<String, dynamic>? metadata,
  }) : metadata = metadata ?? {};
  
  Map<String, dynamic> toJson() {
    return {
      'filePath': filePath,
      'fileName': fileName,
      'fileSize': fileSize,
      'extension': extension,
      'mimeType': mimeType,
      'category': category.toString(),
      'tags': tags,
      'metadata': metadata,
      'confidence': confidence,
      'analyzedAt': analyzedAt.toIso8601String(),
    };
  }
}

/// File categories
enum FileCategory {
  image,
  video,
  audio,
  document,
  spreadsheet,
  presentation,
  archive,
  code,
  unknown,
}
