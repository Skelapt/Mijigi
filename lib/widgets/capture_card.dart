import 'dart:io';
import 'package:flutter/material.dart';
import '../models/capture_item.dart';
import '../theme/app_theme.dart';

class CaptureCard extends StatelessWidget {
  final CaptureItem item;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;

  const CaptureCard({
    super.key,
    required this.item,
    this.onTap,
    this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      onLongPress: onLongPress,
      child: Container(
        height: 64,
        decoration: BoxDecoration(
          color: MijigiColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: MijigiColors.border),
        ),
        clipBehavior: Clip.antiAlias,
        child: Row(
          children: [
            // Thumbnail
            if (item.hasImage && item.filePath != null)
              SizedBox(
                width: 64,
                height: 64,
                child: Image.file(
                  File(item.filePath!),
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    color: MijigiColors.surfaceLight,
                    child: const Icon(Icons.image_not_supported_rounded,
                        color: MijigiColors.textTertiary, size: 20),
                  ),
                ),
              )
            else
              Container(
                width: 64,
                height: 64,
                color: _getCategoryColor().withValues(alpha: 0.08),
                child: Icon(
                  _getTypeIcon(),
                  color: _getCategoryColor(),
                  size: 22,
                ),
              ),

            // Text content
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      _getDisplayLine(),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: MijigiColors.textPrimary,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Row(
                      children: [
                        Text(
                          item.categoryLabel,
                          style: TextStyle(
                            color: _getCategoryColor(),
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const Text(' \u2022 ', style: TextStyle(
                            color: MijigiColors.textTertiary, fontSize: 11)),
                        Text(
                          _timeAgo(),
                          style: const TextStyle(
                            color: MijigiColors.textTertiary,
                            fontSize: 11,
                          ),
                        ),
                        if (!item.isProcessed) ...[
                          const SizedBox(width: 6),
                          const SizedBox(
                            width: 10, height: 10,
                            child: CircularProgressIndicator(
                              strokeWidth: 1.5, color: MijigiColors.accent,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ),

            // Pin indicator
            if (item.isPinned)
              const Padding(
                padding: EdgeInsets.only(right: 12),
                child: Icon(Icons.push_pin_rounded,
                    size: 14, color: MijigiColors.primary),
              ),
          ],
        ),
      ),
    );
  }

  /// First meaningful line from OCR text, title, or fallback
  String _getDisplayLine() {
    if (item.title != null && item.title!.trim().isNotEmpty) {
      return item.title!.trim();
    }
    if (item.rawText != null && item.rawText!.trim().isNotEmpty) {
      // Get first non-empty line
      final lines = item.rawText!.split('\n').where((l) => l.trim().isNotEmpty);
      if (lines.isNotEmpty) {
        final first = lines.first.trim();
        return first.length > 60 ? '${first.substring(0, 60)}...' : first;
      }
    }
    return item.displayTitle;
  }

  String _timeAgo() {
    final diff = DateTime.now().difference(item.createdAt);
    if (diff.inMinutes < 1) return 'now';
    if (diff.inHours < 1) return '${diff.inMinutes}m';
    if (diff.inDays < 1) return '${diff.inHours}h';
    if (diff.inDays < 7) return '${diff.inDays}d';
    return '${item.createdAt.day}/${item.createdAt.month}';
  }

  IconData _getTypeIcon() => switch (item.type) {
    CaptureType.photo => Icons.photo_rounded,
    CaptureType.screenshot => Icons.screenshot_rounded,
    CaptureType.document => Icons.description_rounded,
    CaptureType.note => Icons.edit_note_rounded,
    CaptureType.clipboard => Icons.content_paste_rounded,
    CaptureType.voice => Icons.mic_rounded,
    CaptureType.link => Icons.link_rounded,
  };

  Color _getCategoryColor() => switch (item.category) {
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
