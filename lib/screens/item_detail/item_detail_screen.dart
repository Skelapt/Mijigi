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
  @override
  Widget build(BuildContext context) {
    return Consumer<AppProvider>(
      builder: (context, provider, _) {
        final item =
            provider.items.where((i) => i.id == widget.itemId).firstOrNull;
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

        return Scaffold(
          backgroundColor: MijigiColors.background,
          appBar: AppBar(
            backgroundColor: MijigiColors.background,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_rounded),
              onPressed: () => Navigator.pop(context),
            ),
            actions: [
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
                    borderRadius: BorderRadius.circular(12)),
                onSelected: (value) => _handleAction(value, provider, item),
                itemBuilder: (_) => [
                  const PopupMenuItem(
                      value: 'share',
                      child: Row(children: [
                        Icon(Icons.share_rounded,
                            size: 18, color: MijigiColors.textSecondary),
                        SizedBox(width: 10),
                        Text('Share'),
                      ])),
                  const PopupMenuItem(
                      value: 'copy',
                      child: Row(children: [
                        Icon(Icons.copy_rounded,
                            size: 18, color: MijigiColors.textSecondary),
                        SizedBox(width: 10),
                        Text('Copy text'),
                      ])),
                  const PopupMenuItem(
                      value: 'delete',
                      child: Row(children: [
                        Icon(Icons.delete_rounded,
                            size: 18, color: MijigiColors.error),
                        SizedBox(width: 10),
                        Text('Delete',
                            style: TextStyle(color: MijigiColors.error)),
                      ])),
                ],
              ),
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
                    borderRadius: BorderRadius.circular(12),
                    child: Image.file(
                      File(item.filePath!),
                      width: double.infinity,
                      fit: BoxFit.contain,
                      errorBuilder: (_, __, ___) => Container(
                        height: 200,
                        decoration: BoxDecoration(
                          color: MijigiColors.surfaceLight,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Center(
                            child: Icon(Icons.image_not_supported_rounded,
                                color: MijigiColors.textTertiary, size: 40)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                // Labels (what ML Kit sees in the photo)
                if (item.labels.isNotEmpty) ...[
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: item.labels.map((label) {
                      return Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: MijigiColors.primary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                              color: MijigiColors.primary
                                  .withValues(alpha: 0.2)),
                        ),
                        child: Text(
                          label,
                          style: const TextStyle(
                            color: MijigiColors.primaryLight,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 16),
                ],

                // Extracted data cards (one-tap copy)
                if (item.extractedData != null &&
                    item.extractedData!.isNotEmpty) ...[
                  ...item.extractedData!.entries.map((entry) {
                    return _buildCopyCard(entry.key, entry.value);
                  }),
                  const SizedBox(height: 8),
                ],

                // OCR text
                if (item.rawText != null && item.rawText!.isNotEmpty) ...[
                  const Text(
                    'Text',
                    style: TextStyle(
                      color: MijigiColors.textTertiary,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 6),
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
                        fontSize: 14,
                        height: 1.6,
                      ),
                    ),
                  ),
                ],

                const SizedBox(height: 12),

                // Metadata
                Text(
                  _formatDate(item.createdAt),
                  style: const TextStyle(
                    color: MijigiColors.textTertiary,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  /// Build a one-tap copy card for extracted data (emails, phones, amounts)
  Widget _buildCopyCard(String key, dynamic value) {
    final items = value is List ? value.cast<String>() : [value.toString()];
    final icon = switch (key) {
      'amounts' => Icons.attach_money_rounded,
      'dates' => Icons.calendar_today_rounded,
      'phones' => Icons.phone_rounded,
      'emails' => Icons.email_rounded,
      'urls' => Icons.link_rounded,
      _ => Icons.data_object_rounded,
    };
    final color = switch (key) {
      'amounts' => MijigiColors.fileSheet,
      'phones' => MijigiColors.primary,
      'emails' => MijigiColors.fileNote,
      'dates' => MijigiColors.warning,
      'urls' => MijigiColors.accent,
      _ => MijigiColors.textSecondary,
    };

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 14, color: color),
              const SizedBox(width: 6),
              Text(
                key.toUpperCase(),
                style: TextStyle(
                  color: color,
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          ...items.map((item) => GestureDetector(
                onTap: () {
                  Clipboard.setData(ClipboardData(text: item));
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Copied: $item'),
                      duration: const Duration(seconds: 1),
                      backgroundColor: MijigiColors.surfaceLight,
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                    ),
                  );
                },
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          item,
                          style: const TextStyle(
                            color: MijigiColors.textPrimary,
                            fontSize: 14,
                          ),
                        ),
                      ),
                      const Icon(Icons.content_copy_rounded,
                          size: 14, color: MijigiColors.textTertiary),
                    ],
                  ),
                ),
              )),
        ],
      ),
    );
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
}
