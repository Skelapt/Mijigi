import 'dart:io';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

class OcrResult {
  final String fullText;
  final List<OcrBlock> blocks;

  OcrResult({required this.fullText, required this.blocks});

  bool get isEmpty => fullText.trim().isEmpty;
  bool get isNotEmpty => !isEmpty;
}

class OcrBlock {
  final String text;
  final List<String> lines;

  OcrBlock({required this.text, required this.lines});
}

class OcrService {
  final _recognizer = TextRecognizer(script: TextRecognitionScript.latin);

  Future<OcrResult> processImage(String imagePath) async {
    final inputImage = InputImage.fromFilePath(imagePath);
    final recognized = await _recognizer.processImage(inputImage);

    final blocks = recognized.blocks.map((block) {
      return OcrBlock(
        text: block.text,
        lines: block.lines.map((line) => line.text).toList(),
      );
    }).toList();

    return OcrResult(fullText: recognized.text, blocks: blocks);
  }

  Future<OcrResult> processFile(File file) async {
    return processImage(file.path);
  }

  void dispose() {
    _recognizer.close();
  }
}
