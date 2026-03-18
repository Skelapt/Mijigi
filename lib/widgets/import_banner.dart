import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import '../services/photo_import_service.dart';
import '../theme/app_theme.dart';

class ImportBanner extends StatelessWidget {
  const ImportBanner({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AppProvider>(
      builder: (context, provider, _) {
        // Show import progress if importing
        if (provider.isImporting && provider.importProgress != null) {
          return _buildProgressBanner(provider);
        }

        // Show import prompt if no items yet
        if (provider.totalItems == 0) {
          return _buildImportPrompt(context, provider);
        }

        return const SizedBox.shrink();
      },
    );
  }

  Widget _buildImportPrompt(BuildContext context, AppProvider provider) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            MijigiColors.accent.withValues(alpha: 0.12),
            MijigiColors.primary.withValues(alpha: 0.08),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: MijigiColors.accent.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: MijigiColors.accent.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.photo_library_rounded,
                  color: MijigiColors.accent,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Import your photos',
                      style: TextStyle(
                        color: MijigiColors.textPrimary,
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'Scan your gallery to make everything searchable',
                      style: TextStyle(
                        color: MijigiColors.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () => _startImport(context, provider),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [MijigiColors.accent, MijigiColors.primary],
                      ),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Center(
                      child: Text(
                        'Scan Gallery',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildProgressBanner(AppProvider provider) {
    final progress = provider.importProgress!;
    final isComplete = progress.status == ImportStatus.complete;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: MijigiColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isComplete
              ? MijigiColors.accent.withValues(alpha: 0.3)
              : MijigiColors.primary.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (!isComplete)
                SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    value: progress.progress > 0 ? progress.progress : null,
                    color: MijigiColors.primary,
                  ),
                )
              else
                const Icon(
                  Icons.check_circle_rounded,
                  color: MijigiColors.accent,
                  size: 20,
                ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  progress.message,
                  style: TextStyle(
                    color: isComplete
                        ? MijigiColors.accent
                        : MijigiColors.textPrimary,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          if (!isComplete && progress.total > 0) ...[
            const SizedBox(height: 10),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: progress.progress,
                backgroundColor: MijigiColors.surfaceLight,
                color: MijigiColors.primary,
                minHeight: 4,
              ),
            ),
            const SizedBox(height: 6),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${progress.imported} imported',
                  style: const TextStyle(
                    color: MijigiColors.textTertiary,
                    fontSize: 11,
                  ),
                ),
                Text(
                  '${progress.processed}/${progress.total}',
                  style: const TextStyle(
                    color: MijigiColors.textTertiary,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _startImport(BuildContext context, AppProvider provider) async {
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
  }
}
