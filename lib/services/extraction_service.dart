import '../models/extraction_result.dart';

/// The brain of Mijigi. Extracts structured intelligence from raw text.
/// Works entirely offline - no AI needed for basic extraction.
class ExtractionService {
  static const _monthNames = {
    'january': 1, 'february': 2, 'march': 3, 'april': 4,
    'may': 5, 'june': 6, 'july': 7, 'august': 8,
    'september': 9, 'october': 10, 'november': 11, 'december': 12,
    'jan': 1, 'feb': 2, 'mar': 3, 'apr': 4,
    'jun': 6, 'jul': 7, 'aug': 8, 'sep': 9, 'sept': 9,
    'oct': 10, 'nov': 11, 'dec': 12,
  };

  static final _expiryKeywords = RegExp(
    r'(?:expires?|expiry|exp\.?|valid\s+(?:until|to|thru|through)|'
    r'best\s+before|use\s+by|sell\s+by|'
    r'renewal\s+(?:date|by|on)|renew\s+(?:by|before)|'
    r'warranty\s+(?:until|expires?|ends?|valid)|'
    r'covered?\s+(?:until|through)|'
    r'policy\s+(?:expires?|ends?|renewal)|'
    r'ends?\s+(?:on|date)|ending\s+(?:on|date)|'
    r'due\s+(?:date|by|on|before)|'
    r'deadline|'
    r'maturity\s+date|'
    r'not\s+valid\s+after)',
    caseSensitive: false,
  );

  static final _appointmentKeywords = RegExp(
    r'(?:appointment|appt\.?|scheduled\s+(?:for|on)|'
    r'check[- ]?in|check[- ]?out|'
    r'booking\s+(?:for|on|date)|'
    r'reservation\s+(?:for|on)|'
    r'arrival|departure|'
    r'meeting\s+(?:on|at|date)|'
    r'interview\s+(?:on|at|date))',
    caseSensitive: false,
  );

  static final _referenceKeywords = {
    ReferenceType.booking: RegExp(
        r'(?:booking|reservation)\s*(?:#|no\.?|number|ref|reference|code)?[:.\s]*',
        caseSensitive: false),
    ReferenceType.order: RegExp(
        r'(?:order)\s*(?:#|no\.?|number|id)?[:.\s]*',
        caseSensitive: false),
    ReferenceType.invoice: RegExp(
        r'(?:invoice|inv)\s*(?:#|no\.?|number)?[:.\s]*',
        caseSensitive: false),
    ReferenceType.confirmation: RegExp(
        r'(?:confirmation|conf)\s*(?:#|no\.?|number|code)?[:.\s]*',
        caseSensitive: false),
    ReferenceType.policy: RegExp(
        r'(?:policy)\s*(?:#|no\.?|number)?[:.\s]*',
        caseSensitive: false),
    ReferenceType.account: RegExp(
        r'(?:account|acct?)\s*(?:#|no\.?|number)?[:.\s]*',
        caseSensitive: false),
    ReferenceType.tracking: RegExp(
        r'(?:tracking|track)\s*(?:#|no\.?|number|id)?[:.\s]*',
        caseSensitive: false),
    ReferenceType.general: RegExp(
        r'(?:ref|reference|ref\.?)\s*(?:#|no\.?|number)?[:.\s]*',
        caseSensitive: false),
  };

  /// Extract all structured data from text.
  ExtractionResult extract(String text) {
    if (text.trim().isEmpty) return const ExtractionResult();

    return ExtractionResult(
      dates: _extractDates(text),
      deadlines: _extractDeadlines(text),
      amounts: _extractAmounts(text),
      phoneNumbers: _extractPhones(text),
      emails: _extractEmails(text),
      urls: _extractUrls(text),
      references: _extractReferences(text),
      names: _extractNames(text),
      addresses: _extractAddresses(text),
    );
  }

  // ─── DATE EXTRACTION ───────────────────────────────────────────

  List<ExtractedDate> _extractDates(String text) {
    final dates = <ExtractedDate>[];
    final seen = <String>{};

    // DD/MM/YYYY or MM/DD/YYYY or DD-MM-YYYY or DD.MM.YYYY
    final numericDateRe = RegExp(
      r'(\d{1,2})[/\-.](\d{1,2})[/\-.](\d{2,4})',
    );
    for (final match in numericDateRe.allMatches(text)) {
      final key = match.group(0)!;
      if (seen.contains(key)) continue;
      seen.add(key);

      final a = int.parse(match.group(1)!);
      final b = int.parse(match.group(2)!);
      var y = int.parse(match.group(3)!);
      if (y < 100) y += 2000;

      // Try DD/MM/YYYY first (more common globally)
      DateTime? date;
      if (a <= 31 && b <= 12) {
        date = _tryDate(y, b, a);
      }
      // Fallback to MM/DD/YYYY
      date ??= (a <= 12 && b <= 31) ? _tryDate(y, a, b) : null;

      if (date != null) {
        dates.add(ExtractedDate(
          date: date,
          original: key,
          position: match.start,
        ));
      }
    }

    // YYYY-MM-DD (ISO format)
    final isoDateRe = RegExp(r'(\d{4})-(\d{2})-(\d{2})');
    for (final match in isoDateRe.allMatches(text)) {
      final key = match.group(0)!;
      if (seen.contains(key)) continue;
      seen.add(key);

      final date = _tryDate(
        int.parse(match.group(1)!),
        int.parse(match.group(2)!),
        int.parse(match.group(3)!),
      );
      if (date != null) {
        dates.add(ExtractedDate(
          date: date,
          original: key,
          position: match.start,
        ));
      }
    }

    // Written dates: "March 15, 2026" / "15 March 2026" / "Mar 15, 2026"
    final writtenDateRe = RegExp(
      r'(\d{1,2})(?:st|nd|rd|th)?\s+((?:jan|feb|mar|apr|may|jun|jul|aug|sep|sept|oct|nov|dec)\w*)\s*,?\s*(\d{4})|'
      r'((?:jan|feb|mar|apr|may|jun|jul|aug|sep|sept|oct|nov|dec)\w*)\s+(\d{1,2})(?:st|nd|rd|th)?\s*,?\s*(\d{4})',
      caseSensitive: false,
    );
    for (final match in writtenDateRe.allMatches(text)) {
      final key = match.group(0)!;
      if (seen.contains(key)) continue;
      seen.add(key);

      int day, year;
      int? month;

      if (match.group(1) != null) {
        // "15 March 2026"
        day = int.parse(match.group(1)!);
        month = _monthNames[match.group(2)!.toLowerCase()];
        year = int.parse(match.group(3)!);
      } else {
        // "March 15, 2026"
        month = _monthNames[match.group(4)!.toLowerCase()];
        day = int.parse(match.group(5)!);
        year = int.parse(match.group(6)!);
      }

      if (month != null) {
        final date = _tryDate(year, month, day);
        if (date != null) {
          dates.add(ExtractedDate(
            date: date,
            original: key,
            position: match.start,
          ));
        }
      }
    }

    return dates;
  }

  // ─── DEADLINE EXTRACTION ───────────────────────────────────────

  List<ExtractedDeadline> _extractDeadlines(String text) {
    final deadlines = <ExtractedDeadline>[];
    final dates = _extractDates(text);
    if (dates.isEmpty) return deadlines;

    final lower = text.toLowerCase();

    for (final date in dates) {
      // Look for expiry/deadline context within 100 chars before the date
      final searchStart = (date.position - 100).clamp(0, text.length);
      final contextBefore =
          lower.substring(searchStart, date.position).trim();

      // Also check after the date
      final searchEnd = (date.position + date.original.length + 100)
          .clamp(0, text.length);
      final contextAfter = lower
          .substring(date.position + date.original.length, searchEnd)
          .trim();

      final fullContext = '$contextBefore $contextAfter';

      // Check for expiry keywords
      if (_expiryKeywords.hasMatch(fullContext)) {
        final type = _classifyDeadlineType(fullContext);
        final label = _generateDeadlineLabel(fullContext, type);
        deadlines.add(ExtractedDeadline(
          date: date.date,
          type: type,
          label: label,
          contextPhrase: _extractContextPhrase(text, date.position),
          original: date.original,
        ));
        continue;
      }

      // Check for appointment keywords
      if (_appointmentKeywords.hasMatch(fullContext)) {
        deadlines.add(ExtractedDeadline(
          date: date.date,
          type: DeadlineType.appointment,
          label: _generateDeadlineLabel(fullContext, DeadlineType.appointment),
          contextPhrase: _extractContextPhrase(text, date.position),
          original: date.original,
        ));
      }
    }

    return deadlines;
  }

  DeadlineType _classifyDeadlineType(String context) {
    if (RegExp(r'warranty', caseSensitive: false).hasMatch(context)) {
      return DeadlineType.warranty;
    }
    if (RegExp(r'renew|renewal', caseSensitive: false).hasMatch(context)) {
      return DeadlineType.renewal;
    }
    if (RegExp(r'due|deadline|maturity', caseSensitive: false)
        .hasMatch(context)) {
      return DeadlineType.dueDate;
    }
    if (RegExp(r'appointment|appt|meeting|interview|check.?in|check.?out',
            caseSensitive: false)
        .hasMatch(context)) {
      return DeadlineType.appointment;
    }
    if (RegExp(r'event|concert|conference|ticket', caseSensitive: false)
        .hasMatch(context)) {
      return DeadlineType.event;
    }
    return DeadlineType.expiry;
  }

  String _generateDeadlineLabel(String context, DeadlineType type) {
    // Try to extract meaningful label from context
    final patterns = [
      RegExp(r'(\w+\s+(?:insurance|policy|warranty|subscription|membership|licence|license|permit|registration|certificate|passport|visa|card))',
          caseSensitive: false),
      RegExp(r'(car|home|health|life|travel|pet)\s+insurance',
          caseSensitive: false),
      RegExp(r'(driver.?s?\s+licen[cs]e|passport|visa|medicare)',
          caseSensitive: false),
    ];

    for (final pattern in patterns) {
      final match = pattern.firstMatch(context);
      if (match != null) {
        final label = match.group(0)!;
        return '${label[0].toUpperCase()}${label.substring(1)}';
      }
    }

    return type.name[0].toUpperCase() + type.name.substring(1);
  }

  String _extractContextPhrase(String text, int position) {
    final start = (position - 40).clamp(0, text.length);
    final end = (position + 40).clamp(0, text.length);
    var phrase = text.substring(start, end).trim();
    if (start > 0) phrase = '...$phrase';
    if (end < text.length) phrase = '$phrase...';
    return phrase;
  }

  // ─── AMOUNT EXTRACTION ─────────────────────────────────────────

  List<ExtractedAmount> _extractAmounts(String text) {
    final amounts = <ExtractedAmount>[];
    final seen = <String>{};

    // Currency symbol then number: $42.50, £100, €50.00, R150
    final currencyRe = RegExp(
      r'([\$£€R])\s*([\d,]+\.?\d*)',
    );
    for (final match in currencyRe.allMatches(text)) {
      final key = match.group(0)!;
      if (seen.contains(key)) continue;
      seen.add(key);

      final currency = match.group(1)!;
      final valueStr = match.group(2)!.replaceAll(',', '');
      final value = double.tryParse(valueStr);
      if (value == null || value <= 0) continue;

      // Look for context (Total, Subtotal, etc.)
      final contextStart = (match.start - 30).clamp(0, text.length);
      final contextText = text.substring(contextStart, match.start).toLowerCase();
      String? amountContext;
      for (final label in [
        'total', 'subtotal', 'sub total', 'grand total', 'amount due',
        'balance', 'payment', 'price', 'cost', 'fee', 'charge',
        'tax', 'gst', 'vat', 'tip', 'gratuity', 'discount',
      ]) {
        if (contextText.contains(label)) {
          amountContext = label[0].toUpperCase() + label.substring(1);
          break;
        }
      }

      amounts.add(ExtractedAmount(
        value: value,
        currency: currency,
        formatted: key.trim(),
        context: amountContext,
      ));
    }

    // Number then currency code: 42.50 USD, 100 GBP, 50 EUR
    final codeCurrencyRe = RegExp(
      r'([\d,]+\.?\d*)\s*(USD|GBP|EUR|AUD|NZD|CAD|ZAR)\b',
      caseSensitive: false,
    );
    for (final match in codeCurrencyRe.allMatches(text)) {
      final key = match.group(0)!;
      if (seen.contains(key)) continue;
      seen.add(key);

      final valueStr = match.group(1)!.replaceAll(',', '');
      final value = double.tryParse(valueStr);
      if (value == null || value <= 0) continue;

      final currencyCode = match.group(2)!.toUpperCase();
      final symbol = switch (currencyCode) {
        'USD' => '\$',
        'GBP' => '£',
        'EUR' => '€',
        'ZAR' => 'R',
        _ => currencyCode,
      };

      amounts.add(ExtractedAmount(
        value: value,
        currency: symbol,
        formatted: '$symbol${value.toStringAsFixed(2)}',
      ));
    }

    return amounts;
  }

  // ─── PHONE EXTRACTION ──────────────────────────────────────────

  List<String> _extractPhones(String text) {
    final phones = <String>{};

    // International format: +61 4XX XXX XXX, +1 (234) 567-8901
    final phoneRe = RegExp(
      r'(?:\+?\d{1,3}[\s\-.]?)?\(?\d{2,4}\)?[\s\-.]?\d{3,4}[\s\-.]?\d{3,4}',
    );
    for (final match in phoneRe.allMatches(text)) {
      final phone = match.group(0)!.trim();
      // Must have at least 8 digits
      final digits = phone.replaceAll(RegExp(r'\D'), '');
      if (digits.length >= 8 && digits.length <= 15) {
        phones.add(phone);
      }
    }

    return phones.toList();
  }

  // ─── EMAIL EXTRACTION ──────────────────────────────────────────

  List<String> _extractEmails(String text) {
    final emailRe = RegExp(
      r'[a-zA-Z0-9._%+\-]+@[a-zA-Z0-9.\-]+\.[a-zA-Z]{2,}',
    );
    return emailRe
        .allMatches(text)
        .map((m) => m.group(0)!)
        .toSet()
        .toList();
  }

  // ─── URL EXTRACTION ────────────────────────────────────────────

  List<String> _extractUrls(String text) {
    final urlRe = RegExp(
      r'https?://[^\s<>")\]]+',
    );
    return urlRe.allMatches(text).map((m) => m.group(0)!).toSet().toList();
  }

  // ─── REFERENCE/BOOKING NUMBER EXTRACTION ───────────────────────

  List<ExtractedReference> _extractReferences(String text) {
    final refs = <ExtractedReference>[];
    final seen = <String>{};

    for (final entry in _referenceKeywords.entries) {
      for (final match in entry.value.allMatches(text)) {
        // Look for the reference number after the keyword
        final afterKeyword = text.substring(
          match.end,
          (match.end + 30).clamp(0, text.length),
        );

        final refMatch =
            RegExp(r'([A-Z0-9][A-Z0-9\-]{3,20})', caseSensitive: false)
                .firstMatch(afterKeyword);
        if (refMatch != null) {
          final value = refMatch.group(1)!;
          if (seen.contains(value)) continue;
          seen.add(value);

          refs.add(ExtractedReference(
            value: value,
            type: entry.key,
            original: '${match.group(0)}$value',
          ));
        }
      }
    }

    return refs;
  }

  // ─── NAME EXTRACTION ──────────────────────────────────────────

  List<String> _extractNames(String text) {
    final names = <String>{};

    // Titles followed by names
    final titleRe = RegExp(
      r'(?:Dr\.?|Mr\.?|Mrs\.?|Ms\.?|Prof\.?|Professor)\s+([A-Z][a-z]+(?:\s+[A-Z][a-z]+)*)',
    );
    for (final match in titleRe.allMatches(text)) {
      final fullMatch = match.group(0)!.trim();
      names.add(fullMatch);
    }

    // "Name:" or "Patient:" or "Client:" patterns
    final labelRe = RegExp(
      r'(?:(?:name|patient|client|customer|doctor|contact|from|to|attn|attention)\s*:\s*)([A-Z][a-z]+(?:\s+[A-Z][a-z]+)+)',
      caseSensitive: false,
    );
    for (final match in labelRe.allMatches(text)) {
      names.add(match.group(1)!.trim());
    }

    return names.toList();
  }

  // ─── ADDRESS EXTRACTION ────────────────────────────────────────

  List<String> _extractAddresses(String text) {
    final addresses = <String>{};

    // Street address pattern: number + street name + type
    final streetRe = RegExp(
      r'\d{1,5}\s+[A-Z][a-zA-Z\s]+(?:Street|St|Road|Rd|Avenue|Ave|Drive|Dr|Boulevard|Blvd|Lane|Ln|Court|Ct|Place|Pl|Way|Crescent|Cres|Terrace|Tce|Close|Circuit|Cct|Parade|Pde)\.?(?:\s*,?\s*[A-Z][a-zA-Z\s]+)?(?:\s*,?\s*\d{4,5})?',
      caseSensitive: false,
    );
    for (final match in streetRe.allMatches(text)) {
      addresses.add(match.group(0)!.trim());
    }

    return addresses.toList();
  }

  // ─── HELPERS ───────────────────────────────────────────────────

  DateTime? _tryDate(int year, int month, int day) {
    if (month < 1 || month > 12 || day < 1 || day > 31) return null;
    if (year < 2000 || year > 2100) return null;
    try {
      final date = DateTime(year, month, day);
      // Validate the date is valid (handles Feb 30, etc.)
      if (date.month != month || date.day != day) return null;
      return date;
    } catch (_) {
      return null;
    }
  }
}
