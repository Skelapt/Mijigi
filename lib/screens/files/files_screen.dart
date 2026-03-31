import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/capture_item.dart';
import '../../providers/app_provider.dart';
import '../../theme/app_theme.dart';
import '../../widgets/mijigi_search_bar.dart';
import '../item_detail/item_detail_screen.dart';

class FilesScreen extends StatefulWidget {
  const FilesScreen({super.key});

  @override
  State<FilesScreen> createState() => _FilesScreenState();
}

class _FilesScreenState extends State<FilesScreen> {
  String _selectedFilter = 'all';
  String _localSearch = '';

  /// Get document/file items from persisted storage (not images)
  List<CaptureItem> _getFileItems(AppProvider provider) {
    var items = provider.activeItems.where((i) =>
        i.type == CaptureType.document ||
        i.type == CaptureType.clipboard ||
        i.type == CaptureType.link ||
        i.type == CaptureType.voice ||
        i.type == CaptureType.note).toList();

    // Apply file type filter
    if (_selectedFilter == 'pdf') {
      items = items.where((i) =>
          i.filePath?.toLowerCase().endsWith('.pdf') == true).toList();
    } else if (_selectedFilter == 'docs') {
      items = items.where((i) {
        final path = i.filePath?.toLowerCase() ?? '';
        return path.endsWith('.doc') || path.endsWith('.docx') ||
            path.endsWith('.txt') || path.endsWith('.rtf') ||
            path.endsWith('.odt');
      }).toList();
    } else if (_selectedFilter == 'spreadsheets') {
      items = items.where((i) {
        final path = i.filePath?.toLowerCase() ?? '';
        return path.endsWith('.xls') || path.endsWith('.xlsx') ||
            path.endsWith('.csv') || path.endsWith('.ods');
      }).toList();
    } else if (_selectedFilter == 'notes') {
      items = items.where((i) => i.type == CaptureType.note).toList();
    } else if (_selectedFilter == 'clipboard') {
      items = items.where((i) => i.type == CaptureType.clipboard).toList();
    }

    // Apply search
    if (_localSearch.isNotEmpty) {
      final lower = _localSearch.toLowerCase();
      items = items.where((i) {
        return (i.title?.toLowerCase().contains(lower) ?? false) ||
            (i.rawText?.toLowerCase().contains(lower) ?? false) ||
            (i.filePath?.toLowerCase().contains(lower) ?? false) ||
            i.tags.any((t) => t.toLowerCase().contains(lower));
      }).toList();
    }

    return items;
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AppProvider>(
      builder: (context, provider, _) {
        final fileItems = _getFileItems(provider);
        final allFiles = provider.activeItems.where((i) =>
            i.type != CaptureType.photo && i.type != CaptureType.screenshot).toList();

        // Count by type
        final pdfCount = allFiles.where((i) =>
            i.filePath?.toLowerCase().endsWith('.pdf') == true).length;
        final docCount = allFiles.where((i) {
          final path = i.filePath?.toLowerCase() ?? '';
          return path.endsWith('.doc') || path.endsWith('.docx') ||
              path.endsWith('.txt') || path.endsWith('.rtf');
        }).length;
        final spreadsheetCount = allFiles.where((i) {
          final path = i.filePath?.toLowerCase() ?? '';
          return path.endsWith('.xls') || path.endsWith('.xlsx') ||
              path.endsWith('.csv');
        }).length;
        final noteCount = allFiles.where((i) => i.type == CaptureType.note).length;
        final clipboardCount = allFiles.where((i) => i.type == CaptureType.clipboard).length;

        return CustomScrollView(
          slivers: [
            const SliverToBoxAdapter(child: SizedBox(height: 60)),

            // Title
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Files',
                              style: TextStyle(
                                color: MijigiColors.textPrimary,
                                fontSize: 28,
                                fontWeight: FontWeight.w800,
                                letterSpacing: -0.5,
                              ),
                            ),
                            Text(
                              '${allFiles.length} files',
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
                  ],
                ),
              ),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 16)),

            // Search
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: MijigiSearchBar(
                  hint: 'Search files...',
                  onChanged: (q) => setState(() => _localSearch = q),
                ),
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 16)),

            // File type filters
            SliverToBoxAdapter(
              child: SizedBox(
                height: 36,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  children: [
                    _buildChip('All', allFiles.length, _selectedFilter == 'all',
                        MijigiColors.primary, () => setState(() => _selectedFilter = 'all')),
                    const SizedBox(width: 8),
                    if (pdfCount > 0) ...[
                      _buildChip('PDF', pdfCount, _selectedFilter == 'pdf',
                          MijigiColors.error, () => setState(() => _selectedFilter = 'pdf')),
                      const SizedBox(width: 8),
                    ],
                    if (docCount > 0) ...[
                      _buildChip('Documents', docCount, _selectedFilter == 'docs',
                          MijigiColors.fileDoc, () => setState(() => _selectedFilter = 'docs')),
                      const SizedBox(width: 8),
                    ],
                    if (spreadsheetCount > 0) ...[
                      _buildChip('Spreadsheets', spreadsheetCount, _selectedFilter == 'spreadsheets',
                          MijigiColors.fileSheet, () => setState(() => _selectedFilter = 'spreadsheets')),
                      const SizedBox(width: 8),
                    ],
                    if (noteCount > 0) ...[
                      _buildChip('Notes', noteCount, _selectedFilter == 'notes',
                          MijigiColors.accent, () => setState(() => _selectedFilter = 'notes')),
                      const SizedBox(width: 8),
                    ],
                    if (clipboardCount > 0)
                      _buildChip('Clipboard', clipboardCount, _selectedFilter == 'clipboard',
                          MijigiColors.fileNote, () => setState(() => _selectedFilter = 'clipboard')),
                  ],
                ),
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 16)),

            // File list from persisted storage
            if (fileItems.isEmpty)
              SliverToBoxAdapter(child: _buildEmpty())
            else
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: _FileItemCard(
                          item: fileItems[index],
                          onTap: () => _openItem(fileItems[index]),
                          onLongPress: () => _showActions(provider, fileItems[index]),
                        ),
                      );
                    },
                    childCount: fileItems.length,
                  ),
                ),
              ),

            const SliverToBoxAdapter(child: SizedBox(height: 100)),
          ],
        );
      },
    );
  }

  Widget _buildChip(String label, int count, bool isActive, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isActive ? color.withValues(alpha: 0.15) : MijigiColors.surface,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isActive ? color.withValues(alpha: 0.3) : MijigiColors.border,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: TextStyle(
                color: isActive ? color : MijigiColors.textSecondary,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(width: 6),
            Text(
              '$count',
              style: TextStyle(
                color: isActive ? color : MijigiColors.textTertiary,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
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
              'No files yet',
              style: TextStyle(
                color: MijigiColors.textTertiary,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Tap "Scan Device" to find files\nor capture notes and documents',
              style: TextStyle(
                color: MijigiColors.textTertiary,
                fontSize: 13,
              ),
              textAlign: TextAlign.center,
            ),
          ],
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
                leading: Icon(
                  item.isPinned ? Icons.push_pin_outlined : Icons.push_pin_rounded,
                  color: MijigiColors.primary,
                ),
                title: Text(item.isPinned ? 'Unpin' : 'Pin'),
                onTap: () { Navigator.pop(ctx); provider.togglePin(item.id); },
              ),
              ListTile(
                leading: const Icon(Icons.archive_rounded, color: MijigiColors.warning),
                title: const Text('Archive'),
                onTap: () { Navigator.pop(ctx); provider.archiveItem(item.id); },
              ),
              ListTile(
                leading: const Icon(Icons.delete_rounded, color: MijigiColors.error),
                title: const Text('Delete'),
                onTap: () { Navigator.pop(ctx); provider.deleteItem(item.id); },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FileItemCard extends StatelessWidget {
  final CaptureItem item;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;

  const _FileItemCard({required this.item, required this.onTap, this.onLongPress});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      onLongPress: onLongPress,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: MijigiColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: MijigiColors.border),
        ),
        child: Row(
          children: [
            Container(
              width: 42, height: 42,
              decoration: BoxDecoration(
                color: _iconColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(11),
              ),
              child: Center(child: Icon(_icon, color: _iconColor, size: 20)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.displayTitle,
                    style: const TextStyle(
                      color: MijigiColors.textPrimary,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Text(
                        item.categoryLabel,
                        style: const TextStyle(
                          color: MijigiColors.textTertiary,
                          fontSize: 12,
                        ),
                      ),
                      if (item.filePath != null) ...[
                        const Text(' \u2022 ', style: TextStyle(color: MijigiColors.textTertiary, fontSize: 12)),
                        Text(
                          _fileExtension,
                          style: TextStyle(
                            color: _iconColor,
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            if (item.isPinned)
              const Padding(
                padding: EdgeInsets.only(left: 8),
                child: Icon(Icons.push_pin_rounded, size: 14, color: MijigiColors.primary),
              ),
            const SizedBox(width: 4),
            Text(
              _formatDate(item.createdAt),
              style: const TextStyle(color: MijigiColors.textTertiary, fontSize: 11),
            ),
          ],
        ),
      ),
    );
  }

  String get _fileExtension {
    if (item.filePath == null) return '';
    final parts = item.filePath!.split('.');
    if (parts.length < 2) return '';
    return parts.last.toUpperCase();
  }

  Color get _iconColor {
    final ext = _fileExtension.toLowerCase();
    if (ext == 'pdf') return MijigiColors.error;
    if (['doc', 'docx', 'rtf', 'odt'].contains(ext)) return MijigiColors.fileDoc;
    if (['xls', 'xlsx', 'csv', 'ods'].contains(ext)) return MijigiColors.fileSheet;
    if (item.type == CaptureType.note) return MijigiColors.accent;
    if (item.type == CaptureType.clipboard) return MijigiColors.fileNote;
    if (item.type == CaptureType.link) return MijigiColors.primary;
    return MijigiColors.textSecondary;
  }

  IconData get _icon {
    final ext = _fileExtension.toLowerCase();
    if (ext == 'pdf') return Icons.picture_as_pdf_rounded;
    if (['doc', 'docx', 'rtf', 'odt'].contains(ext)) return Icons.description_rounded;
    if (['xls', 'xlsx', 'csv', 'ods'].contains(ext)) return Icons.table_chart_rounded;
    if (item.type == CaptureType.note) return Icons.sticky_note_2_rounded;
    if (item.type == CaptureType.clipboard) return Icons.content_paste_rounded;
    if (item.type == CaptureType.link) return Icons.link_rounded;
    if (item.type == CaptureType.voice) return Icons.mic_rounded;
    return Icons.insert_drive_file_rounded;
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);
    if (diff.inMinutes < 1) return 'now';
    if (diff.inHours < 1) return '${diff.inMinutes}m';
    if (diff.inDays < 1) return '${diff.inHours}h';
    if (diff.inDays < 7) return '${diff.inDays}d';
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
        'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${months[date.month - 1]} ${date.day}';
  }
}

