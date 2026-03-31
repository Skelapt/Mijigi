import '../models/capture_item.dart';

class SearchResult {
  final CaptureItem item;
  final double relevance;
  final String matchContext;

  SearchResult({
    required this.item,
    required this.relevance,
    required this.matchContext,
  });
}

class SearchService {
  List<SearchResult> search(List<CaptureItem> items, String query) {
    if (query.trim().isEmpty) return [];

    final terms = query.toLowerCase().split(RegExp(r'\s+'));
    final results = <SearchResult>[];

    for (final item in items) {
      final score = _scoreItem(item, terms);
      if (score > 0) {
        results.add(SearchResult(
          item: item,
          relevance: score,
          matchContext: _getMatchContext(item, terms),
        ));
      }
    }

    results.sort((a, b) => b.relevance.compareTo(a.relevance));
    return results;
  }

  double _scoreItem(CaptureItem item, List<String> terms) {
    double score = 0;

    for (final term in terms) {
      // Title match (highest weight)
      if (item.title?.toLowerCase().contains(term) == true) {
        score += 10;
      }

      // Image label match - this is key for visual search
      for (final label in item.labels) {
        if (label.contains(term) || term.contains(label)) {
          score += 8;
        }
      }

      // Raw text match (OCR)
      if (item.rawText?.toLowerCase().contains(term) == true) {
        score += 5;
      }

      // Tag match
      if (item.tags.any((tag) => tag.toLowerCase().contains(term))) {
        score += 7;
      }

      // Extracted data match (emails, phones, amounts)
      if (item.extractedData != null) {
        final dataStr = item.extractedData.toString().toLowerCase();
        if (dataStr.contains(term)) {
          score += 4;
        }
      }
    }

    // Boost pinned items
    if (item.isPinned) score *= 1.2;

    // Slight recency boost
    final daysAgo = DateTime.now().difference(item.createdAt).inDays;
    if (daysAgo < 7) score *= 1.1;

    return score;
  }

  String _getMatchContext(CaptureItem item, List<String> terms) {
    // Check labels first
    for (final term in terms) {
      for (final label in item.labels) {
        if (label.contains(term)) return 'Visual: $label';
      }
    }

    final searchIn = item.rawText ?? item.title ?? '';
    if (searchIn.isEmpty) {
      if (item.labels.isNotEmpty) return item.labels.take(3).join(', ');
      return item.displayTitle;
    }

    for (final term in terms) {
      final idx = searchIn.toLowerCase().indexOf(term);
      if (idx >= 0) {
        final start = (idx - 30).clamp(0, searchIn.length);
        final end = (idx + term.length + 30).clamp(0, searchIn.length);
        var snippet = searchIn.substring(start, end).trim();
        if (start > 0) snippet = '...$snippet';
        if (end < searchIn.length) snippet = '$snippet...';
        return snippet;
      }
    }

    return searchIn.length > 60 ? '${searchIn.substring(0, 60)}...' : searchIn;
  }
}
