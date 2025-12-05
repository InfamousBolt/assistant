/// Represents a chunk of memory (question, answer, keyframe, etc.)
class MemoryChunk {
  final String id;
  final MemoryChunkType type;
  final Map<String, dynamic> content;
  final DateTime timestamp;

  MemoryChunk({
    required this.id,
    required this.type,
    required this.content,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();

  factory MemoryChunk.fromJson(Map<String, dynamic> json) {
    return MemoryChunk(
      id: json['id'] as String,
      type: MemoryChunkType.values.firstWhere(
        (e) => e.toString() == json['type'],
        orElse: () => MemoryChunkType.other,
      ),
      content: json['content'] as Map<String, dynamic>,
      timestamp: DateTime.parse(json['timestamp'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type.toString(),
      'content': content,
      'timestamp': timestamp.toIso8601String(),
    };
  }
}

enum MemoryChunkType {
  keyframe,
  question,
  answer,
  summary,
  ocr,
  other,
}
