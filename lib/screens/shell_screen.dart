import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import '../theme/app_theme.dart';
import 'home/home_screen.dart';
import 'library/library_screen.dart';
import 'upcoming/upcoming_screen.dart';
import 'files/files_screen.dart';
import 'capture/capture_screen.dart';
import 'settings/settings_screen.dart';

class ShellScreen extends StatelessWidget {
  const ShellScreen({super.key});

  // Settings is index 5, accessed via gear icon on home
  static const _screens = [
    HomeScreen(),      // 0
    LibraryScreen(),   // 1
    UpcomingScreen(),  // 2
    FilesScreen(),     // 3
    CaptureScreen(),   // 4
    SettingsScreen(),  // 5
  ];

  @override
  Widget build(BuildContext context) {
    return Consumer<AppProvider>(
      builder: (context, provider, _) {
        return Scaffold(
          backgroundColor: MijigiColors.background,
          body: IndexedStack(
            index: provider.currentTab,
            children: _screens,
          ),
          bottomNavigationBar: Container(
            decoration: const BoxDecoration(
              color: MijigiColors.surface,
              border: Border(
                top: BorderSide(color: MijigiColors.border, width: 0.5),
              ),
            ),
            child: SafeArea(
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _NavItem(
                      icon: Icons.home_rounded,
                      label: 'Home',
                      isActive: provider.currentTab == 0,
                      onTap: () => provider.setTab(0),
                    ),
                    _NavItem(
                      icon: Icons.layers_rounded,
                      label: 'Library',
                      isActive: provider.currentTab == 1,
                      onTap: () => provider.setTab(1),
                    ),
                    _CaptureNavItem(
                      isActive: provider.currentTab == 4,
                      onTap: () => provider.setTab(4),
                    ),
                    _NavItem(
                      icon: Icons.schedule_rounded,
                      label: 'Upcoming',
                      isActive: provider.currentTab == 2,
                      badgeCount: provider.hasAlerts
                          ? provider.expiredDeadlines.length +
                              provider.urgentDeadlines.length
                          : 0,
                      onTap: () => provider.setTab(2),
                    ),
                    _NavItem(
                      icon: Icons.folder_rounded,
                      label: 'Files',
                      isActive: provider.currentTab == 3,
                      onTap: () => provider.setTab(3),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isActive;
  final int badgeCount;
  final VoidCallback onTap;

  const _NavItem({
    required this.icon,
    required this.label,
    required this.isActive,
    this.badgeCount = 0,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: 58,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                  decoration: BoxDecoration(
                    color: isActive
                        ? MijigiColors.primary.withValues(alpha: 0.12)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    icon,
                    size: 22,
                    color: isActive
                        ? MijigiColors.primary
                        : MijigiColors.textTertiary,
                  ),
                ),
                if (badgeCount > 0)
                  Positioned(
                    right: 6,
                    top: -2,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 5, vertical: 2),
                      decoration: BoxDecoration(
                        color: MijigiColors.error,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '$badgeCount',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color:
                    isActive ? MijigiColors.primary : MijigiColors.textTertiary,
                fontSize: 10,
                fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CaptureNavItem extends StatelessWidget {
  final bool isActive;
  final VoidCallback onTap;

  const _CaptureNavItem({
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: 44,
            height: 34,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: isActive
                    ? [MijigiColors.primary, MijigiColors.primaryLight]
                    : [
                        MijigiColors.primary.withValues(alpha: 0.6),
                        MijigiColors.primaryLight.withValues(alpha: 0.6),
                      ],
              ),
              borderRadius: BorderRadius.circular(12),
              boxShadow: isActive
                  ? [
                      BoxShadow(
                        color: MijigiColors.primary.withValues(alpha: 0.3),
                        blurRadius: 12,
                        offset: const Offset(0, 2),
                      ),
                    ]
                  : null,
            ),
            child: const Icon(
              Icons.add_rounded,
              color: Colors.white,
              size: 22,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Capture',
            style: TextStyle(
              color:
                  isActive ? MijigiColors.primary : MijigiColors.textTertiary,
              fontSize: 10,
              fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
