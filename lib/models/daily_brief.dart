import 'deadline.dart';
import 'action_suggestion.dart';
import 'capture_item.dart';

/// The daily intelligence brief - what the user needs to know today.
class DailyBrief {
  final DateTime date;
  final List<Deadline> urgentDeadlines; // within 7 days
  final List<Deadline> upcomingDeadlines; // within 30 days
  final List<Deadline> expiredDeadlines; // missed deadlines
  final List<ActionSuggestion> pendingActions;
  final int itemsCapturedToday;
  final int itemsCapturedThisWeek;
  final double totalSpendingThisWeek;
  final int totalSpendingReceipts;
  final int totalItems;
  final List<CategoryInsight> categoryInsights;

  const DailyBrief({
    required this.date,
    this.urgentDeadlines = const [],
    this.upcomingDeadlines = const [],
    this.expiredDeadlines = const [],
    this.pendingActions = const [],
    this.itemsCapturedToday = 0,
    this.itemsCapturedThisWeek = 0,
    this.totalSpendingThisWeek = 0,
    this.totalSpendingReceipts = 0,
    this.totalItems = 0,
    this.categoryInsights = const [],
  });

  bool get hasUrgentItems =>
      urgentDeadlines.isNotEmpty ||
      expiredDeadlines.isNotEmpty ||
      pendingActions.isNotEmpty;

  int get totalAlerts =>
      urgentDeadlines.length +
      expiredDeadlines.length;

  String get greeting {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning';
    if (hour < 17) return 'Good afternoon';
    return 'Good evening';
  }

  String get summaryLine {
    final parts = <String>[];
    if (expiredDeadlines.isNotEmpty) {
      parts.add('${expiredDeadlines.length} expired');
    }
    if (urgentDeadlines.isNotEmpty) {
      parts.add('${urgentDeadlines.length} due soon');
    }
    if (pendingActions.isNotEmpty) {
      parts.add('${pendingActions.length} actions');
    }
    if (parts.isEmpty) {
      if (totalItems == 0) return 'Capture your first item to get started';
      return 'All clear. Nothing needs your attention.';
    }
    return parts.join(' \u2022 ');
  }
}

class CategoryInsight {
  final ItemCategory category;
  final int count;
  final int newThisWeek;

  const CategoryInsight({
    required this.category,
    required this.count,
    this.newThisWeek = 0,
  });
}
