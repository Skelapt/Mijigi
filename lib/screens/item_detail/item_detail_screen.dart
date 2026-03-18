import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import '../../models/capture_item.dart';
import '../../providers/app_provider.dart';
import '../../theme/app_theme.dart';

class ItemDetailScreen extends StatefulWidget {
  final String itemId;

  const ItemDetailScreen({super.key, required this.itemId});

  @override
  State<ItemDetailScreen> createState() => _ItemDetailScreenState();
}

class _ItemDetailScreenState extends State<ItemDetailScreen> {
  late TextEditingController _titleController;
  late TextEditingController _textController;
  bool _isEditing = false;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController();
    _textController = TextEditingController();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _textController.dispose();
    super.dispose();
  }

  void _loadItem(CaptureItem item) {
    if (!_isEditing) {
      _titleController.text = item.title ?? '';
      _textController.text = item.rawText ?? '';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AppProvider>(
      builder: (context, provider, _) {
        final item = provider.items.where((i) => i.id == widget.itemId).firstOrNull;
        if (item == null) {
          return Scaffold(
            backgroundColor: MijigiColors.background,
            appBar: AppBar(),
            body: const Center(
              child: Text('Item not found',
                  style: TextStyle(color: MijigiColors.textTertiary)),
            ),
          );
        }

        _loadItem(item);

        return Scaffold(
          backgroundColor: MijigiColors.background,
          appBar: AppBar(
            backgroundColor: MijigiColors.background,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_rounded),
              onPressed: () => Navigator.pop(context),
            ),
            actions: [
              if (_isEditing)
                TextButton(
                  onPressed: () => _save(provider, item),
                  child: const Text(
                    'Save',
                    style: TextStyle(
                      color: MijigiColors.primary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                )
              else ...[
                IconButton(
                  icon: const Icon(Icons.edit_rounded, size: 20),
                  onPressed: () => setState(() => _isEditing = true),
                ),
                IconButton(
                  icon: Icon(
                    item.isPinned
                        ? Icons.push_pin_rounded
                        : Icons.push_pin_outlined,
                    size: 20,
                    color: item.isPinned ? MijigiColors.primary : null,
                  ),
                  onPressed: () => provider.togglePin(item.id),
                ),
                PopupMenuButton<String>(
                  color: MijigiColors.surfaceLight,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  onSelected: (value) => _handleAction(value, provider, item),
                  itemBuilder: (_) => [
                    const PopupMenuItem(
                      value: 'share',
                      child: Row(
                        children: [
                          Icon(Icons.share_rounded,
                              size: 18, color: MijigiColors.textSecondary),
                          SizedBox(width: 10),
                          Text('Share'),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'copy',
                      child: Row(
                        children: [
                          Icon(Icons.copy_rounded,
                              size: 18, color: MijigiColors.textSecondary),
                          SizedBox(width: 10),
                          Text('Copy text'),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'reprocess',
                      child: Row(
                        children: [
                          Icon(Icons.refresh_rounded,
                              size: 18, color: MijigiColors.textSecondary),
                          SizedBox(width: 10),
                          Text('Re-scan OCR'),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'archive',
                      child: Row(
                        children: [
                          Icon(Icons.archive_rounded,
                              size: 18, color: MijigiColors.warning),
                          SizedBox(width: 10),
                          Text('Archive'),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          Icon(Icons.delete_rounded,
                              size: 18, color: MijigiColors.error),
                          SizedBox(width: 10),
                          Text('Delete',
                              style: TextStyle(color: MijigiColors.error)),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Image
                if (item.hasImage && item.filePath != null) ...[
                  ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Image.file(
                      File(item.filePath!),
                      width: double.infinity,
                      fit: BoxFit.contain,
                      errorBuilder: (_, __, ___) => Container(
                        height: 200,
                        decoration: BoxDecoration(
                          color: MijigiColors.surfaceLight,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: const Center(
                          child: Icon(Icons.image_not_supported_rounded,
                              color: MijigiColors.textTertiary, size: 40),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                ],

                // Category & Type badges
                Row(
                  children: [
                    _buildBadge(item.categoryLabel, _getCategoryColor(item.category)),
                    const SizedBox(width: 8),
                    _buildBadge(item.type.name, MijigiColors.textTertiary),
                    const Spacer(),
                    if (!item.isProcessed)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: MijigiColors.accent.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Row(
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
                            SizedBox(width: 6),
                            Text(
                              'Processing',
                              style: TextStyle(
                                  color: MijigiColors.accent, fontSize: 11),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 16),

                // Title
                if (_isEditing)
                  TextField(
                    controller: _titleController,
                    style: const TextStyle(
                      color: MijigiColors.textPrimary,
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                    ),
                    decoration: InputDecoration(
                      hintText: 'Title',
                      hintStyle: TextStyle(
                        color: MijigiColors.textTertiary.withValues(alpha: 0.5),
                      ),
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.zero,
                    ),
                  )
                else
                  Text(
                    item.displayTitle,
                    style: const TextStyle(
                      color: MijigiColors.textPrimary,
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                    ),
                  ),

                const SizedBox(height: 4),
                Text(
                  _formatDate(item.createdAt),
                  style: const TextStyle(
                    color: MijigiColors.textTertiary,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 20),

                // Text content
                if (item.rawText != null && item.rawText!.isNotEmpty) ...[
                  const Text(
                    'Extracted Text',
                    style: TextStyle(
                      color: MijigiColors.textSecondary,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  if (_isEditing)
                    TextField(
                      controller: _textController,
                      maxLines: null,
                      style: const TextStyle(
                        color: MijigiColors.textPrimary,
                        fontSize: 15,
                        height: 1.6,
                      ),
                      decoration: InputDecoration(
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide:
                              const BorderSide(color: MijigiColors.border),
                        ),
                        contentPadding: const EdgeInsets.all(14),
                      ),
                    )
                  else
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: MijigiColors.surface,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: MijigiColors.border),
                      ),
                      child: SelectableText(
                        item.rawText!,
                        style: const TextStyle(
                          color: MijigiColors.textPrimary,
                          fontSize: 15,
                          height: 1.6,
                        ),
                      ),
                    ),
                  const SizedBox(height: 20),
                ],

                // Extracted data
                if (item.extractedData != null &&
                    item.extractedData!.isNotEmpty) ...[
                  const Text(
                    'Extracted Data',
                    style: TextStyle(
                      color: MijigiColors.textSecondary,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  ...item.extractedData!.entries.map((entry) {
                    return _buildDataSection(entry.key, entry.value);
                  }),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildBadge(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildDataSection(String key, dynamic value) {
    final items = value is List ? value.cast<String>() : [value.toString()];
    final icon = switch (key) {
      'amounts' => Icons.attach_money_rounded,
      'dates' => Icons.calendar_today_rounded,
      'phones' => Icons.phone_rounded,
      'emails' => Icons.email_rounded,
      'urls' => Icons.link_rounded,
      _ => Icons.data_object_rounded,
    };

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: MijigiColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: MijigiColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: MijigiColors.accent),
              const SizedBox(width: 6),
              Text(
                key.toUpperCase(),
                style: const TextStyle(
                  color: MijigiColors.textTertiary,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          ...items.map((item) => Padding(
                padding: const EdgeInsets.only(bottom: 2),
                child: GestureDetector(
                  onTap: () {
                    Clipboard.setData(ClipboardData(text: item));
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: const Text('Copied'),
                        backgroundColor: MijigiColors.surfaceLight,
                        behavior: SnackBarBehavior.floating,
                        duration: const Duration(seconds: 1),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                      ),
                    );
                  },
                  child: Text(
                    item,
                    style: const TextStyle(
                      color: MijigiColors.textPrimary,
                      fontSize: 14,
                    ),
                  ),
                ),
              )),
        ],
      ),
    );
  }

  void _save(AppProvider provider, CaptureItem item) {
    final updated = item.copyWith(
      title: _titleController.text.trim().isNotEmpty
          ? _titleController.text.trim()
          : null,
      rawText: _textController.text.trim().isNotEmpty
          ? _textController.text.trim()
          : null,
    );
    provider.updateItem(updated);
    setState(() => _isEditing = false);
  }

  void _handleAction(String action, AppProvider provider, CaptureItem item) {
    switch (action) {
      case 'share':
        final text = item.rawText ?? item.displayTitle;
        Share.share(text);
        break;
      case 'copy':
        if (item.rawText != null) {
          Clipboard.setData(ClipboardData(text: item.rawText!));
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Copied to clipboard'),
              backgroundColor: MijigiColors.surfaceLight,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
          );
        }
        break;
      case 'reprocess':
        item.isProcessed = false;
        provider.updateItem(item);
        break;
      case 'archive':
        provider.archiveItem(item.id);
        Navigator.pop(context);
        break;
      case 'delete':
        provider.deleteItem(item.id);
        Navigator.pop(context);
        break;
    }
  }

  String _formatDate(DateTime date) {
    final months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    final hour = date.hour > 12 ? date.hour - 12 : date.hour;
    final amPm = date.hour >= 12 ? 'PM' : 'AM';
    final minute = date.minute.toString().padLeft(2, '0');
    return '${months[date.month - 1]} ${date.day}, ${date.year} at $hour:$minute $amPm';
  }

  Color _getCategoryColor(ItemCategory cat) => switch (cat) {
    ItemCategory.receipt => MijigiColors.categoryReceipt,
    ItemCategory.document => MijigiColors.categoryDocument,
    ItemCategory.medical => MijigiColors.categoryMedical,
    ItemCategory.financial => MijigiColors.categoryFinancial,
    ItemCategory.travel => MijigiColors.categoryTravel,
    ItemCategory.work => MijigiColors.categoryWork,
    ItemCategory.personal => MijigiColors.categoryPersonal,
    ItemCategory.food => MijigiColors.categoryFood,
    ItemCategory.shopping => MijigiColors.categoryShopping,
    _ => MijigiColors.textTertiary,
  };
}
