import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:camera/camera.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import '../../../core/services/camera_service.dart';
import '../../../core/services/ocr_service.dart';
import '../../../core/services/memory_service.dart';
import '../widgets/camera_overlay.dart';

class CameraScreen extends StatefulWidget {
  const CameraScreen({super.key});

  @override
  State<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen> {
  final OcrService _ocrService = OcrService();
  bool _isProcessing = false;
  String _lastOcrText = '';

  @override
  void initState() {
    super.initState();
    _initializeCamera();
  }

  Future<void> _initializeCamera() async {
    final cameraService = context.read<CameraService>();
    final success = await cameraService.initialize();

    if (success && mounted) {
      cameraService.startImageStream(_onImage);
    }
  }

  void _onImage(CameraImage image, bool isKeyframe) {
    if (!isKeyframe || _isProcessing) return;

    _processKeyframe(image);
  }

  Future<void> _processKeyframe(CameraImage image) async {
    _isProcessing = true;

    try {
      // Convert CameraImage to InputImage for ML Kit
      final inputImage = _convertToInputImage(image);
      if (inputImage == null) return;

      // Run OCR
      final ocrResult = await _ocrService.extractText(inputImage);

      if (ocrResult.changed && ocrResult.text.isNotEmpty) {
        _lastOcrText = ocrResult.text;

        // Add to memory
        if (mounted) {
          final memoryService = context.read<MemoryService>();
          memoryService.addOcrEvent(
            ocrResult.text,
            confidence: ocrResult.confidence,
            wordCount: ocrResult.wordCount,
          );
          memoryService.addKeyframe({
            'ocrText': ocrResult.text,
            'confidence': ocrResult.confidence,
          });
        }
      }
    } catch (e) {
      debugPrint('Error processing keyframe: $e');
    } finally {
      _isProcessing = false;
    }
  }

  InputImage? _convertToInputImage(CameraImage image) {
    // Implementation depends on platform
    // This is a simplified version
    return null; // TODO: Implement proper conversion
  }

  @override
  void dispose() {
    _ocrService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Consumer<CameraService>(
        builder: (context, cameraService, child) {
          if (!cameraService.isInitialized || cameraService.controller == null) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          return Stack(
            fit: StackFit.expand,
            children: [
              // Camera Preview
              CameraPreview(cameraService.controller!),

              // Overlay with stats and info
              CameraOverlay(
                frameCount: cameraService.frameCount,
                keyframeCount: cameraService.keyframeCount,
                lastOcrText: _lastOcrText,
              ),
            ],
          );
        },
      ),
    );
  }
}
