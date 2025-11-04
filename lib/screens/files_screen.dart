import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:path_provider/path_provider.dart';
import '../core/design_system/ios18_theme.dart';
import '../core/widgets/glassmorphic_card.dart';
import '../core/widgets/storage_visualization.dart';
import '../providers/services_providers.dart';
import '../services/file_operations_service.dart';

class FilesScreen extends ConsumerStatefulWidget {
  const FilesScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<FilesScreen> createState() => _FilesScreenState();
}

class _FilesScreenState extends ConsumerState<FilesScreen> with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  
  String _selectedFilter = 'All';
  bool _isGridView = false;
  
  final List<String> _filterOptions = ['All', 'Images', 'Documents', 'Videos', 'Audio'];

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );
    
    _slideAnimation = Tween<Offset>(begin: const Offset(0, 0.2), end: Offset.zero).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.elasticOut),
    );
    
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isLargeScreen = screenWidth > 414;
    
    // Watch real file data
    final receivedFilesAsync = ref.watch(receivedFilesProvider);
    final storageInfoAsync = ref.watch(storageInfoProvider);
    
    final receivedFiles = receivedFilesAsync.maybeWhen(
      data: (files) => files,
      orElse: () => <ReceivedFileInfo>[],
    );
    
    final storageInfo = storageInfoAsync.maybeWhen(
      data: (info) => info,
      orElse: () => StorageInfo(usedBytes: 0, fileCount: 0),
    );
    
    return SafeArea(
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: iOS18Spacing.lg,
            vertical: iOS18Spacing.md,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(height: iOS18Spacing.xl),
              
              // Header with view toggle
              FadeTransition(
                opacity: _fadeAnimation,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Files',
                          style: iOS18Typography.largeTitle.copyWith(
                            color: iOS18Colors.getTextPrimary(context),
                          ),
                        ),
                        SizedBox(height: iOS18Spacing.xs),
                        Text(
                          '${receivedFiles.length} files • ${(storageInfo.usedBytes / (1024 * 1024)).toStringAsFixed(1)} MB',
                          style: iOS18Typography.subheadline.copyWith(
                            color: iOS18Colors.getTextSecondary(context),
                          ),
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        GestureDetector(
                          onTap: () {
                            setState(() {
                              _isGridView = !_isGridView;
                            });
                          },
                          child: Container(
                            padding: EdgeInsets.all(iOS18Spacing.sm),
                            decoration: BoxDecoration(
                              color: iOS18Colors.systemBlue.withOpacity(_isGridView ? 0.2 : 0.1),
                              borderRadius: BorderRadius.circular(iOS18Spacing.radiusSM),
                            ),
                            child: Icon(
                              _isGridView ? CupertinoIcons.list_bullet : CupertinoIcons.grid,
                              size: 20,
                              color: iOS18Colors.systemBlue,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              
              SizedBox(height: iOS18Spacing.xl),
              
              // Storage visualization and overview
              SlideTransition(
                position: _slideAnimation,
                child: FadeTransition(
                  opacity: _fadeAnimation,
                  child: GlassmorphicCard(
                    padding: EdgeInsets.all(iOS18Spacing.xl),
                    child: Row(
                      children: [
                        StorageVisualization(
                          usedGB: storageInfo.usedBytes / (1024 * 1024 * 1024),
                          totalGB: 10.0, // Simulated total storage
                          size: 120,
                        ),
                        SizedBox(width: iOS18Spacing.xl),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Storage',
                                style: iOS18Typography.title3.copyWith(
                                  color: iOS18Colors.getTextPrimary(context),
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              SizedBox(height: iOS18Spacing.sm),
                              _buildStorageRow(
                                'Documents',
                                '${(storageInfo.usedBytes * 0.4 / (1024 * 1024)).toStringAsFixed(1)} MB',
                                const Color(0xFF007AFF),
                              ),
                              SizedBox(height: iOS18Spacing.xs),
                              _buildStorageRow(
                                'Images',
                                '${(storageInfo.usedBytes * 0.35 / (1024 * 1024)).toStringAsFixed(1)} MB',
                                const Color(0xFF5856D6),
                              ),
                              SizedBox(height: iOS18Spacing.xs),
                              _buildStorageRow(
                                'Videos',
                                '${(storageInfo.usedBytes * 0.2 / (1024 * 1024)).toStringAsFixed(1)} MB',
                                const Color(0xFF32D74B),
                              ),
                              SizedBox(height: iOS18Spacing.xs),
                              _buildStorageRow(
                                'Other',
                                '${(storageInfo.usedBytes * 0.05 / (1024 * 1024)).toStringAsFixed(1)} MB',
                                const Color(0xFF8E8E93),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              
              SizedBox(height: iOS18Spacing.xl),
              
              // Filter chips
              SizedBox(
                height: 40,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: _filterOptions.length,
                  separatorBuilder: (context, index) => SizedBox(width: iOS18Spacing.sm),
                  itemBuilder: (context, index) {
                    final filter = _filterOptions[index];
                    final isSelected = filter == _selectedFilter;
                    return _buildFilterChip(filter, isSelected);
                  },
                ),
              ),
              
              SizedBox(height: iOS18Spacing.lg),
              
              // Files list/grid
              receivedFiles.isEmpty
                  ? _buildEmptyState()
                  : _isGridView
                      ? _buildFilesGrid()
                      : _buildFilesList(),
              
              SizedBox(height: iOS18Spacing.xl),
              
              // Action buttons
              Row(
                children: [
                  Expanded(
                    child: _buildActionButton(
                      'Upload Files',
                      CupertinoIcons.cloud_upload,
                      iOS18Colors.systemBlue,
                      _handleUpload,
                    ),
                  ),
                  SizedBox(width: iOS18Spacing.md),
                  Expanded(
                    child: _buildActionButton(
                      'Clear All',
                      CupertinoIcons.trash,
                      iOS18Colors.systemRed,
                      () async {
                        HapticFeedback.mediumImpact();
                        final fileOps = ref.read(fileOperationsServiceProvider);
                        await fileOps.clearAllFiles();
                        ref.refresh(receivedFilesProvider);
                        ref.refresh(storageInfoProvider);
                      },
                    ),
                  ),
                ],
              ),
              
              // Bottom padding for navigation
              const SizedBox(height: 120),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStorageCard(
    String title,
    String value,
    String subtitle,
    double progress,
    LinearGradient gradient,
  ) {
    return GlassmorphicCard(
      padding: EdgeInsets.all(iOS18Spacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  gradient: gradient,
                  borderRadius: BorderRadius.circular(iOS18Spacing.radiusSM),
                ),
                child: const Icon(
                  CupertinoIcons.folder_solid,
                  size: 20,
                  color: Colors.white,
                ),
              ),
              SizedBox(width: iOS18Spacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      value,
                      style: iOS18Typography.title2.copyWith(
                        color: iOS18Colors.getTextPrimary(context),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      title,
                      style: iOS18Typography.caption1.copyWith(
                        color: iOS18Colors.getTextSecondary(context),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: iOS18Spacing.md),
          // Progress bar
          Container(
            height: 6,
            decoration: BoxDecoration(
              color: iOS18Colors.getTextTertiary(context).withOpacity(0.3),
              borderRadius: BorderRadius.circular(3),
            ),
            child: FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: progress,
              child: Container(
                decoration: BoxDecoration(
                  gradient: gradient,
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
            ),
          ),
          SizedBox(height: iOS18Spacing.sm),
          Text(
            subtitle,
            style: iOS18Typography.caption2.copyWith(
              color: iOS18Colors.getTextSecondary(context),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, bool isSelected) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        setState(() {
          _selectedFilter = label;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: EdgeInsets.symmetric(
          horizontal: iOS18Spacing.md,
          vertical: iOS18Spacing.sm,
        ),
        decoration: BoxDecoration(
          gradient: isSelected ? iOS18Colors.airDropGradient : null,
          color: isSelected ? null : iOS18Colors.getTextTertiary(context).withOpacity(0.1),
          borderRadius: BorderRadius.circular(iOS18Spacing.radiusSM),
          border: isSelected
              ? null
              : Border.all(
                  color: iOS18Colors.getTextTertiary(context).withOpacity(0.3),
                  width: 0.5,
                ),
        ),
        child: Text(
          label,
          style: iOS18Typography.caption1.copyWith(
            color: isSelected ? Colors.white : iOS18Colors.getTextPrimary(context),
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return GlassmorphicCard(
      padding: EdgeInsets.all(iOS18Spacing.xxxl),
      child: Column(
        children: [
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              gradient: iOS18Colors.fileGradient.scale(0.3),
              borderRadius: BorderRadius.circular(iOS18Spacing.radiusXL),
            ),
            child: const Icon(
              CupertinoIcons.folder,
              size: 50,
              color: Colors.white,
            ),
          ),
          SizedBox(height: iOS18Spacing.lg),
          Text(
            'No Files Yet',
            style: iOS18Typography.title2.copyWith(
              color: iOS18Colors.getTextPrimary(context),
            ),
          ),
          SizedBox(height: iOS18Spacing.sm),
          Text(
            'Upload files to share with nearby devices\nvia AirDrop',
            style: iOS18Typography.subheadline.copyWith(
              color: iOS18Colors.getTextSecondary(context),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildFilesList() {
    final receivedFilesAsync = ref.watch(receivedFilesProvider);
    
    return receivedFilesAsync.when(
      data: (files) {
        final filteredFiles = _filterFiles(files);
        
        if (filteredFiles.isEmpty) {
          return _buildEmptyFilterState();
        }
        
        return Column(
          children: filteredFiles.map((file) => _buildRealFileCard(file)).toList(),
        );
      },
      loading: () => const Center(child: CupertinoActivityIndicator()),
      error: (err, stack) => Center(
        child: Text('Error loading files: $err'),
      ),
    );
  }

  Widget _buildFilesGrid() {
    final receivedFilesAsync = ref.watch(receivedFilesProvider);
    
    return receivedFilesAsync.when(
      data: (files) {
        final filteredFiles = _filterFiles(files);
        
        if (filteredFiles.isEmpty) {
          return _buildEmptyFilterState();
        }
        
        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: iOS18Spacing.md,
            mainAxisSpacing: iOS18Spacing.md,
            childAspectRatio: 0.85,
          ),
          itemCount: filteredFiles.length,
          itemBuilder: (context, index) => _buildRealFileGridCard(filteredFiles[index]),
        );
      },
      loading: () => const Center(child: CupertinoActivityIndicator()),
      error: (err, stack) => Center(
        child: Text('Error loading files: $err'),
      ),
    );
  }
  
  List<ReceivedFileInfo> _filterFiles(List<ReceivedFileInfo> files) {
    if (_selectedFilter == 'All') return files;
    
    return files.where((file) {
      final category = FileOperationsService.getFileCategory(file.extension);
      switch (_selectedFilter) {
        case 'Images':
          return category == FileCategory.image;
        case 'Documents':
          return category == FileCategory.document;
        case 'Videos':
          return category == FileCategory.video;
        case 'Audio':
          return category == FileCategory.audio;
        default:
          return true;
      }
    }).toList();
  }
  
  Widget _buildEmptyFilterState() {
    return GlassmorphicCard(
      padding: EdgeInsets.all(iOS18Spacing.xl),
      child: Column(
        children: [
          Icon(
            CupertinoIcons.search,
            size: 50,
            color: iOS18Colors.getTextTertiary(context),
          ),
          SizedBox(height: iOS18Spacing.md),
          Text(
            'No $_selectedFilter Files',
            style: iOS18Typography.body.copyWith(
              color: iOS18Colors.getTextSecondary(context),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildRealFileCard(ReceivedFileInfo file) {
    final category = FileOperationsService.getFileCategory(file.extension);
    return Padding(
      padding: EdgeInsets.only(bottom: iOS18Spacing.md),
      child: GestureDetector(
        onTap: () => _previewFile(file),
        child: GlassmorphicCard(
          padding: EdgeInsets.all(iOS18Spacing.md),
          child: Row(
            children: [
              // File icon
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  gradient: _getFileGradient(category),
                  borderRadius: BorderRadius.circular(iOS18Spacing.radiusMD),
                ),
                child: Icon(
                  _getFileIcon(category),
                  size: 24,
                  color: Colors.white,
                ),
              ),
              SizedBox(width: iOS18Spacing.md),
              // File info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      file.name,
                      style: iOS18Typography.bodyEmphasized.copyWith(
                        color: iOS18Colors.getTextPrimary(context),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: iOS18Spacing.xs / 2),
                    Row(
                      children: [
                        Text(
                          FileOperationsService.formatBytes(file.size),
                          style: iOS18Typography.caption1.copyWith(
                            color: iOS18Colors.getTextSecondary(context),
                          ),
                        ),
                        Text(
                          ' • ',
                          style: iOS18Typography.caption1.copyWith(
                            color: iOS18Colors.getTextTertiary(context),
                          ),
                        ),
                        Text(
                          _formatDate(file.receivedAt),
                          style: iOS18Typography.caption1.copyWith(
                            color: iOS18Colors.getTextSecondary(context),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              // More button
              GestureDetector(
                onTap: () => _showFileOptions(file),
                child: Container(
                  padding: EdgeInsets.all(iOS18Spacing.sm),
                  child: Icon(
                    CupertinoIcons.ellipsis,
                    size: 20,
                    color: iOS18Colors.getTextSecondary(context),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildRealFileGridCard(ReceivedFileInfo file) {
    final category = FileOperationsService.getFileCategory(file.extension);
    return GestureDetector(
      onTap: () => _previewFile(file),
      child: GlassmorphicCard(
        padding: EdgeInsets.all(iOS18Spacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // File preview/icon
            Expanded(
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  gradient: _getFileGradient(category).scale(0.3),
                  borderRadius: BorderRadius.circular(iOS18Spacing.radiusMD),
                ),
                child: Icon(
                  _getFileIcon(category),
                  size: 40,
                  color: Colors.white,
                ),
              ),
            ),
            SizedBox(height: iOS18Spacing.md),
            // File info
            Text(
              file.name,
              style: iOS18Typography.callout.copyWith(
                color: iOS18Colors.getTextPrimary(context),
                fontWeight: FontWeight.w500,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            SizedBox(height: iOS18Spacing.xs),
            Text(
              '${FileOperationsService.formatBytes(file.size)} • ${_formatDate(file.receivedAt)}',
              style: iOS18Typography.caption2.copyWith(
                color: iOS18Colors.getTextSecondary(context),
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFileListItem(FileItem file) {
    return Padding(
      padding: EdgeInsets.only(bottom: iOS18Spacing.md),
      child: GlassmorphicCard(
        padding: EdgeInsets.all(iOS18Spacing.md),
        child: Row(
          children: [
            // File icon
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                gradient: file.type.gradient,
                borderRadius: BorderRadius.circular(iOS18Spacing.radiusMD),
              ),
              child: Icon(
                file.type.icon,
                size: 24,
                color: Colors.white,
              ),
            ),
            SizedBox(width: iOS18Spacing.md),
            // File info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    file.name,
                    style: iOS18Typography.bodyEmphasized.copyWith(
                      color: iOS18Colors.getTextPrimary(context),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: iOS18Spacing.xs / 2),
                  Row(
                    children: [
                      Text(
                        file.size,
                        style: iOS18Typography.caption1.copyWith(
                          color: iOS18Colors.getTextSecondary(context),
                        ),
                      ),
                      Text(
                        ' • ',
                        style: iOS18Typography.caption1.copyWith(
                          color: iOS18Colors.getTextTertiary(context),
                        ),
                      ),
                      Text(
                        file.dateModified,
                        style: iOS18Typography.caption1.copyWith(
                          color: iOS18Colors.getTextSecondary(context),
                        ),
                      ),
                    ],
                  ),
                  if (file.isUploading) ...
                    [
                      SizedBox(height: iOS18Spacing.sm),
                      _buildProgressBar(file.progress),
                    ],
                ],
              ),
            ),
            // More button
            GestureDetector(
              onTap: () => _showFileOptions(file),
              child: Container(
                padding: EdgeInsets.all(iOS18Spacing.sm),
                child: Icon(
                  CupertinoIcons.ellipsis,
                  size: 20,
                  color: iOS18Colors.getTextSecondary(context),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFileGridItem(FileItem file) {
    return GlassmorphicCard(
      padding: EdgeInsets.all(iOS18Spacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // File preview
          Expanded(
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                gradient: file.type.gradient.scale(0.3),
                borderRadius: BorderRadius.circular(iOS18Spacing.radiusMD),
              ),
              child: Icon(
                file.type.icon,
                size: 40,
                color: Colors.white,
              ),
            ),
          ),
          SizedBox(height: iOS18Spacing.md),
          // File info
          Text(
            file.name,
            style: iOS18Typography.callout.copyWith(
              color: iOS18Colors.getTextPrimary(context),
              fontWeight: FontWeight.w500,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          SizedBox(height: iOS18Spacing.xs),
          Text(
            '${file.size} • ${file.dateModified}',
            style: iOS18Typography.caption2.copyWith(
              color: iOS18Colors.getTextSecondary(context),
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          if (file.isUploading) ...
            [
              SizedBox(height: iOS18Spacing.sm),
              _buildProgressBar(file.progress),
            ],
        ],
      ),
    );
  }

  Widget _buildProgressBar(double progress) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Uploading...',
              style: iOS18Typography.caption2.copyWith(
                color: iOS18Colors.systemBlue,
              ),
            ),
            Text(
              '${(progress * 100).toInt()}%',
              style: iOS18Typography.caption2.copyWith(
                color: iOS18Colors.systemBlue,
              ),
            ),
          ],
        ),
        SizedBox(height: iOS18Spacing.xs / 2),
        Container(
          height: 4,
          decoration: BoxDecoration(
            color: iOS18Colors.getTextTertiary(context).withOpacity(0.3),
            borderRadius: BorderRadius.circular(2),
          ),
          child: FractionallySizedBox(
            alignment: Alignment.centerLeft,
            widthFactor: progress,
            child: Container(
              decoration: BoxDecoration(
                gradient: iOS18Colors.deviceGradient,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildActionButton(
    String title,
    IconData icon,
    Color color,
    VoidCallback onPressed,
  ) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        padding: EdgeInsets.symmetric(
          vertical: iOS18Spacing.lg,
          horizontal: iOS18Spacing.md,
        ),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [color, color.withOpacity(0.8)],
          ),
          borderRadius: BorderRadius.circular(iOS18Spacing.radiusMD),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.3),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 20,
              color: Colors.white,
            ),
            SizedBox(width: iOS18Spacing.sm),
            Text(
              title,
              style: iOS18Typography.callout.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showFileOptions(dynamic file) {
    // Handle both FileItem and ReceivedFileInfo
    final fileName = file is ReceivedFileInfo ? file.name : (file as FileItem).name;
    final filePath = file is ReceivedFileInfo ? file.path : null;
    
    showCupertinoModalPopup(
      context: context,
      builder: (context) => CupertinoActionSheet(
        title: Text(fileName),
        actions: [
          if (file is ReceivedFileInfo) ...
            [
              CupertinoActionSheetAction(
                onPressed: () {
                  Navigator.pop(context);
                  _previewFile(file);
                },
                child: const Text('Preview'),
              ),
              CupertinoActionSheetAction(
                onPressed: () async {
                  Navigator.pop(context);
                  // Share file functionality
                },
                child: const Text('Share'),
              ),
              CupertinoActionSheetAction(
                isDestructiveAction: true,
                onPressed: () async {
                  Navigator.pop(context);
                  final fileOps = ref.read(fileOperationsServiceProvider);
                  await fileOps.deleteFile(file.path);
                  ref.refresh(receivedFilesProvider);
                  ref.refresh(storageInfoProvider);
                },
                child: const Text('Delete'),
              ),
            ],
        ],
        cancelButton: CupertinoActionSheetAction(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
      ),
    );
  }
  
  void _previewFile(ReceivedFileInfo file) {
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: Text(file.name),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 16),
            Icon(
              _getFileIcon(FileOperationsService.getFileCategory(file.extension)),
              size: 64,
              color: iOS18Colors.systemBlue,
            ),
            const SizedBox(height: 16),
            Text('Size: ${FileOperationsService.formatBytes(file.size)}'),
            Text('Received: ${_formatDate(file.receivedAt)}'),
            Text('Type: ${file.extension.toUpperCase()}'),
            const SizedBox(height: 8),
            Text(
              'Path: ${file.path}',
              style: iOS18Typography.caption2.copyWith(
                color: iOS18Colors.getTextTertiary(context),
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
        actions: [
          CupertinoDialogAction(
            child: const Text('Open File'),
            onPressed: () async {
              Navigator.pop(context);
              await _openFile(file);
            },
          ),
          CupertinoDialogAction(
            child: const Text('Close'),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }
  
  
  Future<void> _openFile(ReceivedFileInfo file) async {
    try {
      if (Platform.isAndroid) {
        // Use platform channel to open file with Android Intent
        const platform = MethodChannel('com.nardele.airdrop_app/file_opener');
        try {
          await platform.invokeMethod('openFile', {
            'path': file.path,
            'mimeType': _getMimeType(file.extension),
          });
        } on PlatformException catch (e) {
          print('[FilesScreen] Platform error: ${e.message}');
          _showError('Could not open file: ${e.message}');
        }
      } else {
        // For other platforms, try url_launcher
        final fileUri = Uri.file(file.path);
        if (await canLaunchUrl(fileUri)) {
          await launchUrl(fileUri, mode: LaunchMode.externalApplication);
        } else {
          _showError('Cannot open this file type');
        }
      }
    } catch (e) {
      print('[FilesScreen] Error opening file: $e');
      _showError('Failed to open file: ${e.toString()}');
    }
  }
  
  String _getMimeType(String extension) {
    final ext = extension.toLowerCase();
    // Images
    if (['jpg', 'jpeg'].contains(ext)) return 'image/jpeg';
    if (ext == 'png') return 'image/png';
    if (ext == 'gif') return 'image/gif';
    if (ext == 'webp') return 'image/webp';
    // Videos
    if (ext == 'mp4') return 'video/mp4';
    if (ext == 'avi') return 'video/x-msvideo';
    if (ext == 'mkv') return 'video/x-matroska';
    // Audio
    if (ext == 'mp3') return 'audio/mpeg';
    if (ext == 'wav') return 'audio/wav';
    if (ext == 'ogg') return 'audio/ogg';
    // Documents
    if (ext == 'pdf') return 'application/pdf';
    if (ext == 'doc') return 'application/msword';
    if (ext == 'docx') return 'application/vnd.openxmlformats-officedocument.wordprocessingml.document';
    if (ext == 'txt') return 'text/plain';
    // Default
    return 'application/octet-stream';
  }
  
  void _showError(String message) {
    if (!mounted) return;
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('Error'),
        content: Text(message),
        actions: [
          CupertinoDialogAction(
            child: const Text('OK'),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }
  
  LinearGradient _getFileGradient(FileCategory category) {
    switch (category) {
      case FileCategory.image:
        return const LinearGradient(colors: [Color(0xFF5856D6), Color(0xFFAF52DE)]);
      case FileCategory.video:
        return const LinearGradient(colors: [Color(0xFF007AFF), Color(0xFF5856D6)]);
      case FileCategory.audio:
        return const LinearGradient(colors: [Color(0xFF28CD41), Color(0xFF007AFF)]);
      case FileCategory.document:
        return const LinearGradient(colors: [Color(0xFFFF3B30), Color(0xFFFF9500)]);
      case FileCategory.other:
        return const LinearGradient(colors: [Color(0xFF8E8E93), Color(0xFF6D6D70)]);
    }
  }
  
  IconData _getFileIcon(FileCategory category) {
    switch (category) {
      case FileCategory.image:
        return CupertinoIcons.photo;
      case FileCategory.video:
        return CupertinoIcons.videocam;
      case FileCategory.audio:
        return CupertinoIcons.music_note;
      case FileCategory.document:
        return CupertinoIcons.doc_text;
      case FileCategory.other:
        return CupertinoIcons.doc;
    }
  }
  
  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);
    
    if (difference.inDays == 0) {
      return 'Today ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }

  Widget _buildStorageRow(String label, String size, Color color) {
    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        SizedBox(width: iOS18Spacing.sm),
        Expanded(
          child: Text(
            label,
            style: iOS18Typography.caption1.copyWith(
              color: iOS18Colors.getTextPrimary(context),
            ),
          ),
        ),
        Text(
          size,
          style: iOS18Typography.caption1.copyWith(
            color: iOS18Colors.getTextSecondary(context),
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Future<void> _handleUpload() async {
    HapticFeedback.lightImpact();
    final result = await FilePicker.platform.pickFiles(
      allowMultiple: true,
    );

    if (result != null && result.files.isNotEmpty) {
      // Show confirmation
      if (!mounted) return;
      
      showCupertinoDialog(
        context: context,
        builder: (context) => CupertinoAlertDialog(
          title: const Text('Files Selected'),
          content: Text('${result.files.length} file(s) ready to upload'),
          actions: [
            CupertinoDialogAction(
              child: const Text('Cancel'),
              onPressed: () => Navigator.pop(context),
            ),
            CupertinoDialogAction(
              isDefaultAction: true,
              child: const Text('Upload'),
              onPressed: () async {
                Navigator.pop(context);
                // Simulate upload
                for (final file in result.files) {
                  // In real app, would save file to storage
                  await Future.delayed(const Duration(milliseconds: 500));
                }
                // Refresh providers
                ref.refresh(receivedFilesProvider);
                ref.refresh(storageInfoProvider);
              },
            ),
          ],
        ),
      );
    }
  }
}

// File models
class FileItem {
  final String name;
  final FileType type;
  final String size;
  final String dateModified;
  final double progress;
  final bool isUploading;

  FileItem({
    required this.name,
    required this.type,
    required this.size,
    required this.dateModified,
    required this.progress,
    this.isUploading = false,
  });
}

enum FileType {
  pdf,
  image,
  video,
  audio,
  document,
  presentation,
  archive;

  IconData get icon {
    switch (this) {
      case FileType.pdf:
        return CupertinoIcons.doc_text;
      case FileType.image:
        return CupertinoIcons.photo;
      case FileType.video:
        return CupertinoIcons.videocam;
      case FileType.audio:
        return CupertinoIcons.music_note;
      case FileType.document:
        return CupertinoIcons.doc;
      case FileType.presentation:
        return CupertinoIcons.graph_square;
      case FileType.archive:
        return CupertinoIcons.archivebox;
    }
  }

  LinearGradient get gradient {
    switch (this) {
      case FileType.pdf:
        return const LinearGradient(colors: [Color(0xFFFF3B30), Color(0xFFFF9500)]);
      case FileType.image:
        return const LinearGradient(colors: [Color(0xFF5856D6), Color(0xFFAF52DE)]);
      case FileType.video:
        return const LinearGradient(colors: [Color(0xFF007AFF), Color(0xFF5856D6)]);
      case FileType.audio:
        return const LinearGradient(colors: [Color(0xFF28CD41), Color(0xFF007AFF)]);
      case FileType.document:
        return const LinearGradient(colors: [Color(0xFF007AFF), Color(0xFF5856D6)]);
      case FileType.presentation:
        return const LinearGradient(colors: [Color(0xFFFF9500), Color(0xFFFF2D92)]);
      case FileType.archive:
        return const LinearGradient(colors: [Color(0xFF8E8E93), Color(0xFF6D6D70)]);
    }
  }
}

// Extension for gradient scaling (already exists in home_screen.dart)
extension GradientExtension on LinearGradient {
  LinearGradient scale(double opacity) {
    return LinearGradient(
      begin: begin,
      end: end,
      colors: colors.map((color) => color.withOpacity(opacity)).toList(),
      stops: stops,
    );
  }
}
