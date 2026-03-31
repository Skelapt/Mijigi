import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:google_mlkit_image_labeling/google_mlkit_image_labeling.dart';

class LabelingService {
  ImageLabeler? _labeler;

  ImageLabeler get labeler {
    _labeler ??= ImageLabeler(options: ImageLabelerOptions(confidenceThreshold: 0.5));
    return _labeler!;
  }

  /// Label an image - returns list of label strings (e.g. "dog", "food", "car")
  Future<List<String>> labelImage(String filePath) async {
    try {
      final file = File(filePath);
      if (!await file.exists()) return [];

      final inputImage = InputImage.fromFilePath(filePath);
      final imageLabels = await labeler.processImage(inputImage);

      return imageLabels
          .map((label) => label.label.toLowerCase())
          .toList();
    } catch (e) {
      debugPrint('Labeling failed: $e');
      return [];
    }
  }

  void dispose() {
    _labeler?.close();
  }
}
