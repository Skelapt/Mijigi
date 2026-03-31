enum CaptureType {
  photo,
  screenshot,
  document,
  note,
  clipboard,
  voice,
  link,
}

enum ItemCategory {
  uncategorised,
  receipt,
  document,
  medical,
  financial,
  legal,
  travel,
  food,
  work,
  personal,
  education,
  shopping,
  contact,
  event,
}

class CaptureItem {
  final String id;
  String? title;
  String? rawText;
  String? summary;
  CaptureType type;
  ItemCategory category;
  List<String> tags;
  List<String> labels; // ML Kit image labels (e.g. "dog", "food", "car")
  String? filePath;
  String? thumbnailPath;
  DateTime createdAt;
  Map<String, dynamic>? extractedData;
  String? collectionId;
  bool isPinned;
  bool isProcessed;
  bool isArchived;

  CaptureItem({
    required this.id,
    this.title,
    this.rawText,
    this.summary,
    this.type = CaptureType.note,
    this.category = ItemCategory.uncategorised,
    this.tags = const [],
    this.labels = const [],
    this.filePath,
    this.thumbnailPath,
    DateTime? createdAt,
    this.extractedData,
    this.collectionId,
    this.isPinned = false,
    this.isProcessed = false,
    this.isArchived = false,
  }) : createdAt = createdAt ?? DateTime.now();

  String get displayTitle {
    if (title != null && title!.isNotEmpty) return title!;
    if (rawText != null && rawText!.isNotEmpty) {
      final lines = rawText!.split('\n').where((l) => l.trim().isNotEmpty);
      if (lines.isNotEmpty) {
        final first = lines.first.trim();
        return first.length > 50 ? '${first.substring(0, 50)}...' : first;
      }
    }
    if (labels.isNotEmpty) return labels.take(3).join(', ');
    return _defaultTitle;
  }

  String get _defaultTitle => switch (type) {
    CaptureType.photo => 'Photo',
    CaptureType.screenshot => 'Screenshot',
    CaptureType.document => 'Document',
    CaptureType.note => 'Note',
    CaptureType.clipboard => 'Clipboard',
    CaptureType.voice => 'Voice Memo',
    CaptureType.link => 'Link',
  };

  String get categoryLabel => switch (category) {
    ItemCategory.uncategorised => 'Uncategorised',
    ItemCategory.receipt => 'Receipt',
    ItemCategory.document => 'Document',
    ItemCategory.medical => 'Medical',
    ItemCategory.financial => 'Financial',
    ItemCategory.legal => 'Legal',
    ItemCategory.travel => 'Travel',
    ItemCategory.food => 'Food',
    ItemCategory.work => 'Work',
    ItemCategory.personal => 'Personal',
    ItemCategory.education => 'Education',
    ItemCategory.shopping => 'Shopping',
    ItemCategory.contact => 'Contact',
    ItemCategory.event => 'Event',
  };

  bool get hasImage =>
      filePath != null &&
      (type == CaptureType.photo ||
          type == CaptureType.screenshot ||
          type == CaptureType.document);

  bool get isImageType =>
      type == CaptureType.photo || type == CaptureType.screenshot;

  Map<String, dynamic> toMap() => {
    'id': id,
    'title': title,
    'rawText': rawText,
    'summary': summary,
    'type': type.index,
    'category': category.index,
    'tags': tags,
    'labels': labels,
    'filePath': filePath,
    'thumbnailPath': thumbnailPath,
    'createdAt': createdAt.toIso8601String(),
    'extractedData': extractedData,
    'collectionId': collectionId,
    'isPinned': isPinned,
    'isProcessed': isProcessed,
    'isArchived': isArchived,
  };

  factory CaptureItem.fromMap(Map<dynamic, dynamic> map) => CaptureItem(
    id: map['id'] as String,
    title: map['title'] as String?,
    rawText: map['rawText'] as String?,
    summary: map['summary'] as String?,
    type: CaptureType.values[map['type'] as int? ?? 0],
    category: ItemCategory.values[map['category'] as int? ?? 0],
    tags: (map['tags'] as List?)?.cast<String>() ?? [],
    labels: (map['labels'] as List?)?.cast<String>() ?? [],
    filePath: map['filePath'] as String?,
    thumbnailPath: map['thumbnailPath'] as String?,
    createdAt: DateTime.parse(map['createdAt'] as String),
    extractedData: map['extractedData'] != null
        ? Map<String, dynamic>.from(map['extractedData'] as Map)
        : null,
    collectionId: map['collectionId'] as String?,
    isPinned: map['isPinned'] as bool? ?? false,
    isProcessed: map['isProcessed'] as bool? ?? false,
    isArchived: map['isArchived'] as bool? ?? false,
  );

  CaptureItem copyWith({
    String? title,
    String? rawText,
    String? summary,
    CaptureType? type,
    ItemCategory? category,
    List<String>? tags,
    List<String>? labels,
    String? filePath,
    String? thumbnailPath,
    Map<String, dynamic>? extractedData,
    String? collectionId,
    bool? isPinned,
    bool? isProcessed,
    bool? isArchived,
  }) => CaptureItem(
    id: id,
    title: title ?? this.title,
    rawText: rawText ?? this.rawText,
    summary: summary ?? this.summary,
    type: type ?? this.type,
    category: category ?? this.category,
    tags: tags ?? this.tags,
    labels: labels ?? this.labels,
    filePath: filePath ?? this.filePath,
    thumbnailPath: thumbnailPath ?? this.thumbnailPath,
    createdAt: createdAt,
    extractedData: extractedData ?? this.extractedData,
    collectionId: collectionId ?? this.collectionId,
    isPinned: isPinned ?? this.isPinned,
    isProcessed: isProcessed ?? this.isProcessed,
    isArchived: isArchived ?? this.isArchived,
  );
}
