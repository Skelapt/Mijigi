import '../models/capture_item.dart';
import '../models/daily_brief.dart';
import 'deadline_service.dart';
import 'action_service.dart';

/// Generates the daily intelligence brief.
class BriefService {
  final DeadlineService _deadlineService;
  final ActionService _actionService;

  BriefService(this._deadlineService, this._actionService);

  /// Generate today's brief from all items.
  DailyBrief generate(List<CaptureItem> items) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final weekAgo = today.subtract(const Duration(days: 7));

    // Items captured today
    final capturedToday = items.where((i) =>
        !i.isArchived &&
        i.createdAt.isAfter(today)).length;

    // Items captured this week
    final capturedThisWeek = items.where((i) =>
        !i.isArchived &&
        i.createdAt.isAfter(weekAgo)).length;

    // Spending this week from receipts
    double weeklySpending = 0;
    int receiptCount = 0;
    for (final item in items) {
      if (item.isArchived ||
          item.category != ItemCategory.receipt ||
          !item.createdAt.isAfter(weekAgo)) {
        continue;
      }

      final amounts = item.extractedData?['amounts'] as List?;
      if (amounts != null) {
        receiptCount++;
        for (final amount in amounts) {
          final parsed = _parseAmount(amount.toString());
          if (parsed != null) weeklySpending += parsed;
        }
      }
    }

    // Deadlines
    final urgent = _deadlineService.getUrgent(items);
    final upcoming = _deadlineService.getUpcoming(items, withinDays: 30);
    final expired = _deadlineService.getExpired(items);

    // Pending actions (limit to most recent 10)
    final actions = _actionService.getAllPendingActions(items);
    final pendingActions = actions.take(10).toList();

    // Category insights
    final categoryMap = <ItemCategory, _CategoryData>{};
    for (final item in items.where((i) => !i.isArchived)) {
      final data = categoryMap.putIfAbsent(
          item.category, () => _CategoryData());
      data.total++;
      if (item.createdAt.isAfter(weekAgo)) data.newThisWeek++;
    }
    final insights = categoryMap.entries
        .map((e) => CategoryInsight(
              category: e.key,
              count: e.value.total,
              newThisWeek: e.value.newThisWeek,
            ))
        .where((i) => i.count > 0)
        .toList()
      ..sort((a, b) => b.count.compareTo(a.count));

    return DailyBrief(
      date: now,
      urgentDeadlines: urgent,
      upcomingDeadlines: upcoming,
      expiredDeadlines: expired,
      pendingActions: pendingActions,
      itemsCapturedToday: capturedToday,
      itemsCapturedThisWeek: capturedThisWeek,
      totalSpendingThisWeek: weeklySpending,
      totalSpendingReceipts: receiptCount,
      totalItems: items.where((i) => !i.isArchived).length,
      categoryInsights: insights,
    );
  }

  double? _parseAmount(String text) {
    final match = RegExp(r'[\d,]+\.?\d*').firstMatch(text);
    if (match == null) return null;
    return double.tryParse(match.group(0)!.replaceAll(',', ''));
  }
}

class _CategoryData {
  int total = 0;
  int newThisWeek = 0;
}
