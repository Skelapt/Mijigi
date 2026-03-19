import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/capture_item.dart';
import '../../providers/app_provider.dart';
import '../../theme/app_theme.dart';
import '../../widgets/capture_card.dart';
import '../../widgets/mijigi_search_bar.dart';
import '../item_detail/item_detail_screen.dart';

class LibraryScreen extends StatefulWidget {
  final ItemCategory? filterCategory;

  const LibraryScreen({super.key, this.filterCategory});

  @override
  State<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends State<LibraryScreen> {
  ItemCategory? _selectedCategory;
  String _localSearch = '';
  String _imageFilter = 'all';

  @override
  void initState() {
    super.initState();
    _selectedCategory = widget.filterCategory;
  }

  /// Get only image-type items (photos + screenshots)
  List<CaptureItem> _getImageItems(AppProvider provider) {
    var items = provider.activeItems.where((i) =>
        i.type == CaptureType.photo || i.type == CaptureType.screenshot).toList();

    // Apply sub-filter
    if (_imageFilter == 'photos') {
      items = items.where((i) => i.type == CaptureType.photo).toList();
    } else if (_imageFilter == 'screenshots') {
      items = items.where((i) => i.type == CaptureType.screenshot).toList();
    }

    // Apply category filter if set
    if (_selectedCategory != null) {
      items = items.where((i) => i.category == _selectedCategory).toList();
    }

    // Apply search
    if (_localSearch.isNotEmpty) {
      final lower = _localSearch.toLowerCase();
      items = items.where((i) {
        return (i.title?.toLowerCase().contains(lower) ?? false) ||
            (i.rawText?.toLowerCase().contains(lower) ?? false) ||
            (i.summary?.toLowerCase().contains(lower) ?? false) ||
            i.tags.any((t) => t.toLowerCase().contains(lower));
      }).toList();
    }

    return items;
  }

  @override
  Widget build(BuildContext context) {
    final isSubPage = widget.filterCategory != null;

    return Scaffold(
      backgroundColor: MijigiColors.background,
      appBar: isSubPage
          ? AppBar(
              title: Text(_categoryTitle(_selectedCategory!)),
              backgroundColor: MijigiColors.background,
            )
          : null,
      body: Consumer<AppProvider>(
        builder: (context, provider, _) {
          final items = _getImageItems(provider);
          final photoCount = provider.activeItems
              .where((i) => i.type == CaptureType.photo).length;
          final screenshotCount = provider.activeItems
              .where((i) => i.type == CaptureType.screenshot).length;
          final totalImages = photoCount + screenshotCount;

          return CustomScrollView(
            slivers: [
              if (!isSubPage) ...[
                const SliverToBoxAdapter(child: SizedBox(height: 60)),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Row(
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Images',
                              style: TextStyle(
                                color: MijigiColors.textPrimary,
                                fontSize: 28,
                                fontWeight: FontWeight.w800,
                                letterSpacing: -0.5,
                              ),
                            ),
                            Text(
                              '$totalImages images',
                              style: const TextStyle(
                                color: MijigiColors.textTertiary,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                        const Spacer(),
                      ],
                    ),
                  ),
                ),
                const SliverToBoxAdapter(child: SizedBox(height: 16)),
              ],

              // Search
              SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: isSubPage ? 8 : 0,
                  ),
                  child: MijigiSearchBar(
                    hint: 'Search images...',
                    onChanged: (q) => setState(() => _localSearch = q),
                  ),
                ),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 16)),

              // Image type filter (Photos / Screenshots)
              if (!isSubPage) ...[
                SliverToBoxAdapter(
                  child: SizedBox(
                    height: 36,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      children: [
                        _buildFilterChip('All ($totalImages)', _imageFilter == 'all', () {
                          setState(() { _imageFilter = 'all'; _selectedCategory = null; });
                        }),
                        const SizedBox(width: 8),
                        _buildFilterChip('Photos ($photoCount)', _imageFilter == 'photos', () {
                          setState(() { _imageFilter = 'photos'; _selectedCategory = null; });
                        }),
                        const SizedBox(width: 8),
                        _buildFilterChip('Screenshots ($screenshotCount)', _imageFilter == 'screenshots', () {
                          setState(() { _imageFilter = 'screenshots'; _selectedCategory = null; });
                        }),
                        const SizedBox(width: 16),
                        // Category filters
                        ...provider.activeCategories
                            .where((e) => provider.activeItems.any((i) =>
                                (i.type == CaptureType.photo || i.type == CaptureType.screenshot) &&
                                i.category == e.key))
                            .map((entry) {
                          return Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: _buildFilterChip(
                              _categoryTitle(entry.key),
                              _selectedCategory == entry.key,
                              () => setState(() {
                                _selectedCategory = _selectedCategory == entry.key ? null : entry.key;
                                _imageFilter = 'all';
                              }),
                            ),
                          );
                        }),
                      ],
                    ),
                  ),
                ),
                const SliverToBoxAdapter(child: SizedBox(height: 16)),
              ],

              // Items - compact strip list
              if (items.isEmpty)
                SliverToBoxAdapter(child: _buildEmpty())
              else
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: CaptureCard(
                            item: items[index],
                            onTap: () => _openItem(items[index]),
                            onLongPress: () =>
                                _showActions(provider, items[index]),
                          ),
                        );
                      },
                      childCount: items.length,
                    ),
                  ),
                ),

              const SliverToBoxAdapter(child: SizedBox(height: 100)),
            ],
          );
        },
      ),
    );
  }

  Widget _buildFilterChip(String label, bool selected, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: selected
              ? MijigiColors.primary
              : MijigiColors.surface,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: selected ? MijigiColors.primary : MijigiColors.border,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? Colors.white : MijigiColors.textSecondary,
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Widget _buildEmpty() {
    return Padding(
      padding: const EdgeInsets.only(top: 60),
      child: Center(
        child: Column(
          children: [
            Icon(
              Icons.folder_open_rounded,
              size: 48,
              color: MijigiColors.textTertiary.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 12),
            const Text(
              'Nothing here yet',
              style: TextStyle(
                color: MijigiColors.textTertiary,
                fontSize: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _openItem(CaptureItem item) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ItemDetailScreen(itemId: item.id),
      ),
    );
  }

  void _showActions(AppProvider provider, CaptureItem item) {
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
                title: Text(item.isPinned ? 'Unpin' : 'Pin'),
                onTap: () {
                  Navigator.pop(ctx);
                  provider.togglePin(item.id);
                },
              ),
              ListTile(
                leading: const Icon(Icons.archive_rounded,
                    color: MijigiColors.warning),
                title: const Text('Archive'),
                onTap: () {
                  Navigator.pop(ctx);
                  provider.archiveItem(item.id);
                },
              ),
              ListTile(
                leading: const Icon(Icons.delete_rounded,
                    color: MijigiColors.error),
                title: const Text('Delete'),
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

  String _categoryTitle(ItemCategory cat) => switch (cat) {
    ItemCategory.uncategorised => 'Uncategorised',
    ItemCategory.receipt => 'Receipts',
    ItemCategory.document => 'Documents',
    ItemCategory.medical => 'Medical',
    ItemCategory.financial => 'Financial',
    ItemCategory.legal => 'Legal',
    ItemCategory.travel => 'Travel',
    ItemCategory.food => 'Food & Recipes',
    ItemCategory.work => 'Work',
    ItemCategory.personal => 'Personal',
    ItemCategory.education => 'Education',
    ItemCategory.shopping => 'Shopping',
    ItemCategory.contact => 'Contacts',
    ItemCategory.event => 'Events',
  };
}
