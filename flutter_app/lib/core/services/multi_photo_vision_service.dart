import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'dart:io';
import 'dart:convert';
import 'package:image/image.dart' as img;
import '../config/app_config.dart';

/// Multi-Photo Vision LLM Service - Handles multiple images at once
class MultiPhotoVisionService {
  final Dio _dio = Dio();

  // Preprocessing settings (optimized for latency + quality)
  static const bool enablePreprocessing = true;
  static const int jpegQuality = 85; // 85-90 is sweet spot
  static const int maxDimension = 2048; // GPT-4 Vision "high" detail limit

  /// Send multiple photos to Vision LLM
  Future<MultiPhotoResponse> analyzeMultiplePhotos({
    required List<String> imagePaths,
    required String question,
    bool useMock = true,
  }) async {
    if (useMock || AppConfig.apiKey.isEmpty) {
      return _mockAnalyzeMultiplePhotos(imagePaths, question);
    }

    try {
      final preprocessingStart = DateTime.now();

      // Convert all images to base64 (with optional preprocessing)
      final base64Images = <String>[];
      int originalTotalSize = 0;
      int processedTotalSize = 0;

      for (final path in imagePaths) {
        final originalBytes = await File(path).readAsBytes();
        originalTotalSize += originalBytes.length;

        List<int> finalBytes;
        if (enablePreprocessing) {
          finalBytes = await _preprocessImage(originalBytes);
          processedTotalSize += finalBytes.length;
        } else {
          finalBytes = originalBytes;
        }

        base64Images.add(base64Encode(finalBytes));
      }

      final preprocessingTime = DateTime.now().difference(preprocessingStart);
      debugPrint('🖼️ Preprocessing: ${preprocessingTime.inMilliseconds}ms');
      debugPrint('📦 Size reduction: ${originalTotalSize ~/ 1024}KB → ${processedTotalSize ~/ 1024}KB '
          '(${((1 - processedTotalSize / originalTotalSize) * 100).toStringAsFixed(1)}% smaller)');


      // Build message with multiple images
      final messages = _buildMultiImageMessage(question, base64Images);

      final response = await _dio.post(
        '${AppConfig.apiBaseUrl}/chat/completions',
        options: Options(
          headers: {
            'Authorization': 'Bearer ${AppConfig.apiKey}',
            'Content-Type': 'application/json',
          },
        ),
        data: {
          'model': 'gpt-4o', // GPT-4o supports multiple images
          'messages': messages,
          'max_tokens': 1500, // More tokens for longer problems
          'temperature': 0.3, // Lower for more focused answers
        },
      );

      final answer = response.data['choices'][0]['message']['content'] as String;
      final tokensUsed = response.data['usage']['total_tokens'] as int;

      return MultiPhotoResponse(
        answer: answer,
        photosAnalyzed: imagePaths.length,
        tokensUsed: tokensUsed,
        confidence: 0.95,
        model: 'gpt-4o',
        preprocessingTimeMs: preprocessingTime.inMilliseconds,
        sizeSavingsPercent: ((1 - processedTotalSize / originalTotalSize) * 100),
      );
    } catch (e) {
      debugPrint('Multi-photo Vision API Error: $e');
      return _mockAnalyzeMultiplePhotos(imagePaths, question);
    }
  }

  /// Preprocess image for optimal Vision LLM performance
  /// - Compress with JPEG (quality 85) to reduce file size
  /// - Resize if too large (> 2048px) to stay within API limits
  /// - Keep full color (NO grayscale - Vision LLMs need color info)
  Future<List<int>> _preprocessImage(List<int> originalBytes) async {
    try {
      // Decode image
      img.Image? image = img.decodeImage(originalBytes);
      if (image == null) return originalBytes;

      // Resize if larger than API limit
      if (image.width > maxDimension || image.height > maxDimension) {
        debugPrint('📐 Resizing from ${image.width}x${image.height}');
        if (image.width > image.height) {
          image = img.copyResize(image, width: maxDimension);
        } else {
          image = img.copyResize(image, height: maxDimension);
        }
      }

      // Compress with JPEG (keeps color, reduces file size)
      final compressed = img.encodeJpg(image, quality: jpegQuality);

      debugPrint('✅ Compressed: ${originalBytes.length ~/ 1024}KB → ${compressed.length ~/ 1024}KB');
      return compressed;
    } catch (e) {
      debugPrint('⚠️ Preprocessing failed, using original: $e');
      return originalBytes;
    }
  }

  /// Build message with multiple images for API
  List<Map<String, dynamic>> _buildMultiImageMessage(
    String question,
    List<String> base64Images,
  ) {
    final messages = <Map<String, dynamic>>[];

    // System message
    messages.add({
      'role': 'system',
      'content': 'You are an expert programming assistant. The user has sent you '
          'multiple screenshots that together show a complete coding problem. '
          'Analyze all images in sequence to understand the full problem, then '
          'provide a comprehensive answer.',
    });

    // Build content array with question + all images
    final contentArray = <Map<String, dynamic>>[];

    // Add instructional text
    contentArray.add({
      'type': 'text',
      'text': 'I am showing you ${base64Images.length} screenshots that together '
          'contain a complete coding problem. Please analyze all screenshots in '
          'order to understand the full context.\n\n'
          'Question: $question',
    });

    // Add all images
    for (int i = 0; i < base64Images.length; i++) {
      contentArray.add({
        'type': 'text',
        'text': 'Screenshot ${i + 1} of ${base64Images.length}:',
      });
      contentArray.add({
        'type': 'image_url',
        'image_url': {
          'url': 'data:image/jpeg;base64,${base64Images[i]}',
          'detail': 'high',
        },
      });
    }

    messages.add({
      'role': 'user',
      'content': contentArray,
    });

    return messages;
  }

  /// Mock analysis (for testing)
  Future<MultiPhotoResponse> _mockAnalyzeMultiplePhotos(
    List<String> imagePaths,
    String question,
  ) async {
    await Future.delayed(const Duration(seconds: 1));

    final answer = '''
📋 **Problem Analysis** (Based on ${imagePaths.length} screenshots)

I've analyzed all ${imagePaths.length} screenshots showing the complete coding problem. Here's my understanding:

**Problem Summary:**
The problem asks you to implement an Object Pool design pattern in C++. This is a creational design pattern used to manage reusable objects efficiently.

**Key Requirements I see:**
1. Create a pool that manages object instances
2. Implement acquire() to get available objects
3. Implement release() to return objects to pool
4. Handle thread-safety (if mentioned)
5. Optimize for memory reuse

**Approach:**
```cpp
template<typename T>
class ObjectPool {
private:
    std::vector<std::unique_ptr<T>> pool;
    std::queue<T*> available;
    std::mutex mtx;

public:
    T* acquire() {
        std::lock_guard<std::mutex> lock(mtx);
        if (available.empty()) {
            pool.push_back(std::make_unique<T>());
            return pool.back().get();
        }
        T* obj = available.front();
        available.pop();
        return obj;
    }

    void release(T* obj) {
        std::lock_guard<std::mutex> lock(mtx);
        available.push(obj);
    }
};
```

**Key Points:**
- Use `unique_ptr` for ownership
- `queue` for tracking available objects
- `mutex` for thread safety
- Lazy initialization (create objects on demand)

**Time Complexity:** O(1) for acquire/release
**Space Complexity:** O(n) where n is max objects

[Note: This is a mock response. With real Vision LLM, I would see the actual problem text from all ${imagePaths.length} screenshots and provide specific guidance based on exact requirements, constraints, and examples shown.]
''';

    return MultiPhotoResponse(
      answer: answer,
      photosAnalyzed: imagePaths.length,
      tokensUsed: 800,
      confidence: 0.90,
      model: 'mock-gpt-4o-multi',
    );
  }
}

/// Multi-Photo Response
class MultiPhotoResponse {
  final String answer;
  final int photosAnalyzed;
  final int tokensUsed;
  final double confidence;
  final String model;
  final int preprocessingTimeMs;
  final double sizeSavingsPercent;

  MultiPhotoResponse({
    required this.answer,
    required this.photosAnalyzed,
    required this.tokensUsed,
    required this.confidence,
    required this.model,
    this.preprocessingTimeMs = 0,
    this.sizeSavingsPercent = 0.0,
  });

  /// Get preprocessing summary
  String get preprocessingSummary =>
      'Preprocessing: ${preprocessingTimeMs}ms, '
      'Size reduced by ${sizeSavingsPercent.toStringAsFixed(1)}%';
}
