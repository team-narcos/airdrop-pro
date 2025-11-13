import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/design_system/ios18_theme.dart';
import '../core/widgets/glassmorphic_card.dart';
import '../core/widgets/success_rate_chart.dart';
import '../providers/history_provider.dart';

class HistoryScreen extends ConsumerStatefulWidget {
  const HistoryScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends ConsumerState<HistoryScreen>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  
  String _selectedFilter = 'All';
  
  // Derived from provider
  List<TransferRecord> get _records => ref.watch(transferHistoryProvider);
  
  final List<String> _filterOptions = ['All', 'Sent', 'Received', 'Failed'];

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
    final completedTransfers = _records.length;
    final totalSize = _records.fold<double>(0, (sum, r) => sum + (r.totalBytes / (1024*1024)));
    
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
              
              // Header
              FadeTransition(
                opacity: _fadeAnimation,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'History',
                          style: iOS18Typography.largeTitle.copyWith(
                            color: iOS18Colors.getTextPrimary(context),
                          ),
                        ),
                        SizedBox(height: iOS18Spacing.xs),
                        Text(
'${_records.length} transfers this session',
                          style: iOS18Typography.subheadline.copyWith(
                            color: iOS18Colors.getTextSecondary(context),
                          ),
                        ),
                      ],
                    ),
                    GestureDetector(
                      onTap: () {
                        HapticFeedback.mediumImpact();
                        _clearHistory();
                      },
                      child: Container(
                        padding: EdgeInsets.all(iOS18Spacing.sm),
                        decoration: BoxDecoration(
                          color: iOS18Colors.systemRed.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(iOS18Spacing.radiusSM),
                        ),
                        child: const Icon(
                          CupertinoIcons.clear,
                          size: 20,
                          color: iOS18Colors.systemRed,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              
              SizedBox(height: iOS18Spacing.xl),
              
              // Statistics cards
              SlideTransition(
                position: _slideAnimation,
                child: FadeTransition(
                  opacity: _fadeAnimation,
                  child: _buildStatisticsSection(completedTransfers, totalSize),
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
              
              // Transfer history
              _buildFilteredTransfersList(),
              
              // Bottom padding for navigation
              const SizedBox(height: 120),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatisticsSection(int completedTransfers, double totalSize) {
    final successRate = _records.isNotEmpty 
        ? (completedTransfers / _records.length * 100).toInt() 
        : 0;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Transfer Summary',
          style: iOS18Typography.title2.copyWith(
            color: iOS18Colors.getTextPrimary(context),
          ),
        ),
        SizedBox(height: iOS18Spacing.md),
        
        // Main summary card
        GlassmorphicCard(
          padding: EdgeInsets.all(iOS18Spacing.lg),
          gradient: iOS18Colors.historyGradient.scale(0.1),
          child: Row(
            children: [
              // Success rate circle
              SuccessRateChart(
                successRate: successRate / 100,
                size: 90,
              ),
              SizedBox(width: iOS18Spacing.lg),
              
              // Statistics
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildStatRow('Success Rate', '$successRate%'),
                    SizedBox(height: iOS18Spacing.sm),
                    _buildStatRow('Total Transfers', '${_records.length}'),
                    SizedBox(height: iOS18Spacing.sm),
                    _buildStatRow('Data Transferred', _formatSize(totalSize)),
                  ],
                ),
              ),
            ],
          ),
        ),
        
        SizedBox(height: iOS18Spacing.md),
        
        // Mini stat cards
        Row(
          children: [
            Expanded(
              child: _buildMiniStatCard(
                'Sent',
                '${_records.where((t) => t.success).length}',
                CupertinoIcons.arrow_up_circle,
                iOS18Colors.systemBlue,
              ),
            ),
            SizedBox(width: iOS18Spacing.md),
            Expanded(
              child: _buildMiniStatCard(
                'Received',
                '0',
                CupertinoIcons.arrow_down_circle,
                iOS18Colors.systemGreen,
              ),
            ),
            SizedBox(width: iOS18Spacing.md),
            Expanded(
              child: _buildMiniStatCard(
                'Failed',
                '${_records.where((t) => !t.success).length}',
                CupertinoIcons.xmark_circle,
                iOS18Colors.systemRed,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: iOS18Typography.callout.copyWith(
            color: Colors.white.withOpacity(0.9),
          ),
        ),
        Text(
          value,
          style: iOS18Typography.callout.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildMiniStatCard(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return GlassmorphicCard(
      padding: EdgeInsets.all(iOS18Spacing.md),
      child: Column(
        children: [
          Icon(
            icon,
            size: 24,
            color: color,
          ),
          SizedBox(height: iOS18Spacing.sm),
          Text(
            value,
            style: iOS18Typography.title3.copyWith(
              color: iOS18Colors.getTextPrimary(context),
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            label,
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
          gradient: isSelected ? iOS18Colors.historyGradient : null,
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
              gradient: iOS18Colors.historyGradient.scale(0.3),
              borderRadius: BorderRadius.circular(iOS18Spacing.radiusXL),
            ),
            child: const Icon(
              CupertinoIcons.time,
              size: 50,
              color: Colors.white,
            ),
          ),
          SizedBox(height: iOS18Spacing.lg),
          Text(
            'No Transfer History',
            style: iOS18Typography.title2.copyWith(
              color: iOS18Colors.getTextPrimary(context),
            ),
          ),
          SizedBox(height: iOS18Spacing.sm),
          Text(
            'Your AirDrop transfer history\nwill appear here',
            style: iOS18Typography.subheadline.copyWith(
              color: iOS18Colors.getTextSecondary(context),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }



  Widget _buildFilteredTransfersList() {
    List<TransferRecord> filteredRecords = _records;
    
    // Apply filter
    switch (_selectedFilter) {
      case 'Sent':
        filteredRecords = _records.where((r) => r.direction == TransferDirection.sent).toList();
        break;
      case 'Received':
        filteredRecords = _records.where((r) => r.direction == TransferDirection.received).toList();
        break;
      case 'Failed':
        filteredRecords = _records.where((r) => !r.success).toList();
        break;
      default:
        filteredRecords = _records;
    }
    
    if (filteredRecords.isEmpty) {
      return _buildEmptyState();
    }
    
    return Column(
      children: filteredRecords.map((r) => _buildRecordItem(r)).toList(),
    );
  }
  
  Widget _buildRecordItem(TransferRecord r) {
    return Padding(
      padding: EdgeInsets.only(bottom: iOS18Spacing.md),
      child: GlassmorphicCard(
        padding: EdgeInsets.all(iOS18Spacing.md),
        child: Row(
          children: [
            // File type icon
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                gradient: _getFileTypeGradient(r.fileName),
                borderRadius: BorderRadius.circular(iOS18Spacing.radiusMD),
                boxShadow: [
                  BoxShadow(
                    color: _getFileTypeColor(r.fileName).withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Icon(
                _getFileTypeIcon(r.fileName),
                color: Colors.white,
                size: 28,
              ),
            ),
            SizedBox(width: iOS18Spacing.md),
            
            // File info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          r.fileName,
                          style: iOS18Typography.bodyEmphasized.copyWith(
                            color: iOS18Colors.getTextPrimary(context),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      // Direction indicator
                      Icon(
                        r.direction == TransferDirection.sent 
                            ? CupertinoIcons.arrow_up_circle_fill
                            : CupertinoIcons.arrow_down_circle_fill,
                        color: r.direction == TransferDirection.sent 
                            ? iOS18Colors.systemBlue
                            : iOS18Colors.systemGreen,
                        size: 18,
                      ),
                    ],
                  ),
                  SizedBox(height: iOS18Spacing.xs / 2),
                  Row(
                    children: [
                      Text(
                        _formatBytes(r.totalBytes),
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
                        _formatTimestamp(r.timestamp),
                        style: iOS18Typography.caption1.copyWith(
                          color: iOS18Colors.getTextSecondary(context),
                        ),
                      ),
                    ],
                  ),
                  if (!r.success) ...[
                    SizedBox(height: iOS18Spacing.xs / 2),
                    Text(
                      'Failed',
                      style: iOS18Typography.caption2.copyWith(
                        color: iOS18Colors.systemRed,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  IconData _getFileTypeIcon(String fileName) {
    final extension = fileName.split('.').last.toLowerCase();
    switch (extension) {
      case 'jpg':
      case 'jpeg':
      case 'png':
      case 'gif':
      case 'webp':
        return CupertinoIcons.photo;
      case 'mp4':
      case 'mov':
      case 'avi':
      case 'mkv':
        return CupertinoIcons.videocam;
      case 'mp3':
      case 'wav':
      case 'm4a':
      case 'flac':
        return CupertinoIcons.music_note;
      case 'pdf':
        return CupertinoIcons.doc_text;
      case 'zip':
      case 'rar':
      case '7z':
        return CupertinoIcons.archivebox;
      case 'doc':
      case 'docx':
      case 'txt':
        return CupertinoIcons.doc;
      default:
        return CupertinoIcons.doc;
    }
  }
  
  LinearGradient _getFileTypeGradient(String fileName) {
    final extension = fileName.split('.').last.toLowerCase();
    switch (extension) {
      case 'jpg':
      case 'jpeg':
      case 'png':
      case 'gif':
      case 'webp':
        return const LinearGradient(colors: [Color(0xFFFF3B30), Color(0xFFFF9500)]);
      case 'mp4':
      case 'mov':
      case 'avi':
      case 'mkv':
        return const LinearGradient(colors: [Color(0xFF5856D6), Color(0xFFAF52DE)]);
      case 'mp3':
      case 'wav':
      case 'm4a':
      case 'flac':
        return const LinearGradient(colors: [Color(0xFFFF2D55), Color(0xFFAF52DE)]);
      case 'pdf':
        return const LinearGradient(colors: [Color(0xFFFF3B30), Color(0xFFFF2D55)]);
      case 'zip':
      case 'rar':
      case '7z':
        return const LinearGradient(colors: [Color(0xFF5AC8FA), Color(0xFF007AFF)]);
      default:
        return iOS18Colors.historyGradient;
    }
  }
  
  Color _getFileTypeColor(String fileName) {
    final extension = fileName.split('.').last.toLowerCase();
    switch (extension) {
      case 'jpg':
      case 'jpeg':
      case 'png':
      case 'gif':
      case 'webp':
        return const Color(0xFFFF3B30);
      case 'mp4':
      case 'mov':
      case 'avi':
      case 'mkv':
        return const Color(0xFF5856D6);
      case 'mp3':
      case 'wav':
      case 'm4a':
      case 'flac':
        return const Color(0xFFFF2D55);
      default:
        return iOS18Colors.systemBlue;
    }
  }
  
  String _formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(2)} GB';
  }
  
  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);
    if (difference.inMinutes < 60) return '${difference.inMinutes}m ago';
    if (difference.inHours < 24) return '${difference.inHours}h ago';
    return '${difference.inDays}d ago';
  }

  String _formatSize(double sizeInMB) {
    if (sizeInMB < 1024) return '${sizeInMB.toStringAsFixed(1)} MB';
    return '${(sizeInMB / 1024).toStringAsFixed(1)} GB';
  }

  void _clearHistory() {
    ref.read(transferHistoryProvider.notifier).clear();
    setState(() {});
  }
}

// Extension for gradient scaling (already exists in files_screen.dart)
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
