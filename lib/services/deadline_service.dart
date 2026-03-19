import 'package:uuid/uuid.dart';
import '../models/capture_item.dart';
import '../models/deadline.dart';
import '../models/extraction_result.dart';
import 'storage_service.dart';

/// Manages deadlines extracted from captured items.
class DeadlineService {
  final _uuid = const Uuid();
  final StorageService _storage;

  DeadlineService(this._storage);

  /// Extract deadlines from an item's extracted data.
  List<Deadline> extractDeadlinesFromItem(CaptureItem item) {
    final deadlines = <Deadline>[];
    final data = item.extractedData;
    if (data == null || !data.containsKey('deadlines')) return deadlines;

    final rawDeadlines = data['deadlines'] as List?;
    if (rawDeadlines == null) return deadlines;

    for (final raw in rawDeadlines) {
      if (raw is! Map) continue;
      final map = Map<String, dynamic>.from(raw);

      final dateStr = map['date'] as String?;
      if (dateStr == null) continue;

      final date = DateTime.tryParse(dateStr);
      if (date == null) continue;

      final typeStr = map['type'] as String? ?? 'general';
      final type = DeadlineType.values.firstWhere(
        (t) => t.name == typeStr,
        orElse: () => DeadlineType.general,
      );

      deadlines.add(Deadline(
        id: _uuid.v4(),
        itemId: item.id,
        itemTitle: item.displayTitle,
        label: map['label'] as String? ?? type.name,
        date: date,
        type: type,
        reminderDaysBefore: _defaultReminderDays(type),
      ));
    }

    return deadlines;
  }

  /// Get all deadlines from all items, sorted by date.
  List<Deadline> getAllDeadlines(List<CaptureItem> items) {
    final all = <Deadline>[];
    for (final item in items) {
      all.addAll(extractDeadlinesFromItem(item));
    }
    // Also load persisted deadlines
    all.addAll(_loadPersistedDeadlines());

    // Deduplicate by itemId + date
    final seen = <String>{};
    final unique = <Deadline>[];
    for (final d in all) {
      final key = '${d.itemId}_${d.date.toIso8601String()}';
      if (seen.add(key)) unique.add(d);
    }

    unique.sort((a, b) => a.date.compareTo(b.date));
    return unique;
  }

  /// Get deadlines expiring within X days.
  List<Deadline> getUpcoming(List<CaptureItem> items, {int withinDays = 30}) {
    final now = DateTime.now();
    final cutoff = now.add(Duration(days: withinDays));
    return getAllDeadlines(items)
        .where((d) => !d.isDismissed && d.date.isAfter(now) && d.date.isBefore(cutoff))
        .toList();
  }

  /// Get expired (missed) deadlines.
  List<Deadline> getExpired(List<CaptureItem> items) {
    final now = DateTime.now();
    return getAllDeadlines(items)
        .where((d) => !d.isDismissed && d.date.isBefore(now))
        .toList();
  }

  /// Get urgent deadlines (within 7 days).
  List<Deadline> getUrgent(List<CaptureItem> items) {
    return getUpcoming(items, withinDays: 7);
  }

  /// Persist a deadline.
  Future<void> saveDeadline(Deadline deadline) async {
    final box = _storage.deadlinesBox;
    await box?.put(deadline.id, deadline.toMap());
  }

  /// Dismiss a deadline.
  Future<void> dismissDeadline(String id) async {
    final box = _storage.deadlinesBox;
    final raw = box?.get(id);
    if (raw != null) {
      final map = Map<String, dynamic>.from(raw as Map);
      map['isDismissed'] = true;
      await box?.put(id, map);
    }
  }

  List<Deadline> _loadPersistedDeadlines() {
    final box = _storage.deadlinesBox;
    if (box == null) return [];
    return box.values
        .map((v) => Deadline.fromMap(v as Map))
        .toList();
  }

  int _defaultReminderDays(DeadlineType type) => switch (type) {
        DeadlineType.expiry => 14,
        DeadlineType.warranty => 30,
        DeadlineType.renewal => 14,
        DeadlineType.dueDate => 3,
        DeadlineType.appointment => 1,
        DeadlineType.event => 1,
        DeadlineType.general => 7,
      };
}
