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

      // Raw text match
      if (item.rawText?.toLowerCase().contains(term) == true) {
        score += 5;
      }

      // Summary match
      if (item.summary?.toLowerCase().contains(term) == true) {
        score += 4;
      }

      // Tag match
      if (item.tags.any((tag) => tag.toLowerCase().contains(term))) {
        score += 7;
      }

      // Category match
      if (item.categoryLabel.toLowerCase().contains(term)) {
        score += 3;
      }

      // Extracted data match
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
    // Return the most relevant text snippet
    final searchIn = item.rawText ?? item.title ?? item.summary ?? '';
    if (searchIn.isEmpty) return item.categoryLabel;

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
