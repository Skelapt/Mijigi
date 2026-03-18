import '../models/capture_item.dart';

class CategorisationService {
  /// Auto-categorise based on OCR text content using keyword matching.
  /// This is the offline/free categorisation. AI categorisation can enhance this later.
  ItemCategory categorise(String text) {
    final lower = text.toLowerCase();

    // Receipt detection
    if (_matchesAny(lower, [
      'total', 'subtotal', 'tax', 'receipt', 'invoice', 'amount due',
      'payment', 'paid', 'change', 'cashier', 'transaction',
      'visa', 'mastercard', 'eftpos', 'debit', 'credit card',
    ])) {
      if (_matchesAny(lower, ['total', 'subtotal', r'$', '£', '€', 'amount'])) {
        return ItemCategory.receipt;
      }
    }

    // Medical
    if (_matchesAny(lower, [
      'prescription', 'medication', 'dosage', 'doctor', 'dr.',
      'patient', 'diagnosis', 'hospital', 'clinic', 'pharmacy',
      'mg', 'tablet', 'capsule', 'medical', 'health',
      'appointment', 'referral', 'pathology', 'blood test',
    ])) {
      return ItemCategory.medical;
    }

    // Financial
    if (_matchesAny(lower, [
      'bank', 'account', 'balance', 'statement', 'interest',
      'mortgage', 'loan', 'insurance', 'policy', 'premium',
      'investment', 'superannuation', 'tax return', 'ato',
      'abn', 'bsb', 'annual report',
    ])) {
      return ItemCategory.financial;
    }

    // Legal
    if (_matchesAny(lower, [
      'contract', 'agreement', 'terms and conditions', 'clause',
      'hereby', 'witness', 'signature', 'solicitor', 'lawyer',
      'court', 'tribunal', 'affidavit', 'deed', 'lease',
    ])) {
      return ItemCategory.legal;
    }

    // Travel
    if (_matchesAny(lower, [
      'flight', 'boarding pass', 'airline', 'hotel', 'booking',
      'check-in', 'check-out', 'reservation', 'passport',
      'terminal', 'gate', 'departure', 'arrival', 'itinerary',
    ])) {
      return ItemCategory.travel;
    }

    // Food
    if (_matchesAny(lower, [
      'recipe', 'ingredients', 'tablespoon', 'teaspoon', 'cup',
      'preheat', 'oven', 'bake', 'cook', 'menu', 'restaurant',
      'serves', 'prep time', 'calories',
    ])) {
      return ItemCategory.food;
    }

    // Contact
    if (_matchesAny(lower, [
      'phone:', 'tel:', 'email:', 'mobile:', 'fax:',
      'address:', 'business card', 'contact',
    ])) {
      return ItemCategory.contact;
    }

    // Event
    if (_matchesAny(lower, [
      'event', 'concert', 'conference', 'ticket', 'admission',
      'venue', 'rsvp', 'invite', 'invitation', 'schedule',
      'workshop', 'seminar', 'registration',
    ])) {
      return ItemCategory.event;
    }

    // Shopping
    if (_matchesAny(lower, [
      'price', 'sale', 'discount', 'coupon', 'promo',
      'buy', 'order', 'shipping', 'delivery', 'cart',
      'wishlist', 'product', 'item', 'qty', 'quantity',
    ])) {
      return ItemCategory.shopping;
    }

    // Education
    if (_matchesAny(lower, [
      'course', 'lecture', 'assignment', 'exam', 'study',
      'university', 'school', 'student', 'professor',
      'homework', 'grade', 'semester', 'syllabus',
    ])) {
      return ItemCategory.education;
    }

    // Work
    if (_matchesAny(lower, [
      'meeting', 'agenda', 'minutes', 'action items', 'deadline',
      'project', 'report', 'memo', 'office', 'team',
      'quarterly', 'kpi', 'budget', 'stakeholder',
    ])) {
      return ItemCategory.work;
    }

    // Document (generic catch-all for text-heavy content)
    if (text.length > 200) {
      return ItemCategory.document;
    }

    return ItemCategory.uncategorised;
  }

  bool _matchesAny(String text, List<String> keywords) {
    return keywords.any((kw) => text.contains(kw));
  }

  /// Extract structured data from text (dates, amounts, phone numbers, etc.)
  Map<String, dynamic> extractData(String text) {
    final data = <String, dynamic>{};

    // Extract monetary amounts
    final amounts = RegExp(r'[\$£€]\s*[\d,]+\.?\d*')
        .allMatches(text)
        .map((m) => m.group(0)!)
        .toList();
    if (amounts.isNotEmpty) data['amounts'] = amounts;

    // Extract dates
    final dates = RegExp(
      r'\d{1,2}[/\-\.]\d{1,2}[/\-\.]\d{2,4}',
    ).allMatches(text).map((m) => m.group(0)!).toList();
    if (dates.isNotEmpty) data['dates'] = dates;

    // Extract phone numbers
    final phones = RegExp(
      r'(?:\+?\d{1,3}[\s\-]?)?\(?\d{2,4}\)?[\s\-]?\d{3,4}[\s\-]?\d{3,4}',
    ).allMatches(text).map((m) => m.group(0)!.trim()).where((p) => p.length >= 8).toList();
    if (phones.isNotEmpty) data['phones'] = phones;

    // Extract email addresses
    final emails = RegExp(
      r'[a-zA-Z0-9._%+\-]+@[a-zA-Z0-9.\-]+\.[a-zA-Z]{2,}',
    ).allMatches(text).map((m) => m.group(0)!).toList();
    if (emails.isNotEmpty) data['emails'] = emails;

    // Extract URLs
    final urls = RegExp(
      r'https?://[^\s<>]+',
    ).allMatches(text).map((m) => m.group(0)!).toList();
    if (urls.isNotEmpty) data['urls'] = urls;

    return data;
  }
}
