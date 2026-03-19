/// Types of actions the agent can suggest.
enum ActionType {
  createContact,
  setReminder,
  addToCalendar,
  createTask,
  callNumber,
  sendEmail,
  openUrl,
  saveReceipt,
  addToShoppingList,
  navigate,
  copyText,
}

/// A suggested action generated from item content.
class ActionSuggestion {
  final String id;
  final String itemId;
  final ActionType type;
  final String label;
  final String description;
  final Map<String, dynamic> data;
  bool isCompleted;
  bool isDismissed;

  ActionSuggestion({
    required this.id,
    required this.itemId,
    required this.type,
    required this.label,
    required this.description,
    this.data = const {},
    this.isCompleted = false,
    this.isDismissed = false,
  });

  String get typeIcon => switch (type) {
        ActionType.createContact => '\u{1F4C7}',
        ActionType.setReminder => '\u{23F0}',
        ActionType.addToCalendar => '\u{1F4C5}',
        ActionType.createTask => '\u{2705}',
        ActionType.callNumber => '\u{1F4DE}',
        ActionType.sendEmail => '\u{1F4E7}',
        ActionType.openUrl => '\u{1F310}',
        ActionType.saveReceipt => '\u{1F9FE}',
        ActionType.addToShoppingList => '\u{1F6D2}',
        ActionType.navigate => '\u{1F4CD}',
        ActionType.copyText => '\u{1F4CB}',
      };

  String get actionVerb => switch (type) {
        ActionType.createContact => 'Create Contact',
        ActionType.setReminder => 'Set Reminder',
        ActionType.addToCalendar => 'Add to Calendar',
        ActionType.createTask => 'Create Task',
        ActionType.callNumber => 'Call',
        ActionType.sendEmail => 'Send Email',
        ActionType.openUrl => 'Open Link',
        ActionType.saveReceipt => 'Save Receipt',
        ActionType.addToShoppingList => 'Add to List',
        ActionType.navigate => 'Navigate',
        ActionType.copyText => 'Copy',
      };

  Map<String, dynamic> toMap() => {
        'id': id,
        'itemId': itemId,
        'type': type.index,
        'label': label,
        'description': description,
        'data': data,
        'isCompleted': isCompleted,
        'isDismissed': isDismissed,
      };

  factory ActionSuggestion.fromMap(Map<dynamic, dynamic> map) =>
      ActionSuggestion(
        id: map['id'] as String,
        itemId: map['itemId'] as String,
        type: ActionType.values[map['type'] as int? ?? 0],
        label: map['label'] as String,
        description: map['description'] as String? ?? '',
        data: map['data'] != null
            ? Map<String, dynamic>.from(map['data'] as Map)
            : {},
        isCompleted: map['isCompleted'] as bool? ?? false,
        isDismissed: map['isDismissed'] as bool? ?? false,
      );
}
