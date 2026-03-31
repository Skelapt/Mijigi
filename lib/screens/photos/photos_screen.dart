import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../models/capture_item.dart';
import '../../providers/app_provider.dart';
import '../../theme/app_theme.dart';
import '../../widgets/mijigi_search_bar.dart';
import '../item_detail/item_detail_screen.dart';

class PhotosScreen extends StatefulWidget {
  const PhotosScreen({super.key});

  @override
  State<PhotosScreen> createState() => _PhotosScreenState();
}

class _PhotosScreenState extends State<PhotosScreen> {
  String _filter = 'all'; // 'all', 'screenshots', 'things'
  String _searchQuery = '';

  List<CaptureItem> _getFilteredItems(AppProvider provider) {
    var items = provider.activeItems
        .where((i) => i.isImageType)
        .toList();

    // Apply filter
    if (_filter == 'screenshots') {
      items = items.where((i) => i.type == CaptureType.screenshot).toList();
    } else if (_filter == 'things') {
      items = items.where((i) => i.type == CaptureType.photo).toList();
    }

    // Apply search
    if (_searchQuery.isNotEmpty) {
      final results = provider.searchImages(_searchQuery);
      final resultIds = results.map((r) => r.item.id).toSet();
      items = items.where((i) => resultIds.contains(i.id)).toList();
    }

    return items;
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AppProvider>(
      builder: (context, provider, _) {
        final items = _getFilteredItems(provider);
        final allImages = provider.activeItems.where((i) => i.isImageType);
        final screenshotCount =
            allImages.where((i) => i.type == CaptureType.screenshot).length;
        final thingCount =
            allImages.where((i) => i.type == CaptureType.photo).length;

        return Scaffold(
          backgroundColor: MijigiColors.background,
          body: CustomScrollView(
            slivers: [
              const SliverToBoxAdapter(child: SizedBox(height: 56)),

              // Title
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Row(
                    children: [
                      const Text(
                        'Photos',
                        style: TextStyle(
                          color: MijigiColors.textPrimary,
                          fontSize: 28,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.5,
                        ),
                      ),
                      if (provider.isProcessing) ...[
                        const SizedBox(width: 10),
                        SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: MijigiColors.primary,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),

              const SliverToBoxAdapter(child: SizedBox(height: 16)),

              // Search bar
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: MijigiSearchBar(
                    hint: 'Search photos by description...',
                    onChanged: (q) => setState(() => _searchQuery = q),
                  ),
                ),
              ),

              const SliverToBoxAdapter(child: SizedBox(height: 12)),

              // Filters
              SliverToBoxAdapter(
                child: SizedBox(
                  height: 36,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    children: [
                      _buildChip(
                          'All', allImages.length, _filter == 'all',
                          () => setState(() => _filter = 'all')),
                      const SizedBox(width: 8),
                      _buildChip(
                          'Screenshots', screenshotCount,
                          _filter == 'screenshots',
                          () => setState(() => _filter = 'screenshots')),
                      const SizedBox(width: 8),
                      _buildChip(
                          'Things', thingCount, _filter == 'things',
                          () => setState(() => _filter = 'things')),
                    ],
                  ),
                ),
              ),

              const SliverToBoxAdapter(child: SizedBox(height: 12)),

              // Import progress banner
              if (provider.isImporting && provider.importProgress != null)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.only(left: 20, right: 20, bottom: 12),
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: MijigiColors.primary.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: MijigiColors.primary.withValues(alpha: 0.2)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              SizedBox(
                                width: 14, height: 14,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2, color: MijigiColors.primary,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  'Syncing ${provider.importProgress!.processed}/${provider.importProgress!.total} photos...',
                                  style: const TextStyle(
                                    color: MijigiColors.textSecondary,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          if (provider.importProgress!.message.isNotEmpty) ...[
                            const SizedBox(height: 4),
                            Text(
                              provider.importProgress!.message,
                              style: const TextStyle(color: MijigiColors.textTertiary, fontSize: 11),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                          const SizedBox(height: 8),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: LinearProgressIndicator(
                              value: provider.importProgress!.total > 0
                                  ? provider.importProgress!.processed / provider.importProgress!.total
                                  : 0,
                              backgroundColor: MijigiColors.border,
                              color: MijigiColors.primary,
                              minHeight: 3,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

              // Processing indicator
              if (provider.isProcessing && !provider.isImporting)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.only(left: 20, right: 20, bottom: 12),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: MijigiColors.surface,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: MijigiColors.border),
                      ),
                      child: Row(
                        children: [
                          SizedBox(
                            width: 12, height: 12,
                            child: CircularProgressIndicator(
                              strokeWidth: 1.5, color: MijigiColors.primary,
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Text(
                            'Scanning images...',
                            style: TextStyle(color: MijigiColors.textTertiary, fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

              // Photo grid - 3 columns
              if (items.isEmpty)
                SliverToBoxAdapter(child: _buildEmpty())
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
                        final item = items[index];
                        return _PhotoTile(
                          item: item,
                          onTap: () => _openItem(item),
                          onLongPress: () => _showActions(provider, item),
                        );
                      },
                      childCount: items.length,
                    ),
                  ),
                ),

              const SliverToBoxAdapter(child: SizedBox(height: 100)),
            ],
          ),
          floatingActionButton: FloatingActionButton(
            backgroundColor: MijigiColors.primary,
            onPressed: () => _showCaptureOptions(context, provider),
            child: const Icon(Icons.add_rounded, color: Colors.white),
          ),
        );
      },
    );
  }

  Widget _buildChip(
      String label, int count, bool active, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: active ? MijigiColors.primary : MijigiColors.surface,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: active ? MijigiColors.primary : MijigiColors.border,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: TextStyle(
                color: active ? Colors.white : MijigiColors.textSecondary,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(width: 6),
            Text(
              '$count',
              style: TextStyle(
                color: active
                    ? Colors.white.withValues(alpha: 0.7)
                    : MijigiColors.textTertiary,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmpty() {
    return Padding(
      padding: const EdgeInsets.only(top: 80),
      child: Center(
        child: Column(
          children: [
            Icon(Icons.photo_library_outlined,
                size: 48,
                color: MijigiColors.textTertiary.withValues(alpha: 0.5)),
            const SizedBox(height: 12),
            const Text('No photos yet',
                style: TextStyle(
                    color: MijigiColors.textSecondary,
                    fontSize: 16,
                    fontWeight: FontWeight.w600)),
            const SizedBox(height: 6),
            const Text('Tap + to add photos or import from gallery',
                style:
                    TextStyle(color: MijigiColors.textTertiary, fontSize: 13)),
          ],
        ),
      ),
    );
  }

  void _showCaptureOptions(BuildContext context, AppProvider provider) {
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
                width: 36,
                height: 4,
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: MijigiColors.textTertiary.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              ListTile(
                leading: const Icon(Icons.camera_alt_rounded,
                    color: MijigiColors.primary),
                title: const Text('Take Photo', style: TextStyle(color: MijigiColors.textPrimary)),
                onTap: () async {
                  Navigator.pop(ctx);
                  final item = await provider.captureFromCamera();
                  if (item != null && mounted) _openItem(item);
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_library_rounded,
                    color: MijigiColors.primaryLight),
                title: const Text('Choose from Gallery', style: TextStyle(color: MijigiColors.textPrimary)),
                onTap: () async {
                  Navigator.pop(ctx);
                  final item = await provider.captureFromGallery();
                  if (item != null && mounted) _openItem(item);
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_library_outlined,
                    color: MijigiColors.accent),
                title: const Text('Import Multiple', style: TextStyle(color: MijigiColors.textPrimary)),
                onTap: () async {
                  Navigator.pop(ctx);
                  await provider.captureMultipleFromGallery();
                },
              ),
              ListTile(
                leading: const Icon(Icons.sync_rounded,
                    color: MijigiColors.textSecondary),
                title: const Text('Sync Device Photos', style: TextStyle(color: MijigiColors.textPrimary)),
                subtitle: const Text('Import all photos from your device',
                    style: TextStyle(
                        color: MijigiColors.textTertiary, fontSize: 12)),
                onTap: () async {
                  Navigator.pop(ctx);
                  final hasPermission = await provider.requestPhotoPermission();
                  if (hasPermission) {
                    provider.importDevicePhotos();
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _openItem(CaptureItem item) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => ItemDetailScreen(itemId: item.id)),
    );
  }

  void _showActions(AppProvider provider, CaptureItem item) {
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
                width: 36,
                height: 4,
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: MijigiColors.textTertiary.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              ListTile(
                leading: Icon(
                  item.isPinned
                      ? Icons.push_pin_outlined
                      : Icons.push_pin_rounded,
                  color: MijigiColors.primary,
                ),
                title: Text(item.isPinned ? 'Unpin' : 'Pin', style: const TextStyle(color: MijigiColors.textPrimary)),
                onTap: () {
                  Navigator.pop(ctx);
                  provider.togglePin(item.id);
                },
              ),
              ListTile(
                leading: const Icon(Icons.delete_rounded,
                    color: MijigiColors.error),
                title: const Text('Delete', style: TextStyle(color: MijigiColors.error)),
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

class _PhotoTile extends StatelessWidget {
  final CaptureItem item;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;

  const _PhotoTile({
    required this.item,
    required this.onTap,
    this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      onLongPress: onLongPress,
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (item.filePath != null)
            Image.file(
              File(item.filePath!),
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(
                color: MijigiColors.surfaceLight,
                child: const Icon(Icons.image_not_supported_rounded,
                    color: MijigiColors.textTertiary, size: 24),
              ),
            )
          else
            Container(
              color: MijigiColors.surfaceLight,
              child: const Icon(Icons.image_rounded,
                  color: MijigiColors.textTertiary, size: 24),
            ),
          // Screenshot badge
          if (item.type == CaptureType.screenshot)
            Positioned(
              top: 4,
              right: 4,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.6),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Icon(Icons.screenshot_rounded,
                    size: 12, color: Colors.white70),
              ),
            ),
          // Processing indicator
          if (!item.isProcessed)
            Positioned(
              bottom: 4,
              right: 4,
              child: SizedBox(
                width: 12,
                height: 12,
                child: CircularProgressIndicator(
                  strokeWidth: 1.5,
                  color: MijigiColors.primary,
                ),
              ),
            ),
          // Pin indicator
          if (item.isPinned)
            Positioned(
              top: 4,
              left: 4,
              child: Container(
                padding: const EdgeInsets.all(2),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.6),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Icon(Icons.push_pin_rounded,
                    size: 12, color: MijigiColors.primary),
              ),
            ),
        ],
      ),
    );
  }
}
