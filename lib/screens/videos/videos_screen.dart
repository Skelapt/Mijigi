import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../models/capture_item.dart';
import '../../providers/app_provider.dart';
import '../../theme/app_theme.dart';
import '../item_detail/item_detail_screen.dart';

class VideosScreen extends StatelessWidget {
  const VideosScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AppProvider>(
      builder: (context, provider, _) {
        final videos = provider.activeItems
            .where((i) => i.type == CaptureType.video && i.filePath != null)
            .toList();

        return Scaffold(
          backgroundColor: MijigiColors.background,
          body: CustomScrollView(
            slivers: [
              const SliverToBoxAdapter(child: SizedBox(height: 56)),

              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Row(
                    children: [
                      const Text(
                        'Videos',
                        style: TextStyle(
                          color: MijigiColors.textPrimary,
                          fontSize: 28,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.5,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        '${videos.length} videos',
                        style: const TextStyle(
                          color: MijigiColors.textTertiary,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SliverToBoxAdapter(child: SizedBox(height: 16)),

              if (videos.isEmpty)
                SliverToBoxAdapter(child: _buildEmpty(context, provider))
              else
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 2),
                  sliver: SliverGrid(
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3,
                      crossAxisSpacing: 2,
                      mainAxisSpacing: 2,
                    ),
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final item = videos[index];
                        return _VideoTile(
                          item: item,
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) =>
                                  ItemDetailScreen(itemId: item.id),
                            ),
                          ),
                          onLongPress: () =>
                              _showActions(context, provider, item),
                        );
                      },
                      childCount: videos.length,
                    ),
                  ),
                ),

              const SliverToBoxAdapter(child: SizedBox(height: 100)),
            ],
          ),
          floatingActionButton: FloatingActionButton(
            backgroundColor: MijigiColors.primary,
            onPressed: () => _captureVideo(context, provider),
            child: const Icon(Icons.videocam_rounded, color: Colors.white),
          ),
        );
      },
    );
  }

  Widget _buildEmpty(BuildContext context, AppProvider provider) {
    return Padding(
      padding: const EdgeInsets.only(top: 80),
      child: Center(
        child: Column(
          children: [
            Icon(Icons.videocam_off_rounded,
                size: 48,
                color: MijigiColors.textTertiary.withValues(alpha: 0.5)),
            const SizedBox(height: 12),
            const Text('No videos yet',
                style: TextStyle(
                    color: MijigiColors.textSecondary,
                    fontSize: 16,
                    fontWeight: FontWeight.w600)),
            const SizedBox(height: 6),
            const Text('Tap the camera button to record a video',
                style:
                    TextStyle(color: MijigiColors.textTertiary, fontSize: 13)),
          ],
        ),
      ),
    );
  }

  void _captureVideo(BuildContext context, AppProvider provider) {
    showModalBottomSheet(
      context: context,
      backgroundColor: MijigiColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 36, height: 4,
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: MijigiColors.textTertiary.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              ListTile(
                leading: const Icon(Icons.videocam_rounded, color: MijigiColors.primary),
                title: const Text('Record Video', style: TextStyle(color: MijigiColors.textPrimary)),
                onTap: () async {
                  Navigator.pop(ctx);
                  final item = await provider.captureVideoFromCamera();
                  if (item != null && context.mounted) {
                    Navigator.push(context, MaterialPageRoute(
                      builder: (_) => ItemDetailScreen(itemId: item.id),
                    ));
                  }
                },
              ),
              ListTile(
                leading: const Icon(Icons.video_library_rounded, color: MijigiColors.primaryLight),
                title: const Text('Choose from Gallery', style: TextStyle(color: MijigiColors.textPrimary)),
                onTap: () async {
                  Navigator.pop(ctx);
                  final item = await provider.captureVideoFromGallery();
                  if (item != null && context.mounted) {
                    Navigator.push(context, MaterialPageRoute(
                      builder: (_) => ItemDetailScreen(itemId: item.id),
                    ));
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showActions(
      BuildContext context, AppProvider provider, CaptureItem item) {
    HapticFeedback.mediumImpact();
    showModalBottomSheet(
      context: context,
      backgroundColor: MijigiColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 36, height: 4,
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: MijigiColors.textTertiary.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              ListTile(
                leading: const Icon(Icons.delete_rounded,
                    color: MijigiColors.error),
                title: const Text('Delete',
                    style: TextStyle(color: MijigiColors.error)),
                onTap: () {
                  Navigator.pop(ctx);
                  provider.deleteItem(item.id);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _VideoTile extends StatelessWidget {
  final CaptureItem item;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;

  const _VideoTile({
    required this.item,
    required this.onTap,
    this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      onLongPress: onLongPress,
      child: Container(
        color: MijigiColors.surfaceLight,
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (item.thumbnailPath != null)
              Image.file(
                File(item.thumbnailPath!),
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => _buildPlaceholder(),
              )
            else
              _buildPlaceholder(),
            // Play icon overlay
            Center(
              child: Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.5),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.play_arrow_rounded,
                  color: Colors.white,
                  size: 22,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlaceholder() {
    return Container(
      color: MijigiColors.surfaceLight,
      child: const Center(
        child: Icon(Icons.videocam_rounded,
            color: MijigiColors.textTertiary, size: 28),
      ),
    );
  }
}
