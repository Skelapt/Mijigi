import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../models/capture_item.dart';
import '../../providers/app_provider.dart';
import '../../theme/app_theme.dart';
import '../../widgets/mijigi_search_bar.dart';
import '../../widgets/capture_card.dart';
import '../../widgets/collection_tile.dart';
import '../../widgets/quick_action_button.dart';
import '../../widgets/command_bar.dart';
import '../../widgets/import_banner.dart';
import '../agent/agent_screen.dart';
import '../item_detail/item_detail_screen.dart';
import '../library/library_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _searchController = TextEditingController();

  String get _greeting {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning';
    if (hour < 17) return 'Good afternoon';
    return 'Good evening';
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AppProvider>(
      builder: (context, provider, _) {
        final isSearching = provider.searchQuery.isNotEmpty;

        return CustomScrollView(
          slivers: [
            // Top padding
            const SliverToBoxAdapter(child: SizedBox(height: 60)),

            // Greeting
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _greeting,
                      style: const TextStyle(
                        color: MijigiColors.textTertiary,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        const Text(
                          'Mijigi',
                          style: TextStyle(
                            color: MijigiColors.textPrimary,
                            fontSize: 28,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.5,
                          ),
                        ),
                        if (provider.isProcessing) ...[
                          const SizedBox(width: 12),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: MijigiColors.accent.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                SizedBox(
                                  width: 10,
                                  height: 10,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 1.5,
                                    color: MijigiColors.accent,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                const Text(
                                  'Processing',
                                  style: TextStyle(
                                    color: MijigiColors.accent,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 20)),

            // Search bar
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: MijigiSearchBar(
                  controller: _searchController,
                  onChanged: (q) => provider.search(q),
                ),
              ),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 14)),

            // Agent command bar
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: CommandBar(
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const AgentScreen()),
                  ),
                ),
              ),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 24)),

            if (isSearching)
              _buildSearchResults(provider)
            else ...[
              // Import banner
              if (provider.totalItems == 0 || provider.isImporting)
                const SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.only(bottom: 20),
                    child: ImportBanner(),
                  ),
                ),

              // Quick actions
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      QuickActionButton(
                        icon: Icons.camera_alt_rounded,
                        label: 'Camera',
                        color: MijigiColors.primary,
                        onTap: () => _captureCamera(provider),
                      ),
                      QuickActionButton(
                        icon: Icons.photo_library_rounded,
                        label: 'Gallery',
                        color: MijigiColors.accent,
                        onTap: () => _captureGallery(provider),
                      ),
                      QuickActionButton(
                        icon: Icons.edit_note_rounded,
                        label: 'Note',
                        color: MijigiColors.warning,
                        onTap: () => _captureNote(context, provider),
                      ),
                      QuickActionButton(
                        icon: Icons.content_paste_rounded,
                        label: 'Clipboard',
                        color: MijigiColors.categoryMedical,
                        onTap: () => _captureClipboard(provider),
                      ),
                    ],
                  ),
                ),
              ),

              const SliverToBoxAdapter(child: SizedBox(height: 28)),

              // Smart Collections
              if (provider.activeCategories.isNotEmpty) ...[
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Row(
                      children: [
                        const Text(
                          'Collections',
                          style: TextStyle(
                            color: MijigiColors.textPrimary,
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const Spacer(),
                        GestureDetector(
                          onTap: () => provider.setTab(1),
                          child: const Text(
                            'See all',
                            style: TextStyle(
                              color: MijigiColors.primary,
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SliverToBoxAdapter(child: SizedBox(height: 12)),
                SliverToBoxAdapter(
                  child: SizedBox(
                    height: 120,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      itemCount: provider.activeCategories.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 10),
                      itemBuilder: (context, index) {
                        final entry = provider.activeCategories[index];
                        return SizedBox(
                          width: 140,
                          child: CollectionTile(
                            category: entry.key,
                            count: entry.value,
                            onTap: () => _openCategory(context, entry.key),
                          ),
                        );
                      },
                    ),
                  ),
                ),
                const SliverToBoxAdapter(child: SizedBox(height: 28)),
              ],

              // Recent items
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Row(
                    children: [
                      const Text(
                        'Recent',
                        style: TextStyle(
                          color: MijigiColors.textPrimary,
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        '${provider.totalItems} items',
                        style: const TextStyle(
                          color: MijigiColors.textTertiary,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 12)),

              if (provider.recentItems.isEmpty)
                SliverToBoxAdapter(
                  child: _buildEmptyState(),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final item = provider.recentItems[index];
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: CaptureCard(
                            item: item,
                            onTap: () => _openItem(context, item),
                            onLongPress: () =>
                                _showItemActions(context, provider, item),
                          ),
                        );
                      },
                      childCount: provider.recentItems.length,
                    ),
                  ),
                ),
            ],

            const SliverToBoxAdapter(child: SizedBox(height: 100)),
          ],
        );
      },
    );
  }

  Widget _buildSearchResults(AppProvider provider) {
    if (provider.searchResults.isEmpty) {
      return SliverToBoxAdapter(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.only(top: 60),
            child: Column(
              children: [
                Icon(
                  Icons.search_off_rounded,
                  size: 48,
                  color: MijigiColors.textTertiary.withValues(alpha: 0.5),
                ),
                const SizedBox(height: 12),
                const Text(
                  'No results found',
                  style: TextStyle(
                    color: MijigiColors.textTertiary,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            final result = provider.searchResults[index];
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: CaptureCard(
                item: result.item,
                onTap: () => _openItem(context, result.item),
              ),
            );
          },
          childCount: provider.searchResults.length,
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
      child: Column(
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: MijigiColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(24),
            ),
            child: const Icon(
              Icons.add_photo_alternate_rounded,
              size: 36,
              color: MijigiColors.primary,
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Capture your first item',
            style: TextStyle(
              color: MijigiColors.textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Take a photo, import from gallery, or\njot down a quick note to get started.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: MijigiColors.textTertiary,
              fontSize: 14,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  void _captureCamera(AppProvider provider) async {
    final item = await provider.captureFromCamera();
    if (item != null && mounted) {
      _openItem(context, item);
    }
  }

  void _captureGallery(AppProvider provider) async {
    final item = await provider.captureFromGallery();
    if (item != null && mounted) {
      _openItem(context, item);
    }
  }

  void _captureNote(BuildContext context, AppProvider provider) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: MijigiColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => _NoteSheet(
        onSave: (text, title) async {
          Navigator.pop(ctx);
          await provider.captureNote(text, title: title);
        },
      ),
    );
  }

  void _captureClipboard(AppProvider provider) async {
    // Get clipboard data
    final data = await _getClipboardText();
    if (data != null && data.isNotEmpty) {
      await provider.captureClipboard(data);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Clipboard saved'),
            backgroundColor: MijigiColors.surfaceLight,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Clipboard is empty'),
            backgroundColor: MijigiColors.surfaceLight,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
    }
  }

  Future<String?> _getClipboardText() async {
    try {
      final data = await Clipboard.getData(Clipboard.kTextPlain);
      return data?.text;
    } catch (_) {
      return null;
    }
  }

  void _openItem(BuildContext context, CaptureItem item) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ItemDetailScreen(itemId: item.id),
      ),
    );
  }

  void _openCategory(BuildContext context, ItemCategory category) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => LibraryScreen(filterCategory: category),
      ),
    );
  }

  void _showItemActions(
      BuildContext context, AppProvider provider, CaptureItem item) {
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
}

class _NoteSheet extends StatefulWidget {
  final Future<void> Function(String text, String? title) onSave;

  const _NoteSheet({required this.onSave});

  @override
  State<_NoteSheet> createState() => _NoteSheetState();
}

class _NoteSheetState extends State<_NoteSheet> {
  final _titleController = TextEditingController();
  final _textController = TextEditingController();

  @override
  void dispose() {
    _titleController.dispose();
    _textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 16,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            width: 36,
            height: 4,
            margin: const EdgeInsets.only(bottom: 16),
            alignment: Alignment.center,
            child: Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: MijigiColors.textTertiary.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const Text(
            'Quick Note',
            style: TextStyle(
              color: MijigiColors.textPrimary,
              fontSize: 20,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _titleController,
            style: const TextStyle(color: MijigiColors.textPrimary),
            decoration: const InputDecoration(
              hintText: 'Title (optional)',
            ),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _textController,
            autofocus: true,
            maxLines: 5,
            minLines: 3,
            style: const TextStyle(color: MijigiColors.textPrimary),
            decoration: const InputDecoration(
              hintText: 'Type your note...',
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () {
              if (_textController.text.trim().isNotEmpty) {
                widget.onSave(
                  _textController.text.trim(),
                  _titleController.text.trim().isNotEmpty
                      ? _titleController.text.trim()
                      : null,
                );
              }
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
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
