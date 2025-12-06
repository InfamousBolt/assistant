import 'package:flutter/foundation.dart';
import 'package:camera/camera.dart';
import 'dart:collection';

/// Smart Capture Service - Intelligently captures frames based on events
class SmartCaptureService extends ChangeNotifier {
  // Buffer to store recent frames
  final Queue<CameraImage> _frameBuffer = Queue();
  static const int maxBufferSize = 5; // Keep last 5 frames (~0.5 seconds at 10fps)

  CameraImage? _lastCapturedFrame;
  DateTime? _lastCaptureTime;
  int _manualCaptureCount = 0;
  int _autoCaptureCount = 0;

  CameraImage? get lastCapturedFrame => _lastCapturedFrame;
  int get manualCaptureCount => _manualCaptureCount;
  int get autoCaptureCount => _autoCaptureCount;

  /// Add frame to buffer (continuous background process)
  void bufferFrame(CameraImage frame) {
    _frameBuffer.add(frame);

    // Keep buffer size limited
    if (_frameBuffer.length > maxBufferSize) {
      _frameBuffer.removeFirst();
    }
  }

  /// Capture frame when question is detected (automatic)
  CameraImage? captureOnQuestion() {
    debugPrint('📸 Auto-capture triggered by question');

    // Get most recent frame from buffer
    if (_frameBuffer.isNotEmpty) {
      _lastCapturedFrame = _frameBuffer.last;
      _lastCaptureTime = DateTime.now();
      _autoCaptureCount++;
      notifyListeners();
      return _lastCapturedFrame;
    }

    debugPrint('⚠️ No frames in buffer');
    return null;
  }

  /// Manual capture by user (tap screen/button)
  CameraImage? captureManually() {
    debugPrint('📸 Manual capture by user');

    if (_frameBuffer.isNotEmpty) {
      _lastCapturedFrame = _frameBuffer.last;
      _lastCaptureTime = DateTime.now();
      _manualCaptureCount++;
      notifyListeners();
      return _lastCapturedFrame;
    }

    return null;
  }

  /// Check if enough time passed since last capture (anti-spam)
  bool canCapture({Duration minInterval = const Duration(seconds: 2)}) {
    if (_lastCaptureTime == null) return true;

    final elapsed = DateTime.now().difference(_lastCaptureTime!);
    return elapsed >= minInterval;
  }

  /// Get capture statistics
  Map<String, dynamic> getStats() {
    return {
      'buffer_size': _frameBuffer.length,
      'manual_captures': _manualCaptureCount,
      'auto_captures': _autoCaptureCount,
      'total_captures': _manualCaptureCount + _autoCaptureCount,
      'last_capture': _lastCaptureTime?.toString() ?? 'Never',
    };
  }

  /// Clear buffer and reset
  void clear() {
    _frameBuffer.clear();
    _lastCapturedFrame = null;
    notifyListeners();
  }
}
