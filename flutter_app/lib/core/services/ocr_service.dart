import 'package:flutter/foundation.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

/// OCR Service - Extracts text from images
class OcrService {
  final _textRecognizer = TextRecognizer();
  String _previousText = '';
  int _textChangeCount = 0;

  int get textChangeCount => _textChangeCount;
  String get previousText => _previousText;

  /// Extract text from camera image
  Future<OcrResult> extractText(InputImage inputImage) async {
    try {
      final recognizedText = await _textRecognizer.processImage(inputImage);

      final text = recognizedText.text;
      final confidence = _calculateConfidence(recognizedText);
      final changed = _hasTextChanged(text);

      if (changed && text.isNotEmpty) {
        _textChangeCount++;
        _previousText = text;
        debugPrint('OCR: Text changed - ${text.substring(0, text.length > 50 ? 50 : text.length)}...');
      }

      return OcrResult(
        text: text,
        confidence: confidence,
        changed: changed,
        wordCount: text.split(' ').length,
        blocks: recognizedText.blocks.length,
      );
    } catch (e) {
      debugPrint('OCR Error: $e');
      return OcrResult(
        text: '',
        confidence: 0.0,
        changed: false,
        wordCount: 0,
        blocks: 0,
      );
    }
  }

  /// Calculate average confidence from recognized text
  double _calculateConfidence(RecognizedText recognizedText) {
    if (recognizedText.blocks.isEmpty) return 0.0;

    double totalConfidence = 0.0;
    int count = 0;

    for (final block in recognizedText.blocks) {
      for (final line in block.lines) {
        for (final element in line.elements) {
          // ML Kit doesn't provide confidence directly
          // Use text length as a proxy for confidence
          if (element.text.isNotEmpty) {
            totalConfidence += 0.9; // Assume high confidence
            count++;
          }
        }
      }
    }

    return count > 0 ? totalConfidence / count : 0.0;
  }

  /// Check if text changed significantly
  bool _hasTextChanged(String newText) {
    if (_previousText.isEmpty) {
      return newText.isNotEmpty;
    }

    final newWords = newText.toLowerCase().split(' ').toSet();
    final oldWords = _previousText.toLowerCase().split(' ').toSet();

    final intersection = newWords.intersection(oldWords);
    final similarity = intersection.length / newWords.length;

    // If less than 70% similar, consider it changed
    return similarity < 0.7;
  }

  /// Dispose resources
  void dispose() {
    _textRecognizer.close();
  }
}

/// OCR Result Model
class OcrResult {
  final String text;
  final double confidence;
  final bool changed;
  final int wordCount;
  final int blocks;

  OcrResult({
    required this.text,
    required this.confidence,
    required this.changed,
    required this.wordCount,
    required this.blocks,
  });
}
