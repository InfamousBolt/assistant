import 'package:flutter/foundation.dart';
import 'package:record/record.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:permission_handler/permission_handler.dart';

/// Audio Service - Handles audio recording and speech-to-text
class AudioService extends ChangeNotifier {
  final _audioRecorder = AudioRecorder();
  final _speechToText = stt.SpeechToText();

  bool _isRecording = false;
  bool _isListening = false;
  bool _isInitialized = false;
  String _lastTranscript = '';
  int _speechDetectedCount = 0;

  bool get isRecording => _isRecording;
  bool get isListening => _isListening;
  bool get isInitialized => _isInitialized;
  String get lastTranscript => _lastTranscript;
  int get speechCount => _speechDetectedCount;

  /// Initialize audio service
  Future<bool> initialize() async {
    try {
      // Request microphone permission
      final status = await Permission.microphone.request();
      if (!status.isGranted) {
        debugPrint('Microphone permission denied');
        return false;
      }

      // Initialize speech-to-text
      _isInitialized = await _speechToText.initialize(
        onError: (error) => debugPrint('STT Error: $error'),
        onStatus: (status) => debugPrint('STT Status: $status'),
      );

      if (_isInitialized) {
        debugPrint('Audio service initialized successfully');
      }

      notifyListeners();
      return _isInitialized;
    } catch (e) {
      debugPrint('Error initializing audio: $e');
      return false;
    }
  }

  /// Start listening for speech
  Future<void> startListening({
    required Function(String) onResult,
    Function(bool)? onDetectQuestion,
  }) async {
    if (!_isInitialized) {
      debugPrint('Audio service not initialized');
      return;
    }

    _isListening = true;
    notifyListeners();

    await _speechToText.listen(
      onResult: (result) {
        _lastTranscript = result.recognizedWords;
        _speechDetectedCount++;

        onResult(_lastTranscript);

        // Detect if it's a question
        if (onDetectQuestion != null) {
          final isQuestion = _isQuestion(_lastTranscript);
          if (isQuestion) {
            onDetectQuestion(true);
          }
        }

        notifyListeners();
      },
      listenFor: const Duration(seconds: 30),
      pauseFor: const Duration(seconds: 3),
      partialResults: true,
      cancelOnError: true,
      listenMode: stt.ListenMode.dictation,
    );
  }

  /// Stop listening
  Future<void> stopListening() async {
    if (_isListening) {
      await _speechToText.stop();
      _isListening = false;
      notifyListeners();
    }
  }

  /// Start recording audio to file
  Future<void> startRecording(String path) async {
    if (await _audioRecorder.hasPermission()) {
      await _audioRecorder.start(
        const RecordConfig(
          encoder: AudioEncoder.aacLc,
          sampleRate: 16000,
          bitRate: 128000,
        ),
        path: path,
      );
      _isRecording = true;
      notifyListeners();
    }
  }

  /// Stop recording
  Future<String?> stopRecording() async {
    if (_isRecording) {
      final path = await _audioRecorder.stop();
      _isRecording = false;
      notifyListeners();
      return path;
    }
    return null;
  }

  /// Detect if text is a question
  bool _isQuestion(String text) {
    final lowerText = text.toLowerCase().trim();

    // Check for question mark
    if (lowerText.endsWith('?')) return true;

    // Check for question words
    final questionWords = [
      'what', 'who', 'where', 'when', 'why', 'how',
      'can', 'could', 'would', 'should', 'is', 'are',
      'do', 'does', 'did',
    ];

    for (final word in questionWords) {
      if (lowerText.startsWith(word)) return true;
    }

    return false;
  }

  /// Check if speaker is the user (simplified)
  bool isUserSpeaking() {
    // In production, implement actual speaker identification
    // using voice embeddings (ECAPA-TDNN)
    return false; // For now, assume all speech is from others
  }

  @override
  void dispose() {
    _audioRecorder.dispose();
    super.dispose();
  }
}
