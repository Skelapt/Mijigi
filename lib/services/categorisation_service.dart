import '../models/capture_item.dart';

class CategorisationService {
  /// Auto-categorise using weighted keyword scoring.
  /// Each category has keywords with weights. The category with the highest
  /// total score wins. This avoids false positives from single keyword matches.
  ItemCategory categorise(String text) {
    if (text.trim().isEmpty) return ItemCategory.uncategorised;
    final lower = text.toLowerCase();

    final scores = <ItemCategory, double>{};

    for (final entry in _categoryRules.entries) {
      double score = 0;
      for (final rule in entry.value) {
        if (lower.contains(rule.keyword)) {
          score += rule.weight;
        }
      }
      if (score > 0) scores[entry.key] = score;
    }

    if (scores.isEmpty) {
      // Fallback: if it has lots of text, call it a document
      if (text.length > 200) return ItemCategory.document;
      return ItemCategory.uncategorised;
    }

    // Sort by score, pick highest
    final sorted = scores.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    // Only assign if score is above threshold (at least 2 points)
    // to avoid weak single-keyword matches
    if (sorted.first.value < 2.0) {
      if (text.length > 200) return ItemCategory.document;
      return ItemCategory.uncategorised;
    }

    return sorted.first.key;
  }

  /// Extract structured data from text.
  Map<String, dynamic> extractData(String text) {
    final data = <String, dynamic>{};

    final amounts = RegExp(r'[\$\u00A3\u20AC\u20B9R]\s*[\d,]+\.?\d*')
        .allMatches(text)
        .map((m) => m.group(0)!)
        .toList();
    if (amounts.isNotEmpty) data['amounts'] = amounts;

    final dates = RegExp(r'\d{1,2}[/\-\.]\d{1,2}[/\-\.]\d{2,4}')
        .allMatches(text)
        .map((m) => m.group(0)!)
        .toList();
    if (dates.isNotEmpty) data['dates'] = dates;

    final phones = RegExp(
      r'(?:\+?\d{1,3}[\s\-]?)?\(?\d{2,4}\)?[\s\-]?\d{3,4}[\s\-]?\d{3,4}',
    ).allMatches(text).map((m) => m.group(0)!.trim()).where((p) => p.length >= 8).toList();
    if (phones.isNotEmpty) data['phones'] = phones;

    final emails = RegExp(
      r'[a-zA-Z0-9._%+\-]+@[a-zA-Z0-9.\-]+\.[a-zA-Z]{2,}',
    ).allMatches(text).map((m) => m.group(0)!).toList();
    if (emails.isNotEmpty) data['emails'] = emails;

    final urls = RegExp(r'https?://[^\s<>]+')
        .allMatches(text).map((m) => m.group(0)!).toList();
    if (urls.isNotEmpty) data['urls'] = urls;

    return data;
  }

  // --- Weighted keyword rules ---
  // Weight guide:
  //  3.0 = strong signal (e.g. "prescription" → medical)
  //  2.0 = good signal (e.g. "doctor" → medical)
  //  1.0 = weak signal (needs other keywords to confirm)
  //  0.5 = very weak (common word that leans toward a category)

  static final Map<ItemCategory, List<_KeywordRule>> _categoryRules = {
    ItemCategory.receipt: [
      _KeywordRule('receipt', 3.0),
      _KeywordRule('invoice', 3.0),
      _KeywordRule('subtotal', 3.0),
      _KeywordRule('total:', 2.5),
      _KeywordRule('amount due', 2.5),
      _KeywordRule('tax', 1.5),
      _KeywordRule('gst', 2.0),
      _KeywordRule('vat', 2.0),
      _KeywordRule('cashier', 2.0),
      _KeywordRule('transaction', 1.5),
      _KeywordRule('eftpos', 2.5),
      _KeywordRule('visa', 1.0),
      _KeywordRule('mastercard', 1.5),
      _KeywordRule('paid', 1.0),
      _KeywordRule('change due', 2.0),
      _KeywordRule('qty', 1.5),
      _KeywordRule('unit price', 2.0),
      _KeywordRule('payment received', 2.5),
    ],

    ItemCategory.medical: [
      _KeywordRule('prescription', 3.0),
      _KeywordRule('medication', 3.0),
      _KeywordRule('dosage', 3.0),
      _KeywordRule('patient', 2.0),
      _KeywordRule('diagnosis', 3.0),
      _KeywordRule('hospital', 2.5),
      _KeywordRule('clinic', 2.0),
      _KeywordRule('pharmacy', 2.5),
      _KeywordRule('mg', 1.0),
      _KeywordRule('tablet', 1.5),
      _KeywordRule('capsule', 2.0),
      _KeywordRule('medical', 2.0),
      _KeywordRule('referral', 2.0),
      _KeywordRule('pathology', 3.0),
      _KeywordRule('blood test', 3.0),
      _KeywordRule('dr.', 1.0),
      _KeywordRule('doctor', 1.5),
      _KeywordRule('health insurance', 2.5),
      _KeywordRule('medicare', 3.0),
    ],

    ItemCategory.financial: [
      _KeywordRule('bank statement', 3.0),
      _KeywordRule('account number', 2.5),
      _KeywordRule('balance', 1.5),
      _KeywordRule('interest rate', 2.5),
      _KeywordRule('mortgage', 3.0),
      _KeywordRule('loan', 2.0),
      _KeywordRule('insurance policy', 3.0),
      _KeywordRule('premium', 1.5),
      _KeywordRule('investment', 2.0),
      _KeywordRule('superannuation', 3.0),
      _KeywordRule('tax return', 3.0),
      _KeywordRule('ato', 2.0),
      _KeywordRule('abn', 2.0),
      _KeywordRule('bsb', 2.5),
      _KeywordRule('annual report', 2.0),
      _KeywordRule('dividend', 2.5),
      _KeywordRule('portfolio', 1.5),
      _KeywordRule('financial', 1.5),
      _KeywordRule('bank', 1.0),
    ],

    ItemCategory.legal: [
      _KeywordRule('contract', 2.5),
      _KeywordRule('agreement', 2.0),
      _KeywordRule('terms and conditions', 3.0),
      _KeywordRule('clause', 2.0),
      _KeywordRule('hereby', 2.5),
      _KeywordRule('witness', 1.5),
      _KeywordRule('solicitor', 3.0),
      _KeywordRule('lawyer', 2.5),
      _KeywordRule('court', 2.0),
      _KeywordRule('tribunal', 3.0),
      _KeywordRule('affidavit', 3.0),
      _KeywordRule('deed', 2.0),
      _KeywordRule('lease agreement', 3.0),
      _KeywordRule('indemnify', 3.0),
      _KeywordRule('liability', 2.0),
      _KeywordRule('jurisdiction', 2.5),
    ],

    ItemCategory.travel: [
      _KeywordRule('flight', 2.5),
      _KeywordRule('boarding pass', 3.0),
      _KeywordRule('airline', 2.5),
      _KeywordRule('hotel', 2.0),
      _KeywordRule('booking confirmation', 3.0),
      _KeywordRule('check-in', 2.0),
      _KeywordRule('check-out', 2.0),
      _KeywordRule('reservation', 2.0),
      _KeywordRule('passport', 2.5),
      _KeywordRule('terminal', 1.5),
      _KeywordRule('gate', 1.0),
      _KeywordRule('departure', 2.0),
      _KeywordRule('arrival', 2.0),
      _KeywordRule('itinerary', 3.0),
      _KeywordRule('baggage', 2.0),
      _KeywordRule('seat', 0.5),
    ],

    ItemCategory.food: [
      _KeywordRule('recipe', 3.0),
      _KeywordRule('ingredients', 2.5),
      _KeywordRule('tablespoon', 3.0),
      _KeywordRule('teaspoon', 3.0),
      _KeywordRule('preheat', 3.0),
      _KeywordRule('oven', 1.5),
      _KeywordRule('bake', 1.5),
      _KeywordRule('serves', 2.0),
      _KeywordRule('prep time', 3.0),
      _KeywordRule('cook time', 3.0),
      _KeywordRule('calories', 2.0),
      _KeywordRule('menu', 1.5),
      _KeywordRule('restaurant', 1.5),
      _KeywordRule('cup of', 1.0),
    ],

    ItemCategory.contact: [
      _KeywordRule('phone:', 2.5),
      _KeywordRule('tel:', 2.5),
      _KeywordRule('email:', 2.0),
      _KeywordRule('mobile:', 2.5),
      _KeywordRule('fax:', 2.5),
      _KeywordRule('address:', 1.5),
      _KeywordRule('business card', 3.0),
      _KeywordRule('linkedin', 1.5),
      _KeywordRule('www.', 0.5),
    ],

    ItemCategory.event: [
      _KeywordRule('event', 1.5),
      _KeywordRule('concert', 3.0),
      _KeywordRule('conference', 2.5),
      _KeywordRule('ticket', 2.0),
      _KeywordRule('admission', 2.5),
      _KeywordRule('venue', 2.0),
      _KeywordRule('rsvp', 3.0),
      _KeywordRule('invitation', 2.5),
      _KeywordRule('workshop', 2.0),
      _KeywordRule('seminar', 2.5),
      _KeywordRule('registration', 1.5),
    ],

    ItemCategory.shopping: [
      _KeywordRule('price', 1.0),
      _KeywordRule('sale', 1.0),
      _KeywordRule('discount', 2.0),
      _KeywordRule('coupon', 3.0),
      _KeywordRule('promo code', 3.0),
      _KeywordRule('order confirmation', 3.0),
      _KeywordRule('shipping', 2.0),
      _KeywordRule('delivery', 1.5),
      _KeywordRule('tracking number', 3.0),
      _KeywordRule('add to cart', 3.0),
      _KeywordRule('wishlist', 2.5),
      _KeywordRule('out of stock', 2.5),
    ],

    ItemCategory.education: [
      _KeywordRule('course', 1.5),
      _KeywordRule('lecture', 2.5),
      _KeywordRule('assignment', 2.5),
      _KeywordRule('exam', 2.5),
      _KeywordRule('university', 2.5),
      _KeywordRule('school', 1.5),
      _KeywordRule('student', 1.5),
      _KeywordRule('professor', 2.5),
      _KeywordRule('homework', 3.0),
      _KeywordRule('semester', 2.5),
      _KeywordRule('syllabus', 3.0),
      _KeywordRule('grade', 1.0),
      _KeywordRule('study', 1.0),
    ],

    ItemCategory.work: [
      _KeywordRule('meeting notes', 3.0),
      _KeywordRule('agenda', 2.5),
      _KeywordRule('minutes', 1.5),
      _KeywordRule('action items', 3.0),
      _KeywordRule('deadline', 2.0),
      _KeywordRule('project', 1.0),
      _KeywordRule('report', 1.0),
      _KeywordRule('memo', 2.5),
      _KeywordRule('quarterly', 2.0),
      _KeywordRule('kpi', 3.0),
      _KeywordRule('stakeholder', 2.5),
      _KeywordRule('deliverable', 3.0),
      _KeywordRule('sprint', 2.5),
    ],

    ItemCategory.personal: [
      // Personal is the catch-all for things that don't fit elsewhere
      // Keep weights low so other categories win when they match
      _KeywordRule('diary', 2.0),
      _KeywordRule('journal', 2.0),
      _KeywordRule('dear', 1.0),
      _KeywordRule('birthday', 1.5),
      _KeywordRule('anniversary', 1.5),
      _KeywordRule('family', 1.0),
      _KeywordRule('remember', 0.5),
    ],
  };
}

class _KeywordRule {
  final String keyword;
  final double weight;
  const _KeywordRule(this.keyword, this.weight);
}
