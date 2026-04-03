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

class _PhotosScreenState extends State<PhotosScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _filter = 'all';
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  List<CaptureItem> _getFilteredItems(AppProvider provider) {
    var items = provider.activeItems
        .where((i) => i.isImageType || i.type == CaptureType.video)
        .toList();

    if (_filter == 'screenshots') {
      items = items.where((i) => i.type == CaptureType.screenshot).toList();
    } else if (_filter == 'videos') {
      items = items.where((i) => i.type == CaptureType.video).toList();
    } else if (_filter == 'things') {
      items = items.where((i) => i.type == CaptureType.photo).toList();
    }

    if (_searchQuery.isNotEmpty) {
      final results = provider.searchImages(_searchQuery);
      final resultIds = results.map((r) => r.item.id).toSet();
      items = items.where((i) => resultIds.contains(i.id)).toList();
    }

    return items;
  }

  /// Collect all extracted data items (emails, phones, urls, amounts) from all
  /// media items, most recent first, capped at 20.
  List<_QuickActionItem> _getQuickActions(AppProvider provider) {
    final mediaItems = provider.activeItems
        .where((i) => i.isImageType || i.type == CaptureType.video)
        .toList();

    final List<_QuickActionItem> actions = [];

    for (final item in mediaItems) {
      final data = item.extractedData;
      if (data == null) continue;

      final emails = data['emails'] as List?;
      if (emails != null) {
        for (final e in emails) {
          actions.add(_QuickActionItem(
            value: e.toString(),
            type: _QuickActionType.email,
            createdAt: item.createdAt,
          ));
        }
      }

      final phones = data['phones'] as List?;
      if (phones != null) {
        for (final p in phones) {
          actions.add(_QuickActionItem(
            value: p.toString(),
            type: _QuickActionType.phone,
            createdAt: item.createdAt,
          ));
        }
      }

      final urls = data['urls'] as List?;
      if (urls != null) {
        for (final u in urls) {
          actions.add(_QuickActionItem(
            value: u.toString(),
            type: _QuickActionType.url,
            createdAt: item.createdAt,
          ));
        }
      }

      // No amounts - only emails, links, addresses
    }

    // Sort most recent first, deduplicate by value, take 20
    actions.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    final seen = <String>{};
    final unique = <_QuickActionItem>[];
    for (final a in actions) {
      if (seen.add(a.value)) {
        unique.add(a);
        if (unique.length >= 20) break;
      }
    }
    return unique;
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AppProvider>(
      builder: (context, provider, _) {
        final allMedia = provider.activeItems
            .where((i) => i.isImageType || i.type == CaptureType.video);
        final screenshotCount =
            allMedia.where((i) => i.type == CaptureType.screenshot).length;
        final videoCount =
            allMedia.where((i) => i.type == CaptureType.video).length;
        final photoCount =
            allMedia.where((i) => i.type == CaptureType.photo).length;

        return Scaffold(
          backgroundColor: MijigiColors.background,
          body: NestedScrollView(
            headerSliverBuilder: (context, _) => [
              const SliverToBoxAdapter(child: SizedBox(height: 48)),

              // Sub-tabs: All | Collections  --  subtle underline style
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: SizedBox(
                    height: 40,
                    child: TabBar(
                      controller: _tabController,
                      indicator: const UnderlineTabIndicator(
                        borderSide: BorderSide(
                          color: MijigiColors.primary,
                          width: 2.0,
                        ),
                        insets: EdgeInsets.symmetric(horizontal: 16),
                      ),
                      indicatorSize: TabBarIndicatorSize.label,
                      dividerColor: Colors.transparent,
                      labelColor: MijigiColors.textPrimary,
                      unselectedLabelColor: MijigiColors.textTertiary,
                      labelStyle: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          letterSpacing: 0.1),
                      unselectedLabelStyle: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w400),
                      tabs: const [
                        Tab(text: 'All'),
                        Tab(text: 'Collections'),
                      ],
                    ),
                  ),
                ),
              ),

              const SliverToBoxAdapter(child: SizedBox(height: 14)),

              // Import progress
              if (provider.isImporting && provider.importProgress != null)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      margin: const EdgeInsets.only(bottom: 10),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            MijigiColors.primary.withValues(alpha: 0.06),
                            MijigiColors.primary.withValues(alpha: 0.02),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                            color:
                                MijigiColors.primary.withValues(alpha: 0.12)),
                      ),
                      child: Row(
                        children: [
                          SizedBox(
                            width: 14,
                            height: 14,
                            child: CircularProgressIndicator(
                              strokeWidth: 1.5,
                              color: MijigiColors.primaryLight,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Syncing ${provider.importProgress!.processed}/${provider.importProgress!.total}',
                              style: const TextStyle(
                                  color: MijigiColors.textSecondary,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w400),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
            ],
            body: TabBarView(
              controller: _tabController,
              children: [
                // TAB 1: All photos/videos
                _buildAllTab(provider, allMedia.length, screenshotCount,
                    videoCount, photoCount),
                // TAB 2: Collections
                _buildCollectionsTab(provider),
              ],
            ),
          ),
          floatingActionButton: Container(
            decoration: BoxDecoration(
              gradient: MijigiGradients.buttonGradient,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: MijigiColors.primary.withValues(alpha: 0.3),
                  blurRadius: 16,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: FloatingActionButton(
              backgroundColor: Colors.transparent,
              elevation: 0,
              onPressed: () => _showCaptureOptions(context, provider),
              child: const Icon(Icons.add_rounded, color: Colors.white, size: 26),
            ),
          ),
        );
      },
    );
  }

  final ScrollController _scrollController = ScrollController();
  String? _visibleDate;
  bool _showDateBubble = false;

  String _getDateForIndex(List<CaptureItem> items, int index) {
    if (index < 0 || index >= items.length) return '';
    final date = items[index].createdAt;
    final now = DateTime.now();
    if (date.year == now.year && date.month == now.month && date.day == now.day) {
      return 'Today';
    }
    final yesterday = now.subtract(const Duration(days: 1));
    if (date.year == yesterday.year && date.month == yesterday.month && date.day == yesterday.day) {
      return 'Yesterday';
    }
    const months = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
    if (date.year == now.year) {
      return '${months[date.month - 1]} ${date.day}';
    }
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }

  Widget _buildAllTab(AppProvider provider, int total, int screenshots,
      int videos, int photos) {
    final items = _getFilteredItems(provider);
    final quickActions = _getQuickActions(provider);

    return Stack(
      children: [
        NotificationListener<ScrollNotification>(
          onNotification: (notification) {
            if (items.isEmpty) return false;
            if (notification is ScrollUpdateNotification) {
              // Calculate which item is visible based on scroll offset
              // Grid is 3 columns, each row ~(screenWidth/3) height
              final rowHeight = (MediaQuery.of(context).size.width - 4) / 3;
              final scrollOffset = _scrollController.offset;
              // Account for header height (~180px for search + pills + filters)
              final adjustedOffset = (scrollOffset - 180).clamp(0.0, double.infinity);
              final visibleRow = (adjustedOffset / (rowHeight + 1)).floor();
              final visibleIndex = (visibleRow * 3).clamp(0, items.length - 1);
              final date = _getDateForIndex(items, visibleIndex);
              if (date != _visibleDate) {
                setState(() { _visibleDate = date; _showDateBubble = true; });
              }
            }
            if (notification is ScrollEndNotification) {
              Future.delayed(const Duration(seconds: 1), () {
                if (mounted) setState(() => _showDateBubble = false);
              });
            }
            return false;
          },
          child: CustomScrollView(
            controller: _scrollController,
            slivers: [
        // Search
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: MijigiSearchBar(
              hint: 'Search by description...',
              onChanged: (q) => setState(() => _searchQuery = q),
            ),
          ),
        ),

        const SliverToBoxAdapter(child: SizedBox(height: 12)),

        // Quick actions row
        if (quickActions.isNotEmpty)
          SliverToBoxAdapter(
            child: SizedBox(
              height: 34,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                itemCount: quickActions.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (context, index) {
                  final action = quickActions[index];
                  return _QuickActionPill(
                    action: action,
                    onTap: () {
                      Clipboard.setData(ClipboardData(text: action.value));
                      HapticFeedback.lightImpact();
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Copied: ${action.value}'),
                          duration: const Duration(seconds: 1),
                          backgroundColor: MijigiColors.surfaceLight,
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ),

        if (quickActions.isNotEmpty)
          const SliverToBoxAdapter(child: SizedBox(height: 12)),

        // Filters
        SliverToBoxAdapter(
          child: SizedBox(
            height: 34,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              children: [
                _chip('All', total, _filter == 'all',
                    () => setState(() => _filter = 'all')),
                const SizedBox(width: 8),
                _chip('Screenshots', screenshots, _filter == 'screenshots',
                    () => setState(() => _filter = 'screenshots')),
                const SizedBox(width: 8),
                _chip('Videos', videos, _filter == 'videos',
                    () => setState(() => _filter = 'videos')),
                const SizedBox(width: 8),
                _chip('Things', photos, _filter == 'things',
                    () => setState(() => _filter = 'things')),
              ],
            ),
          ),
        ),

        const SliverToBoxAdapter(child: SizedBox(height: 12)),

        // Grid
        if (items.isEmpty)
          SliverToBoxAdapter(child: _buildEmpty())
        else
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 1),
            sliver: SliverGrid(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                crossAxisSpacing: 1,
                mainAxisSpacing: 1,
                childAspectRatio: 1.0,
              ),
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final item = items[index];
                  return _MediaTile(
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
    ),
    // Date bubble on right side
    if (_showDateBubble && _visibleDate != null && _visibleDate!.isNotEmpty)
      Positioned(
        right: 8,
        top: 0,
        bottom: 0,
        child: Center(
          child: AnimatedOpacity(
            opacity: _showDateBubble ? 1.0 : 0.0,
            duration: const Duration(milliseconds: 200),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
              decoration: BoxDecoration(
                gradient: MijigiGradients.buttonGradient,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: MijigiColors.primary.withValues(alpha: 0.25),
                    blurRadius: 10,
                  ),
                ],
              ),
              child: Text(
                _visibleDate!,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.2,
                ),
              ),
            ),
          ),
        ),
      ),
    ],
    );
  }

  Widget _buildCollectionsTab(AppProvider provider) {
    final collections = provider.getSmartCollections();

    return CustomScrollView(
      slivers: [
        const SliverToBoxAdapter(child: SizedBox(height: 12)),
        if (collections.isEmpty)
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.only(top: 80),
              child: Center(
                child: Column(
                  children: [
                    Icon(Icons.collections_bookmark_rounded,
                        size: 44,
                        color: MijigiColors.textTertiary
                            .withValues(alpha: 0.4)),
                    const SizedBox(height: 16),
                    const Text('No collections yet',
                        style: TextStyle(
                            color: MijigiColors.textSecondary,
                            fontSize: 16,
                            fontWeight: FontWeight.w500)),
                    const SizedBox(height: 8),
                    const Text(
                        'Collections auto-create as Mijigi scans your photos',
                        style: TextStyle(
                            color: MijigiColors.textTertiary, fontSize: 13,
                            fontWeight: FontWeight.w400)),
                  ],
                ),
              ),
            ),
          )
        else
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            sliver: SliverGrid(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 14,
                mainAxisSpacing: 14,
                childAspectRatio: 1.0,
              ),
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final collection = collections[index];
                  return _CollectionCard(
                    collection: collection,
                    onTap: () => _openCollection(provider, collection),
                  );
                },
                childCount: collections.length,
              ),
            ),
          ),
        const SliverToBoxAdapter(child: SizedBox(height: 100)),
      ],
    );
  }

  Widget _chip(String label, int count, bool active, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOutCubic,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: active
              ? MijigiColors.primary.withValues(alpha: 0.12)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: active
                ? MijigiColors.primary.withValues(alpha: 0.4)
                : MijigiColors.border.withValues(alpha: 0.6),
            width: 0.5,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: TextStyle(
                color: active ? MijigiColors.primaryLight : MijigiColors.textSecondary,
                fontSize: 12,
                fontWeight: FontWeight.w500,
                letterSpacing: 0.1,
              ),
            ),
            if (count > 0) ...[
              const SizedBox(width: 6),
              Text(
                '$count',
                style: TextStyle(
                  color: active
                      ? MijigiColors.primary.withValues(alpha: 0.7)
                      : MijigiColors.textTertiary,
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
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
                size: 44,
                color: MijigiColors.textTertiary.withValues(alpha: 0.4)),
            const SizedBox(height: 16),
            const Text('No photos yet',
                style: TextStyle(
                    color: MijigiColors.textSecondary,
                    fontSize: 16,
                    fontWeight: FontWeight.w500)),
          ],
        ),
      ),
    );
  }

  void _showCaptureOptions(BuildContext context, AppProvider provider) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => Container(
        decoration: MijigiGradients.frostedSheet(),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 36,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: MijigiColors.textTertiary.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                ListTile(
                  leading: const Icon(Icons.camera_alt_rounded,
                      color: MijigiColors.primaryLight),
                  title: const Text('Take Photo',
                      style: TextStyle(color: MijigiColors.textPrimary,
                          fontWeight: FontWeight.w400)),
                  onTap: () async {
                    Navigator.pop(ctx);
                    final item = await provider.captureFromCamera();
                    if (item != null && mounted) _openItem(item);
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.videocam_rounded,
                      color: MijigiColors.primaryLight),
                  title: const Text('Record Video',
                      style: TextStyle(color: MijigiColors.textPrimary,
                          fontWeight: FontWeight.w400)),
                  onTap: () async {
                    Navigator.pop(ctx);
                    final item = await provider.captureVideoFromCamera();
                    if (item != null && mounted) _openItem(item);
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.photo_library_rounded,
                      color: MijigiColors.accent),
                  title: const Text('Choose from Gallery',
                      style: TextStyle(color: MijigiColors.textPrimary,
                          fontWeight: FontWeight.w400)),
                  onTap: () async {
                    Navigator.pop(ctx);
                    final item = await provider.captureFromGallery();
                    if (item != null && mounted) _openItem(item);
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.sync_rounded,
                      color: MijigiColors.textSecondary),
                  title: const Text('Sync Device Photos',
                      style: TextStyle(color: MijigiColors.textPrimary,
                          fontWeight: FontWeight.w400)),
                  onTap: () async {
                    Navigator.pop(ctx);
                    final ok = await provider.requestPhotoPermission();
                    if (ok) provider.importDevicePhotos();
                  },
                ),
              ],
            ),
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

  void _openCollection(AppProvider provider, SmartCollection collection) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => _CollectionDetailScreen(collection: collection),
      ),
    );
  }

  void _showActions(AppProvider provider, CaptureItem item) {
    HapticFeedback.mediumImpact();
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => Container(
        decoration: MijigiGradients.frostedSheet(),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 36,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: MijigiColors.textTertiary.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                ListTile(
                  leading: Icon(
                    item.isPinned
                        ? Icons.push_pin_outlined
                        : Icons.push_pin_rounded,
                    color: MijigiColors.primaryLight,
                  ),
                  title: Text(item.isPinned ? 'Unpin' : 'Pin',
                      style:
                          const TextStyle(color: MijigiColors.textPrimary,
                              fontWeight: FontWeight.w400)),
                  onTap: () {
                    Navigator.pop(ctx);
                    provider.togglePin(item.id);
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.delete_rounded,
                      color: MijigiColors.error),
                  title: const Text('Delete',
                      style: TextStyle(color: MijigiColors.error,
                          fontWeight: FontWeight.w400)),
                  onTap: () {
                    Navigator.pop(ctx);
                    provider.deleteItem(item.id);
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// --- Quick action types and data ---
enum _QuickActionType { email, phone, url, amount }

class _QuickActionItem {
  final String value;
  final _QuickActionType type;
  final DateTime createdAt;

  const _QuickActionItem({
    required this.value,
    required this.type,
    required this.createdAt,
  });

  IconData get icon => switch (type) {
    _QuickActionType.email => Icons.email_rounded,
    _QuickActionType.phone => Icons.phone_rounded,
    _QuickActionType.url => Icons.link_rounded,
    _QuickActionType.amount => Icons.attach_money_rounded,
  };

  Color get color => switch (type) {
    _QuickActionType.email => const Color(0xFF8B5CF6),  // purple
    _QuickActionType.phone => const Color(0xFF3B82F6),  // blue
    _QuickActionType.url => const Color(0xFF06B6D4),    // cyan
    _QuickActionType.amount => const Color(0xFF22C55E), // green
  };

  String get displayValue {
    if (type == _QuickActionType.url) {
      // Show just the domain
      try {
        final uri = Uri.parse(value);
        if (uri.host.isNotEmpty) return uri.host;
      } catch (_) {}
      // Fallback: strip protocol
      return value
          .replaceFirst(RegExp(r'https?://'), '')
          .replaceFirst(RegExp(r'/.*'), '');
    }
    return value;
  }
}

// --- Quick action pill widget ---
class _QuickActionPill extends StatelessWidget {
  final _QuickActionItem action;
  final VoidCallback onTap;

  const _QuickActionPill({required this.action, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: action.color.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: action.color.withValues(alpha: 0.12),
            width: 0.5,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(action.icon, size: 13, color: action.color.withValues(alpha: 0.8)),
            const SizedBox(width: 6),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 150),
              child: Text(
                action.displayValue,
                style: TextStyle(
                  color: action.color.withValues(alpha: 0.9),
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  letterSpacing: 0.1,
                ),
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// --- Media tile (photo or video) ---
class _MediaTile extends StatelessWidget {
  final CaptureItem item;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;

  const _MediaTile({
    required this.item,
    required this.onTap,
    this.onLongPress,
  });

  String? get _firstOcrLine {
    final text = item.rawText;
    if (text == null || text.trim().isEmpty) return null;
    final lines = text.split('\n').where((l) => l.trim().isNotEmpty);
    if (lines.isEmpty) return null;
    final first = lines.first.trim();
    return first.length > 60 ? '${first.substring(0, 60)}...' : first;
  }

  @override
  Widget build(BuildContext context) {
    final ocrLine = _firstOcrLine;

    return GestureDetector(
      onTap: onTap,
      onLongPress: onLongPress,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Use thumbnail for videos, file path for images
          if (item.type == CaptureType.video && item.thumbnailPath != null)
            Image.file(
              File(item.thumbnailPath!),
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(
                color: MijigiColors.surfaceLight,
                child: const Icon(Icons.videocam_rounded,
                    color: MijigiColors.textTertiary, size: 24),
              ),
            )
          else if (item.filePath != null)
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
          // OCR text strip at bottom
          if (ocrLine != null)
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 6, vertical: 5),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.black.withValues(alpha: 0.8),
                    ],
                  ),
                ),
                child: Text(
                  ocrLine,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 8,
                    fontWeight: FontWeight.w400,
                    height: 1.2,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
          // Video play icon
          if (item.type == CaptureType.video)
            Center(
              child: Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.45),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.2),
                    width: 0.5,
                  ),
                ),
                child: const Icon(Icons.play_arrow_rounded,
                    color: Colors.white, size: 20),
              ),
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
                  color: Colors.black.withValues(alpha: 0.45),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Icon(Icons.screenshot_rounded,
                    size: 10, color: Colors.white70),
              ),
            ),
          // Processing
          if (!item.isProcessed)
            Positioned(
              bottom: ocrLine != null ? 20 : 4,
              right: 4,
              child: SizedBox(
                width: 10,
                height: 10,
                child: CircularProgressIndicator(
                  strokeWidth: 1.5,
                  color: MijigiColors.primaryLight,
                ),
              ),
            ),
          // Pinned
          if (item.isPinned)
            Positioned(
              top: 4,
              left: 4,
              child: Container(
                padding: const EdgeInsets.all(3),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.45),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Icon(Icons.push_pin_rounded,
                    size: 10, color: MijigiColors.primaryLight),
              ),
            ),
        ],
      ),
    );
  }
}

// --- Collection card ---
class _CollectionCard extends StatelessWidget {
  final SmartCollection collection;
  final VoidCallback onTap;

  const _CollectionCard({required this.collection, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          gradient: MijigiGradients.cardGradient,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: MijigiColors.border.withValues(alpha: 0.5)),
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Cover image
            if (collection.coverPath != null)
              Image.file(
                File(collection.coverPath!),
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  color: collection.color.withValues(alpha: 0.06),
                  child: Icon(collection.icon,
                      color: collection.color.withValues(alpha: 0.7), size: 36),
                ),
              )
            else
              Container(
                color: collection.color.withValues(alpha: 0.06),
                child: Icon(collection.icon,
                    color: collection.color.withValues(alpha: 0.7), size: 36),
              ),
            // Gradient overlay
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.black.withValues(alpha: 0.8),
                    ],
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      collection.name,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        letterSpacing: -0.2,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${collection.count} items',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.6),
                        fontSize: 11,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// --- Collection detail screen ---
class _CollectionDetailScreen extends StatelessWidget {
  final SmartCollection collection;

  const _CollectionDetailScreen({required this.collection});

  @override
  Widget build(BuildContext context) {
    return Consumer<AppProvider>(
      builder: (context, provider, _) {
        final items = provider.getCollectionItems(collection.key);

        return Scaffold(
          backgroundColor: MijigiColors.background,
          appBar: AppBar(
            backgroundColor: MijigiColors.background,
            title: Row(
              children: [
                Icon(collection.icon, color: collection.color, size: 20),
                const SizedBox(width: 8),
                Text(collection.name),
              ],
            ),
          ),
          body: items.isEmpty
              ? const Center(
                  child: Text('No items',
                      style: TextStyle(color: MijigiColors.textTertiary,
                          fontWeight: FontWeight.w400)))
              : GridView.builder(
                  padding: const EdgeInsets.all(1),
                  gridDelegate:
                      const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    crossAxisSpacing: 1,
                    mainAxisSpacing: 1,
                  ),
                  itemCount: items.length,
                  itemBuilder: (context, index) {
                    final item = items[index];
                    return _MediaTile(
                      item: item,
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                              ItemDetailScreen(itemId: item.id),
                        ),
                      ),
                    );
                  },
                ),
        );
      },
    );
  }
}
