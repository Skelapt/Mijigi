/// Rich structured data extracted from OCR text.
class ExtractionResult {
  final List<ExtractedDate> dates;
  final List<ExtractedDeadline> deadlines;
  final List<ExtractedAmount> amounts;
  final List<String> phoneNumbers;
  final List<String> emails;
  final List<String> urls;
  final List<ExtractedReference> references;
  final List<String> names;
  final List<String> addresses;

  const ExtractionResult({
    this.dates = const [],
    this.deadlines = const [],
    this.amounts = const [],
    this.phoneNumbers = const [],
    this.emails = const [],
    this.urls = const [],
    this.references = const [],
    this.names = const [],
    this.addresses = const [],
  });

  bool get isEmpty =>
      dates.isEmpty &&
      deadlines.isEmpty &&
      amounts.isEmpty &&
      phoneNumbers.isEmpty &&
      emails.isEmpty &&
      urls.isEmpty &&
      references.isEmpty &&
      names.isEmpty &&
      addresses.isEmpty;

  bool get isNotEmpty => !isEmpty;

  int get totalExtracted =>
      dates.length +
      deadlines.length +
      amounts.length +
      phoneNumbers.length +
      emails.length +
      urls.length +
      references.length +
      names.length +
      addresses.length;

  /// Convert to legacy Map format for backward compatibility with extractedData field
  Map<String, dynamic> toMap() {
    final map = <String, dynamic>{};
    if (amounts.isNotEmpty) {
      map['amounts'] = amounts.map((a) => a.formatted).toList();
    }
    if (dates.isNotEmpty) {
      map['dates'] = dates.map((d) => d.original).toList();
    }
    if (deadlines.isNotEmpty) {
      map['deadlines'] = deadlines
          .map((d) => {
                'label': d.label,
                'date': d.date.toIso8601String(),
                'type': d.type.name,
                'context': d.contextPhrase,
              })
          .toList();
    }
    if (phoneNumbers.isNotEmpty) map['phones'] = phoneNumbers;
    if (emails.isNotEmpty) map['emails'] = emails;
    if (urls.isNotEmpty) map['urls'] = urls;
    if (references.isNotEmpty) {
      map['references'] =
          references.map((r) => '${r.type}: ${r.value}').toList();
    }
    if (names.isNotEmpty) map['names'] = names;
    if (addresses.isNotEmpty) map['addresses'] = addresses;
    return map;
  }
}

class ExtractedDate {
  final DateTime date;
  final String original; // the raw text matched
  final int position; // position in text

  const ExtractedDate({
    required this.date,
    required this.original,
    this.position = 0,
  });
}

enum DeadlineType {
  expiry,
  warranty,
  renewal,
  dueDate,
  appointment,
  event,
  general,
}

class ExtractedDeadline {
  final DateTime date;
  final DeadlineType type;
  final String label;
  final String contextPhrase; // surrounding text that indicates it's a deadline
  final String original;

  const ExtractedDeadline({
    required this.date,
    required this.type,
    required this.label,
    required this.contextPhrase,
    required this.original,
  });

  bool get isExpired => date.isBefore(DateTime.now());
  int get daysUntil => date.difference(DateTime.now()).inDays;

  String get urgencyLabel {
    final days = daysUntil;
    if (days < 0) return 'Expired';
    if (days == 0) return 'Today';
    if (days == 1) return 'Tomorrow';
    if (days <= 7) return '$days days';
    if (days <= 30) return '${(days / 7).ceil()} weeks';
    if (days <= 365) return '${(days / 30).ceil()} months';
    return '${(days / 365).ceil()} years';
  }
}

class ExtractedAmount {
  final double value;
  final String currency; // $, £, €, R
  final String formatted;
  final String? context; // "Total", "Subtotal", etc.

  const ExtractedAmount({
    required this.value,
    required this.currency,
    required this.formatted,
    this.context,
  });
}

enum ReferenceType {
  booking,
  order,
  invoice,
  confirmation,
  policy,
  account,
  tracking,
  general,
}

class ExtractedReference {
  final String value;
  final ReferenceType type;
  final String original;

  const ExtractedReference({
    required this.value,
    required this.type,
    required this.original,
  });
}
