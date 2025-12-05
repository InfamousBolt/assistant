import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/services/memory_service.dart';
import '../../../core/services/llm_service.dart';
import '../../../core/services/audio_service.dart';
import '../widgets/message_bubble.dart';
import '../widgets/listening_indicator.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final LlmService _llmService = LlmService();
  bool _isLoading = false;
  final String _lastOcrText = '';

  @override
  void initState() {
    super.initState();
    // Initialize audio service when screen loads
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeAudio();
    });
  }

  Future<void> _initializeAudio() async {
    final audioService = context.read<AudioService>();
    final initialized = await audioService.initialize();
    if (!initialized) {
      debugPrint('Failed to initialize audio service');
    }
  }

  void _startListening() async {
    final audioService = context.read<AudioService>();

    // Check if initialized
    if (!audioService.isInitialized) {
      debugPrint('Audio service not initialized, initializing now...');
      final initialized = await audioService.initialize();
      if (!initialized) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Microphone permission required. Please enable in Settings.'),
            ),
          );
        }
        return;
      }
    }

    await audioService.startListening(
      onResult: (transcript) {
        debugPrint('Transcript: $transcript');
      },
      onDetectQuestion: (isQuestion) {
        if (isQuestion) {
          _handleQuestion(audioService.lastTranscript);
        }
      },
    );
  }

  void _stopListening() async {
    final audioService = context.read<AudioService>();
    await audioService.stopListening();
  }

  Future<void> _handleQuestion(String question) async {
    if (question.trim().isEmpty) return;

    final memoryService = context.read<MemoryService>();

    // Add question to memory
    memoryService.addQuestion(question);

    setState(() {
      _isLoading = true;
    });

    try {
      // Get conversation history
      final conversationHistory = memoryService.getConversationHistory();

      // Generate answer
      final response = await _llmService.generateAnswer(
        question: question,
        context: conversationHistory,
        ocrText: _lastOcrText,
        useMock: true, // Set to false when API key is available
      );

      // Add answer to memory
      memoryService.addAnswer(response.answer, question);

      // Auto-scroll to bottom
      _scrollToBottom();

      // Check if summary needed
      if (memoryService.shouldCreateSummary()) {
        memoryService.createSummary();
      }
    } catch (e) {
      debugPrint('Error generating answer: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  void dispose() {
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('AI Assistant'),
        actions: [
          Consumer<AudioService>(
            builder: (context, audioService, child) {
              return IconButton(
                icon: Icon(
                  audioService.isListening ? Icons.mic : Icons.mic_none,
                  color: audioService.isListening ? Colors.red : null,
                ),
                onPressed: audioService.isListening
                    ? _stopListening
                    : _startListening,
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.clear_all),
            onPressed: () {
              context.read<MemoryService>().clear();
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Listening Indicator
          Consumer<AudioService>(
            builder: (context, audioService, child) {
              if (!audioService.isListening) return const SizedBox.shrink();
              return const ListeningIndicator();
            },
          ),

          // Messages List
          Expanded(
            child: Consumer<MemoryService>(
              builder: (context, memoryService, child) {
                final messages = memoryService.getConversationHistory();

                if (messages.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.chat_bubble_outline,
                          size: 64,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Ask me anything about your code!',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'I can see your screen and help explain code',
                          style: TextStyle(
                            color: Colors.grey[500],
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.all(16),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final message = messages[index];
                    return MessageBubble(message: message);
                  },
                );
              },
            ),
          ),

          // Loading Indicator
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.all(8.0),
              child: LinearProgressIndicator(),
            ),

          // Input Field
          Container(
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 4,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _textController,
                        decoration: const InputDecoration(
                          hintText: 'Ask a question...',
                          border: OutlineInputBorder(),
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                        ),
                        onSubmitted: (text) {
                          _handleQuestion(text);
                          _textController.clear();
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton.filled(
                      icon: const Icon(Icons.send),
                      onPressed: () {
                        _handleQuestion(_textController.text);
                        _textController.clear();
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
