import 'package:flutter/material.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
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
  bool _showGrid = true;

  @override
  void initState() {
    super.initState();
    _selectedCategory = widget.filterCategory;
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
          var items = _selectedCategory != null
              ? provider.getItemsByCategory(_selectedCategory!)
              : provider.activeItems;

          if (_localSearch.isNotEmpty) {
            final lower = _localSearch.toLowerCase();
            items = items.where((i) {
              return (i.title?.toLowerCase().contains(lower) ?? false) ||
                  (i.rawText?.toLowerCase().contains(lower) ?? false) ||
                  (i.summary?.toLowerCase().contains(lower) ?? false) ||
                  i.tags.any((t) => t.toLowerCase().contains(lower));
            }).toList();
          }

          return CustomScrollView(
            slivers: [
              if (!isSubPage) ...[
                const SliverToBoxAdapter(child: SizedBox(height: 60)),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Row(
                      children: [
                        const Text(
                          'Library',
                          style: TextStyle(
                            color: MijigiColors.textPrimary,
                            fontSize: 28,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.5,
                          ),
                        ),
                        const Spacer(),
                        GestureDetector(
                          onTap: () => setState(() => _showGrid = !_showGrid),
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: MijigiColors.surface,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: MijigiColors.border),
                            ),
                            child: Icon(
                              _showGrid
                                  ? Icons.grid_view_rounded
                                  : Icons.view_list_rounded,
                              color: MijigiColors.textSecondary,
                              size: 20,
                            ),
                          ),
                        ),
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
                    hint: _selectedCategory != null
                        ? 'Search ${_categoryTitle(_selectedCategory!).toLowerCase()}...'
                        : 'Search library...',
                    onChanged: (q) => setState(() => _localSearch = q),
                  ),
                ),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 16)),

              // Category filter chips (only on main library)
              if (!isSubPage && provider.activeCategories.isNotEmpty) ...[
                SliverToBoxAdapter(
                  child: SizedBox(
                    height: 36,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      children: [
                        _buildFilterChip('All', _selectedCategory == null, () {
                          setState(() => _selectedCategory = null);
                        }),
                        const SizedBox(width: 8),
                        ...provider.activeCategories.map((entry) {
                          return Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: _buildFilterChip(
                              _categoryTitle(entry.key),
                              _selectedCategory == entry.key,
                              () => setState(
                                  () => _selectedCategory = entry.key),
                            ),
                          );
                        }),
                      ],
                    ),
                  ),
                ),
                const SliverToBoxAdapter(child: SizedBox(height: 16)),
              ],

              // Items
              if (items.isEmpty)
                SliverToBoxAdapter(child: _buildEmpty())
              else if (_showGrid)
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  sliver: SliverMasonryGrid.count(
                    crossAxisCount: 2,
                    mainAxisSpacing: 10,
                    crossAxisSpacing: 10,
                    childCount: items.length,
                    itemBuilder: (context, index) {
                      return CaptureCard(
                        item: items[index],
                        onTap: () => _openItem(items[index]),
                        onLongPress: () =>
                            _showActions(provider, items[index]),
                      );
                    },
                  ),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 10),
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
