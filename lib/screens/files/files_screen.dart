import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../models/capture_item.dart';
import '../../providers/app_provider.dart';
import '../../services/file_scanner_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/mijigi_search_bar.dart';
import '../item_detail/item_detail_screen.dart';
import '../scanner/scanner_review_screen.dart';

class FilesScreen extends StatefulWidget {
  const FilesScreen({super.key});

  @override
  State<FilesScreen> createState() => _FilesScreenState();
}

class _FilesScreenState extends State<FilesScreen> {
  bool _isScanning = false;
  String _scanStatus = '';
  String _selectedFilter = 'all';
  String _localSearch = '';

  List<CaptureItem> _getFileItems(AppProvider provider) {
    var items = provider.activeItems.where((i) =>
        i.type == CaptureType.document ||
        i.type == CaptureType.link ||
        i.type == CaptureType.voice ||
        i.type == CaptureType.note).toList();

    if (_selectedFilter == 'pdf') {
      items = items.where((i) =>
          i.filePath?.toLowerCase().endsWith('.pdf') == true).toList();
    } else if (_selectedFilter == 'docs') {
      items = items.where((i) {
        final path = i.filePath?.toLowerCase() ?? '';
        return path.endsWith('.doc') || path.endsWith('.docx') ||
            path.endsWith('.txt') || path.endsWith('.rtf');
      }).toList();
    } else if (_selectedFilter == 'spreadsheets') {
      items = items.where((i) {
        final path = i.filePath?.toLowerCase() ?? '';
        return path.endsWith('.xls') || path.endsWith('.xlsx') ||
            path.endsWith('.csv') || path.endsWith('.ods');
      }).toList();
    } else if (_selectedFilter == 'notes') {
      items = items.where((i) => i.type == CaptureType.note).toList();
    }

    if (_localSearch.isNotEmpty) {
      final lower = _localSearch.toLowerCase();
      items = items.where((i) {
        return (i.title?.toLowerCase().contains(lower) ?? false) ||
            (i.rawText?.toLowerCase().contains(lower) ?? false) ||
            (i.filePath?.toLowerCase().contains(lower) ?? false);
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
            i.type != CaptureType.photo && i.type != CaptureType.screenshot &&
            i.type != CaptureType.clipboard && i.type != CaptureType.video).toList();

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
              path.endsWith('.csv') || path.endsWith('.ods');
        }).length;
        final noteCount = allFiles.where((i) => i.type == CaptureType.note).length;

        return Scaffold(
          backgroundColor: MijigiColors.background,
          body: CustomScrollView(
            slivers: [
              const SliverToBoxAdapter(child: SizedBox(height: 60)),

              // Header
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: const Text(
                    'Documents',
                    style: TextStyle(
                      color: MijigiColors.textPrimary,
                      fontSize: 28,
                      fontWeight: FontWeight.w300,
                      letterSpacing: -0.5,
                    ),
                  ),
                ),
              ),

              const SliverToBoxAdapter(child: SizedBox(height: 20)),

              // Scanner hero card
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: GestureDetector(
                    onTap: () => _scanDocument(context, provider),
                    child: Container(
                      padding: const EdgeInsets.all(22),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            Color(0xFF1A3A62),
                            Color(0xFF132844),
                            Color(0xFF0A1A30),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: MijigiColors.primary.withValues(alpha: 0.15),
                          width: 0.5,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: MijigiColors.primary.withValues(alpha: 0.08),
                            blurRadius: 20,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 52,
                            height: 52,
                            decoration: BoxDecoration(
                              color: MijigiColors.primary.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: const Icon(
                              Icons.document_scanner_rounded,
                              color: MijigiColors.primaryLight,
                              size: 26,
                            ),
                          ),
                          const SizedBox(width: 18),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Scan Document',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 17,
                                    fontWeight: FontWeight.w500,
                                    letterSpacing: -0.2,
                                  ),
                                ),
                                const SizedBox(height: 5),
                                Text(
                                  'Multi-page  /  Filters  /  Rotate  /  Export PDF',
                                  style: TextStyle(
                                    color: Colors.white.withValues(alpha: 0.45),
                                    fontSize: 12,
                                    fontWeight: FontWeight.w400,
                                    letterSpacing: 0.2,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Icon(
                            Icons.arrow_forward_ios_rounded,
                            color: Colors.white.withValues(alpha: 0.3),
                            size: 14,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

              const SliverToBoxAdapter(child: SizedBox(height: 18)),

              // Quick actions row
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Row(
                    children: [
                      _QuickAction(
                        icon: Icons.note_add_rounded,
                        label: 'Note',
                        color: MijigiColors.fileNote,
                        onTap: () => _createNote(provider),
                      ),
                      const SizedBox(width: 12),
                      _QuickAction(
                        icon: Icons.radar_rounded,
                        label: 'Scan Device',
                        color: MijigiColors.accent,
                        isLoading: _isScanning,
                        onTap: _isScanning ? null : () => _startScan(provider),
                      ),
                    ],
                  ),
                ),
              ),

              if (_isScanning)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.only(left: 20, right: 20, top: 12),
                    child: Text(
                      _scanStatus,
                      style: TextStyle(
                        color: MijigiColors.textTertiary.withValues(alpha: 0.7),
                        fontSize: 12,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ),
                ),

              const SliverToBoxAdapter(child: SizedBox(height: 18)),

              // Search
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: MijigiSearchBar(
                    hint: 'Search documents...',
                    onChanged: (q) => setState(() => _localSearch = q),
                  ),
                ),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 14)),

              // Filter chips
              SliverToBoxAdapter(
                child: SizedBox(
                  height: 34,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    children: [
                      _chip('All', allFiles.length, _selectedFilter == 'all',
                          () => setState(() => _selectedFilter = 'all')),
                      if (pdfCount > 0) ...[
                        const SizedBox(width: 8),
                        _chip('PDF', pdfCount, _selectedFilter == 'pdf',
                            () => setState(() => _selectedFilter = 'pdf')),
                      ],
                      if (docCount > 0) ...[
                        const SizedBox(width: 8),
                        _chip('Documents', docCount, _selectedFilter == 'docs',
                            () => setState(() => _selectedFilter = 'docs')),
                      ],
                      if (spreadsheetCount > 0) ...[
                        const SizedBox(width: 8),
                        _chip('Spreadsheets', spreadsheetCount,
                            _selectedFilter == 'spreadsheets',
                            () => setState(() => _selectedFilter = 'spreadsheets')),
                      ],
                      if (noteCount > 0) ...[
                        const SizedBox(width: 8),
                        _chip('Notes', noteCount, _selectedFilter == 'notes',
                            () => setState(() => _selectedFilter = 'notes')),
                      ],
                    ],
                  ),
                ),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 14)),

              // File list
              if (fileItems.isEmpty)
                SliverToBoxAdapter(child: _buildEmpty())
              else
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: _FileCard(
                            item: fileItems[index],
                            onTap: () => _openItem(fileItems[index]),
                            onLongPress: () =>
                                _showActions(provider, fileItems[index]),
                          ),
                        );
                      },
                      childCount: fileItems.length,
                    ),
                  ),
                ),

              const SliverToBoxAdapter(child: SizedBox(height: 100)),
            ],
          ),
        );
      },
    );
  }

  Widget _chip(String label, int count, bool active, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
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
      padding: const EdgeInsets.only(top: 50),
      child: Center(
        child: Column(
          children: [
            Icon(Icons.folder_open_rounded,
                size: 44,
                color: MijigiColors.textTertiary.withValues(alpha: 0.4)),
            const SizedBox(height: 16),
            const Text('No documents yet',
                style: TextStyle(
                    color: MijigiColors.textSecondary,
                    fontSize: 16,
                    fontWeight: FontWeight.w500)),
            const SizedBox(height: 8),
            const Text('Scan a document or create a note',
                style:
                    TextStyle(color: MijigiColors.textTertiary, fontSize: 13,
                        fontWeight: FontWeight.w400)),
          ],
        ),
      ),
    );
  }

  Future<void> _scanDocument(BuildContext context, AppProvider provider) async {
    final picker = ImagePicker();
    final XFile? photo = await picker.pickImage(
      source: ImageSource.camera,
      imageQuality: 95,
    );
    if (photo != null && context.mounted) {
      final result = await Navigator.push<bool>(
        context,
        MaterialPageRoute(
          builder: (_) => ScannerReviewScreen(initialImagePath: photo.path),
        ),
      );
      if (result == true) {
        provider.reloadItems();
      }
    }
  }

  void _createNote(AppProvider provider) {
    final controller = TextEditingController();
    final titleController = TextEditingController();
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => Container(
        decoration: MijigiGradients.frostedSheet(),
        child: Padding(
          padding: EdgeInsets.only(
            left: 20, right: 20, top: 20,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 36, height: 4,
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                  color: MijigiColors.textTertiary.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              TextField(
                controller: titleController,
                style: const TextStyle(
                    color: MijigiColors.textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.w500),
                decoration: const InputDecoration(
                  hintText: 'Title',
                  hintStyle: TextStyle(color: MijigiColors.textTertiary),
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: controller,
                autofocus: true,
                maxLines: 6,
                minLines: 3,
                style: const TextStyle(
                    color: MijigiColors.textPrimary, fontSize: 14,
                    fontWeight: FontWeight.w400),
                decoration: const InputDecoration(
                  hintText: 'Write your note...',
                  hintStyle: TextStyle(color: MijigiColors.textTertiary),
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: Container(
                  decoration: BoxDecoration(
                    gradient: MijigiGradients.buttonGradient,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      shadowColor: Colors.transparent,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16)),
                    ),
                    onPressed: () async {
                      if (controller.text.trim().isNotEmpty) {
                        await provider.captureNote(
                          controller.text.trim(),
                          title: titleController.text.trim().isEmpty
                              ? null
                              : titleController.text.trim(),
                        );
                        if (ctx.mounted) Navigator.pop(ctx);
                      }
                    },
                    child: const Text('Save Note',
                        style: TextStyle(fontWeight: FontWeight.w600)),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _startScan(AppProvider provider) async {
    final scanner = FileScannerService();
    final hasPermission = await scanner.requestPermission();
    if (!hasPermission) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Storage access denied',
                style: TextStyle(color: Colors.white)),
            backgroundColor: MijigiColors.surfaceLight,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14)),
          ),
        );
      }
      return;
    }

    setState(() {
      _isScanning = true;
      _scanStatus = 'Scanning device files...';
    });

    await scanner.scanDeviceFiles();
    setState(() => _scanStatus = 'Importing files...');

    final existingPaths = provider.items
        .where((i) => i.filePath != null)
        .map((i) => i.filePath!)
        .toSet();

    await for (final progress in scanner.importFiles(
      storage: provider.storage,
      existingFilePaths: existingPaths,
    )) {
      setState(() {
        _scanStatus =
            'Processing ${progress.processed}/${progress.totalFound}: ${progress.currentFile}';
      });

      if (progress.status == FileScanStatus.complete) {
        provider.reloadItems();
      }
    }

    setState(() => _isScanning = false);
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
                  width: 36, height: 4,
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

// --- Quick action button ---
class _QuickAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback? onTap;
  final bool isLoading;

  const _QuickAction({
    required this.icon,
    required this.label,
    required this.color,
    this.onTap,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            gradient: MijigiGradients.cardGradient,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: color.withValues(alpha: 0.12),
              width: 0.5,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (isLoading)
                SizedBox(
                  width: 16, height: 16,
                  child: CircularProgressIndicator(
                      strokeWidth: 1.5, color: color),
                )
              else
                Icon(icon, color: color.withValues(alpha: 0.8), size: 18),
              const SizedBox(width: 10),
              Text(
                label,
                style: TextStyle(
                  color: color.withValues(alpha: 0.9),
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// --- File card with left color accent stripe ---
class _FileCard extends StatelessWidget {
  final CaptureItem item;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;

  const _FileCard(
      {required this.item, required this.onTap, this.onLongPress});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      onLongPress: onLongPress,
      child: Container(
        decoration: BoxDecoration(
          gradient: MijigiGradients.cardGradient,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: MijigiColors.border.withValues(alpha: 0.4),
            width: 0.5,
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: IntrinsicHeight(
          child: Row(
            children: [
              // Left color accent stripe
              Container(
                width: 3,
                decoration: BoxDecoration(
                  color: _iconColor,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(16),
                    bottomLeft: Radius.circular(16),
                  ),
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: _iconColor.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(_icon, color: _iconColor.withValues(alpha: 0.8), size: 20),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              item.displayTitle,
                              style: const TextStyle(
                                color: MijigiColors.textPrimary,
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                letterSpacing: -0.1,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _subtitle,
                              style: TextStyle(
                                color: MijigiColors.textTertiary.withValues(alpha: 0.7),
                                fontSize: 12,
                                fontWeight: FontWeight.w400,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (item.isPinned)
                        Icon(Icons.push_pin_rounded,
                            size: 14, color: MijigiColors.primaryLight.withValues(alpha: 0.7)),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String get _subtitle {
    final parts = <String>[];
    if (_fileExtension.isNotEmpty) parts.add(_fileExtension);
    parts.add(_formatDate(item.createdAt));
    return parts.join('  /  ');
  }

  String get _fileExtension {
    if (item.filePath == null) return '';
    final parts = item.filePath!.split('.');
    if (parts.length < 2) return '';
    return parts.last.toUpperCase();
  }

  Color get _iconColor {
    final ext = _fileExtension.toLowerCase();
    if (ext == 'pdf') return MijigiColors.filePdf;
    if (['doc', 'docx', 'rtf'].contains(ext)) return MijigiColors.fileDoc;
    if (['xls', 'xlsx', 'csv'].contains(ext)) return MijigiColors.fileSheet;
    if (item.type == CaptureType.note) return MijigiColors.fileNote;
    return MijigiColors.textSecondary;
  }

  IconData get _icon {
    final ext = _fileExtension.toLowerCase();
    if (ext == 'pdf') return Icons.picture_as_pdf_rounded;
    if (['doc', 'docx', 'rtf'].contains(ext)) return Icons.description_rounded;
    if (['xls', 'xlsx', 'csv'].contains(ext)) return Icons.table_chart_rounded;
    if (item.type == CaptureType.note) return Icons.sticky_note_2_rounded;
    if (item.type == CaptureType.link) return Icons.link_rounded;
    return Icons.insert_drive_file_rounded;
  }

  String _formatDate(DateTime date) {
    final diff = DateTime.now().difference(date);
    if (diff.inMinutes < 1) return 'now';
    if (diff.inHours < 1) return '${diff.inMinutes}m ago';
    if (diff.inDays < 1) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
        'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${months[date.month - 1]} ${date.day}';
  }
}
