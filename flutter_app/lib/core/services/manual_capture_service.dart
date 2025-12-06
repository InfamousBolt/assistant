import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';

/// Question Buffer - Stores recent questions for manual capture
class QuestionBuffer extends ChangeNotifier {
  final List<DetectedQuestion> _questions = [];
  static const maxBufferSize = 5;
  static const maxAge = Duration(seconds: 15);

  List<DetectedQuestion> get questions => List.unmodifiable(_questions);

  /// Add a detected question to buffer
  void addQuestion(String text, DateTime timestamp) {
    _questions.add(DetectedQuestion(
      text: text,
      timestamp: timestamp,
      id: DateTime.now().millisecondsSinceEpoch.toString(),
    ));

    // Remove old questions
    _cleanOldQuestions();

    // Limit buffer size
    if (_questions.length > maxBufferSize) {
      _questions.removeAt(0);
    }

    notifyListeners();
    debugPrint('📝 Question buffered: $text (${_questions.length} in buffer)');
  }

  /// Get the most recent question
  DetectedQuestion? getLatestQuestion() {
    _cleanOldQuestions();
    return _questions.isNotEmpty ? _questions.last : null;
  }

  /// Get all valid questions
  List<DetectedQuestion> getValidQuestions() {
    _cleanOldQuestions();
    return List.from(_questions);
  }

  /// Remove questions older than maxAge
  void _cleanOldQuestions() {
    final now = DateTime.now();
    _questions.removeWhere((q) =>
      now.difference(q.timestamp) > maxAge
    );
  }

  /// Clear a specific question (after answering)
  void removeQuestion(String id) {
    _questions.removeWhere((q) => q.id == id);
    notifyListeners();
  }

  /// Clear all questions
  void clear() {
    _questions.clear();
    notifyListeners();
  }

  /// Get count of pending questions
  int get pendingCount {
    _cleanOldQuestions();
    return _questions.length;
  }
}

/// Detected Question Model
class DetectedQuestion {
  final String id;
  final String text;
  final DateTime timestamp;
  bool answered;

  DetectedQuestion({
    required this.id,
    required this.text,
    required this.timestamp,
    this.answered = false,
  });

  String get timeAgo {
    final diff = DateTime.now().difference(timestamp);
    if (diff.inSeconds < 60) return '${diff.inSeconds}s ago';
    return '${diff.inMinutes}m ago';
  }
}

/// Manual Capture Service - Handles tap-based photo capture
class ManualCaptureService extends ChangeNotifier {
  CameraController? _cameraController;
  final QuestionBuffer questionBuffer;

  int _singleTapCount = 0;
  int _doubleTapCount = 0;
  String? _lastCapturedImagePath;

  ManualCaptureService({required this.questionBuffer});

  int get singleTapCount => _singleTapCount;
  int get doubleTapCount => _doubleTapCount;
  String? get lastCapturedImage => _lastCapturedImagePath;

  void setCameraController(CameraController controller) {
    _cameraController = controller;
  }

  /// Single tap - Just capture photo (no question)
  Future<CaptureResult?> handleSingleTap() async {
    if (_cameraController == null || !_cameraController!.value.isInitialized) {
      debugPrint('⚠️ Camera not initialized');
      return null;
    }

    try {
      debugPrint('📸 Single tap - Capturing photo only');

      final image = await _cameraController!.takePicture();
      _lastCapturedImagePath = image.path;
      _singleTapCount++;

      notifyListeners();

      return CaptureResult(
        imagePath: image.path,
        question: null,
        captureType: CaptureType.photoOnly,
      );
    } catch (e) {
      debugPrint('Error capturing photo: $e');
      return null;
    }
  }

  /// Double tap - Capture photo + use recent question
  Future<CaptureResult?> handleDoubleTap() async {
    if (_cameraController == null || !_cameraController!.value.isInitialized) {
      debugPrint('⚠️ Camera not initialized');
      return null;
    }

    try {
      debugPrint('📸📸 Double tap - Capturing photo with question');

      // Get latest question
      final question = questionBuffer.getLatestQuestion();

      if (question == null) {
        debugPrint('⚠️ No recent question in buffer');
        // Fall back to single tap behavior
        return await handleSingleTap();
      }

      // Capture photo
      final image = await _cameraController!.takePicture();
      _lastCapturedImagePath = image.path;
      _doubleTapCount++;

      // Remove question from buffer
      questionBuffer.removeQuestion(question.id);

      notifyListeners();

      return CaptureResult(
        imagePath: image.path,
        question: question.text,
        captureType: CaptureType.photoWithQuestion,
        questionId: question.id,
      );
    } catch (e) {
      debugPrint('Error capturing photo: $e');
      return null;
    }
  }

  /// Get capture statistics
  Map<String, dynamic> getStats() {
    return {
      'single_taps': _singleTapCount,
      'double_taps': _doubleTapCount,
      'total_captures': _singleTapCount + _doubleTapCount,
      'pending_questions': questionBuffer.pendingCount,
      'last_image': _lastCapturedImagePath,
    };
  }
}

/// Capture Result
class CaptureResult {
  final String imagePath;
  final String? question;
  final CaptureType captureType;
  final String? questionId;

  CaptureResult({
    required this.imagePath,
    this.question,
    required this.captureType,
    this.questionId,
  });

  /// Check if this capture should be sent to LLM
  bool get shouldProcessWithLLM => question != null;
}

/// Capture Type
enum CaptureType {
  photoOnly,           // Single tap - just save photo
  photoWithQuestion,   // Double tap - answer question
}
