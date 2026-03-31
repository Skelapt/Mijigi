import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import '../theme/app_theme.dart';
import 'photos/photos_screen.dart';
import 'clipboard/clipboard_screen.dart';
import 'files/files_screen.dart';

class ShellScreen extends StatelessWidget {
  const ShellScreen({super.key});

  static const _screens = [
    PhotosScreen(),    // 0
    ClipboardScreen(), // 1
    FilesScreen(),     // 2
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
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _NavItem(
                      icon: Icons.photo_library_rounded,
                      label: 'Photos',
                      isActive: provider.currentTab == 0,
                      onTap: () => provider.setTab(0),
                    ),
                    _NavItem(
                      icon: Icons.content_paste_rounded,
                      label: 'Clipboard',
                      isActive: provider.currentTab == 1,
                      onTap: () => provider.setTab(1),
                    ),
                    _NavItem(
                      icon: Icons.folder_rounded,
                      label: 'Files',
                      isActive: provider.currentTab == 2,
                      onTap: () => provider.setTab(2),
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
  final VoidCallback onTap;

  const _NavItem({
    required this.icon,
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: 70,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
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
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: isActive
                    ? MijigiColors.primary
                    : MijigiColors.textTertiary,
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
