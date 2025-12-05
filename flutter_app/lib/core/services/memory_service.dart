import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import '../models/memory_chunk.dart';
import '../models/conversation_message.dart';
import '../config/app_config.dart';

/// Memory Service - Manages conversation memory and summaries
class MemoryService extends ChangeNotifier {
  final List<MemoryChunk> _memoryChunks = [];
  final List<MemoryChunk> _summaries = [];
  DateTime _lastSummaryTime = DateTime.now();
  final DateTime _sessionStartTime = DateTime.now();
  int _totalInteractions = 0;

  final _uuid = const Uuid();

  List<MemoryChunk> get memoryChunks => List.unmodifiable(_memoryChunks);
  List<MemoryChunk> get summaries => List.unmodifiable(_summaries);
  int get totalInteractions => _totalInteractions;
  Duration get sessionDuration => DateTime.now().difference(_sessionStartTime);

  /// Add a keyframe to memory
  void addKeyframe(Map<String, dynamic> frameData) {
    final chunk = MemoryChunk(
      id: _uuid.v4(),
      type: MemoryChunkType.keyframe,
      content: {
        'description': 'Visual keyframe captured',
        'ocrText': frameData['ocrText'] ?? '',
        'confidence': frameData['confidence'] ?? 0.0,
      },
    );

    _addChunk(chunk);
  }

  /// Add a question to memory
  void addQuestion(String question, {double? confidence}) {
    final chunk = MemoryChunk(
      id: _uuid.v4(),
      type: MemoryChunkType.question,
      content: {
        'text': question,
        'confidence': confidence ?? 1.0,
      },
    );

    _addChunk(chunk);
    _totalInteractions++;
  }

  /// Add an answer to memory
  void addAnswer(String answer, String question) {
    final chunk = MemoryChunk(
      id: _uuid.v4(),
      type: MemoryChunkType.answer,
      content: {
        'text': answer,
        'question': question,
      },
    );

    _addChunk(chunk);
  }

  /// Add OCR text detection to memory
  void addOcrEvent(String text, {double? confidence, int? wordCount}) {
    if (text.isEmpty) return;

    final chunk = MemoryChunk(
      id: _uuid.v4(),
      type: MemoryChunkType.ocr,
      content: {
        'text': text,
        'confidence': confidence ?? 0.0,
        'wordCount': wordCount ?? 0,
      },
    );

    _addChunk(chunk);
  }

  /// Add chunk to memory (with max limit)
  void _addChunk(MemoryChunk chunk) {
    _memoryChunks.add(chunk);

    // Keep only recent chunks
    if (_memoryChunks.length > AppConfig.maxMemoryChunks) {
      _memoryChunks.removeAt(0);
    }

    notifyListeners();
  }

  /// Check if it's time to create a summary
  bool shouldCreateSummary() {
    final elapsed = DateTime.now().difference(_lastSummaryTime);
    return elapsed.inSeconds >= AppConfig.summaryIntervalSeconds;
  }

  /// Create a summary of recent interactions
  Map<String, dynamic> createSummary() {
    final recentQuestions = <String>[];
    final recentOcr = <String>[];
    int recentKeyframes = 0;

    for (final chunk in _memoryChunks) {
      switch (chunk.type) {
        case MemoryChunkType.question:
          recentQuestions.add(chunk.content['text'] as String);
          break;
        case MemoryChunkType.ocr:
          recentOcr.add(chunk.content['text'] as String);
          break;
        case MemoryChunkType.keyframe:
          recentKeyframes++;
          break;
        default:
          break;
      }
    }

    final summary = {
      'timeframe': {
        'start': _lastSummaryTime.toIso8601String(),
        'end': DateTime.now().toIso8601String(),
        'duration_seconds': DateTime.now().difference(_lastSummaryTime).inSeconds,
      },
      'statistics': {
        'questions_asked': recentQuestions.length,
        'keyframes_captured': recentKeyframes,
        'ocr_events': recentOcr.length,
      },
      'questions': recentQuestions.take(5).toList(),
      'detected_text': recentOcr.toSet().take(3).toList(),
      'summary_text': _generateSummaryText(recentQuestions, recentOcr),
    };

    final summaryChunk = MemoryChunk(
      id: _uuid.v4(),
      type: MemoryChunkType.summary,
      content: summary,
    );

    _summaries.add(summaryChunk);
    _lastSummaryTime = DateTime.now();
    notifyListeners();

    debugPrint('Summary created: ${summary['summary_text']}');

    return summary;
  }

  /// Generate human-readable summary text
  String _generateSummaryText(List<String> questions, List<String> ocrTexts) {
    final parts = <String>[];

    if (questions.isNotEmpty) {
      parts.add('Received ${questions.length} questions about code and errors');
    }

    if (ocrTexts.isNotEmpty) {
      final uniqueTexts = ocrTexts.toSet();
      parts.add('Detected ${uniqueTexts.length} unique text segments on screen');
    }

    if (parts.isEmpty) {
      parts.add('Monitoring session with no significant activity');
    }

    return '${parts.join('. ')}.';
  }

  /// Get recent context for LLM
  List<Map<String, dynamic>> getRecentContext({int maxChunks = 10}) {
    return _memoryChunks
        .reversed
        .take(maxChunks)
        .map((chunk) => chunk.toJson())
        .toList()
        .reversed
        .toList();
  }

  /// Get latest summary
  Map<String, dynamic>? getLatestSummary() {
    if (_summaries.isEmpty) return null;
    return _summaries.last.toJson();
  }

  /// Convert memory chunks to conversation messages
  List<ConversationMessage> getConversationHistory() {
    final messages = <ConversationMessage>[];

    for (final chunk in _memoryChunks) {
      if (chunk.type == MemoryChunkType.question) {
        messages.add(ConversationMessage(
          id: chunk.id,
          text: chunk.content['text'] as String,
          role: MessageRole.user,
          timestamp: chunk.timestamp,
          confidence: chunk.content['confidence'] as double?,
        ));
      } else if (chunk.type == MemoryChunkType.answer) {
        messages.add(ConversationMessage(
          id: chunk.id,
          text: chunk.content['text'] as String,
          role: MessageRole.assistant,
          timestamp: chunk.timestamp,
        ));
      }
    }

    return messages;
  }

  /// Save memory to persistent storage
  Future<void> saveToStorage() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      final data = {
        'session_start': _sessionStartTime.toIso8601String(),
        'total_interactions': _totalInteractions,
        'memory_chunks': _memoryChunks.map((c) => c.toJson()).toList(),
        'summaries': _summaries.map((s) => s.toJson()).toList(),
      };

      await prefs.setString('memory_data', jsonEncode(data));
      debugPrint('Memory saved to storage');
    } catch (e) {
      debugPrint('Error saving memory: $e');
    }
  }

  /// Load memory from persistent storage
  Future<void> loadFromStorage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final dataString = prefs.getString('memory_data');

      if (dataString != null) {
        final data = jsonDecode(dataString) as Map<String, dynamic>;

        _totalInteractions = data['total_interactions'] as int;

        _memoryChunks.clear();
        for (final chunkData in data['memory_chunks'] as List) {
          _memoryChunks.add(MemoryChunk.fromJson(chunkData as Map<String, dynamic>));
        }

        _summaries.clear();
        for (final summaryData in data['summaries'] as List) {
          _summaries.add(MemoryChunk.fromJson(summaryData as Map<String, dynamic>));
        }

        notifyListeners();
        debugPrint('Memory loaded from storage');
      }
    } catch (e) {
      debugPrint('Error loading memory: $e');
    }
  }

  /// Clear all memory
  void clear() {
    _memoryChunks.clear();
    _summaries.clear();
    _totalInteractions = 0;
    _lastSummaryTime = DateTime.now();
    notifyListeners();
    debugPrint('Memory cleared');
  }
}
