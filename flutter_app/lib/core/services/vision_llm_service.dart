import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'dart:io';
import 'dart:convert';
import '../config/app_config.dart';
import '../models/conversation_message.dart';

/// Vision LLM Service - Handles image + text to vision-capable LLMs
class VisionLlmService {
  final Dio _dio = Dio();
  int _totalCalls = 0;
  int _totalTokens = 0;

  int get totalCalls => _totalCalls;
  int get totalTokens => _totalTokens;

  /// Generate answer using image directly (GPT-4 Vision)
  Future<LlmResponse> generateAnswerWithImage({
    required String question,
    required String imagePath,
    List<ConversationMessage> context = const [],
    bool useMock = true,
  }) async {
    _totalCalls++;

    if (useMock || AppConfig.apiKey.isEmpty) {
      return _mockGenerateAnswerWithImage(question, imagePath, context);
    }

    try {
      // Read image and convert to base64
      final imageBytes = await File(imagePath).readAsBytes();
      final base64Image = base64Encode(imageBytes);

      // Build messages for GPT-4 Vision
      final messages = _buildVisionMessages(question, base64Image, context);

      final response = await _dio.post(
        '${AppConfig.apiBaseUrl}/chat/completions',
        options: Options(
          headers: {
            'Authorization': 'Bearer ${AppConfig.apiKey}',
            'Content-Type': 'application/json',
          },
        ),
        data: {
          'model': 'gpt-4-vision-preview', // or 'gpt-4o' for latest
          'messages': messages,
          'max_tokens': AppConfig.llmMaxTokens,
          'temperature': AppConfig.llmTemperature,
        },
      );

      final answer = response.data['choices'][0]['message']['content'] as String;
      final tokensUsed = response.data['usage']['total_tokens'] as int;

      _totalTokens += tokensUsed;

      return LlmResponse(
        answer: answer,
        confidence: 0.95,
        tokensUsed: tokensUsed,
        model: 'gpt-4-vision',
      );
    } catch (e) {
      debugPrint('Vision LLM API Error: $e');
      // Fallback to mock
      return _mockGenerateAnswerWithImage(question, imagePath, context);
    }
  }

  /// Build messages for vision API
  List<Map<String, dynamic>> _buildVisionMessages(
    String question,
    String base64Image,
    List<ConversationMessage> context,
  ) {
    final messages = <Map<String, dynamic>>[];

    // System message
    messages.add({
      'role': 'system',
      'content': 'You are an expert programming assistant helping in a technical interview. '
          'You can see code on the screen and should provide clear, concise explanations. '
          'Focus on the specific question asked and reference what you see in the image.',
    });

    // Add recent context (text only)
    for (final msg in context.take(3)) {
      messages.add({
        'role': msg.role == MessageRole.user ? 'user' : 'assistant',
        'content': msg.text,
      });
    }

    // Current question with image
    messages.add({
      'role': 'user',
      'content': [
        {
          'type': 'text',
          'text': question,
        },
        {
          'type': 'image_url',
          'image_url': {
            'url': 'data:image/jpeg;base64,$base64Image',
            'detail': 'high', // high, low, or auto
          },
        },
      ],
    });

    return messages;
  }

  /// Mock response with image (for testing)
  Future<LlmResponse> _mockGenerateAnswerWithImage(
    String question,
    String imagePath,
    List<ConversationMessage> context,
  ) async {
    // Simulate API delay
    await Future.delayed(const Duration(milliseconds: 500));

    final lowerQuestion = question.toLowerCase();
    String answer;

    // Generate contextual mock answers
    if (lowerQuestion.contains('function') || lowerQuestion.contains('does')) {
      answer = 'Looking at the code in the image, this function appears to process '
          'input data and return a transformed result. The structure suggests it '
          'handles the main logic for this feature.\n\n'
          'Key observations from the code:\n'
          '• Clean function structure\n'
          '• Proper parameter handling\n'
          '• Return value is computed correctly';
    } else if (lowerQuestion.contains('error') || lowerQuestion.contains('fix')) {
      answer = 'I can see the error in your code. The issue appears to be on line X '
          'where you\'re trying to access a property that might be null.\n\n'
          'To fix this:\n'
          '1. Add null checking before accessing the property\n'
          '2. Use optional chaining if available\n'
          '3. Initialize the variable properly';
    } else if (lowerQuestion.contains('how') || lowerQuestion.contains('implement')) {
      answer = 'Based on what I see in your screen, here\'s how to implement this:\n\n'
          '1. First, set up the initial structure\n'
          '2. Add the core logic in the main function\n'
          '3. Handle edge cases\n'
          '4. Test with sample inputs\n\n'
          'The code structure you have is a good starting point!';
    } else {
      answer = 'Looking at your code, I can see you\'re implementing a solution '
          'that handles data processing. The approach looks solid and follows '
          'best practices for this type of problem.\n\n'
          'The key aspects I notice:\n'
          '• Good code organization\n'
          '• Clear variable naming\n'
          '• Proper function decomposition';
    }

    // Add visual context note
    answer += '\n\n[Note: This is a mock response. With a real Vision LLM, '
        'I would see the actual code in your image and provide specific feedback.]';

    final tokens = answer.split(' ').length + question.split(' ').length + 100;
    _totalTokens += tokens;

    return LlmResponse(
      answer: answer,
      confidence: 0.90,
      tokensUsed: tokens,
      model: 'mock-gpt-4-vision',
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
