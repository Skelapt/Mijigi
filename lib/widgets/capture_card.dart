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
        decoration: BoxDecoration(
          color: MijigiColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: MijigiColors.border),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (item.hasImage && item.filePath != null) _buildImage(),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      _buildCategoryChip(),
                      const Spacer(),
                      if (item.isPinned)
                        const Icon(
                          Icons.push_pin_rounded,
                          size: 14,
                          color: MijigiColors.primary,
                        ),
                      if (!item.isProcessed)
                        const SizedBox(
                          width: 12,
                          height: 12,
                          child: CircularProgressIndicator(
                            strokeWidth: 1.5,
                            color: MijigiColors.accent,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    item.displayTitle,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: MijigiColors.textPrimary,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (item.rawText != null && item.rawText!.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      item.rawText!,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: MijigiColors.textSecondary,
                        fontSize: 12,
                        height: 1.4,
                      ),
                    ),
                  ],
                  const SizedBox(height: 8),
                  _buildFooter(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImage() {
    return AspectRatio(
      aspectRatio: 16 / 10,
      child: Image.file(
        File(item.filePath!),
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => Container(
          color: MijigiColors.surfaceLight,
          child: const Center(
            child: Icon(Icons.image_not_supported_rounded,
                color: MijigiColors.textTertiary),
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryChip() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: _getCategoryColor().withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        item.categoryLabel,
        style: TextStyle(
          color: _getCategoryColor(),
          fontSize: 10,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildFooter() {
    final now = DateTime.now();
    final diff = now.difference(item.createdAt);
    String timeAgo;
    if (diff.inMinutes < 1) {
      timeAgo = 'Just now';
    } else if (diff.inHours < 1) {
      timeAgo = '${diff.inMinutes}m ago';
    } else if (diff.inDays < 1) {
      timeAgo = '${diff.inHours}h ago';
    } else if (diff.inDays < 7) {
      timeAgo = '${diff.inDays}d ago';
    } else {
      timeAgo = '${item.createdAt.day}/${item.createdAt.month}/${item.createdAt.year}';
    }

    return Row(
      children: [
        Icon(
          _getTypeIcon(),
          size: 12,
          color: MijigiColors.textTertiary,
        ),
        const SizedBox(width: 4),
        Text(
          timeAgo,
          style: const TextStyle(
            color: MijigiColors.textTertiary,
            fontSize: 11,
          ),
        ),
        if (item.extractedData != null && item.extractedData!.isNotEmpty) ...[
          const Spacer(),
          Icon(
            Icons.auto_awesome_rounded,
            size: 12,
            color: MijigiColors.accent.withValues(alpha: 0.7),
          ),
        ],
      ],
    );
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
