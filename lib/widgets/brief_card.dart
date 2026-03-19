import 'package:flutter/material.dart';
import '../models/daily_brief.dart';
import '../theme/app_theme.dart';

class BriefCard extends StatelessWidget {
  final DailyBrief brief;
  final VoidCallback? onTapDeadlines;
  final VoidCallback? onTapActions;

  const BriefCard({
    super.key,
    required this.brief,
    this.onTapDeadlines,
    this.onTapActions,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: brief.hasUrgentItems
              ? [
                  MijigiColors.warning.withValues(alpha: 0.15),
                  MijigiColors.primary.withValues(alpha: 0.08),
                ]
              : [
                  MijigiColors.primary.withValues(alpha: 0.12),
                  MijigiColors.accent.withValues(alpha: 0.06),
                ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: brief.hasUrgentItems
              ? MijigiColors.warning.withValues(alpha: 0.25)
              : MijigiColors.primary.withValues(alpha: 0.15),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: brief.hasUrgentItems
                        ? MijigiColors.warning.withValues(alpha: 0.2)
                        : MijigiColors.primary.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    brief.hasUrgentItems
                        ? Icons.notifications_active_rounded
                        : Icons.auto_awesome_rounded,
                    color: brief.hasUrgentItems
                        ? MijigiColors.warning
                        : MijigiColors.primary,
                    size: 18,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Daily Brief',
                        style: TextStyle(
                          color: MijigiColors.textPrimary,
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Text(
                        brief.summaryLine,
                        style: TextStyle(
                          color: brief.hasUrgentItems
                              ? MijigiColors.warning
                              : MijigiColors.textTertiary,
                          fontSize: 12,
                          fontWeight: brief.hasUrgentItems
                              ? FontWeight.w600
                              : FontWeight.w400,
                        ),
                      ),
                    ],
                  ),
                ),
                if (brief.totalAlerts > 0)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: MijigiColors.error.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '${brief.totalAlerts}',
                      style: const TextStyle(
                        color: MijigiColors.error,
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
              ],
            ),

            const SizedBox(height: 14),

            // Stats row
            Row(
              children: [
                _StatChip(
                  icon: Icons.layers_rounded,
                  value: '${brief.totalItems}',
                  label: 'items',
                ),
                const SizedBox(width: 12),
                if (brief.itemsCapturedToday > 0) ...[
                  _StatChip(
                    icon: Icons.add_circle_rounded,
                    value: '+${brief.itemsCapturedToday}',
                    label: 'today',
                    color: MijigiColors.accent,
                  ),
                  const SizedBox(width: 12),
                ],
                if (brief.totalSpendingThisWeek > 0)
                  _StatChip(
                    icon: Icons.receipt_rounded,
                    value: '\$${brief.totalSpendingThisWeek.toStringAsFixed(0)}',
                    label: 'this week',
                    color: MijigiColors.categoryReceipt,
                  ),
              ],
            ),

            // Urgent deadlines
            if (brief.expiredDeadlines.isNotEmpty ||
                brief.urgentDeadlines.isNotEmpty) ...[
              const SizedBox(height: 14),
              const Divider(color: MijigiColors.border, height: 1),
              const SizedBox(height: 12),
              ...brief.expiredDeadlines.take(2).map((d) => _DeadlineChip(
                    deadline: d,
                    isExpired: true,
                    onTap: onTapDeadlines,
                  )),
              ...brief.urgentDeadlines.take(3).map((d) => _DeadlineChip(
                    deadline: d,
                    isExpired: false,
                    onTap: onTapDeadlines,
                  )),
              if (brief.urgentDeadlines.length > 3 ||
                  brief.expiredDeadlines.length > 2)
                GestureDetector(
                  onTap: onTapDeadlines,
                  child: Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      'View all deadlines',
                      style: TextStyle(
                        color: MijigiColors.primary,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
            ],
          ],
        ),
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  final Color? color;

  const _StatChip({
    required this.icon,
    required this.value,
    required this.label,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 13, color: color ?? MijigiColors.textTertiary),
        const SizedBox(width: 4),
        Text(
          value,
          style: TextStyle(
            color: color ?? MijigiColors.textPrimary,
            fontSize: 13,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(width: 3),
        Text(
          label,
          style: const TextStyle(
            color: MijigiColors.textTertiary,
            fontSize: 11,
          ),
        ),
      ],
    );
  }
}

class _DeadlineChip extends StatelessWidget {
  final dynamic deadline;
  final bool isExpired;
  final VoidCallback? onTap;

  const _DeadlineChip({
    required this.deadline,
    required this.isExpired,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Row(
          children: [
            Container(
              width: 6,
              height: 6,
              decoration: BoxDecoration(
                color: isExpired ? MijigiColors.error : MijigiColors.warning,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                deadline.label as String,
                style: const TextStyle(
                  color: MijigiColors.textPrimary,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Text(
              deadline.urgencyLabel as String,
              style: TextStyle(
                color: isExpired ? MijigiColors.error : MijigiColors.warning,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
