import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import '../theme/app_theme.dart';
import 'photos/photos_screen.dart';
import 'scanner/scanner_tab_screen.dart';
import 'files/files_screen.dart';
import 'clipboard/clipboard_screen.dart';

class ShellScreen extends StatefulWidget {
  const ShellScreen({super.key});

  @override
  State<ShellScreen> createState() => _ShellScreenState();
}

class _ShellScreenState extends State<ShellScreen> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // App came to foreground
      context.read<AppProvider>().checkClipboardNow();
    }
  }

  static const _screens = [
    PhotosScreen(),      // 0
    ScannerTabScreen(),  // 1
    FilesScreen(),       // 2
    ClipboardScreen(),   // 3
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
            decoration: BoxDecoration(
              color: const Color(0xFF0A0E14),
              border: const Border(
                top: BorderSide(color: Color(0xFF1A1F28), width: 0.5),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.5),
                  blurRadius: 24,
                  offset: const Offset(0, -6),
                ),
              ],
            ),
            child: SafeArea(
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
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
                      icon: Icons.document_scanner_rounded,
                      label: 'Scanner',
                      isActive: provider.currentTab == 1,
                      onTap: () => provider.setTab(1),
                    ),
                    _NavItem(
                      icon: Icons.folder_rounded,
                      label: 'Docs',
                      isActive: provider.currentTab == 2,
                      onTap: () => provider.setTab(2),
                    ),
                    _NavItem(
                      icon: Icons.content_paste_rounded,
                      label: 'Clipboard',
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
        width: 72,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeOutCubic,
              padding:
                  const EdgeInsets.symmetric(horizontal: 18, vertical: 7),
              decoration: BoxDecoration(
                color: isActive
                    ? MijigiColors.primary.withValues(alpha: 0.10)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(
                icon,
                size: 22,
                color: isActive
                    ? MijigiColors.primaryLight
                    : MijigiColors.textTertiary,
              ),
            ),
            const SizedBox(height: 5),
            Text(
              label,
              style: TextStyle(
                color: isActive
                    ? MijigiColors.primaryLight
                    : MijigiColors.textTertiary,
                fontSize: 10,
                fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
                letterSpacing: 0.2,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
