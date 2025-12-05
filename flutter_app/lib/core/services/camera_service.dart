import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as img;
import '../config/app_config.dart';

/// Camera Service - Handles camera operations and keyframe detection
class CameraService extends ChangeNotifier {
  CameraController? _controller;
  bool _isInitialized = false;
  img.Image? _previousFrame;
  int _frameCount = 0;
  int _keyframeCount = 0;

  bool get isInitialized => _isInitialized;
  CameraController? get controller => _controller;
  int get frameCount => _frameCount;
  int get keyframeCount => _keyframeCount;
  double get keyframeRatio =>
      _frameCount > 0 ? _keyframeCount / _frameCount : 0.0;

  /// Initialize camera
  Future<bool> initialize() async {
    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) {
        debugPrint('No cameras available');
        return false;
      }

      // Use back camera by default
      final camera = cameras.firstWhere(
        (camera) => camera.lensDirection == CameraLensDirection.back,
        orElse: () => cameras.first,
      );

      _controller = CameraController(
        camera,
        ResolutionPreset.medium,
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.yuv420,
      );

      await _controller!.initialize();
      _isInitialized = true;
      notifyListeners();

      debugPrint('Camera initialized successfully');
      return true;
    } catch (e) {
      debugPrint('Error initializing camera: $e');
      return false;
    }
  }

  /// Start image stream for processing
  void startImageStream(Function(CameraImage, bool) onImage) {
    if (!_isInitialized || _controller == null) return;

    _controller!.startImageStream((image) {
      _frameCount++;

      // Convert CameraImage to processable format
      final isKeyframe = _detectKeyframe(image);

      if (isKeyframe) {
        _keyframeCount++;
      }

      onImage(image, isKeyframe);
    });
  }

  /// Stop image stream
  Future<void> stopImageStream() async {
    if (_controller != null && _isInitialized) {
      await _controller!.stopImageStream();
    }
  }

  /// Detect if current frame is a keyframe using SSIM
  bool _detectKeyframe(CameraImage image) {
    // For now, use a simple approach
    // In production, implement proper SSIM calculation

    // Simplified: detect keyframe every N frames or based on change
    if (_frameCount % 30 == 0) {
      return true;
    }

    return false;
  }

  /// Calculate structural similarity (simplified version)
  double _calculateSSIM(img.Image current, img.Image previous) {
    // Simplified SSIM calculation
    // In production, use proper SSIM algorithm

    if (current.width != previous.width ||
        current.height != previous.height) {
      return 0.0;
    }

    int diffPixels = 0;
    final totalPixels = current.width * current.height;

    for (int y = 0; y < current.height; y++) {
      for (int x = 0; x < current.width; x++) {
        final currentPixel = current.getPixel(x, y);
        final previousPixel = previous.getPixel(x, y);

        if (currentPixel != previousPixel) {
          diffPixels++;
        }
      }
    }

    return 1.0 - (diffPixels / totalPixels);
  }

  /// Dispose resources
  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }
}
