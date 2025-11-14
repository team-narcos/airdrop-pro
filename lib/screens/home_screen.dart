import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/widgets/premium_bottom_nav.dart';
import '../core/widgets/enterprise_animated_background.dart';
import 'files_screen.dart';
import 'history_screen.dart';
import 'settings_screen.dart';
import 'new_share_tab.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  int _selectedIndex = 0;

  final List<Widget> _screens = [
    const NewShareTab(),
    const FilesScreen(),
    const HistoryScreen(),
    const SettingsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      backgroundColor: Colors.transparent,
      child: EnterpriseAnimatedBackground(
        child: Stack(
          children: [
            // Main content
            _screens[_selectedIndex],
          // Premium bottom navigation
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: PremiumBottomNavigation(
              currentIndex: _selectedIndex,
              onTap: (index) {
                setState(() {
                  _selectedIndex = index;
                });
              },
              items: const [
                PremiumBottomNavItem(
                  icon: CupertinoIcons.arrow_up_doc,
                  label: 'Share',
                ),
                PremiumBottomNavItem(
                  icon: CustomNavIcons.files,
                  label: 'Files',
                ),
                PremiumBottomNavItem(
                  icon: CustomNavIcons.history,
                  label: 'History',
                ),
                PremiumBottomNavItem(
                  icon: CustomNavIcons.settings,
                  label: 'Settings',
                ),
              ],
            ),
          ),
          ],
        ),
      ),
    );
  }
}
