import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/agent_models.dart';
import '../../providers/agent_provider.dart';
import '../../providers/app_provider.dart';
import '../../theme/app_theme.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AppProvider>(
      builder: (context, provider, _) {
        return CustomScrollView(
          slivers: [
            const SliverToBoxAdapter(child: SizedBox(height: 60)),
            const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 20),
                child: Text(
                  'Settings',
                  style: TextStyle(
                    color: MijigiColors.textPrimary,
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.5,
                  ),
                ),
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 24)),

            // Stats card
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        MijigiColors.primary.withValues(alpha: 0.15),
                        MijigiColors.accent.withValues(alpha: 0.08),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: MijigiColors.primary.withValues(alpha: 0.2),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Your Data',
                        style: TextStyle(
                          color: MijigiColors.textPrimary,
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          _StatItem(
                            label: 'Items',
                            value: '${provider.totalItems}',
                            icon: Icons.layers_rounded,
                          ),
                          const SizedBox(width: 24),
                          _StatItem(
                            label: 'Categories',
                            value: '${provider.activeCategories.length}',
                            icon: Icons.category_rounded,
                          ),
                          const SizedBox(width: 24),
                          _StatItem(
                            label: 'Pinned',
                            value: '${provider.pinnedItems.length}',
                            icon: Icons.push_pin_rounded,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 24)),

            // Settings sections
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSectionTitle('AI Agent'),
                    const SizedBox(height: 8),
                    Consumer<AgentProvider>(
                      builder: (context, agent, _) {
                        return _buildSettingsGroup([
                          _SettingsTile(
                            icon: Icons.auto_awesome_rounded,
                            title: 'API Configuration',
                            subtitle: agent.isConfigured
                                ? 'Connected'
                                : 'Not configured',
                            color: agent.isConfigured
                                ? MijigiColors.accent
                                : null,
                            onTap: () => _showApiConfig(context, agent),
                          ),
                        ]);
                      },
                    ),

                    const SizedBox(height: 20),
                    _buildSectionTitle('General'),
                    const SizedBox(height: 8),
                    _buildSettingsGroup([
                      _SettingsTile(
                        icon: Icons.notifications_rounded,
                        title: 'Notifications',
                        subtitle: 'Reminders & alerts',
                        onTap: () {},
                      ),
                      _SettingsTile(
                        icon: Icons.palette_rounded,
                        title: 'Appearance',
                        subtitle: 'Dark mode',
                        onTap: () {},
                      ),
                    ]),

                    const SizedBox(height: 20),
                    _buildSectionTitle('Data'),
                    const SizedBox(height: 8),
                    _buildSettingsGroup([
                      _SettingsTile(
                        icon: Icons.photo_library_rounded,
                        title: 'Scan Gallery',
                        subtitle: provider.isImporting
                            ? 'Importing...'
                            : 'Import all device photos',
                        color: MijigiColors.accent,
                        onTap: provider.isImporting
                            ? () {}
                            : () => _startGalleryScan(context, provider),
                      ),
                      _SettingsTile(
                        icon: Icons.cloud_upload_rounded,
                        title: 'Backup',
                        subtitle: 'Export your data',
                        onTap: () {},
                      ),
                      _SettingsTile(
                        icon: Icons.download_rounded,
                        title: 'Import',
                        subtitle: 'Import from backup',
                        onTap: () {},
                      ),
                      _SettingsTile(
                        icon: Icons.delete_sweep_rounded,
                        title: 'Clear Data',
                        subtitle: 'Delete all items',
                        color: MijigiColors.error,
                        onTap: () => _confirmClearData(context, provider),
                      ),
                    ]),

                    const SizedBox(height: 20),
                    _buildSectionTitle('About'),
                    const SizedBox(height: 8),
                    _buildSettingsGroup([
                      _SettingsTile(
                        icon: Icons.info_rounded,
                        title: 'About Mijigi',
                        subtitle: 'Version 1.0.0',
                        onTap: () {},
                      ),
                      _SettingsTile(
                        icon: Icons.privacy_tip_rounded,
                        title: 'Privacy',
                        subtitle: 'Your data stays on device',
                        onTap: () {},
                      ),
                    ]),
                  ],
                ),
              ),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 32)),

            // Footer
            const SliverToBoxAdapter(
              child: Center(
                child: Column(
                  children: [
                    Text(
                      'Mijigi',
                      style: TextStyle(
                        color: MijigiColors.textTertiary,
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Capture anything. Find everything.',
                      style: TextStyle(
                        color: MijigiColors.textTertiary,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 100)),
          ],
        );
      },
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        color: MijigiColors.textTertiary,
        fontSize: 13,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.5,
      ),
    );
  }

  Widget _buildSettingsGroup(List<_SettingsTile> tiles) {
    return Container(
      decoration: BoxDecoration(
        color: MijigiColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: MijigiColors.border),
      ),
      child: Column(
        children: [
          for (int i = 0; i < tiles.length; i++) ...[
            tiles[i],
            if (i < tiles.length - 1)
              const Divider(
                color: MijigiColors.border,
                height: 1,
                indent: 56,
              ),
          ],
        ],
      ),
    );
  }

  void _startGalleryScan(BuildContext context, AppProvider provider) async {
    final hasPermission = await provider.requestPhotoPermission();
    if (!hasPermission) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Photo access denied. Enable in Settings.'),
            backgroundColor: MijigiColors.surfaceLight,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
      return;
    }

    provider.importDevicePhotos();
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Scanning gallery... Check Home for progress.'),
          backgroundColor: MijigiColors.surfaceLight,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10)),
        ),
      );
    }
  }

  void _confirmClearData(BuildContext context, AppProvider provider) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: MijigiColors.surface,
        title: const Text(
          'Clear All Data?',
          style: TextStyle(color: MijigiColors.textPrimary),
        ),
        content: const Text(
          'This will permanently delete all your captured items. This cannot be undone.',
          style: TextStyle(color: MijigiColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              // TODO: Implement clear all
            },
            child: const Text(
              'Delete All',
              style: TextStyle(color: MijigiColors.error),
            ),
          ),
        ],
      ),
    );
  }

  void _showApiConfig(BuildContext context, AgentProvider agent) {
    final endpointController =
        TextEditingController(text: agent.config.apiEndpoint ?? '');
    final keyController =
        TextEditingController(text: agent.config.apiKey ?? '');

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: MijigiColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          left: 20,
          right: 20,
          top: 16,
          bottom: MediaQuery.of(ctx).viewInsets.bottom + 16,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 36,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: MijigiColors.textTertiary.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const Text(
              'AI Agent API',
              style: TextStyle(
                color: MijigiColors.textPrimary,
                fontSize: 20,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Connect your AI backend to unlock intelligent commands, smart organisation, and natural language search.',
              style: TextStyle(
                color: MijigiColors.textTertiary,
                fontSize: 13,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: endpointController,
              style: const TextStyle(color: MijigiColors.textPrimary),
              decoration: const InputDecoration(
                hintText: 'API Endpoint URL',
                prefixIcon: Icon(Icons.link_rounded,
                    color: MijigiColors.textTertiary, size: 20),
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: keyController,
              obscureText: true,
              style: const TextStyle(color: MijigiColors.textPrimary),
              decoration: const InputDecoration(
                hintText: 'API Key',
                prefixIcon: Icon(Icons.key_rounded,
                    color: MijigiColors.textTertiary, size: 20),
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                agent.updateConfig(AgentConfig(
                  apiEndpoint: endpointController.text.trim(),
                  apiKey: keyController.text.trim(),
                ));
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: const Text('API configured'),
                    backgroundColor: MijigiColors.surfaceLight,
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: MijigiColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: const Text(
                'Save',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color? color;
  final VoidCallback onTap;

  const _SettingsTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Icon(icon, color: color ?? MijigiColors.textSecondary, size: 22),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: color ?? MijigiColors.textPrimary,
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      color: MijigiColors.textTertiary,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              color: MijigiColors.textTertiary.withValues(alpha: 0.5),
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;

  const _StatItem({
    required this.label,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 14, color: MijigiColors.textTertiary),
            const SizedBox(width: 4),
            Text(
              label,
              style: const TextStyle(
                color: MijigiColors.textTertiary,
                fontSize: 12,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            color: MijigiColors.textPrimary,
            fontSize: 22,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }
}
