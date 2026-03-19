import 'package:flutter/material.dart';
import '../models/action_suggestion.dart';
import '../theme/app_theme.dart';

class ActionSuggestionCard extends StatelessWidget {
  final ActionSuggestion action;
  final VoidCallback? onExecute;
  final VoidCallback? onDismiss;

  const ActionSuggestionCard({
    super.key,
    required this.action,
    this.onExecute,
    this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: MijigiColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: MijigiColors.border),
      ),
      child: Row(
        children: [
          // Action icon
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: _actionColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Center(
              child: Icon(
                _actionIcon,
                color: _actionColor,
                size: 18,
              ),
            ),
          ),
          const SizedBox(width: 10),

          // Content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  action.label,
                  style: const TextStyle(
                    color: MijigiColors.textPrimary,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (action.description.isNotEmpty)
                  Text(
                    action.description,
                    style: const TextStyle(
                      color: MijigiColors.textTertiary,
                      fontSize: 11,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
              ],
            ),
          ),

          // Action buttons
          if (onDismiss != null)
            GestureDetector(
              onTap: onDismiss,
              child: Padding(
                padding: const EdgeInsets.all(6),
                child: Icon(
                  Icons.close_rounded,
                  size: 16,
                  color: MijigiColors.textTertiary.withValues(alpha: 0.5),
                ),
              ),
            ),
          const SizedBox(width: 4),
          GestureDetector(
            onTap: onExecute,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: _actionColor.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                action.actionVerb,
                style: TextStyle(
                  color: _actionColor,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color get _actionColor => switch (action.type) {
        ActionType.createContact => MijigiColors.primary,
        ActionType.setReminder => MijigiColors.warning,
        ActionType.addToCalendar => MijigiColors.accent,
        ActionType.createTask => MijigiColors.categoryReceipt,
        ActionType.callNumber => MijigiColors.categoryTravel,
        ActionType.sendEmail => MijigiColors.categoryWork,
        ActionType.openUrl => MijigiColors.categoryDocument,
        ActionType.saveReceipt => MijigiColors.categoryFinancial,
        ActionType.addToShoppingList => MijigiColors.categoryShopping,
        ActionType.navigate => MijigiColors.categoryTravel,
        ActionType.copyText => MijigiColors.textSecondary,
      };

  IconData get _actionIcon => switch (action.type) {
        ActionType.createContact => Icons.person_add_rounded,
        ActionType.setReminder => Icons.alarm_add_rounded,
        ActionType.addToCalendar => Icons.calendar_month_rounded,
        ActionType.createTask => Icons.check_circle_outline_rounded,
        ActionType.callNumber => Icons.phone_rounded,
        ActionType.sendEmail => Icons.email_rounded,
        ActionType.openUrl => Icons.open_in_new_rounded,
        ActionType.saveReceipt => Icons.receipt_long_rounded,
        ActionType.addToShoppingList => Icons.shopping_cart_rounded,
        ActionType.navigate => Icons.navigation_rounded,
        ActionType.copyText => Icons.copy_rounded,
      };
}
