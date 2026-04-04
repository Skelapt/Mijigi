import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

class PdfService {
  /// Create a PDF from a list of image file paths.
  /// Returns the path to the created PDF file.
  Future<String?> createPdfFromImages({
    required List<String> imagePaths,
    required String fileName,
    List<int>? rotations, // degrees per page: 0, 90, 180, 270
  }) async {
    try {
      final pdf = pw.Document();

      for (var i = 0; i < imagePaths.length; i++) {
        final file = File(imagePaths[i]);
        if (!await file.exists()) continue;

        final bytes = await file.readAsBytes();
        final image = pw.MemoryImage(bytes);
        final rotation = rotations != null && i < rotations.length
            ? rotations[i]
            : 0;

        pdf.addPage(
          pw.Page(
            pageFormat: PdfPageFormat.a4,
            margin: pw.EdgeInsets.zero,
            build: (context) {
              pw.Widget imageWidget = pw.Center(
                child: pw.Image(image, fit: pw.BoxFit.contain),
              );

              if (rotation != 0) {
                imageWidget = pw.Transform.rotateBox(
                  angle: rotation * 3.14159265 / 180,
                  child: imageWidget,
                );
              }

              return imageWidget;
            },
          ),
        );
      }

      final dir = await getApplicationDocumentsDirectory();
      final sanitized = fileName
          .replaceAll(RegExp(r'[^\w\s-]'), '')
          .replaceAll(RegExp(r'\s+'), '_');
      final path =
          '${dir.path}/${sanitized}_${DateTime.now().millisecondsSinceEpoch}.pdf';

      final file = File(path);
      final bytes = await pdf.save();
      await file.writeAsBytes(bytes);

      debugPrint('[Picxtract] PDF created: $path (${imagePaths.length} pages)');
      return path;
    } catch (e) {
      debugPrint('[Picxtract] PDF creation failed: $e');
      return null;
    }
  }

  /// Get the number of pages in a PDF file.
  Future<int> getPageCount(String pdfPath) async {
    try {
      final file = File(pdfPath);
      final bytes = await file.readAsBytes();
      // Count page objects in PDF - simple approach
      final content = String.fromCharCodes(bytes);
      return RegExp(r'/Type\s*/Page[^s]').allMatches(content).length;
    } catch (_) {
      return 0;
    }
  }
}
