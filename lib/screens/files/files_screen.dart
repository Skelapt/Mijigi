import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/app_provider.dart';
import '../../services/file_scanner_service.dart';
import '../../theme/app_theme.dart';
import '../item_detail/item_detail_screen.dart';

class FilesScreen extends StatefulWidget {
  const FilesScreen({super.key});

  @override
  State<FilesScreen> createState() => _FilesScreenState();
}

class _FilesScreenState extends State<FilesScreen> {
  List<ScannedFile>? _scannedFiles;
  StorageBreakdown? _storage;
  List<DuplicateGroup>? _duplicates;
  bool _isScanning = false;
  String _scanStatus = '';
  String _selectedFilter = 'all';

  @override
  Widget build(BuildContext context) {
    return Consumer<AppProvider>(
      builder: (context, provider, _) {
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
                    const Text(
                      'Files',
                      style: TextStyle(
                        color: MijigiColors.textPrimary,
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _scannedFiles != null
                          ? '${_scannedFiles!.length} files found on device'
                          : 'Scan your device to find and organise files',
                      style: const TextStyle(
                        color: MijigiColors.textTertiary,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 20)),

            // Scan button or progress
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: _isScanning
                    ? _buildScanProgress()
                    : _buildScanButton(provider),
              ),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 20)),

            // Storage breakdown
            if (_storage != null) ...[
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: _buildStorageCard(),
                ),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 16)),
            ],

            // Duplicates alert
            if (_duplicates != null && _duplicates!.isNotEmpty) ...[
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: _buildDuplicatesCard(),
                ),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 16)),
            ],

            // File type filters
            if (_scannedFiles != null && _scannedFiles!.isNotEmpty) ...[
              SliverToBoxAdapter(
                child: SizedBox(
                  height: 40,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    children: [
                      _FilterChip(
                        label: 'All',
                        count: _scannedFiles!.length,
                        isActive: _selectedFilter == 'all',
                        onTap: () => setState(() => _selectedFilter = 'all'),
                      ),
                      const SizedBox(width: 8),
                      _FilterChip(
                        label: 'Documents',
                        count: _storage?.documentCount ?? 0,
                        isActive: _selectedFilter == 'documents',
                        color: MijigiColors.categoryDocument,
                        onTap: () =>
                            setState(() => _selectedFilter = 'documents'),
                      ),
                      const SizedBox(width: 8),
                      _FilterChip(
                        label: 'Images',
                        count: _storage?.imageCount ?? 0,
                        isActive: _selectedFilter == 'images',
                        color: MijigiColors.categoryPersonal,
                        onTap: () =>
                            setState(() => _selectedFilter = 'images'),
                      ),
                      const SizedBox(width: 8),
                      _FilterChip(
                        label: 'Audio',
                        count: _storage?.audioCount ?? 0,
                        isActive: _selectedFilter == 'audio',
                        color: MijigiColors.categoryWork,
                        onTap: () =>
                            setState(() => _selectedFilter = 'audio'),
                      ),
                      const SizedBox(width: 8),
                      _FilterChip(
                        label: 'Video',
                        count: _storage?.videoCount ?? 0,
                        isActive: _selectedFilter == 'video',
                        color: MijigiColors.categoryTravel,
                        onTap: () =>
                            setState(() => _selectedFilter = 'video'),
                      ),
                    ],
                  ),
                ),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 16)),

              // File list
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final filtered = _filteredFiles;
                      if (index >= filtered.length) return null;
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: _FileCard(
                          file: filtered[index],
                          onTap: () => _openFile(context, provider, filtered[index]),
                        ),
                      );
                    },
                    childCount: _filteredFiles.length.clamp(0, 50),
                  ),
                ),
              ),

              if (_filteredFiles.length > 50)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 8),
                    child: Text(
                      'Showing 50 of ${_filteredFiles.length} files',
                      style: const TextStyle(
                        color: MijigiColors.textTertiary,
                        fontSize: 13,
                      ),
                      textAlign: TextAlign.center,
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

  List<ScannedFile> get _filteredFiles {
    if (_scannedFiles == null) return [];
    return switch (_selectedFilter) {
      'documents' => _scannedFiles!.where((f) => f.isDocument).toList(),
      'images' => _scannedFiles!.where((f) => f.isImage).toList(),
      'audio' => _scannedFiles!.where((f) => f.isAudio).toList(),
      'video' => _scannedFiles!.where((f) => f.isVideo).toList(),
      _ => _scannedFiles!,
    };
  }

  Widget _buildScanButton(AppProvider provider) {
    return GestureDetector(
      onTap: () => _startScan(provider),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              MijigiColors.accent.withValues(alpha: 0.15),
              MijigiColors.primary.withValues(alpha: 0.08),
            ],
          ),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: MijigiColors.accent.withValues(alpha: 0.2),
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: MijigiColors.accent.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.folder_open_rounded,
                color: MijigiColors.accent,
                size: 24,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _scannedFiles != null ? 'Scan Again' : 'Scan Device Files',
                    style: const TextStyle(
                      color: MijigiColors.textPrimary,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const Text(
                    'Find PDFs, documents, and files on your device',
                    style: TextStyle(
                      color: MijigiColors.textTertiary,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.arrow_forward_rounded,
              color: MijigiColors.accent,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildScanProgress() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: MijigiColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: MijigiColors.border),
      ),
      child: Column(
        children: [
          Row(
            children: [
              SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: MijigiColors.accent,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  _scanStatus,
                  style: const TextStyle(
                    color: MijigiColors.textPrimary,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStorageCard() {
    final s = _storage!;
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: MijigiColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: MijigiColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.storage_rounded,
                  size: 18, color: MijigiColors.accent),
              const SizedBox(width: 8),
              const Text(
                'Storage Overview',
                style: TextStyle(
                  color: MijigiColors.textPrimary,
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const Spacer(),
              Text(
                s.totalSizeFormatted,
                style: const TextStyle(
                  color: MijigiColors.accent,
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Visual bar
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: SizedBox(
              height: 12,
              child: Row(
                children: [
                  if (s.documentCount > 0)
                    _BarSegment(
                        flex: s.documentCount,
                        color: MijigiColors.categoryDocument),
                  if (s.imageCount > 0)
                    _BarSegment(
                        flex: s.imageCount,
                        color: MijigiColors.categoryPersonal),
                  if (s.audioCount > 0)
                    _BarSegment(
                        flex: s.audioCount,
                        color: MijigiColors.categoryWork),
                  if (s.videoCount > 0)
                    _BarSegment(
                        flex: s.videoCount,
                        color: MijigiColors.categoryTravel),
                  if (s.otherCount > 0)
                    _BarSegment(
                        flex: s.otherCount,
                        color: MijigiColors.textTertiary),
                ],
              ),
            ),
          ),
          const SizedBox(height: 14),

          // Legend
          Wrap(
            spacing: 16,
            runSpacing: 8,
            children: [
              _LegendItem(
                  color: MijigiColors.categoryDocument,
                  label: 'Documents',
                  count: s.documentCount),
              _LegendItem(
                  color: MijigiColors.categoryPersonal,
                  label: 'Images',
                  count: s.imageCount),
              _LegendItem(
                  color: MijigiColors.categoryWork,
                  label: 'Audio',
                  count: s.audioCount),
              _LegendItem(
                  color: MijigiColors.categoryTravel,
                  label: 'Video',
                  count: s.videoCount),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDuplicatesCard() {
    final totalWasted = _duplicates!.fold<int>(
        0, (sum, d) => sum + d.wastedBytes);

    String wastedFormatted;
    if (totalWasted < 1024 * 1024) {
      wastedFormatted = '${(totalWasted / 1024).toStringAsFixed(0)}KB';
    } else {
      wastedFormatted =
          '${(totalWasted / (1024 * 1024)).toStringAsFixed(1)}MB';
    }

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: MijigiColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: MijigiColors.warning.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: MijigiColors.warning.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.file_copy_rounded,
              color: MijigiColors.warning,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${_duplicates!.length} duplicate groups found',
                  style: const TextStyle(
                    color: MijigiColors.textPrimary,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  '$wastedFormatted could be freed',
                  style: const TextStyle(
                    color: MijigiColors.warning,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
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
            content:
                const Text('Storage access denied. Enable in Settings.'),
            backgroundColor: MijigiColors.surfaceLight,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
      return;
    }

    setState(() {
      _isScanning = true;
      _scanStatus = 'Scanning device files...';
    });

    // Phase 1: Scan
    final files = await scanner.scanDeviceFiles();
    setState(() {
      _scannedFiles = files;
      _storage = scanner.analyzeStorage(files);
      _scanStatus = 'Checking for duplicates...';
    });

    // Phase 2: Find duplicates
    final duplicates = await scanner.findDuplicates(files);
    setState(() {
      _duplicates = duplicates;
      _scanStatus = 'Importing files...';
    });

    // Phase 3: Import documents into Mijigi
    final existingPaths = provider.items
        .where((i) => i.filePath != null)
        .map((i) => i.filePath!)
        .toSet();

    // Only import documents and PDFs (not images - those go through photo import)
    final docsToImport = files.where((f) => f.isDocument && !f.isImage).toList();
    final newDocs =
        docsToImport.where((f) => !existingPaths.contains(f.path)).toList();

    if (newDocs.isNotEmpty) {
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
    }

    setState(() {
      _isScanning = false;
    });
  }

  void _openFile(BuildContext context, AppProvider provider, ScannedFile file) {
    // Check if this file is already in Mijigi
    final existing = provider.items.where((i) => i.filePath == file.path).firstOrNull;
    if (existing != null) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ItemDetailScreen(itemId: existing.id),
        ),
      );
    } else {
      // Show file info
      _showFileInfo(context, file);
    }
  }

  void _showFileInfo(BuildContext context, ScannedFile file) {
    showModalBottomSheet(
      context: context,
      backgroundColor: MijigiColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
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
              Text(
                file.name,
                style: const TextStyle(
                  color: MijigiColors.textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 12),
              _InfoRow(label: 'Size', value: file.sizeFormatted),
              _InfoRow(label: 'Type', value: file.mimeType ?? file.extension),
              _InfoRow(
                  label: 'Modified',
                  value: _formatDate(file.modified)),
              _InfoRow(label: 'Path', value: file.path),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final int count;
  final bool isActive;
  final Color? color;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.count,
    required this.isActive,
    this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final chipColor = color ?? MijigiColors.primary;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isActive
              ? chipColor.withValues(alpha: 0.15)
              : MijigiColors.surface,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isActive
                ? chipColor.withValues(alpha: 0.3)
                : MijigiColors.border,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: TextStyle(
                color: isActive ? chipColor : MijigiColors.textSecondary,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(width: 6),
            Text(
              '$count',
              style: TextStyle(
                color: isActive
                    ? chipColor
                    : MijigiColors.textTertiary,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FileCard extends StatelessWidget {
  final ScannedFile file;
  final VoidCallback? onTap;

  const _FileCard({required this.file, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: MijigiColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: MijigiColors.border),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: _fileColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Center(
                child: Icon(_fileIcon, color: _fileColor, size: 20),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    file.name,
                    style: const TextStyle(
                      color: MijigiColors.textPrimary,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    '${file.sizeFormatted} \u2022 ${file.extension}',
                    style: const TextStyle(
                      color: MijigiColors.textTertiary,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
            Text(
              _formatDate(file.modified),
              style: const TextStyle(
                color: MijigiColors.textTertiary,
                fontSize: 11,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color get _fileColor {
    if (file.isPdf) return MijigiColors.error;
    if (file.isDocument) return MijigiColors.categoryDocument;
    if (file.isImage) return MijigiColors.categoryPersonal;
    if (file.isAudio) return MijigiColors.categoryWork;
    if (file.isVideo) return MijigiColors.categoryTravel;
    return MijigiColors.textTertiary;
  }

  IconData get _fileIcon {
    if (file.isPdf) return Icons.picture_as_pdf_rounded;
    if (file.isDocument) return Icons.description_rounded;
    if (file.isImage) return Icons.image_rounded;
    if (file.isAudio) return Icons.audiotrack_rounded;
    if (file.isVideo) return Icons.videocam_rounded;
    return Icons.insert_drive_file_rounded;
  }

  String _formatDate(DateTime date) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return '${months[date.month - 1]} ${date.day}';
  }
}

class _BarSegment extends StatelessWidget {
  final int flex;
  final Color color;

  const _BarSegment({required this.flex, required this.color});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      flex: flex,
      child: Container(color: color),
    );
  }
}

class _LegendItem extends StatelessWidget {
  final Color color;
  final String label;
  final int count;

  const _LegendItem({
    required this.color,
    required this.label,
    required this.count,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 4),
        Text(
          '$label ($count)',
          style: const TextStyle(
            color: MijigiColors.textSecondary,
            fontSize: 12,
          ),
        ),
      ],
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 70,
            child: Text(
              label,
              style: const TextStyle(
                color: MijigiColors.textTertiary,
                fontSize: 13,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                color: MijigiColors.textPrimary,
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
