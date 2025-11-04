import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../core/design_system/ios18_theme.dart';
import '../core/widgets/glassmorphic_card.dart';
import '../core/platform/platform_adapter.dart';

class FeaturesStatusScreen extends StatelessWidget {
  const FeaturesStatusScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isDark = MediaQuery.of(context).platformBrightness == Brightness.dark;
    final backgroundColor = isDark ? const Color(0xFF000000) : iOS18Colors.backgroundPrimary;
    
    return CupertinoPageScaffold(
      backgroundColor: backgroundColor,
      child: SafeArea(
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            // Header
            SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.all(iOS18Spacing.lg),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        GestureDetector(
                          onTap: () => Navigator.of(context).pop(),
                          child: Container(
                            padding: EdgeInsets.all(iOS18Spacing.sm),
                            decoration: BoxDecoration(
                              color: iOS18Colors.getTextTertiary(context).withOpacity(0.2),
                              borderRadius: BorderRadius.circular(iOS18Spacing.radiusSM),
                            ),
                            child: Icon(
                              CupertinoIcons.back,
                              size: 24,
                              color: iOS18Colors.getTextPrimary(context),
                            ),
                          ),
                        ),
                        SizedBox(width: iOS18Spacing.md),
                        Text(
                          'Advanced Features',
                          style: iOS18Typography.title1.copyWith(
                            color: isDark ? Colors.white : Colors.black,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: iOS18Spacing.sm),
                    Text(
                      '${_getAllFeatures().where((f) => f.isImplemented).length}/${_getAllFeatures().length} Features Implemented',
                      style: iOS18Typography.body.copyWith(
                        color: isDark ? Colors.white70 : iOS18Colors.getTextSecondary(context),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Phase 1: Advanced Connectivity
            _buildPhaseSection(
              context,
              'Phase 1: Advanced Connectivity',
              'Multi-protocol networking without WiFi dependency',
              [
                FeatureItem(
                  title: 'WiFi Direct Transport',
                  description: 'Peer-to-peer connection without router',
                  isImplemented: true,
                  isAvailable: PlatformAdapter.supportsWiFiDirect,
                  icon: CupertinoIcons.wifi,
                ),
                FeatureItem(
                  title: 'Bluetooth Mesh Networking',
                  description: 'Multi-hop mesh for extended range',
                  isImplemented: true,
                  isAvailable: PlatformAdapter.supportsBluetooth,
                  icon: CupertinoIcons.antenna_radiowaves_left_right,
                ),
                FeatureItem(
                  title: 'Hybrid Connection Manager',
                  description: 'Intelligent protocol switching',
                  isImplemented: true,
                  isAvailable: true,
                  icon: CupertinoIcons.shuffle,
                ),
                FeatureItem(
                  title: 'WebRTC Fallback',
                  description: 'Browser-based P2P connection',
                  isImplemented: true,
                  isAvailable: true,
                  icon: CupertinoIcons.globe,
                ),
              ],
            ),

            // Phase 2: File Transfer Optimization
            _buildPhaseSection(
              context,
              'Phase 2: File Transfer Optimization',
              'Large file support with compression & resume',
              [
                FeatureItem(
                  title: 'Advanced File Chunking',
                  description: 'Adaptive chunk sizes with checksums',
                  isImplemented: true,
                  isAvailable: true,
                  icon: CupertinoIcons.doc_on_doc,
                ),
                FeatureItem(
                  title: 'Smart Compression Engine',
                  description: 'Format-aware compression (up to 70% savings)',
                  isImplemented: true,
                  isAvailable: true,
                  icon: CupertinoIcons.arrow_2_squarepath,
                ),
                FeatureItem(
                  title: 'Resume & Recovery',
                  description: 'Automatic retry with state persistence',
                  isImplemented: true,
                  isAvailable: PlatformAdapter.supportsFileSystem,
                  icon: CupertinoIcons.refresh,
                ),
              ],
            ),

            // Phase 3: AI & Social Features
            _buildPhaseSection(
              context,
              'Phase 3: AI & Social Features',
              'Smart categorization and user profiles',
              [
                FeatureItem(
                  title: 'AI Content Recognition',
                  description: 'ML-based file categorization & tagging',
                  isImplemented: true,
                  isAvailable: true,
                  icon: CupertinoIcons.lightbulb_fill,
                ),
                FeatureItem(
                  title: 'User Profile Manager',
                  description: 'Contact ratings, favorites & statistics',
                  isImplemented: true,
                  isAvailable: true,
                  icon: CupertinoIcons.person_2_fill,
                ),
                FeatureItem(
                  title: 'Smart Search',
                  description: 'Semantic search across transfers',
                  isImplemented: true,
                  isAvailable: true,
                  icon: CupertinoIcons.search,
                ),
              ],
            ),

            // Phase 4: Enhanced Security
            _buildPhaseSection(
              context,
              'Phase 4: Enhanced Security',
              'Military-grade encryption & authentication',
              [
                FeatureItem(
                  title: 'AES-256 Encryption',
                  description: 'End-to-end file encryption',
                  isImplemented: true,
                  isAvailable: true,
                  icon: CupertinoIcons.lock_shield_fill,
                ),
                FeatureItem(
                  title: 'RSA Key Exchange',
                  description: 'Secure 2048-bit key negotiation',
                  isImplemented: true,
                  isAvailable: true,
                  icon: CupertinoIcons.lock_fill,
                ),
                FeatureItem(
                  title: 'Biometric Authentication',
                  description: 'Face ID / Touch ID / Fingerprint',
                  isImplemented: true,
                  isAvailable: !PlatformAdapter.isWeb,
                  icon: CupertinoIcons.hand_raised_fill,
                ),
              ],
            ),

            // Platform Info
            SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.all(iOS18Spacing.lg),
                child: GlassmorphicCard(
                  child: Padding(
                    padding: EdgeInsets.all(iOS18Spacing.md),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              CupertinoIcons.device_phone_portrait,
                              color: iOS18Colors.systemBlue,
                              size: 20,
                            ),
                            SizedBox(width: iOS18Spacing.sm),
                            Text(
                              'Platform Information',
                              style: iOS18Typography.headline.copyWith(
                                color: isDark ? Colors.white : Colors.black,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: iOS18Spacing.md),
                        _buildInfoRow(context, 'Platform', PlatformAdapter.platformName),
                        _buildInfoRow(context, 'P2P Support', PlatformAdapter.supportsP2P ? 'Available' : 'Limited (Web)'),
                        _buildInfoRow(context, 'SQLite Support', PlatformAdapter.supportsSQLite ? 'Available' : 'Not Available'),
                        _buildInfoRow(context, 'TCP Sockets', PlatformAdapter.supportsTCP ? 'Available' : 'Not Available'),
                      ],
                    ),
                  ),
                ),
              ),
            ),

            SliverToBoxAdapter(
              child: Container(height: 120),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPhaseSection(
    BuildContext context,
    String title,
    String subtitle,
    List<FeatureItem> features,
  ) {
    final isDark = MediaQuery.of(context).platformBrightness == Brightness.dark;
    return SliverToBoxAdapter(
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: iOS18Spacing.lg,
          vertical: iOS18Spacing.sm,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: iOS18Typography.title2.copyWith(
                color: isDark ? Colors.white : Colors.black,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: iOS18Spacing.xs),
            Text(
              subtitle,
              style: iOS18Typography.body.copyWith(
                fontSize: 12,
                color: isDark ? Colors.white60 : iOS18Colors.getTextSecondary(context),
              ),
            ),
            SizedBox(height: iOS18Spacing.md),
            ...features.map((feature) => _buildFeatureCard(context, feature)),
          ],
        ),
      ),
    );
  }

  Widget _buildFeatureCard(BuildContext context, FeatureItem feature) {
    final isDark = MediaQuery.of(context).platformBrightness == Brightness.dark;
    final statusColor = feature.isImplemented
        ? (feature.isAvailable ? iOS18Colors.systemGreen : Colors.orange)
        : (isDark ? Colors.white38 : iOS18Colors.getTextTertiary(context));

    return GlassmorphicCard(
      margin: EdgeInsets.only(bottom: iOS18Spacing.sm),
      child: Padding(
        padding: EdgeInsets.all(iOS18Spacing.md),
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.all(iOS18Spacing.sm),
              decoration: BoxDecoration(
                color: statusColor.withOpacity(0.2),
                borderRadius: BorderRadius.circular(iOS18Spacing.radiusSM),
              ),
              child: Icon(
                feature.icon,
                color: statusColor,
                size: 24,
              ),
            ),
            SizedBox(width: iOS18Spacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    feature.title,
                    style: iOS18Typography.headline.copyWith(
                      color: isDark ? Colors.white : Colors.black,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  SizedBox(height: iOS18Spacing.xs),
                  Text(
                    feature.description,
                    style: iOS18Typography.body.copyWith(
                      fontSize: 12,
                      color: isDark ? Colors.white60 : iOS18Colors.getTextSecondary(context),
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: EdgeInsets.symmetric(
                horizontal: iOS18Spacing.sm,
                vertical: iOS18Spacing.xs,
              ),
              decoration: BoxDecoration(
                color: statusColor.withOpacity(0.2),
                borderRadius: BorderRadius.circular(iOS18Spacing.radiusXS),
              ),
              child: Text(
                feature.isImplemented
                    ? (feature.isAvailable ? 'Active' : 'Limited')
                    : 'Planned',
                style: iOS18Typography.body.copyWith(
                  fontSize: 10,
                  color: statusColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(BuildContext context, String label, String value) {
    final isDark = MediaQuery.of(context).platformBrightness == Brightness.dark;
    return Padding(
      padding: EdgeInsets.symmetric(vertical: iOS18Spacing.xs),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: iOS18Typography.body.copyWith(
              color: isDark ? Colors.white60 : iOS18Colors.getTextSecondary(context),
            ),
          ),
          Text(
            value,
            style: iOS18Typography.body.copyWith(
              color: isDark ? Colors.white : Colors.black,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  List<FeatureItem> _getAllFeatures() {
    return [
      FeatureItem(title: 'WiFi Direct', description: '', isImplemented: true, isAvailable: true, icon: CupertinoIcons.wifi),
      FeatureItem(title: 'Bluetooth Mesh', description: '', isImplemented: true, isAvailable: true, icon: CupertinoIcons.antenna_radiowaves_left_right),
      FeatureItem(title: 'Hybrid Manager', description: '', isImplemented: true, isAvailable: true, icon: CupertinoIcons.shuffle),
      FeatureItem(title: 'File Chunking', description: '', isImplemented: true, isAvailable: true, icon: CupertinoIcons.doc_on_doc),
      FeatureItem(title: 'Compression', description: '', isImplemented: true, isAvailable: true, icon: CupertinoIcons.arrow_2_squarepath),
      FeatureItem(title: 'Resume/Recovery', description: '', isImplemented: true, isAvailable: true, icon: CupertinoIcons.refresh),
      FeatureItem(title: 'AI Recognition', description: '', isImplemented: true, isAvailable: true, icon: CupertinoIcons.lightbulb_fill),
      FeatureItem(title: 'User Profiles', description: '', isImplemented: true, isAvailable: true, icon: CupertinoIcons.person_2_fill),
      FeatureItem(title: 'AES Encryption', description: '', isImplemented: true, isAvailable: true, icon: CupertinoIcons.lock_shield_fill),
    ];
  }
}

class FeatureItem {
  final String title;
  final String description;
  final bool isImplemented;
  final bool isAvailable;
  final IconData icon;

  FeatureItem({
    required this.title,
    required this.description,
    required this.isImplemented,
    required this.isAvailable,
    required this.icon,
  });
}

