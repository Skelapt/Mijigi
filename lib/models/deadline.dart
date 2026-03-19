import 'extraction_result.dart';

/// A tracked deadline/expiry from a captured item.
class Deadline {
  final String id;
  final String itemId;
  final String itemTitle;
  final String label;
  final DateTime date;
  final DeadlineType type;
  final int reminderDaysBefore;
  bool isNotified;
  bool isDismissed;

  Deadline({
    required this.id,
    required this.itemId,
    required this.itemTitle,
    required this.label,
    required this.date,
    required this.type,
    this.reminderDaysBefore = 7,
    this.isNotified = false,
    this.isDismissed = false,
  });

  bool get isExpired => date.isBefore(DateTime.now());
  int get daysUntil => date.difference(DateTime.now()).inDays;

  bool get shouldRemind {
    if (isDismissed || isNotified || isExpired) return false;
    return daysUntil <= reminderDaysBefore;
  }

  String get urgencyLabel {
    final days = daysUntil;
    if (days < 0) return 'Expired ${-days}d ago';
    if (days == 0) return 'Today!';
    if (days == 1) return 'Tomorrow';
    if (days <= 7) return 'In $days days';
    if (days <= 30) return 'In ${(days / 7).ceil()} weeks';
    return 'In ${(days / 30).ceil()} months';
  }

  String get typeLabel => switch (type) {
        DeadlineType.expiry => 'Expires',
        DeadlineType.warranty => 'Warranty',
        DeadlineType.renewal => 'Renewal',
        DeadlineType.dueDate => 'Due',
        DeadlineType.appointment => 'Appointment',
        DeadlineType.event => 'Event',
        DeadlineType.general => 'Deadline',
      };

  Map<String, dynamic> toMap() => {
        'id': id,
        'itemId': itemId,
        'itemTitle': itemTitle,
        'label': label,
        'date': date.toIso8601String(),
        'type': type.index,
        'reminderDaysBefore': reminderDaysBefore,
        'isNotified': isNotified,
        'isDismissed': isDismissed,
      };

  factory Deadline.fromMap(Map<dynamic, dynamic> map) => Deadline(
        id: map['id'] as String,
        itemId: map['itemId'] as String,
        itemTitle: map['itemTitle'] as String? ?? '',
        label: map['label'] as String,
        date: DateTime.parse(map['date'] as String),
        type: DeadlineType.values[map['type'] as int? ?? 0],
        reminderDaysBefore: map['reminderDaysBefore'] as int? ?? 7,
        isNotified: map['isNotified'] as bool? ?? false,
        isDismissed: map['isDismissed'] as bool? ?? false,
      );
}
