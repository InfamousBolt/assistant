/// Represents a chat message in the conversation
class ConversationMessage {
  final String id;
  final String text;
  final MessageRole role;
  final DateTime timestamp;
  final double? confidence;
  final String? ocrText;
  final String? imageUrl;

  ConversationMessage({
    required this.id,
    required this.text,
    required this.role,
    DateTime? timestamp,
    this.confidence,
    this.ocrText,
    this.imageUrl,
  }) : timestamp = timestamp ?? DateTime.now();

  factory ConversationMessage.fromJson(Map<String, dynamic> json) {
    return ConversationMessage(
      id: json['id'] as String,
      text: json['text'] as String,
      role: MessageRole.values.firstWhere(
        (e) => e.toString() == json['role'],
      ),
      timestamp: DateTime.parse(json['timestamp'] as String),
      confidence: json['confidence'] as double?,
      ocrText: json['ocrText'] as String?,
      imageUrl: json['imageUrl'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'text': text,
      'role': role.toString(),
      'timestamp': timestamp.toIso8601String(),
      'confidence': confidence,
      'ocrText': ocrText,
      'imageUrl': imageUrl,
    };
  }
}

enum MessageRole {
  user,
  assistant,
  system,
}
