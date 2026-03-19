import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';

/// Extracts text from PDF files.
class PdfService {
  /// Extract all text from a PDF file.
  Future<String> extractText(String filePath) async {
    try {
      final bytes = await File(filePath).readAsBytes();
      return await compute(_extractFromBytes, bytes);
    } catch (e) {
      debugPrint('PDF extraction failed: $e');
      return '';
    }
  }

  /// Check if a file is a valid PDF by reading magic bytes.
  static bool isPdf(String filePath) {
    try {
      final file = File(filePath);
      if (!file.existsSync()) return false;
      final bytes = file.openSync().readSync(5);
      // PDF magic bytes: %PDF-
      return bytes.length >= 5 &&
          bytes[0] == 0x25 &&
          bytes[1] == 0x50 &&
          bytes[2] == 0x44 &&
          bytes[3] == 0x46 &&
          bytes[4] == 0x2D;
    } catch (_) {
      return false;
    }
  }

  /// Get PDF page count.
  Future<int> getPageCount(String filePath) async {
    try {
      final bytes = await File(filePath).readAsBytes();
      final document = PdfDocument(inputBytes: bytes);
      final count = document.pages.count;
      document.dispose();
      return count;
    } catch (_) {
      return 0;
    }
  }
}

/// Isolate function for PDF text extraction.
String _extractFromBytes(List<int> bytes) {
  try {
    final document = PdfDocument(inputBytes: bytes);
    final buffer = StringBuffer();

    for (int i = 0; i < document.pages.count; i++) {
      final text = PdfTextExtractor(document).extractText(startPageIndex: i);
      if (text.isNotEmpty) {
        buffer.writeln(text);
      }
    }

    document.dispose();
    return buffer.toString().trim();
  } catch (_) {
    return '';
  }
}
