import 'package:flutter/material.dart';
import '../models/capture_item.dart';
import '../theme/app_theme.dart';

class CollectionTile extends StatelessWidget {
  final ItemCategory category;
  final int count;
  final VoidCallback? onTap;

  const CollectionTile({
    super.key,
    required this.category,
    required this.count,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: MijigiColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: MijigiColors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: _getColor().withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                _getIcon(),
                color: _getColor(),
                size: 20,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              _getLabel(),
              style: const TextStyle(
                color: MijigiColors.textPrimary,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              '$count ${count == 1 ? 'item' : 'items'}',
              style: const TextStyle(
                color: MijigiColors.textTertiary,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getLabel() => switch (category) {
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

  IconData _getIcon() => switch (category) {
    ItemCategory.uncategorised => Icons.folder_rounded,
    ItemCategory.receipt => Icons.receipt_long_rounded,
    ItemCategory.document => Icons.description_rounded,
    ItemCategory.medical => Icons.local_hospital_rounded,
    ItemCategory.financial => Icons.account_balance_rounded,
    ItemCategory.legal => Icons.gavel_rounded,
    ItemCategory.travel => Icons.flight_rounded,
    ItemCategory.food => Icons.restaurant_rounded,
    ItemCategory.work => Icons.work_rounded,
    ItemCategory.personal => Icons.person_rounded,
    ItemCategory.education => Icons.school_rounded,
    ItemCategory.shopping => Icons.shopping_bag_rounded,
    ItemCategory.contact => Icons.contact_phone_rounded,
    ItemCategory.event => Icons.event_rounded,
  };

  Color _getColor() => switch (category) {
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
