import 'package:flutter/foundation.dart';
import 'dart:io';

/// Photo Gallery Service - Manages multi-photo capture sessions
class PhotoGalleryService extends ChangeNotifier {
  final List<CapturedPhoto> _photos = [];
  bool _isSessionActive = false;
  String? _sessionQuestion;
  DateTime? _sessionStartTime;

  List<CapturedPhoto> get photos => List.unmodifiable(_photos);
  bool get isSessionActive => _isSessionActive;
  int get photoCount => _photos.length;
  String? get sessionQuestion => _sessionQuestion;

  /// Start a new capture session
  void startSession({String? question}) {
    _isSessionActive = true;
    _sessionQuestion = question;
    _sessionStartTime = DateTime.now();
    _photos.clear();
    notifyListeners();
    debugPrint('📸 Started multi-photo session');
  }

  /// Add a photo to the current session
  void addPhoto(String imagePath, {String? annotation}) {
    if (!_isSessionActive) {
      debugPrint('⚠️ No active session');
      return;
    }

    final photo = CapturedPhoto(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      imagePath: imagePath,
      annotation: annotation,
      captureTime: DateTime.now(),
      sequenceNumber: _photos.length + 1,
    );

    _photos.add(photo);
    notifyListeners();
    debugPrint('📸 Added photo ${photo.sequenceNumber} to session');
  }

  /// Remove a photo from session
  void removePhoto(String photoId) {
    _photos.removeWhere((p) => p.id == photoId);
    _resequencePhotos();
    notifyListeners();
  }

  /// Resequence photos after deletion
  void _resequencePhotos() {
    for (int i = 0; i < _photos.length; i++) {
      _photos[i].sequenceNumber = i + 1;
    }
  }

  /// Update session question
  void updateSessionQuestion(String question) {
    _sessionQuestion = question;
    notifyListeners();
  }

  /// End session and prepare for submission
  MultiPhotoSession? endSession() {
    if (!_isSessionActive || _photos.isEmpty) {
      return null;
    }

    final session = MultiPhotoSession(
      photos: List.from(_photos),
      question: _sessionQuestion ?? 'Explain this code problem',
      startTime: _sessionStartTime!,
      endTime: DateTime.now(),
    );

    // Clear session
    _isSessionActive = false;
    _photos.clear();
    _sessionQuestion = null;
    _sessionStartTime = null;

    notifyListeners();
    debugPrint('✅ Ended session with ${session.photos.length} photos');

    return session;
  }

  /// Cancel session without saving
  void cancelSession() {
    _photos.clear();
    _isSessionActive = false;
    _sessionQuestion = null;
    _sessionStartTime = null;
    notifyListeners();
    debugPrint('❌ Session cancelled');
  }

  /// Get session statistics
  Map<String, dynamic> getSessionStats() {
    return {
      'active': _isSessionActive,
      'photo_count': _photos.length,
      'has_question': _sessionQuestion != null,
      'duration_seconds': _sessionStartTime != null
          ? DateTime.now().difference(_sessionStartTime!).inSeconds
          : 0,
    };
  }
}

/// Captured Photo Model
class CapturedPhoto {
  final String id;
  final String imagePath;
  String? annotation;
  final DateTime captureTime;
  int sequenceNumber;

  CapturedPhoto({
    required this.id,
    required this.imagePath,
    this.annotation,
    required this.captureTime,
    required this.sequenceNumber,
  });

  /// Get file
  File get file => File(imagePath);

  /// Get file size
  Future<int> get fileSize async {
    try {
      return await file.length();
    } catch (e) {
      return 0;
    }
  }

  /// Check if file exists
  Future<bool> exists() async {
    return await file.exists();
  }
}

/// Multi-Photo Session (ready for LLM)
class MultiPhotoSession {
  final List<CapturedPhoto> photos;
  final String question;
  final DateTime startTime;
  final DateTime endTime;

  MultiPhotoSession({
    required this.photos,
    required this.question,
    required this.startTime,
    required this.endTime,
  });

  Duration get duration => endTime.difference(startTime);
  int get photoCount => photos.length;

  /// Get all image paths in sequence
  List<String> get imagePaths =>
      photos.map((p) => p.imagePath).toList();

  /// Get session summary
  String get summary =>
      'Captured ${photos.length} photos over ${duration.inSeconds}s';
}

/// Capture Mode Type
enum CaptureMode {
  single,           // Single photo mode
  multiPhoto,       // Multi-photo session mode
  continuous,       // Continuous capture mode
}
