import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../models/capture_item.dart';
import '../models/agent_models.dart';

class AgentService {
  AgentConfig _config = AgentConfig();

  void updateConfig(AgentConfig config) {
    _config = config;
  }

  AgentConfig get config => _config;

  /// Process a command locally first (fast, free), then via API if configured
  Future<AgentMessage> processCommand(
    String command,
    List<CaptureItem> allItems,
  ) async {
    // Try local processing first
    final localResult = _processLocally(command, allItems);
    if (localResult != null) return localResult;

    // If API is configured, send to AI
    if (_config.isConfigured) {
      return _processViaApi(command, allItems);
    }

    // Fallback
    return AgentMessage(
      text: 'I can search and organise your items locally. Configure an AI API in Settings to unlock full agent capabilities like natural language commands, smart summaries, and intelligent organisation.',
      isUser: false,
    );
  }

  /// Local processing - handles common commands without needing an API
  AgentMessage? _processLocally(String command, List<CaptureItem> items) {
    final lower = command.toLowerCase().trim();

    // --- Search commands ---
    if (lower.startsWith('find') ||
        lower.startsWith('search') ||
        lower.startsWith('show me') ||
        lower.startsWith('where')) {
      return _handleSearch(lower, items);
    }

    // --- Spending / receipt commands ---
    if (lower.contains('spend') ||
        lower.contains('receipt') ||
        lower.contains('total') ||
        lower.contains('how much')) {
      return _handleSpending(lower, items);
    }

    // --- Count / stats commands ---
    if (lower.startsWith('how many') || lower.contains('count')) {
      return _handleCount(lower, items);
    }

    // --- Organise commands ---
    if (lower.startsWith('organise') ||
        lower.startsWith('organize') ||
        lower.startsWith('sort') ||
        lower.startsWith('clean up')) {
      return _handleOrganise(items);
    }

    // --- Summary commands ---
    if (lower.contains('summary') ||
        lower.contains('summarise') ||
        lower.contains('summarize') ||
        lower.contains('overview') ||
        lower.startsWith('what do i have')) {
      return _handleSummary(items);
    }

    // --- Expiry / deadline commands ---
    if (lower.contains('expir') ||
        lower.contains('deadline') ||
        lower.contains('due') ||
        lower.contains('renew')) {
      return _handleExpiry(items);
    }

    // --- Pin commands ---
    if (lower.startsWith('pin ')) {
      return _handlePinCommand(lower, items);
    }

    return null;
  }

  AgentMessage _handleSearch(String query, List<CaptureItem> items) {
    // Extract search terms (remove command words)
    var searchTerms = query
        .replaceAll(RegExp(r'^(find|search|show me|where is|where are)\s*'), '')
        .replaceAll(RegExp(r'^(all|my|the)\s*'), '')
        .trim();

    // Category search
    for (final cat in ItemCategory.values) {
      if (searchTerms.contains(cat.name.toLowerCase()) ||
          searchTerms.contains(_pluralCategory(cat))) {
        final found = items.where((i) => i.category == cat).toList();
        if (found.isNotEmpty) {
          return AgentMessage(
            text: 'Found ${found.length} ${_pluralCategory(cat)}.',
            isUser: false,
            itemIds: found.map((i) => i.id).toList(),
          );
        } else {
          return AgentMessage(
            text: 'No ${_pluralCategory(cat)} found.',
            isUser: false,
          );
        }
      }
    }

    // Type search
    for (final type in CaptureType.values) {
      if (searchTerms.contains(type.name.toLowerCase()) ||
          searchTerms.contains('${type.name.toLowerCase()}s')) {
        final found = items.where((i) => i.type == type).toList();
        if (found.isNotEmpty) {
          return AgentMessage(
            text: 'Found ${found.length} ${type.name}s.',
            isUser: false,
            itemIds: found.map((i) => i.id).toList(),
          );
        }
      }
    }

    // Text search
    final found = items.where((i) {
      final text =
          '${i.title ?? ''} ${i.rawText ?? ''} ${i.summary ?? ''}'.toLowerCase();
      return searchTerms.split(' ').every((term) => text.contains(term));
    }).toList();

    if (found.isNotEmpty) {
      return AgentMessage(
        text: 'Found ${found.length} item${found.length == 1 ? '' : 's'} matching "$searchTerms".',
        isUser: false,
        itemIds: found.map((i) => i.id).toList(),
      );
    }

    return AgentMessage(
      text: 'No items found matching "$searchTerms".',
      isUser: false,
    );
  }

  AgentMessage _handleSpending(String query, List<CaptureItem> items) {
    final receipts =
        items.where((i) => i.category == ItemCategory.receipt).toList();

    if (receipts.isEmpty) {
      return AgentMessage(
        text: 'No receipts found. Take photos of your receipts and I\'ll track your spending automatically.',
        isUser: false,
      );
    }

    // Try to extract amounts from all receipts
    double total = 0;
    int counted = 0;
    final amounts = <String>[];

    for (final receipt in receipts) {
      if (receipt.extractedData != null &&
          receipt.extractedData!['amounts'] != null) {
        final receiptAmounts =
            (receipt.extractedData!['amounts'] as List).cast<String>();
        for (final amount in receiptAmounts) {
          final cleaned =
              amount.replaceAll(RegExp(r'[^\d.]'), '');
          final value = double.tryParse(cleaned);
          if (value != null) {
            total += value;
            counted++;
            amounts.add(amount);
          }
        }
      }
    }

    // Check for time filter
    DateTime? after;
    if (query.contains('this month')) {
      final now = DateTime.now();
      after = DateTime(now.year, now.month, 1);
    } else if (query.contains('this week')) {
      after = DateTime.now().subtract(const Duration(days: 7));
    } else if (query.contains('today')) {
      final now = DateTime.now();
      after = DateTime(now.year, now.month, now.day);
    }

    if (after != null) {
      final filtered =
          receipts.where((r) => r.createdAt.isAfter(after!)).toList();
      total = 0;
      counted = 0;
      for (final receipt in filtered) {
        if (receipt.extractedData?['amounts'] != null) {
          for (final amount
              in (receipt.extractedData!['amounts'] as List).cast<String>()) {
            final value =
                double.tryParse(amount.replaceAll(RegExp(r'[^\d.]'), ''));
            if (value != null) {
              total += value;
              counted++;
            }
          }
        }
      }

      return AgentMessage(
        text: counted > 0
            ? 'Found ${filtered.length} receipts with $counted amounts detected. Estimated total: \$${total.toStringAsFixed(2)}'
            : 'Found ${filtered.length} receipts but couldn\'t extract amounts. Try clearer photos for better OCR results.',
        isUser: false,
        itemIds: filtered.map((i) => i.id).toList(),
        insight: counted > 0
            ? AgentInsight(
                title: 'Spending',
                data: {
                  'Receipts': '${filtered.length}',
                  'Total': '\$${total.toStringAsFixed(2)}',
                },
                type: InsightType.spending,
              )
            : null,
      );
    }

    return AgentMessage(
      text: counted > 0
          ? 'You have ${receipts.length} receipts with $counted amounts detected. Total: \$${total.toStringAsFixed(2)}'
          : 'You have ${receipts.length} receipts. I couldn\'t extract amounts automatically. Try "how much did I spend this month" for filtered results.',
      isUser: false,
      itemIds: receipts.map((i) => i.id).toList(),
      insight: counted > 0
          ? AgentInsight(
              title: 'All-time Spending',
              data: {
                'Receipts': '${receipts.length}',
                'Total': '\$${total.toStringAsFixed(2)}',
              },
              type: InsightType.spending,
            )
          : null,
    );
  }

  AgentMessage _handleCount(String query, List<CaptureItem> items) {
    for (final cat in ItemCategory.values) {
      if (query.contains(cat.name.toLowerCase()) ||
          query.contains(_pluralCategory(cat))) {
        final count = items.where((i) => i.category == cat).length;
        return AgentMessage(
          text: 'You have $count ${_pluralCategory(cat)}.',
          isUser: false,
        );
      }
    }

    for (final type in CaptureType.values) {
      if (query.contains(type.name.toLowerCase()) ||
          query.contains('${type.name.toLowerCase()}s')) {
        final count = items.where((i) => i.type == type).length;
        return AgentMessage(
          text: 'You have $count ${type.name}s.',
          isUser: false,
        );
      }
    }

    return AgentMessage(
      text: 'You have ${items.length} items total.',
      isUser: false,
    );
  }

  AgentMessage _handleOrganise(List<CaptureItem> items) {
    final uncategorised =
        items.where((i) => i.category == ItemCategory.uncategorised).toList();

    if (uncategorised.isEmpty) {
      return AgentMessage(
        text: 'Everything is already organised. All ${items.length} items are categorised.',
        isUser: false,
      );
    }

    return AgentMessage(
      text: '${uncategorised.length} items are uncategorised. I can auto-categorise them based on their content.',
      isUser: false,
      itemIds: uncategorised.map((i) => i.id).toList(),
      actions: [
        AgentAction(
          label: 'Auto-categorise ${uncategorised.length} items',
          type: AgentActionType.organise,
          params: {'itemIds': uncategorised.map((i) => i.id).toList()},
        ),
      ],
    );
  }

  AgentMessage _handleSummary(List<CaptureItem> items) {
    final categoryCounts = <String, int>{};
    for (final item in items) {
      final label = _pluralCategory(item.category);
      categoryCounts[label] = (categoryCounts[label] ?? 0) + 1;
    }

    final sorted = categoryCounts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    final breakdown =
        sorted.map((e) => '${e.key}: ${e.value}').join('\n');

    final pinned = items.where((i) => i.isPinned).length;
    final withText = items.where((i) => i.rawText != null).length;

    return AgentMessage(
      text: 'You have ${items.length} items total. $withText have extracted text. $pinned are pinned.\n\n$breakdown',
      isUser: false,
      insight: AgentInsight(
        title: 'Your Mijigi',
        data: {
          'Total Items': '${items.length}',
          'With Text': '$withText',
          'Pinned': '$pinned',
          'Categories': '${sorted.length}',
        },
        type: InsightType.summary,
      ),
    );
  }

  AgentMessage _handleExpiry(List<CaptureItem> items) {
    final withDates = items.where((i) {
      return i.extractedData?['dates'] != null &&
          (i.extractedData!['dates'] as List).isNotEmpty;
    }).toList();

    if (withDates.isEmpty) {
      return AgentMessage(
        text: 'No items with dates detected. Scan documents like insurance policies, passports, or warranties and I\'ll track their expiry dates.',
        isUser: false,
      );
    }

    return AgentMessage(
      text: 'Found ${withDates.length} items with dates. Here they are — check for upcoming deadlines.',
      isUser: false,
      itemIds: withDates.map((i) => i.id).toList(),
    );
  }

  AgentMessage _handlePinCommand(String query, List<CaptureItem> items) {
    final searchTerm = query.replaceFirst('pin ', '').trim();
    final found = items.where((i) {
      final text = '${i.title ?? ''} ${i.rawText ?? ''}'.toLowerCase();
      return text.contains(searchTerm);
    }).toList();

    if (found.isEmpty) {
      return AgentMessage(
        text: 'No items found matching "$searchTerm" to pin.',
        isUser: false,
      );
    }

    return AgentMessage(
      text: 'Found ${found.length} item${found.length == 1 ? '' : 's'} matching "$searchTerm".',
      isUser: false,
      itemIds: found.map((i) => i.id).toList(),
      actions: [
        AgentAction(
          label: 'Pin ${found.length} item${found.length == 1 ? '' : 's'}',
          type: AgentActionType.pin,
          params: {'itemIds': found.map((i) => i.id).toList()},
        ),
      ],
    );
  }

  /// Process via external AI API
  Future<AgentMessage> _processViaApi(
    String command,
    List<CaptureItem> items,
  ) async {
    try {
      // Build context - send relevant items (limit to avoid token overflow)
      final relevantItems = _getRelevantItems(command, items);
      final itemContext = relevantItems.map((i) => {
            'id': i.id,
            'title': i.displayTitle,
            'type': i.type.name,
            'category': i.categoryLabel,
            'text': i.rawText != null
                ? (i.rawText!.length > 300
                    ? '${i.rawText!.substring(0, 300)}...'
                    : i.rawText)
                : null,
            'extractedData': i.extractedData,
            'createdAt': i.createdAt.toIso8601String(),
            'isPinned': i.isPinned,
          }).toList();

      final body = jsonEncode({
        'command': command,
        'context': {
          'items': itemContext,
          'totalItems': items.length,
          'categories': items
              .map((i) => i.categoryLabel)
              .toSet()
              .toList(),
        },
      });

      final response = await http.post(
        Uri.parse(_config.apiEndpoint!),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${_config.apiKey}',
        },
        body: body,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        return _parseApiResponse(data);
      } else {
        return AgentMessage(
          text: 'API error (${response.statusCode}). Check your API configuration in Settings.',
          isUser: false,
        );
      }
    } catch (e) {
      debugPrint('Agent API error: $e');
      // Fallback to local processing
      final localResult = _processLocally(command, items);
      if (localResult != null) return localResult;

      return AgentMessage(
        text: 'Couldn\'t reach the AI API. Processed locally instead. Check your connection and API settings.',
        isUser: false,
      );
    }
  }

  List<CaptureItem> _getRelevantItems(
      String command, List<CaptureItem> items) {
    final lower = command.toLowerCase();
    var relevant = items.toList();

    // Filter by category if mentioned
    for (final cat in ItemCategory.values) {
      if (lower.contains(cat.name.toLowerCase())) {
        relevant = relevant.where((i) => i.category == cat).toList();
        break;
      }
    }

    // Limit to 50 most recent
    if (relevant.length > 50) {
      relevant = relevant.sublist(0, 50);
    }

    return relevant;
  }

  AgentMessage _parseApiResponse(Map<String, dynamic> data) {
    final message = data['message'] as String? ?? 'Done.';
    final itemIds = (data['items'] as List?)?.cast<String>();
    final rawActions = data['actions'] as List?;

    List<AgentAction>? actions;
    if (rawActions != null) {
      actions = rawActions.map((a) {
        final actionMap = a as Map<String, dynamic>;
        return AgentAction(
          label: actionMap['label'] as String? ?? 'Action',
          type: AgentActionType.values.firstWhere(
            (t) => t.name == actionMap['type'],
            orElse: () => AgentActionType.organise,
          ),
          params: actionMap['params'] as Map<String, dynamic>? ?? {},
        );
      }).toList();
    }

    AgentInsight? insight;
    if (data['insight'] != null) {
      final insightMap = data['insight'] as Map<String, dynamic>;
      insight = AgentInsight(
        title: insightMap['title'] as String? ?? '',
        data: (insightMap['data'] as Map<String, dynamic>?)
                ?.map((k, v) => MapEntry(k, v.toString())) ??
            {},
      );
    }

    return AgentMessage(
      text: message,
      isUser: false,
      itemIds: itemIds,
      actions: actions,
      insight: insight,
    );
  }

  String _pluralCategory(ItemCategory cat) => switch (cat) {
        ItemCategory.uncategorised => 'uncategorised',
        ItemCategory.receipt => 'receipts',
        ItemCategory.document => 'documents',
        ItemCategory.medical => 'medical items',
        ItemCategory.financial => 'financial items',
        ItemCategory.legal => 'legal documents',
        ItemCategory.travel => 'travel items',
        ItemCategory.food => 'food & recipes',
        ItemCategory.work => 'work items',
        ItemCategory.personal => 'personal items',
        ItemCategory.education => 'education items',
        ItemCategory.shopping => 'shopping items',
        ItemCategory.contact => 'contacts',
        ItemCategory.event => 'events',
      };
}
