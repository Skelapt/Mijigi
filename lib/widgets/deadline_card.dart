import 'package:flutter/material.dart';
import '../models/deadline.dart';
import '../models/extraction_result.dart';
import '../theme/app_theme.dart';

class DeadlineCard extends StatelessWidget {
  final Deadline deadline;
  final VoidCallback? onTap;
  final VoidCallback? onDismiss;

  const DeadlineCard({
    super.key,
    required this.deadline,
    this.onTap,
    this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    final isExpired = deadline.isExpired;
    final isUrgent = !isExpired && deadline.daysUntil <= 7;
    final color = isExpired
        ? MijigiColors.error
        : isUrgent
            ? MijigiColors.warning
            : MijigiColors.accent;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: MijigiColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: color.withValues(alpha: 0.3),
          ),
        ),
        child: Row(
          children: [
            // Urgency indicator
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: Icon(
                  _typeIcon,
                  color: color,
                  size: 20,
                ),
              ),
            ),
            const SizedBox(width: 12),

            // Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    deadline.label,
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
                        deadline.typeLabel,
                        style: TextStyle(
                          color: MijigiColors.textTertiary,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        '\u2022',
                        style: TextStyle(
                          color: MijigiColors.textTertiary.withValues(alpha: 0.5),
                          fontSize: 10,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        _formatDate(deadline.date),
                        style: const TextStyle(
                          color: MijigiColors.textTertiary,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Urgency badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                deadline.urgencyLabel,
                style: TextStyle(
                  color: color,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  IconData get _typeIcon => switch (deadline.type) {
        DeadlineType.expiry => Icons.timer_off_rounded,
        DeadlineType.warranty => Icons.shield_rounded,
        DeadlineType.renewal => Icons.autorenew_rounded,
        DeadlineType.dueDate => Icons.event_rounded,
        DeadlineType.appointment => Icons.calendar_today_rounded,
        DeadlineType.event => Icons.celebration_rounded,
        DeadlineType.general => Icons.schedule_rounded,
      };

  String _formatDate(DateTime date) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }
}
