import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../config/app_config.dart';
import '../models/conversation_message.dart';

/// LLM Service - Handles communication with GPT API
class LlmService {
  final Dio _dio = Dio();
  int _totalCalls = 0;
  int _totalTokens = 0;

  int get totalCalls => _totalCalls;
  int get totalTokens => _totalTokens;

  /// Generate answer to a question
  Future<LlmResponse> generateAnswer({
    required String question,
    required List<ConversationMessage> context,
    String? ocrText,
    bool useMock = true,
  }) async {
    _totalCalls++;

    if (useMock || AppConfig.apiKey.isEmpty) {
      return _mockGenerateAnswer(question, context, ocrText);
    }

    try {
      final messages = _buildMessages(question, context, ocrText);

      final response = await _dio.post(
        '${AppConfig.apiBaseUrl}/chat/completions',
        options: Options(
          headers: {
            'Authorization': 'Bearer ${AppConfig.apiKey}',
            'Content-Type': 'application/json',
          },
        ),
        data: {
          'model': AppConfig.llmModel,
          'messages': messages,
          'max_tokens': AppConfig.llmMaxTokens,
          'temperature': AppConfig.llmTemperature,
        },
      );

      final answer = response.data['choices'][0]['message']['content'];
      final tokensUsed = response.data['usage']['total_tokens'];

      _totalTokens += tokensUsed;

      return LlmResponse(
        answer: answer,
        confidence: 0.95,
        tokensUsed: tokensUsed,
        model: AppConfig.llmModel,
      );
    } catch (e) {
      debugPrint('LLM API Error: $e');
      // Fallback to mock
      return _mockGenerateAnswer(question, context, ocrText);
    }
  }

  /// Build messages for API
  List<Map<String, String>> _buildMessages(
    String question,
    List<ConversationMessage> context,
    String? ocrText,
  ) {
    final messages = <Map<String, String>>[];

    // System message
    messages.add({
      'role': 'system',
      'content': 'You are a helpful AI assistant that helps explain code, '
          'fix errors, and answer programming questions. You can see the '
          'user\'s screen and understand visual context.',
    });

    // Add recent context
    for (final msg in context.take(5)) {
      messages.add({
        'role': msg.role == MessageRole.user ? 'user' : 'assistant',
        'content': msg.text,
      });
    }

    // Add current question with OCR context
    String questionWithContext = question;
    if (ocrText != null && ocrText.isNotEmpty) {
      questionWithContext = 'Context from screen: $ocrText\n\nQuestion: $question';
    }

    messages.add({
      'role': 'user',
      'content': questionWithContext,
    });

    return messages;
  }

  /// Mock LLM response (for testing)
  Future<LlmResponse> _mockGenerateAnswer(
    String question,
    List<ConversationMessage> context,
    String? ocrText,
  ) async {
    // Simulate API delay
    await Future.delayed(const Duration(milliseconds: 500));

    final lowerQuestion = question.toLowerCase();
    String answer;

    if (lowerQuestion.contains('error') || lowerQuestion.contains('fix')) {
      answer = 'This error typically occurs when a value is null or undefined. '
          'Check your variable initialization and ensure all objects are '
          'properly created before use.';
    } else if (lowerQuestion.contains('function') || lowerQuestion.contains('does')) {
      answer = 'This function processes the input data and returns a transformed result. '
          'It appears to handle the main logic for this feature.';
    } else if (lowerQuestion.contains('how')) {
      answer = 'To implement this, follow these steps:\n'
          '1. Initialize the required variables\n'
          '2. Process the input data\n'
          '3. Apply the transformation\n'
          '4. Return the result';
    } else {
      answer = 'Based on the code visible and your question, this appears to be '
          'implementing a standard pattern for handling data processing.';
    }

    // Add OCR context if available
    if (ocrText != null && ocrText.isNotEmpty) {
      answer += '\n\nI can see from your screen: ${ocrText.substring(0, ocrText.length > 100 ? 100 : ocrText.length)}...';
    }

    // Add context reference
    if (context.length > 1) {
      answer += '\n\nBased on our conversation, I\'m providing context-aware assistance.';
    }

    final tokens = answer.split(' ').length + question.split(' ').length + 50;
    _totalTokens += tokens;

    return LlmResponse(
      answer: answer,
      confidence: 0.85 + (0.15 * (context.length / 10)),
      tokensUsed: tokens,
      model: 'mock-${AppConfig.llmModel}',
    );
  }
}

/// LLM Response Model
class LlmResponse {
  final String answer;
  final double confidence;
  final int tokensUsed;
  final String model;

  LlmResponse({
    required this.answer,
    required this.confidence,
    required this.tokensUsed,
    required this.model,
  });
}
