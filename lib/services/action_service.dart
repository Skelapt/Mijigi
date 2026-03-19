import 'package:uuid/uuid.dart';
import '../models/capture_item.dart';
import '../models/action_suggestion.dart';

/// Generates smart action suggestions from captured item content.
class ActionService {
  final _uuid = const Uuid();

  /// Generate action suggestions for a single item.
  List<ActionSuggestion> generateActions(CaptureItem item) {
    final actions = <ActionSuggestion>[];
    final data = item.extractedData;
    if (data == null) return actions;

    // Phone numbers → Call action
    final phones = _getList(data, 'phones');
    for (final phone in phones) {
      actions.add(ActionSuggestion(
        id: _uuid.v4(),
        itemId: item.id,
        type: ActionType.callNumber,
        label: 'Call $phone',
        description: 'Tap to call this number',
        data: {'phone': phone},
      ));
    }

    // Emails → Send email action
    final emails = _getList(data, 'emails');
    for (final email in emails) {
      actions.add(ActionSuggestion(
        id: _uuid.v4(),
        itemId: item.id,
        type: ActionType.sendEmail,
        label: 'Email $email',
        description: 'Compose an email',
        data: {'email': email},
      ));
    }

    // URLs → Open action
    final urls = _getList(data, 'urls');
    for (final url in urls) {
      actions.add(ActionSuggestion(
        id: _uuid.v4(),
        itemId: item.id,
        type: ActionType.openUrl,
        label: 'Open link',
        description: url.length > 50 ? '${url.substring(0, 50)}...' : url,
        data: {'url': url},
      ));
    }

    // Names → Create contact
    final names = _getList(data, 'names');
    for (final name in names) {
      actions.add(ActionSuggestion(
        id: _uuid.v4(),
        itemId: item.id,
        type: ActionType.createContact,
        label: 'Save contact: $name',
        description: 'Create a new contact',
        data: {
          'name': name,
          if (phones.isNotEmpty) 'phone': phones.first,
          if (emails.isNotEmpty) 'email': emails.first,
        },
      ));
    }

    // Deadlines → Set reminder
    final deadlines = data['deadlines'] as List?;
    if (deadlines != null) {
      for (final dl in deadlines) {
        if (dl is! Map) continue;
        final label = dl['label'] as String? ?? 'Deadline';
        final dateStr = dl['date'] as String?;
        if (dateStr == null) continue;

        final date = DateTime.tryParse(dateStr);
        if (date == null || date.isBefore(DateTime.now())) continue;

        actions.add(ActionSuggestion(
          id: _uuid.v4(),
          itemId: item.id,
          type: ActionType.setReminder,
          label: 'Remind: $label',
          description: 'Set a reminder before this date',
          data: {'date': dateStr, 'label': label},
        ));

        actions.add(ActionSuggestion(
          id: _uuid.v4(),
          itemId: item.id,
          type: ActionType.addToCalendar,
          label: 'Calendar: $label',
          description: 'Add to your calendar',
          data: {'date': dateStr, 'label': label},
        ));
      }
    }

    // Receipts → Save receipt action
    if (item.category == ItemCategory.receipt) {
      final amounts = _getList(data, 'amounts');
      final total = amounts.isNotEmpty ? amounts.last : null;
      actions.add(ActionSuggestion(
        id: _uuid.v4(),
        itemId: item.id,
        type: ActionType.saveReceipt,
        label: 'Track expense${total != null ? ': $total' : ''}',
        description: 'Add to spending tracker',
        data: {'amounts': amounts},
      ));
    }

    // Food category with ingredients → Shopping list
    if (item.category == ItemCategory.food) {
      actions.add(ActionSuggestion(
        id: _uuid.v4(),
        itemId: item.id,
        type: ActionType.addToShoppingList,
        label: 'Create shopping list',
        description: 'Extract ingredients from recipe',
        data: {'text': item.rawText ?? ''},
      ));
    }

    // Contact category → Create contact
    if (item.category == ItemCategory.contact && names.isEmpty) {
      actions.add(ActionSuggestion(
        id: _uuid.v4(),
        itemId: item.id,
        type: ActionType.createContact,
        label: 'Save as contact',
        description: 'Create contact from this info',
        data: {
          if (phones.isNotEmpty) 'phone': phones.first,
          if (emails.isNotEmpty) 'email': emails.first,
        },
      ));
    }

    // Addresses → Navigate
    final addresses = _getList(data, 'addresses');
    for (final addr in addresses) {
      actions.add(ActionSuggestion(
        id: _uuid.v4(),
        itemId: item.id,
        type: ActionType.navigate,
        label: 'Navigate to address',
        description: addr.length > 50 ? '${addr.substring(0, 50)}...' : addr,
        data: {'address': addr},
      ));
    }

    return actions;
  }

  /// Generate actions for all items, returns only pending (not completed/dismissed).
  List<ActionSuggestion> getAllPendingActions(List<CaptureItem> items) {
    final all = <ActionSuggestion>[];
    for (final item in items) {
      if (!item.isProcessed || item.isArchived) continue;
      all.addAll(generateActions(item));
    }
    return all.where((a) => !a.isCompleted && !a.isDismissed).toList();
  }

  List<String> _getList(Map<String, dynamic> data, String key) {
    final raw = data[key];
    if (raw is List) return raw.cast<String>();
    return [];
  }
}
